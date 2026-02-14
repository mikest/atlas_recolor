## Custom editor for manipulating 4 rows of PackedColorArray[16] gradient colors.
## Each row contains 8 ordinal gradient pairs (16 colors total). The first color
## in each pair is the start of a two-color gradient, and the second is the end.
@tool
extends EditorProperty

const NUM_ROWS: int = 4
const GRADIENTS_PER_ROW: int = 8
const COLORS_PER_GRADIENT: int = 2
const COLORS_PER_ROW: int = GRADIENTS_PER_ROW * COLORS_PER_GRADIENT
const BUTTON_SIZE: int = 24
const GRID_MARGIN: int = 16
const PANEL_MARGIN: int = 8
const PREVIEW_SIZE: int = (BUTTON_SIZE*2 + GRID_MARGIN) * NUM_ROWS + GRID_MARGIN

## Property names on the edited object for each row.
const ROW_PROPERTIES: PackedStringArray = [
	"row1",
	"row2",
	"row3",
	"row4",
]

var _grid: GridContainer
var _updating: bool = false
## Indexed as _buttons[row][color_index] for direct access.
var _buttons: Array[Array] = []
var _empty_stylebox: StyleBoxEmpty
var _background: StyleBoxTexture
var _panel: PanelContainer
var _margin: MarginContainer
var _bake: Button
var _vbox: VBoxContainer
var _hbox: HBoxContainer

# baking
var _renderer: SubViewport
var _mesh_instance: MeshInstance3D
var _camera: Camera3D
var _preview: TextureRect
var _file_dialog: FileDialog

func _init() -> void:
	print("init")
	
	# used by the colorpickerbuttons
	_empty_stylebox = StyleBoxEmpty.new()
	
	# Build the grid panel.
	_grid = GridContainer.new()
	_grid.columns = GRADIENTS_PER_ROW
	_grid.add_theme_constant_override("v_separation", GRID_MARGIN)
	_grid.add_theme_constant_override("h_separation", GRID_MARGIN)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_HEIGHT, 0)
	
	# Margin container for aligning the color editor buttons with the texture background
	_margin = MarginContainer.new()
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_margin.add_theme_constant_override("margin_left", PANEL_MARGIN)
	_margin.add_theme_constant_override("margin_top", PANEL_MARGIN)
	_margin.add_theme_constant_override("margin_right", PANEL_MARGIN)
	_margin.add_theme_constant_override("margin_bottom", PANEL_MARGIN)
	_margin.add_child(_grid)

	# Background will eventually have the underlay texture
	_background = StyleBoxTexture.new()
	_background.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	_background.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH

	# Our panel editor
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _background)
	_panel.add_child(_margin)
	_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	# Add the Editor panel and Preview side by side
	_hbox = HBoxContainer.new()
	_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	#_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hbox.add_child(_panel)
	
	# A little arrow to show what the editor applies to...
	var _label: Label = Label.new()
	_label.text = ">"
	_hbox.add_child(_label)

	# Preview of the composited texture
	_preview = TextureRect.new()
	_preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_preview.custom_minimum_size = Vector2(PREVIEW_SIZE, PREVIEW_SIZE)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hbox.add_child(_preview)
	
	# now for the stack
	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vbox.add_child(_hbox)
	
	_bake = Button.new()
	_bake.text = "Bake to Image..."
	_bake.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_bake.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_bake.pressed.connect(_on_bake_image)
	_vbox.add_child(_bake)

	add_child(_vbox)
	set_bottom_editor(_vbox)

	# construct the rendering mesh
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = QuadMesh.new()
	
	_mesh_instance.material_override = StandardMaterial3D.new()

	_camera = Camera3D.new()
	_camera.set_orthogonal(1.0,0.05,4000)

	_renderer = SubViewport.new()
	_renderer.world_3d = World3D.new()
	_renderer.world_3d.environment = Environment.new()
	_renderer.world_3d.environment.background_mode = Environment.BG_COLOR
	_renderer.world_3d.environment.background_color = Color.TRANSPARENT
	_renderer.world_3d.environment.ambient_light_color = Color(1,1,1,1)
	_renderer.world_3d.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_renderer.world_3d.environment.ambient_light_energy = 1.0
	_renderer.world_3d.environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED

	_renderer.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_renderer.size = Vector2(1024, 1024)
	_renderer.add_child(_mesh_instance)
	_renderer.add_child(_camera)
	add_child(_renderer)

	# Create 4 rows × 8 columns of gradient pair controls.
	for row_idx: int in range(NUM_ROWS):
		var row_buttons: Array[ColorPickerButton] = []

		for grad_idx: int in range(GRADIENTS_PER_ROW):
			var vbox: VBoxContainer = VBoxContainer.new()

			# First color in the gradient pair.
			var btn_start: ColorPickerButton = _create_color_button(row_idx, grad_idx * COLORS_PER_GRADIENT)
			vbox.add_child(btn_start)
			row_buttons.append(btn_start)

			# Second color in the gradient pair.
			var btn_end: ColorPickerButton = _create_color_button(row_idx, grad_idx * COLORS_PER_GRADIENT + 1)
			vbox.add_child(btn_end)
			row_buttons.append(btn_end)

			_grid.add_child(vbox)

		_buttons.append(row_buttons)
	
	# file dialog
	_file_dialog = FileDialog.new()
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	#file_dialog.root_subfolder = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	_file_dialog.filters = ["*.png ; PNG File"]
	_file_dialog.file_selected.connect(_on_file_dialog_file_selected)
	add_child(_file_dialog)
	
	_refresh_all()


func _enter_tree() -> void:
	# noew we can move camera
	_camera.set_global_position.call_deferred(Vector3(0, 0, 1))
	
	# viola!
	_preview.texture = _renderer.get_texture()


func _on_bake_image():
	_file_dialog.popup_centered_ratio(0.6)
	print("baking...")
	pass


func _on_file_dialog_file_selected(path: String):
	var tex := _renderer.get_texture()
	if tex:
		var img := tex.get_image()
		if img:
			img.save_png(path)


func _create_color_button(row_idx: int, color_idx: int) -> ColorPickerButton:
	# Create a ColorPickerButton and tag it with row/index metadata.
	var btn: ColorPickerButton = ColorPickerButton.new()
	btn.set_meta("row", row_idx)
	btn.set_meta("index", color_idx)
	btn.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	
	btn.set_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	
	btn.color_changed.connect(_on_color_changed.bind(btn))
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_stylebox_override("normal", _empty_stylebox)
	
	add_focusable(btn)
	return btn


func _get_color(row_idx: int, color_idx: int) -> Color:
	# Read a single color from the shader parameter row array.
	var mat: ShaderMaterial = get_edited_object() as ShaderMaterial
	if mat == null:
		return Color.BLACK
	var colors: PackedColorArray = mat.get_shader_parameter(ROW_PROPERTIES[row_idx])
	if colors == null or colors.size() != COLORS_PER_ROW:
		return Color.BLACK
	return colors[color_idx]


func _set_color(row_idx: int, color_idx: int, color: Color) -> void:
	# Write a single color into the shader parameter row array.
	var mat: ShaderMaterial = get_edited_object() as ShaderMaterial
	if mat == null:
		return
	var param_name: String = ROW_PROPERTIES[row_idx]
	var colors: PackedColorArray = mat.get_shader_parameter(param_name)
	if colors == null or colors.size() != COLORS_PER_ROW:
		colors = PackedColorArray()
		colors.resize(COLORS_PER_ROW)
	colors[color_idx] = color
	mat.set_shader_parameter(param_name, colors)


func _on_color_changed(color: Color, btn: ColorPickerButton) -> void:
	# Handle a color change from one of the picker buttons.
	if _updating:
		return
	var row_idx: int = btn.get_meta("row")
	var color_idx: int = btn.get_meta("index")
	_set_color(row_idx, color_idx, color)


func _update_property() -> void:
	# Called when the property value changes externally.
	if _updating:
		return
	_updating = true
	_refresh_all()
	_updating = false


func _refresh_all() -> void:
	# Sync every button color from the edited object.
	var mat: ShaderMaterial = get_edited_object() as ShaderMaterial
	if mat == null:
		return
	
	var obj: AtlasRecolorShader = get_edited_object() as AtlasRecolorShader
	
	print("updating")

	for row_idx: int in range(NUM_ROWS):
		var row_buttons: Array = _buttons[row_idx]
		for color_idx: int in range(COLORS_PER_ROW):
			var btn: ColorPickerButton = row_buttons[color_idx] as ColorPickerButton
			btn.color = _get_color(row_idx, color_idx)
	
	_renderer.size = Vector2i(obj.bake_size, obj.bake_size)
	_background.set_texture(obj.underlay_texture)
	
	var standard := _mesh_instance.material_override as StandardMaterial3D
	standard.albedo_texture = obj.underlay_texture
	_mesh_instance.material_overlay = mat
