@tool
extends EditorPlugin

const AtlasRecolorShaderScript = preload("res://addons/atlas_recolor/scripts/atlas_recolor_shader.gd")
const AtlasRecolorShaderIcon = preload("res://addons/atlas_recolor/icons/AtlasRecolorShader.svg")

var _inspector_plugin: EditorInspectorPlugin


func _enable_plugin() -> void:
	# Register custom types.
	# add_custom_type("AtlasRecolorShader", "ShaderMaterial", AtlasRecolorShaderScript, AtlasRecolorShaderIcon)
	add_custom_type("AtlasRecolorShader", "ShaderMaterial", AtlasRecolorShaderScript, null)


func _disable_plugin() -> void:
	# Unregister custom types.
	remove_custom_type("AtlasRecolorShader")


func _enter_tree() -> void:
	# Initialize and register the inspector plugin.
	_inspector_plugin = preload("res://addons/atlas_recolor/scripts/atlas_recolor_inspector.gd").new()
	add_inspector_plugin(_inspector_plugin)


func _exit_tree() -> void:
	# Clean up the inspector plugin.
	remove_inspector_plugin(_inspector_plugin)
