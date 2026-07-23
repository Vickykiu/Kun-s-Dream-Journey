# Kun's Dream Journey — Menu and Options Foundation

This is an editable Godot 4.7.x project for Kiu Chun Woon's assignment. It includes:

- A polished, responsive main menu using the supplied Kunkun pixel-art background
- Looping menu background music
- Start, Chapter Selection, Options, and Quit navigation
- Master Volume and Music Volume controls with saved settings
- A chapter-selection screen with Chapter 1 enabled and Chapters 2–4 locked
- A placeholder Chapter 1: Orientation Day scene
- Keyboard, mouse, and controller-friendly focus navigation

## Run the Project

1. Extract the ZIP.
2. Open Godot 4.7.1 (or another Godot 4.7.x patch release).
3. Select **Import**, browse to this folder, and choose `project.godot`.
4. Click **Import & Edit**.
5. Press **F6** to run the current scene or **F5** to run the complete project.

The project opens at the main menu. Godot uses the `4.7` compatibility feature tag for all 4.7.x patch releases, including 4.7.1.

## Controls

- Mouse: point and click
- Keyboard: Arrow keys to move focus, Enter/Space to select
- Controller: D-pad/left stick to move focus, confirm button to select
- Escape: return from Options, Chapter Selection, or Chapter 1

## Project Structure

```text
assets/
  audio/menu_theme.mp3
  images/kunkun_menu_background.png
  themes/dream_theme.tres
scenes/
  main_menu.tscn
  options_menu.tscn
  chapter_selection.tscn
  chapter_1_placeholder.tscn
scripts/
  music_manager.gd
  main_menu.gd
  options_menu.gd
  chapter_selection.gd
  chapter_1_placeholder.gd
```

## Editing Notes

- The base design canvas is 1920 × 1080 and scales responsively through Godot's `canvas_items` stretch mode.
- Menu music is managed by the `MusicManager` AutoLoad, so it continues while changing between menu screens.
- Volume values are saved to `user://audio_settings.cfg`.
- Replace `chapter_1_placeholder.tscn` with the Chapter 1 rhythm-training level when it is ready, or update the scene paths in `main_menu.gd` and `chapter_selection.gd`.
- The current MP3 is user-supplied. Confirm its reuse and distribution rights before publishing.
