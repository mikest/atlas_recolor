## A ShaderMaterial for atlas-based recoloring.
@tool
@icon("res://addons/atlas_recolor/icons/AtlasRecolorShader.svg")
class_name AtlasRecolorShader
extends ShaderMaterial
const SHADER: Shader = preload("res://addons/atlas_recolor/shader/atlas_recolor.gdshader")


func _init() -> void:
	shader = SHADER
