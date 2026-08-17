class_name ItemDB
extends RefCounted

# Every item that can end up in the player's pockets, in one place.
# Add a new item here, then call GameState.add_item("its_id") from wherever
# the player picks it up. The inventory screen picks it up automatically.
#
#   evidence = true  ->  counts toward the ending check in Chapter 3
#                        (< 2 evidence = Loop ending, >= 2 = the other routes)
#   icon             ->  optional, "" means the inventory just shows text

const ITEMS := {
	# --- Chapter 1 (Kiu Chun Woon) ---
	"torn_diary_page": {
		"name": "Torn Diary Page",
		"description": "A page torn out of a diary. The handwriting is smudged, but two lines are readable: \"Don't trust them. Run.\"",
		"evidence": true,
		"icon": "",
	},

	# --- Chapter 2 (Lau Kah Kei) ---
	"rusty_key": {
		"name": "Rusty Key",
		"description": "An old key from a corner of the storeroom, lying in the dust beside a pile of dead instruments. Too rusty to be a dorm key — it opens something else.",
		"evidence": false,
		"icon": "res://Lau Kah Kei/assets/image/items/key.webp",
	},
	"roommate_keepsake": {
		"name": "Roommate's Keepsake",
		"description": "A photo of you and Ricardo Milos at the camp gate, left on his neatly made bed. On the back, in shaky handwriting: \"Don't forget me.\"",
		"evidence": true,
		"icon": "res://Lau Kah Kei/assets/image/items/selfie pic.png",
	},
	"anomaly_usb": {
		"name": "Anomaly Log USB",
		"description": "Pulled from a hidden port on the side of the monitor room computer. One file sits on it: \"Loop record: attempt 114. Warning: core energy insufficient.\"",
		"evidence": true,
		"icon": "res://Lau Kah Kei/assets/image/items/usb.png",
	},
	"key_b13": {
		"name": "B-13 Key",
		"description": "A rusted darkroom key from the monitor room drawer. The number B-13 is scratched into the metal.",
		"evidence": false,
		"icon": "res://Lau Kah Kei/assets/image/items/key_b13.png",
	},
	"wire_cutters": {
	"name": "Wire Cutters",
	"description": "An old pair of wire cutters. It should be strong enough to cut electrical wires.",
	"icon": "res://Lew Jia Jia/assets/WireCutters.png",
	"evidence": false
	},
	"death_list": {
	"name": "Death List",
	"description": "A list containing the names of everyone at the training camp. Kun's name is circled in red and marked: 3rd time.",
	"icon": "res://Lew Jia Jia/assets/Safe_File.png",
	"evidence": true
	},
}


static func get_item(id: String) -> Dictionary:
	return ITEMS.get(id, {
		"name": id,
		"description": "",
		"evidence": false,
		"icon": "",
	})


static func is_evidence(id: String) -> bool:
	return get_item(id).get("evidence", false)


# How many evidence items exist in the whole game — used for the "2 / 4"
# counter on the inventory screen.
static func total_evidence() -> int:
	var n := 0
	for id in ITEMS:
		if ITEMS[id]["evidence"]:
			n += 1
	return n
