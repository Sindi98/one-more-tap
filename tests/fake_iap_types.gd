extends RefCounted
## Fake of the godot-iap plugin's OpenIAP types, with only what iap_backend.gd uses.
enum ProductQueryType { IN_APP = 0, SUBS = 1, ALL = 2 }


class ProductRequest:
	var skus: Array[String] = []
	var type: int = 0


class RequestPurchaseIosProps:
	var sku := ""


class RequestPurchaseAndroidProps:
	var skus: Array[String] = []


class RequestPurchasePropsByPlatforms:
	var google: RequestPurchaseAndroidProps
	var apple: RequestPurchaseIosProps


class RequestPurchaseProps:
	var request: RequestPurchasePropsByPlatforms
	var type: int = 0
