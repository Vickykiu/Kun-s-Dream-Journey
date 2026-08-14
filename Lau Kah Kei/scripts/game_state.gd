extends Node

# Global state that survives scene changes (autoload singleton).
# Access from anywhere as GameState.has_key, etc.

# Shorthands for the two things other scripts ask about by name (door.gd
# checks has_key before it will unlock A-02). Read-only on purpose: they are
# worked out from the inventory below, so picking the item up is the only
# thing that makes them true and there is nothing to keep in sync.
var has_key: bool:
	get:
		return has_item("rusty_key")

var has_photo: bool:
	get:
		return has_item("roommate_keepsake")

# Remembers where the player was in each scene, keyed by scene path.
# e.g. spawn_points["res://scenes/corridor.tscn"] = Vector2(918, 400)
var spawn_points := {}


# --- Inventory ----------------------------------------------------------
# Item ids in the order they were picked up. The ids come from ItemDB.
# Shared by all four chapters — Chapter 3 reads evidence_count() to decide
# which ending the player gets.

var items: Array[String] = []


func add_item(id: String) -> void:
	if id == "" or items.has(id):
		return
	items.append(id)


func has_item(id: String) -> bool:
	return items.has(id)


# Only the items flagged as evidence in ItemDB count here.
#   < 2  -> Ending 1 (Loop)
#   >= 2 -> Ending 2 (Reincarnation) or Ending 3 (Survivor), depending on route
func evidence_count() -> int:
	var n := 0
	for id in items:
		if ItemDB.is_evidence(id):
			n += 1
	return n


# --- World flags --------------------------------------------------------
# One-off "this already happened" markers that have to survive a scene
# change, e.g. the pillow has been searched, the drawer has been opened.

var flags := {}


func set_flag(id: String) -> void:
	if id != "":
		flags[id] = true


func has_flag(id: String) -> bool:
	return flags.has(id)
