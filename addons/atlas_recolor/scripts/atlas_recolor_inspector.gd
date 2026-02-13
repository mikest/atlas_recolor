## Inspector plugin for AtlasRecolorShader resources.
@tool
extends EditorInspectorPlugin
const AtlasEditor = preload("res://addons/atlas_recolor/scripts/atlas_editor.gd")


func _can_handle(object: Object) -> bool:
	# Only handle AtlasRecolorShader instances.
	return object is AtlasRecolorShader


func _parse_begin(object: Object) -> void:
	# TODO: Add custom controls at the top of the inspector.
	pass


func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	# Replace the default editor for the "shader" property.
	if name == "shader":
		add_property_editor(name, AtlasEditor.new())
		return true
	return false


func _parse_end(object: Object) -> void:
	# TODO: Add custom controls at the bottom of the inspector.
	pass
