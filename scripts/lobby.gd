class_name Lobby
extends RefCounted
## An AIR HOCKEY lobby: who is in it and on which team, how the match is set
## up, and how a lobby is found on the local network. Pure logic: no nodes,
## no sockets, testable headless. The host keeps the real one and sends it to
## the guests (see Net).
##
## A lobby code on the local network is four characters that hold the last
## two numbers of the host's local address, plus a check against typos: a
## guest on the same network adds its own first two numbers to reach the
## host. A lobby on the relay (online) has five characters, chosen by the
## relay, from the same set.

const PROTOCOL := 1  ## bumped when what the phones say to each other changes
const GAME_ID := "omt-hockey"
const SIZES: Array[int] = [1, 2]  ## players per team: 1 vs 1, 2 vs 2
const GOALS: Array[int] = [3, 5, 7]  ## goals to win, the host picks
const NAME_MAX := 12
## Code characters: no 0/O and 1/I, easy to mix up.
const CODE_CHARS := "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
const CODE_LENGTH := 4
const ONLINE_CODE_LENGTH := 5

var team_size := 2
var goals := Hockey.GOALS_TO_WIN
var code := ""  ## friends type it to come in: see code_for(), or given by the relay
var players := {}  ## peer id -> {"name": String, "team": int}
var order: Array[int] = []  ## peer ids in the order they came in, the host first


func capacity() -> int:
	return team_size * 2


func full() -> bool:
	return players.size() >= capacity()


func count(team: int) -> int:
	var n := 0
	for id in players:
		if players[id]["team"] == team:
			n += 1
	return n


func team_of(id: int) -> int:
	return int(players[id]["team"]) if players.has(id) else -1


func name_of(id: int) -> String:
	return str(players[id]["name"]) if players.has(id) else ""


## A new player goes to the team with fewer players. False if the lobby is
## full or the player is already in.
func add(id: int, player_name: String) -> bool:
	if full() or players.has(id):
		return false
	var team := 1 if count(1) < count(0) else 0
	players[id] = {"name": clean_name(player_name), "team": team}
	order.append(id)
	return true


func remove(id: int) -> void:
	players.erase(id)
	order.erase(id)


## To the other team, if it has room.
func switch(id: int) -> bool:
	if not players.has(id):
		return false
	var other := 1 - team_of(id)
	if count(other) >= team_size:
		return false
	players[id]["team"] = other
	return true


## 1 vs 1 or 2 vs 2. Not fewer places than players: false. Teams that end
## up too big send their last players over.
func set_team_size(size: int) -> bool:
	if size not in SIZES or players.size() > size * 2:
		return false
	team_size = size
	for team in 2:
		for i in range(order.size() - 1, -1, -1):
			if count(team) <= team_size:
				break
			if team_of(order[i]) == team:
				players[order[i]]["team"] = 1 - team
	return true


## The next choice of goals to win, back to the first after the last.
func next_goals() -> void:
	var i := GOALS.find(goals)
	goals = GOALS[(i + 1) % GOALS.size()]


## The players of a team, in the order they came in, then 0 for each place a
## bot takes. Mallet `slot` of the team in the match belongs to entry `slot`.
func roster(team: int) -> Array[int]:
	var ids: Array[int] = []
	for id in order:
		if team_of(id) == team:
			ids.append(id)
	while ids.size() < team_size:
		ids.append(0)
	return ids


## What the guests get: plain values only.
func to_dict() -> Dictionary:
	var list := []
	for id in order:
		list.append({"id": id, "name": name_of(id), "team": team_of(id)})
	return {"size": team_size, "goals": goals, "code": code, "players": list}


## The host's lobby, as sent by to_dict(). Anything odd in it is left out.
func from_dict(d: Dictionary) -> void:
	var size := int_of(d, "size", 1)
	team_size = size if size in SIZES else 1
	var g := int_of(d, "goals", Hockey.GOALS_TO_WIN)
	goals = g if g in GOALS else Hockey.GOALS_TO_WIN
	code = clean_code(str(d.get("code", ""))).left(ONLINE_CODE_LENGTH)
	players.clear()
	order.clear()
	var list: Variant = d.get("players", [])
	if not list is Array:
		return
	for e: Variant in list:
		if not e is Dictionary or players.size() >= capacity():
			continue
		var id := int_of(e, "id", 0)
		if id <= 0 or players.has(id):
			continue
		var team := clampi(int_of(e, "team", 0), 0, 1)
		players[id] = {"name": clean_name(str(e.get("name", ""))), "team": team}
		order.append(id)


## A code as typed: in capitals, without spaces.
static func clean_code(text: String) -> String:
	return text.strip_edges().to_upper().replace(" ", "")


## Names are short, in capitals, on one line.
static func clean_name(text: String) -> String:
	var out := ""
	for c in text.strip_edges().to_upper():
		if c.unicode_at(0) >= 32 and c != "\u007f":
			out += c
	out = out.strip_edges().left(NAME_MAX)
	return out if not out.is_empty() else "?"


## The address to reach this phone on the local network: a private IPv4
## address, Wi-Fi style first. "" if there is none.
static func local_ip(addresses: PackedStringArray) -> String:
	var best := ""
	var best_rank := 0
	for a: String in addresses:
		var p := a.split(".")
		if p.size() != 4 or not a.is_valid_ip_address():
			continue
		var x := int(p[0])
		var y := int(p[1])
		var rank := 0
		if x == 192 and y == 168:
			rank = 3
		elif x == 172 and y >= 16 and y <= 31:
			rank = 2
		elif x == 10:
			rank = 1
		if rank > best_rank:
			best = a
			best_rank = rank
	return best


## The code of a lobby hosted at `ip`, "" if `ip` is not an IPv4 address.
static func code_for(ip: String) -> String:
	var p := ip.split(".")
	if p.size() != 4 or not ip.is_valid_ip_address():
		return ""
	var value := (int(p[2]) << 8) | int(p[3])
	var bits := (value << 4) | _check(value)
	var out := ""
	for i in CODE_LENGTH:
		out = CODE_CHARS[bits & 31] + out
		bits >>= 5
	return out


## The address of the lobby whose code is `text`, for a guest at `own_ip`;
## "" if the code is mistyped or this phone has no address.
static func ip_for(text: String, own_ip: String) -> String:
	var clean := clean_code(text)
	var p := own_ip.split(".")
	if clean.length() != CODE_LENGTH or p.size() != 4:
		return ""
	var bits := 0
	for c in clean:
		var k := CODE_CHARS.find(c)
		if k < 0:
			return ""
		bits = (bits << 5) | k
	var value := bits >> 4
	if bits & 15 != _check(value):
		return ""
	return "%s.%s.%d.%d" % [p[0], p[1], value >> 8, value & 255]


## What a host says on the network every second, so guests can list it.
static func beacon(
	host_name: String, players_in: int, places: int, lobby_code: String
) -> PackedByteArray:
	var data := {
		"g": GAME_ID, "v": PROTOCOL, "n": host_name, "p": players_in, "m": places, "c": lobby_code
	}
	return JSON.stringify(data).to_utf8_buffer()


## A beacon heard on the network: {"name", "players", "places", "code"}, or
## {} if it is not one of ours, from another version, or garbled.
static func parse_beacon(bytes: PackedByteArray) -> Dictionary:
	if bytes.size() > 512:
		return {}
	# Other apps broadcast too: what isn't JSON is dropped without a word.
	var json := JSON.new()
	if json.parse(bytes.get_string_from_utf8()) != OK or not json.data is Dictionary:
		return {}
	var d: Dictionary = json.data
	if str(d.get("g", "")) != GAME_ID or int_of(d, "v", -1) != PROTOCOL:
		return {}
	return {
		"name": clean_name(str(d.get("n", ""))),
		"players": clampi(int_of(d, "p", 0), 0, 4),
		"places": clampi(int_of(d, "m", 2), 2, 4),
		"code": str(d.get("c", "")).left(CODE_LENGTH),
	}


## Four bits that change when a character of the code is mistyped.
static func _check(value: int) -> int:
	var sum := 0
	for i in 4:
		sum += ((value >> (i * 4)) & 15) * (2 * i + 3)
	return sum % 16


## A whole number from a dictionary that came over the network, or
## `fallback` if it holds something else.
static func int_of(d: Dictionary, key: String, fallback: int) -> int:
	var v: Variant = d.get(key, fallback)
	if v is int:
		return v
	if v is float and is_finite(v):
		return int(v)
	return fallback
