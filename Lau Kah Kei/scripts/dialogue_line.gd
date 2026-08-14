@tool
extends Resource
class_name DialogueLine

# One page of the dialogue box. The words and the face that says them sit on
# the same object, so there is no second list to keep lined up by counting:
# in the Inspector you press Add Element, type the line, and drag the
# expression into the slot right next to it.
#
# Leave `portrait` empty and the page uses the speaker's default face — the
# `portrait` field on the Interactable. Only fill it in on the pages where
# the expression actually changes.

@export_multiline var text: String = "":
	set(value):
		text = value
		# Label the array element with the line itself, so a collapsed list
		# reads as the conversation instead of a stack of identical
		# "DialogueLine" rows. Makes reordering pages possible by eye.
		resource_name = value.substr(0, 40)

@export var portrait: Texture2D


# Pressing "Add Element" on a resource array hands back a null slot that you
# can't type into until you pick a type from a dropdown. Anything exporting
# an Array[DialogueLine] runs it through here in a setter, so a new page
# turns up with its Text box and Portrait slot already there.
static func fill_blanks(pages: Array[DialogueLine]) -> Array[DialogueLine]:
	for i in pages.size():
		if pages[i] == null:
			pages[i] = DialogueLine.new()
	return pages
