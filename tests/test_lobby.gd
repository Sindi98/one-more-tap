extends SceneTree
## Headless tests for the AIR HOCKEY lobby: teams, places, settings, what
## goes over the network, codes and beacons. Run from the project folder:
##   godot --headless --path . --script res://tests/test_lobby.gd
## Exit code 0 = all passed.

const LobbyScript := preload("res://scripts/lobby.gd")

var _fails := 0


func _init() -> void:
	_test_teams_fill_evenly()
	_test_places()
	_test_switch_needs_room()
	_test_team_size()
	_test_goals_cycle()
	_test_roster_and_bots()
	_test_leaving()
	_test_round_trip()
	_test_junk_from_the_network()
	_test_names()
	_test_local_ip()
	_test_codes()
	_test_beacons()
	print("all tests passed" if _fails == 0 else "%d failures" % _fails)
	quit(1 if _fails > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		print("FAIL ", msg)


func _lobby(ids: Array):
	var l = LobbyScript.new()
	for id in ids:
		l.add(id, "P%d" % id)
	return l


func _test_teams_fill_evenly() -> void:
	var l = _lobby([1, 20, 30, 40])
	_check(l.count(0) == 2 and l.count(1) == 2, "two and two")
	_check(l.team_of(1) == 0 and l.team_of(20) == 1, "the host on blue, the next on red")
	_check(l.team_of(99) == -1 and l.name_of(99) == "", "nobody")


func _test_places() -> void:
	var l = _lobby([1, 20, 30, 40])
	_check(l.full() and not l.add(50, "LATE"), "a full 2 vs 2 takes nobody else")
	_check(not l.add(20, "AGAIN"), "nobody comes in twice")
	var one = LobbyScript.new()
	one.set_team_size(1)
	_check(one.add(1, "A") and one.add(2, "B") and not one.add(3, "C"), "1 vs 1: two places")


func _test_switch_needs_room() -> void:
	var l = _lobby([1, 20, 30, 40])
	_check(not l.switch(1), "the other team is full")
	l.remove(20)
	_check(l.switch(1) and l.team_of(1) == 1, "room on the other team")
	_check(not l.switch(99), "nobody to switch")


func _test_team_size() -> void:
	var l = _lobby([1, 20, 30])
	_check(not l.set_team_size(1), "three players don't fit in 1 vs 1")
	_check(not l.set_team_size(3), "3 vs 3 doesn't exist")
	l.remove(30)
	l.switch(20)  # both on blue
	_check(l.count(0) == 2, "both on blue before")
	_check(l.set_team_size(1) and l.team_size == 1, "two players fit in 1 vs 1")
	_check(l.count(0) == 1 and l.count(1) == 1, "the last one in moves over")
	_check(l.team_of(1) == 0, "the host keeps their team")


func _test_goals_cycle() -> void:
	var l = LobbyScript.new()
	var seen := []
	for i in LobbyScript.GOALS.size():
		l.next_goals()
		seen.append(l.goals)
	seen.sort()
	_check(seen == [3, 5, 7], "every choice of goals comes round: %s" % [seen])


func _test_roster_and_bots() -> void:
	var l = _lobby([1, 20, 30])
	_check(l.roster(0) == [1, 30], "blue: the host, then the third")
	_check(l.roster(1) == [20, 0], "red: one player and a bot")
	l.set_team_size(2)
	var alone = _lobby([1])
	_check(alone.roster(1) == [0, 0], "alone: the other team is all bots")


func _test_leaving() -> void:
	var l = _lobby([1, 20, 30, 40])
	l.remove(30)
	_check(not l.full() and l.roster(0) == [1, 0], "a bot takes the empty place")
	_check(l.add(50, "NEW") and l.team_of(50) == 0, "a new player takes it")


func _test_round_trip() -> void:
	var l = _lobby([1, 20, 30])
	l.set_team_size(2)
	l.next_goals()
	l.code = "26WK"
	var copy = LobbyScript.new()
	copy.from_dict(l.to_dict())
	_check(copy.to_dict() == l.to_dict(), "a guest gets the same lobby")
	_check(copy.order == l.order, "in the same order")


func _test_junk_from_the_network() -> void:
	var l = LobbyScript.new()
	l.from_dict({"size": 9, "goals": "lots", "code": 42, "players": "everyone"})
	_check(l.team_size == 1 and l.goals == 5 and l.players.is_empty(), "nonsense becomes defaults")
	(
		l
		. from_dict(
			{
				"size": 1,
				"players":
				[
					{"id": 1, "name": "HOST", "team": 0},
					{"id": 1, "name": "TWICE", "team": 1},
					{"id": -4, "name": "NEGATIVE", "team": 0},
					"not a player",
					{"id": 7.0, "name": "a" + "\n".repeat(3) + "b", "team": 8},
					{"id": 8, "name": "ONE TOO MANY", "team": 1},
				]
			}
		)
	)
	_check(l.order == [1, 7], "only sensible players, no more than the places: %s" % [l.order])
	_check(l.team_of(7) == 1 and l.name_of(7) == "AB", "teams and names cleaned up")


func _test_names() -> void:
	_check(LobbyScript.clean_name("  marco  ") == "MARCO", "trimmed and in capitals")
	_check(
		LobbyScript.clean_name("") == "?" and LobbyScript.clean_name("\t\n") == "?", "never empty"
	)
	_check(LobbyScript.clean_name("A".repeat(40)).length() == LobbyScript.NAME_MAX, "short")


func _test_local_ip() -> void:
	var none: String = LobbyScript.local_ip(PackedStringArray(["127.0.0.1", "::1"]))
	_check(none == "", "loopback only: none")
	var home: String = LobbyScript.local_ip(
		PackedStringArray(["10.0.0.5", "fe80::1", "192.168.1.23"])
	)
	_check(home == "192.168.1.23", "home Wi-Fi first")
	var office: String = LobbyScript.local_ip(PackedStringArray(["169.254.3.3", "172.20.1.9"]))
	_check(office == "172.20.1.9", "no link-local")
	var other: String = LobbyScript.local_ip(PackedStringArray(["8.8.8.8", "10.1.2.3"]))
	_check(other == "10.1.2.3", "private only")


func _test_codes() -> void:
	for ip in ["192.168.1.57", "192.168.43.1", "10.0.0.2", "172.16.255.254", "192.168.0.0"]:
		var code: String = LobbyScript.code_for(ip)
		_check(code.length() == LobbyScript.CODE_LENGTH, "a code for %s: %s" % [ip, code])
		var parts: PackedStringArray = ip.split(".")
		var guest := "%s.%s.77.88" % [parts[0], parts[1]]
		_check(LobbyScript.ip_for(code, guest) == ip, "%s back from %s" % [ip, code])
		_check(LobbyScript.ip_for(" " + code.to_lower() + " ", guest) == ip, "any case, spaces")
	var sample: String = LobbyScript.code_for("192.168.1.57")
	var mistyped := 0
	var tried := 0
	for i in sample.length():
		for c in LobbyScript.CODE_CHARS:
			if c == sample[i]:
				continue
			tried += 1
			var typo: String = sample.substr(0, i) + c + sample.substr(i + 1)
			if LobbyScript.ip_for(typo, "192.168.1.2") == "":
				mistyped += 1
	_check(mistyped > tried * 0.85, "most typos are caught: %d of %d" % [mistyped, tried])
	_check(LobbyScript.ip_for("26W", "192.168.1.2") == "", "too short")
	_check(LobbyScript.ip_for("26W0", "192.168.1.2") == "", "0 is not a code character")
	_check(LobbyScript.ip_for(sample, "") == "", "no address of our own")
	_check(LobbyScript.code_for("not an ip") == "", "no code without an address")


func _test_beacons() -> void:
	var b: PackedByteArray = LobbyScript.beacon("marco", 3, 4, "26WK")
	var info: Dictionary = LobbyScript.parse_beacon(b)
	_check(
		info == {"name": "MARCO", "players": 3, "places": 4, "code": "26WK"},
		"a beacon is read back: %s" % [info]
	)
	var other := JSON.stringify({"g": "another-game", "v": 1}).to_utf8_buffer()
	_check(LobbyScript.parse_beacon(other).is_empty(), "other games are ignored")
	var future := JSON.stringify({"g": LobbyScript.GAME_ID, "v": 99}).to_utf8_buffer()
	_check(LobbyScript.parse_beacon(future).is_empty(), "other versions are ignored")
	_check(LobbyScript.parse_beacon("{{{".to_utf8_buffer()).is_empty(), "garbage is ignored")
	var odd := {"g": LobbyScript.GAME_ID, "v": LobbyScript.PROTOCOL, "p": [], "m": 100}
	var parsed: Dictionary = LobbyScript.parse_beacon(JSON.stringify(odd).to_utf8_buffer())
	_check(parsed["players"] == 0 and parsed["places"] == 4, "odd numbers are made sensible")
