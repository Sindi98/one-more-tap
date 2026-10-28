extends Node
## AdMob through the Poing Studios plugin (addons/admob): consent (GDPR), SDK
## start, one interstitial and one rewarded ad always loaded in the background.
## Ads loads this script only where the plugin can run, so nothing else in the
## game depends on the plugin's classes.

signal changed  ## an ad finished loading, was used, or consent options changed

const RETRY_FIRST := 15.0  ## seconds before retrying a failed load, doubled each time
const RETRY_MAX := 300.0
const REWARD_GRACE := 0.3  ## the reward callback can trail the "closed" callback

var _ids: Dictionary
var _started := false
var _interstitial: InterstitialAd
var _rewarded: RewardedAd
var _retry := {"interstitial": 0.0, "rewarded": 0.0}


func start(ids: Dictionary) -> void:
	_ids = ids
	if Engine.has_singleton("PoingGodotAdMobConsentInformation"):
		var params := ConsentRequestParameters.new()
		UserMessagingPlatform.consent_information.update(
			params, _on_consent_info_updated, _on_consent_info_failed
		)
	else:
		_start_sdk()  # editor mock ads: there is no consent form to show


func interstitial_ready() -> bool:
	return _interstitial != null


func rewarded_ready() -> bool:
	return _rewarded != null


## done.call() once the ad is closed (or could not be shown).
func show_interstitial(done: Callable) -> void:
	var ad := _interstitial
	_interstitial = null
	var cb := FullScreenContentCallback.new()
	cb.on_ad_dismissed_full_screen_content = func() -> void:
		ad.destroy()
		done.call()
		_load_interstitial()
	cb.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void:
		ad.destroy()
		done.call()
		_load_interstitial()
	ad.full_screen_content_callback = cb
	ad.show()
	changed.emit()


## done.call(earned: bool) once the ad is closed (or could not be shown).
func show_rewarded(done: Callable) -> void:
	var ad := _rewarded
	_rewarded = null
	var earned := [false]
	var finish := func() -> void:
		ad.destroy()
		done.call(earned[0])
		_load_rewarded()
	var cb := FullScreenContentCallback.new()
	cb.on_ad_dismissed_full_screen_content = func() -> void:
		get_tree().create_timer(REWARD_GRACE).timeout.connect(finish)
	cb.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void:
		finish.call()
	ad.full_screen_content_callback = cb
	var reward := OnUserEarnedRewardListener.new()
	reward.on_user_earned_reward = func(_item: RewardedItem) -> void:
		earned[0] = true
	ad.show(reward)
	changed.emit()


## GDPR: users in the EEA/UK must be able to change their choice at any time.
func privacy_options_required() -> bool:
	if not Engine.has_singleton("PoingGodotAdMobConsentInformation"):
		return false
	return (
		UserMessagingPlatform.consent_information.get_privacy_options_requirement_status()
		== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED
	)


func show_privacy_options() -> void:
	UserMessagingPlatform.show_privacy_options_form(
		func(_error: FormError) -> void: _after_consent()
	)


# --- consent ---------------------------------------------------------------


func _on_consent_info_updated() -> void:
	var info := UserMessagingPlatform.consent_information
	if (
		info.get_is_consent_form_available()
		and info.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED
	):
		UserMessagingPlatform.load_consent_form(
			func(form: ConsentForm) -> void:
				form.show(func(_error: FormError) -> void: _after_consent()),
			func(_error: FormError) -> void: _after_consent()
		)
	else:
		_after_consent()


func _on_consent_info_failed(_error: FormError) -> void:
	_after_consent()  # offline: the choice saved last time may still allow ads


## Ads are requested only once the consent flow allows it (Google's
## "canRequestAds": consent obtained, or not needed in this country).
func _after_consent() -> void:
	changed.emit()
	var status := UserMessagingPlatform.consent_information.get_consent_status()
	if (
		status == ConsentInformation.ConsentStatus.OBTAINED
		or status == ConsentInformation.ConsentStatus.NOT_REQUIRED
	):
		_start_sdk()


# --- loading ---------------------------------------------------------------


func _start_sdk() -> void:
	if _started:
		return
	_started = true
	var config := RequestConfiguration.new()
	config.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_PG
	MobileAds.set_request_configuration(config)
	MobileAds.set_ios_app_pause_on_background(true)  # freeze the game under an ad
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		_load_interstitial()
		_load_rewarded()
	MobileAds.initialize(listener)


func _load_interstitial() -> void:
	var cb := InterstitialAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_interstitial = ad
		_retry["interstitial"] = 0.0
		changed.emit()
	cb.on_ad_failed_to_load = func(_error: LoadAdError) -> void:
		_retry_later("interstitial", _load_interstitial)
	InterstitialAdLoader.new().load(_ids["interstitial"], AdRequest.new(), cb)


func _load_rewarded() -> void:
	var cb := RewardedAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: RewardedAd) -> void:
		_rewarded = ad
		_retry["rewarded"] = 0.0
		changed.emit()
	cb.on_ad_failed_to_load = func(_error: LoadAdError) -> void:
		_retry_later("rewarded", _load_rewarded)
	RewardedAdLoader.new().load(_ids["rewarded"], AdRequest.new(), cb)


## No fill or no network: try again later, waiting longer each time.
func _retry_later(kind: String, load_again: Callable) -> void:
	var wait: float = clampf(_retry[kind] * 2.0, RETRY_FIRST, RETRY_MAX)
	_retry[kind] = wait
	get_tree().create_timer(wait).timeout.connect(load_again)
