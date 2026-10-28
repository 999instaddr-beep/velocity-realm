extends Node3D

var car: VehicleBody3D
var cam: Camera3D
var speed_label: Label
var touches := {}
var zones := {}
var zone_nodes := {}
var steer_in := 0.0
var gas := 0.0
var brake_in := 0.0
var hand := false

func _ready() -> void:
	_build_world()
	_build_car()
	_build_ui()

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	e.sky = sky
	e.background_mode = Environment.BG_SKY
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.shadow_enabled = true
	add_child(sun)

	_add_box(Vector3(0, -0.5, 0), Vector3(2000, 1, 2000), Color(0.25, 0.25, 0.27))
	for i in range(12):
		_add_box(Vector3(randf_range(-80, 80), 2, randf_range(-150, -20)),
			Vector3(4, 4, 4), Color(0.7, 0.2, 0.2))

func _add_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	bm.material = mat
	mesh.mesh = bm
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(mesh)
	body.add_child(col)
	add_child(body)

func _build_car() -> void:
	car = VehicleBody3D.new()
	car.mass = 800.0
	car.position = Vector3(0, 1.5, 0)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.8, 0.6, 4.0)
	col.shape = shape
	col.position = Vector3(0, 0.6, 0)
	car.add_child(col)
	var body_mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.8, 0.6, 4.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.4, 0.9)
	mat.metallic = 0.8
	mat.roughness = 0.25
	bm.material = mat
	body_mesh.mesh = bm
	body_mesh.position = Vector3(0, 0.6, 0)
	car.add_child(body_mesh)

	for x in [-0.95, 0.95]:
		for z in [-1.3, 1.3]:
			var w := VehicleWheel3D.new()
			w.position = Vector3(x, 0.35, z)
			w.wheel_radius = 0.35
			w.suspension_travel = 0.25
			w.suspension_stiffness = 45.0
			w.wheel_friction_slip = 3.0
			w.use_as_steering = z < 0
			w.use_as_traction = true
			var wm := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.35
			cm.bottom_radius = 0.35
			cm.height = 0.3
			wm.mesh = cm
			wm.rotation_degrees = Vector3(0, 0, 90)
			w.add_child(wm)
			car.add_child(w)
	add_child(car)

	cam = Camera3D.new()
	cam.current = true
	add_child(cam)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var size := get_viewport().get_visible_rect().size
	var h := size.y
	var w := size.x
	zones = {
		"left": Rect2(30, h - 170, 130, 130),
		"right": Rect2(180, h - 170, 130, 130),
		"brake": Rect2(w - 330, h - 170, 130, 130),
		"gas": Rect2(w - 170, h - 190, 130, 150),
		"hand": Rect2(w - 170, h - 300, 130, 90),
	}
	for n in zones:
		var r := ColorRect.new()
		r.position = zones[n].position
		r.size = zones[n].size
		r.color = Color(1, 1, 1, 0.2)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var l := Label.new()
		l.text = n.to_upper()
		r.add_child(l)
		layer.add_child(r)
		zone_nodes[n] = r
	speed_label = Label.new()
	speed_label.position = Vector2(w / 2 - 60, 20)
	speed_label.add_theme_font_size_override("font_size", 32)
	layer.add_child(speed_label)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = event.position
		else:
			touches.erase(event.index)
	elif event is InputEventScreenDrag:
		touches[event.index] = event.position
	else:
		return
	steer_in = 0.0
	gas = 0.0
	brake_in = 0.0
	hand = false
	var active := {}
	for p in touches.values():
		for n in zones:
			if zones[n].has_point(p):
				active[n] = true
	if active.has("left"): steer_in += 1.0
	if active.has("right"): steer_in -= 1.0
	if active.has("gas"): gas = 1.0
	if active.has("brake"): brake_in = 1.0
	if active.has("hand"): hand = true
	for n in zone_nodes:
		zone_nodes[n].color.a = 0.5 if active.has(n) else 0.2

func _physics_process(delta: float) -> void:
	var s := steer_in
	var g := gas
	var b := brake_in
	if s == 0.0:
		s = Input.get_axis("ui_right", "ui_left")
	if Input.is_action_pressed("ui_up"): g = 1.0
	if Input.is_action_pressed("ui_down"): b = 1.0
	car.steering = move_toward(car.steering, s * 0.5, delta * 3.0)
	var fwd := -car.global_transform.basis.z
	var v := car.linear_velocity.dot(fwd)
	car.engine_force = g * 3000.0
	car.brake = 0.0
	if b > 0.0:
		if v > 1.0:
			car.brake = 30.0
		else:
			car.engine_force = -1500.0
	if hand:
		car.brake = 40.0

	var target := car.global_position - fwd * 8.0 + Vector3(0, 3.5, 0)
	cam.global_position = cam.global_position.lerp(target, delta * 5.0)
	cam.look_at(car.global_position + Vector3(0, 1, 0))
	speed_label.text = "%d km/h" % int(car.linear_velocity.length() * 3.6)
