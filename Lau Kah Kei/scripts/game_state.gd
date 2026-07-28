extends Node

# Global state that survives scene changes (autoload singleton).
# Access from anywhere as GameState.has_key, etc.

var has_key := false
var has_photo := false

# Remembers where the player was in each scene, keyed by scene path.
# e.g. spawn_points["res://scenes/corridor.tscn"] = Vector2(918, 400)
var spawn_points := {}
