## A ShaderMaterial for atlas-based recoloring.
@tool
@icon("res://addons/atlas_recolor/icons/AtlasRecolorShader.svg")
class_name AtlasRecolorShader
extends ShaderMaterial
const SHADER: Shader = preload("res://addons/atlas_recolor/shader/atlas_recolor.gdshader")
const UNDERLAY: Texture2D = preload("res://addons/atlas_recolor/assets/default_texture.png")

## When baking, this will be the size of the output texture.
@export_range(2,1024,2) var bake_size: int = 1024:
	get(): return bake_size
	set(val):
		bake_size = val
		

@export var underlay_texture: Texture2D:
	get(): return get_shader_parameter("background")
	set(val):
		set_shader_parameter("background", val)

func _init() -> void:
	shader = SHADER
	underlay_texture = UNDERLAY

func _property_can_revert(prop: StringName) -> bool:
	if prop in ["shader", "underlay_texture"]:
		return true
	return false

func _property_get_revert(prop: StringName) -> Variant:
	if prop == "shader":
		return SHADER
	if prop == "underlay_texture":
		return UNDERLAY
	return null

func _validate_property(property: Dictionary):
	# hide the shader parameter
	if property.name in ["shader"]:
		property.usage = PROPERTY_USAGE_NO_EDITOR
