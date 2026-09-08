extends Node

# Global state that survives scene changes (autoload singleton).
# Access from anywhere as GameState.has_key, etc.

# Shorthands for the two things other scripts ask about by name.
var has_key: bool:
	get:
		return has_item("rusty_key")

var has_photo: bool:
	get:
		return has_item("roommate_keepsake")


# ===== Player Position =====

# Remembers where the player was in each scene.
var spawn_points := {}


# ===== New Game =====

var new_game_started: bool = false


# ===== Inventory =====

var items: Array[String] = []


func add_item(id: String) -> void:
	if id == "" or items.has(id):
		return

	items.append(id)


func has_item(id: String) -> bool:
	return items.has(id)


func evidence_count() -> int:
	var n := 0

	for id in items:
		if ItemDB.is_evidence(id):
			n += 1

	return n


# ===== World Flags =====

var flags := {}


func set_flag(id: String) -> void:
	if id != "":
		flags[id] = true


func has_flag(id: String) -> bool:
	return flags.has(id)
