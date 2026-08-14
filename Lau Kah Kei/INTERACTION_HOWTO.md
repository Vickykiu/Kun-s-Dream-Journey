# Interaction, Dialogue & Inventory — How To Use

Owner: **Lau Kah Kei** (Chapter 2)
For: Chun Woon (Ch.1), Jia Jia (Ch.3), Hong Fei (Ch.4)

These systems are shared across all four chapters. **Everything is already
registered as an autoload in `project.godot` — you do not install anything.**
Drag a prefab into your scene, fill in the Inspector, done. No new script.

If you need something these don't do, **connect to a signal** (see §8) rather
than editing my scripts — otherwise the next merge overwrites your change and
breaks the other three chapters.

---

## 1. What you get

| Thing | What it is | Where |
|---|---|---|
| **Interactable** | Walk up → prompt → press E → text box | `scenes/interactable.tscn` |
| **Pickup** | Walk up → E → item fills the screen → E → into the bag | `scenes/pickup.tscn` |
| **PromptLayer** | The "Press E to…" label every prompt is printed on | `scenes/prompt_label.tscn` |
| **Dialogue** | Autoload. Text box at the bottom of the screen | `Dialogue.show_lines([...])` |
| **ItemView** | Autoload. Holds one object up, full screen | `await ItemView.show_item(tex)` |
| **Inventory** | Autoload. Press **I** anywhere. Builds itself | nothing to do |
| **GameState** | Autoload. Items + flags that survive scene changes | `GameState.set_flag(...)` |

Keys are already bound project-wide: **E** = `interact`, **I** = `inventory`.

---

## 2. One-time setup per scene (do this first!)

**Drag `Lau Kah Kei/scenes/prompt_label.tscn` into your scene.**

Every prompt in the game ("Press E to look", "Locked — needs a key") is printed
on whatever `Label` is in the group `prompt` in the current scene. **No label →
no prompt.** The interaction still works, there is just nothing on screen, which
looks exactly like a broken script. This is the #1 thing people get wrong.

Move it or restyle it however you like — just keep it in the `prompt` group.

The player also has to be my `scenes/player.tscn` (node named `Player`, in group
`player`). **Chapter 3 and Chapter 4 already instance it**, so you're fine.

---

## 3. Recipe: something to look at

1. Drag **`scenes/interactable.tscn`** into your scene.
2. Move it over the object and resize its `CollisionShape2D` to cover it.
3. In the Inspector:
   - **Prompt Text** — `"Press E to look at the desk"`
   - **Lines** — press *Add Element*, type the line. Each element is **one page**
     of the text box. A `Portrait` slot sits right next to the text: drag a face
     in only on the pages where the expression actually changes.
   - **Speaker Name** / **Portrait** — the default name + face for all pages.
     Leave both empty for furniture (plain text, no face — that is the right
     look for "you look at a bed").

That's the whole thing. Useful extras, all optional:

| Field | What it does |
|---|---|
| `lines_after` | Different text from the 2nd look onward. Empty = repeat `lines` |
| `flag_id` | Remembers "already searched" across scene changes. **Set this on anything important** |
| `requires_flag` | Stays inert until that flag is set — use it to gate a puzzle |
| `locked_text` | Shown while locked. Empty = no prompt at all, as if nothing were there |
| `one_shot` | Works once, then the prompt stops appearing |
| `hide_after` | Disappears after the first look |
| `item_id` | Also hands over an item — see §5 |

---

## 4. Recipe: something to pick up

1. Drag **`scenes/pickup.tscn`** in, drop your art on its `Sprite` node, resize
   the collision shape.
2. Set **Item Id** to an id from `ItemDB` (§5). That is the only required field.
3. Optional: **Lines** = what Kun says once it is in his pocket. **Back Texture**
   = the other side, for something with writing on the back.

The flow is fixed on purpose, so every item in the game feels the same:

```
walk up  ->  "Press E to pick up"
press E  ->  item fills the screen (ItemView)
press E  ->  turns over — only if back_texture is set
press E  ->  into the bag, object disappears, Kun reacts
```

Picked-up items stay picked up — walking back into the room does not lay the
item out on the floor again.

---

## 5. Adding a new item

Add one entry to `scripts/item_db.gd`, then use that id anywhere:

```gdscript
"broken_mirror": {
    "name": "Broken Mirror",
    "description": "Shown in the inventory under the name.",
    "evidence": true,        # counts toward the Chapter 3 ending check
    "icon": "res://Tay Hong Fei/assets/mirror.png",   # "" = text only
},
```

- Skip this and the inventory shows the raw id with no description.
- `icon` doubles as the default close-up image, so most items need no art setup.
- `evidence: true` feeds `GameState.evidence_count()` — **< 2 = Loop ending,
  >= 2 = the other routes.** Only flag things that are actual proof.

To give an item from a drawer or a computer instead of off the floor, put
`item_id` on an **Interactable**: it plays `lines`, then runs the exact same
close-up → press E → pocket flow, then `pickup_lines`.

---

## 6. Talking from your own script

```gdscript
Dialogue.show_lines(["The door won't move.", "Something is holding it."])
Dialogue.show_lines(lines, portrait_texture, "Teacher Mei")   # face + name tag
await Dialogue.finished                                       # wait until closed
```

Pages can be plain `String`s or `DialogueLine` resources, mixed freely. The
player is frozen while the box is up and every key except E is swallowed, so
nothing behind it can fire.

**Always `await` before starting a cutscene or a puzzle**, otherwise it opens
underneath the text box.

---

## 7. Holding something up / the bag

```gdscript
await ItemView.show_item(front_texture)                # one look
await ItemView.show_item(front_texture, back_texture)  # E turns it over first
```

Inventory needs **nothing** from you — it builds its own UI and reads
`GameState.items`. Just make sure items go in through `GameState.add_item("id")`
(both prefabs already do this).

Before you open your own fullscreen UI, check that nothing else owns the screen:

```gdscript
if Dialogue.is_active() or ItemView.is_active() or Inventory.is_open():
    return
```

---

## 8. Hooking up your own logic

Don't edit `interactable.gd` / `pickup.gd`. Connect a signal instead — Node tab
→ pick the signal → choose your node.

| Signal | Fires |
|---|---|
| `interacted(node)` | Interactable: the moment E is pressed, before anything shows |
| `finished(node)` | Interactable: everything is over — text read, item pocketed. **Start puzzles / cutscenes here** |
| `collected(node)` | Pickup: the item is in the bag |

Cross-scene state goes through GameState, never a local `var`:

```gdscript
GameState.set_flag("b13_safe_opened")
if GameState.has_flag("b13_safe_opened"): ...
GameState.has_item("key_b13")
```

---

## 9. Bonus: doors

`scripts/door.gd` on an Area2D does scene transitions. Set `target_scene`, and
optionally `requires_key` + `locked_text`. It remembers where the player stood,
so coming back puts them at the door instead of at the default spawn.

---

## 10. When it doesn't work

| Symptom | Cause |
|---|---|
| Walk up, nothing appears | No `prompt_label.tscn` / no Label in the `prompt` group in that scene |
| Prompt shows, E does nothing | `Dialogue`, `ItemView` or `Inventory` is still open — they take E first |
| Nothing at all happens | `CollisionShape2D` missing or too small, or your player node isn't named `Player` |
| Item shows as a raw id in the bag | Not added to `ItemDB` |
| Text box skips its first page | You called `Dialogue.show_lines()` inside the same input event that closed something else — `await` first |
| Object comes back after leaving the room | No `flag_id` set on the Interactable |
| Esc quits to the main menu mid-dialogue | Shouldn't happen — the overlay is hidden automatically. Tell me if it does |
