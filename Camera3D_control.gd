extends Camera3D

## Global position of pivot point
@export var pivot_pos: Vector3 = Vector3.ZERO:
	set(value):
		pivot_pos = value
		_place_pivot()
		
#@export_group("Camera Control")
## Mouse button used for orbital movement
@export_enum("LEFT_BUTTON", "MIDDLE_BUTTON")
var action_mouse_button: String = "MIDDLE_BUTTON"
@export_range(0.5, 2, 0.1) var rotation_speed: float = 1.0
@export_range(0.5, 4, 0.1) var translation_speed: float = 1.0
@export_range(0.5, 2, 0.1) var zoom_speed: float = 1.0
@export var zoom_in: float = 1:
	set(value):
		if value > 0:
			zoom_in = value
@export var zoom_out: float = 10:
	set(value):
		if value > zoom_in:
			zoom_out = value

var _state: int = State.IDLE
var _cam_from_pivot_dist: float
var _pivot_transform: Transform3D
var _pole_mesh := ImmediateMesh.new()
var _pole_mesh_instance := MeshInstance3D.new()
var _pole_mat := StandardMaterial3D.new()

enum State{
	IDLE,
	ROTATED,
	TRANSLATED,
	LOOKAT,
}

const _MOUSE_SENSITIVITY = 0.002
const _WHEEL_SENSITIVITY = 0.1
const _ANGLE_GAP = PI/128

func _ready() -> void:
	_place_pivot()
	_pole_mat.vertex_color_use_as_albedo = true
	_pole_mesh_instance.mesh = _pole_mesh
	_pole_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_pole_mesh_instance)
	
	$"../CSGBox3D".size.x = float($"../main/LineEdit_L".text)
	$"../CSGBox3D".size.y = float($"../main/LineEdit_h".text)
	$"../CSGBox3D".size.z = float($"../main/LineEdit_b".text)
	$"../CSGBox3D".scale = Vector3(0.1,0.1,0.1)
	
	$"../DirectionalLight3D".rotate_x(5)
	#self.position.z = 17
func _place_pivot():
	if is_inside_tree() and global_position != pivot_pos:
		_pivot_transform = Transform3D(Basis(), pivot_pos)
		_pivot_transform = _pivot_transform.looking_at(global_position)
		_cam_from_pivot_dist = global_position.distance_to(pivot_pos)
		var new_cam_pos: Vector3 = _pivot_transform.basis.z * -(_cam_from_pivot_dist) + pivot_pos
		look_at_from_position(new_cam_pos, pivot_pos)

func _process(_delta: float) -> void:
	
	if Engine.is_editor_hint():
		_place_pivot()
		var global_tr_inv = global_transform.inverse()
		var pivot_global_pos = (global_tr_inv * _pivot_transform).origin
		_pole_mesh.clear_surfaces()
		_pole_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _pole_mat)
		_pole_mesh.surface_set_color(Color.WEB_PURPLE)
		_pole_mesh.surface_add_vertex(Vector3.ZERO)
		_pole_mesh.surface_add_vertex(pivot_global_pos)
		_pole_mesh.surface_end()

	#print($"../HSlider".value)
	#size += $"../HSlider".value
	
	#position.z =1+ $"../HSlider".value
	
	#near = near*($"../HSlider".value-50)/2
	#size= size*($"../HSlider".value-50)
	
func _unhandled_input(event: InputEvent) -> void:
	if not current: return
	
	if event is InputEventMouseButton:
		match action_mouse_button:
			"MIDDLE_BUTTON":
				if event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
					if event.shift_pressed:
						_state = State.TRANSLATED
					else:
						_state = State.ROTATED
				elif event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
					_state = State.IDLE
			"LEFT_BUTTON":
				if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					if event.shift_pressed:
						_state = State.TRANSLATED
					else:
						_state = State.ROTATED
				elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
					_state = State.IDLE
#		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
#			_state = State.LOOKAT
#		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
#			_state = State.IDLE
			
	match(_state):
		State.IDLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			pivot_pos = _pivot_transform.origin
		State.ROTATED, State.TRANSLATED, State.LOOKAT:
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
			
	if event is InputEventMouseMotion and _state == State.ROTATED:
		var euler_angles = _pivot_transform.basis.get_euler()
		euler_angles.x += event.relative.y * _MOUSE_SENSITIVITY * rotation_speed
		euler_angles.x = clampf(euler_angles.x, -PI/2 + _ANGLE_GAP, PI/2 - _ANGLE_GAP)
		euler_angles.y -= event.relative.x * _MOUSE_SENSITIVITY * rotation_speed
		_pivot_transform.basis = Basis.from_euler(euler_angles)
		# Move camera position and look at
		_cam_from_pivot_dist = global_position.distance_to(pivot_pos)
		var new_cam_pos: Vector3 = _pivot_transform.basis.z * -(_cam_from_pivot_dist) + pivot_pos
		if global_position != pivot_pos:
			look_at_from_position(new_cam_pos, pivot_pos)
			
	if event is InputEventMouseMotion and _state == State.TRANSLATED:
		_pivot_transform = _pivot_transform.translated_local(
			Vector3(event.relative.x * _MOUSE_SENSITIVITY * translation_speed,
					event.relative.y * _MOUSE_SENSITIVITY * translation_speed,
					0))
		global_transform = global_transform.translated_local(
			Vector3(-event.relative.x * _MOUSE_SENSITIVITY * translation_speed,
					event.relative.y * _MOUSE_SENSITIVITY * translation_speed,
					0))
			
#	if event is InputEventMouseMotion and _state == State.LOOKAT:
#		_pivot_transform = _pivot_transform.translated_local(
#			Vector3(-event.relative.x * _MOUSE_SENSITIVITY,
#					-event.relative.y * _MOUSE_SENSITIVITY,
#					0))
#		pivot_pos = _pivot_transform.origin
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		if global_position.distance_to(pivot_pos) > zoom_in:
			translate_object_local(Vector3.FORWARD * _WHEEL_SENSITIVITY * zoom_speed)
			size -= 1
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		if global_position.distance_to(pivot_pos) < zoom_out:
			translate_object_local(Vector3.FORWARD * -_WHEEL_SENSITIVITY * zoom_speed)
			size += 1
	
	#print(size)
	
#var mouse_position
#var delta:Vector2
#func _on_InputEvent(event):
	#if event is InputEventMouseButton:
		#if event.pressed:
			## マウスボタンが押されたとき
			#mouse_position = event.position
		#else:
			## マウスボタンが離されたとき
			#pass
	#elif event is InputEventMouseMotion:
		## マウスが動いたとき
		#delta = event.position - mouse_position
		#mouse_position = event.position
		#print(mouse_position)
		## マウスの移動量を使用して何か処理を行う
		#pass

var flag:bool
func _on_button_pressed():
	
	#if projection == Camera3D.PROJECTION_PERSPECTIVE:
	if flag == false:
	#projection = Camera3D.PROJECTION_PERSPECTIVE
		projection = Camera3D.PROJECTION_ORTHOGONAL
		flag = true
		$"../TabContainer/dSize/Button".text = "ORTHOGONAL"
		#near = 10
	else:
		projection = Camera3D.PROJECTION_PERSPECTIVE
		flag = false
		$"../TabContainer/dSize/Button".text = "PERSPECTIVE"
	print(flag)		
	#if projection == Camera3D.PROJECTION_ORTHOGONAL:
	##projection = Camera3D.PROJECTION_PERSPECTIVE
		#projection = Camera3D.PROJECTION_PERSPECTIVE
	#if flag == true:
	##projection = Camera3D.PROJECTION_PERSPECTIVE
		#projection = Camera3D.PROJECTION_PERSPECTIVE
		#flag = false
		

	pass # Replace with function body.

var SliderVal:float
var scaelVal:float
func _on_h_slider_drag_ended(value_changed):
	print(value_changed)
	SliderVal = $"../TabContainer/dSize/HSlider".value
	scaelVal = float($"../TabContainer/dSize/LineEdit".text)
	$"../CSGBox3D".scale = Vector3(scaelVal*SliderVal,scaelVal*SliderVal,scaelVal*SliderVal)
	pass # Replace with function body.
#$"../HSlider".value


func _on_line_edit_text_changed(new_text):
	scaelVal = float($"../TabContainer/dSize/LineEdit".text)
	$"../CSGBox3D".scale = Vector3(scaelVal*SliderVal,scaelVal*SliderVal,scaelVal*SliderVal)	
	pass # Replace with function body.


func _on_h_slider_2_drag_ended(value_changed):
	var lightDispX = $"../TabContainer/tb2/HSlider2".value
	print(lightDispX)
	$"../DirectionalLight3D".rotate_x($"../TabContainer/tb2/HSlider2".value)
	pass # Replace with function body.
