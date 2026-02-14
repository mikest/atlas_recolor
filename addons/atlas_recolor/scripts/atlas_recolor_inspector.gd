## Inspector plugin for AtlasRecolorShader resources.
@tool
extends EditorInspectorPlugin
const AtlasEditor = preload("res://addons/atlas_recolor/scripts/atlas_editor.gd")


func _can_handle(object: Object) -> bool:
	# Only handle AtlasRecolorShader instances.
	return object is AtlasRecolorShader


# list of props we should update the editor for
var _update_props: Array = [
			"bake_size",
			"underlay_texture",
			"shader_parameter/background",
			"shader_parameter/row1",
			"shader_parameter/row2",
			"shader_parameter/row3",
			"shader_parameter/row4"
		]


func _parse_begin(object: Object) -> void:
	add_property_editor_for_multiple_properties("Atlas Overlay", _update_props, AtlasEditor.new())
	pass


func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	return false


func _parse_end(object: Object) -> void:
	pass
