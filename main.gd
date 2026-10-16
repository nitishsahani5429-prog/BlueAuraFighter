extends Node3D

var game_over: bool = false
const ARENA_RADIUS: float = 17.5

var player: CharacterBody3D
var player_visuals: Node3D
var player_aura: MeshInstance3D
var player_hp: float = 100.0
const PLAYER_MAX_HP: float = 100.0
const PLAYER_SPEED: float = 7.5
var player_facing: Vector3 = Vector3.FORWARD
var punch_cd: float = 0.0
var blast_cd: float = 0.0
const PUNCH_COOLDOWN: float = 0.45
const BLAST_COOLDOWN: float = 1.4

var enemy: CharacterBody3D
var enemy_visuals: Node3D
var enemy_hp: float = 120.0
const ENEMY_MAX_HP: float = 120.0
const ENEMY_SPEED: float = 4.2
var enemy_atk_cd: float = 0.0
const ENEMY_ATK_COOLDOWN: float = 1.3

var camera_pivot: Node3D
var camera: Camera3D
var projectiles: Array = []
var aura_time: float = 0.0

var player_hp_bar: ProgressBar
var enemy_hp_bar: ProgressBar
var punch_btn: Button
var blast_btn: Button
var end_panel: Panel
var end_label: Label

var joy_base: Control
var joy_knob: Control
var joy_vector: Vector2 = Vector2.ZERO
var joy_touch_idx: int = -1
const JOY_RADIUS: float = 75.0

func _ready() -> void:
	_setup_environment()
	_build_arena()
	_build_player()
	_build_enemy()
	_build_camera()
	_build_ui()

func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.05, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.5, 0.65)
	env.ambient_light_energy = 1.0
	env.glow_enabled = false

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = false
	sun.light_energy = 1.1
	add_child(sun)

func _build_arena() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "ArenaFloor"
	add_child(floor_body)

	var col := CollisionShape3D.new()
	var cyl_shape := CylinderShape3D.new()
	cyl_shape.radius = ARENA_RADIUS + 1.0
	cyl_shape.height = 1.0
	col.shape = cyl_shape
	col.position = Vector3(0, -0.5, 0)
	floor_body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var cyl_mesh := CylinderMesh.new()
	cyl_mesh.top_radius = ARENA_RADIUS + 1.0
	cyl_mesh.bottom_radius = ARENA_RADIUS + 1.5
	cyl_mesh.height = 1.0
	cyl_mesh.radial_segments = 24
	mesh_inst.mesh = cyl_mesh
	mesh_inst.position = Vector3(0, -0.5, 0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.18, 0.25)
	mat.roughness = 0.85
	mesh_inst.material_override = mat
	floor_body.add_child(mesh_inst)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 0, 5)
	add_child(player)

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.8
	col.shape = cap
	col.position = Vector3(0, 0.9, 0)
	player.add_child(col)

	player_visuals = Node3D.new()
	player.add_child(player_visuals)

	var black_mat := StandardMaterial3D.new()
	black_mat.albedo_color = Color(0.07, 0.07, 0.09)

	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.36
	torso_mesh.height = 1.25
	torso.mesh = torso_mesh
	torso.position = Vector3(0, 0.85, 0)
	torso.material_override = black_mat
	player_visuals.add_child(torso)

	player_aura = MeshInstance3D.new()
	var aura_mesh := CapsuleMesh.new()
	aura_mesh.radius = 0.68
	aura_mesh.height = 2.25
	player_aura.mesh = aura_mesh
	player_aura.position = Vector3(0, 1.05, 0)

	var aura_mat := StandardMaterial3D.new()
	aura_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	aura_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	aura_mat.albedo_color = Color(0.15, 0.65, 1.0, 0.28)
	player_aura.material_override = aura_mat
	player_visuals.add_child(player_aura)

func _build_enemy() -> void:
	enemy = CharacterBody3D.new()
	enemy.name = "ShadowEnemy"
	enemy.position = Vector3(0, 0, -5)
	add_child(enemy)

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.5
	cap.height = 1.9
	col.shape = cap
	col.position = Vector3(0, 0.95, 0)
	enemy.add_child(col)

	enemy_visuals = Node3D.new()
	enemy.add_child(enemy_visuals)

	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0.06, 0.02, 0.1)

	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.42
	body_mesh.height = 1.5
	body.mesh = body_mesh
	body.position = Vector3(0, 0.95, 0)
	body.material_override = shadow_mat
	enemy_visuals.add_child(body)

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.position = player.position
	add_child(camera_pivot)

	camera = Camera3D.new()
	camera.position = Vector3(0, 4.8, 7.8)
	camera.rotation_degrees = Vector3(-24, 0, 0)
	camera_pivot.add_child(camera)

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root)

	player_hp_bar = ProgressBar.new()
	player_hp_bar.position = Vector2(36, 48)
	player_hp_bar.size = Vector2(340, 28)
	player_hp_bar.max_value = PLAYER_MAX_HP
	player_hp_bar.value = player_hp
	root.add_child(player_hp_bar)

	enemy_hp_bar = ProgressBar.new()
	enemy_hp_bar.position = Vector2(904, 48)
	enemy_hp_bar.size = Vector2(340, 28)
	enemy_hp_bar.max_value = ENEMY_MAX_HP
	enemy_hp_bar.value = enemy_hp
	root.add_child(enemy_hp_bar)

	joy_base = Panel.new()
	joy_base.position = Vector2(90, 460)
	joy_base.size = Vector2(180, 180)
	root.add_child(joy_base)

	joy_knob = Panel.new()
	joy_knob.size = Vector2(76, 76)
	joy_knob.position = (joy_base.size - joy_knob.size) * 0.5
	joy_base.add_child(joy_knob)

	punch_btn = Button.new()
	punch_btn.text = "PUNCH"
	punch_btn.position = Vector2(900, 520)
	punch_btn.size = Vector2(155, 115)
	punch_btn.pressed.connect(_on_punch_pressed)
	root.add_child(punch_btn)

	blast_btn = Button.new()
	blast_btn.text = "BLUE BLAST"
	blast_btn.position = Vector2(1080, 450)
	blast_btn.size = Vector2(155, 115)
	blast_btn.pressed.connect(_on_blast_pressed)
	root.add_child(blast_btn)

	end_panel = Panel.new()
	end_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_panel.visible = false
	root.add_child(end_panel)

	end_label = Label.new()
	end_label.position = Vector2(440, 230)
	end_label.size = Vector2(400, 80)
	end_panel.add_child(end_label)

	var restart_btn := Button.new()
	restart_btn.text = "RESTART"
	restart_btn.position = Vector2(510, 350)
	restart_btn.size = Vector2(260, 85)
	restart_btn.pressed.connect(_restart_game)
	end_panel.add_child(restart_btn)

func _physics_process(delta: float) -> void:
	if game_over: return
	aura_time += delta * 6.5
	var s: float = 1.0 + sin(aura_time) * 0.07
	player_aura.scale = Vector3(s, 1.0 + cos(aura_time) * 0.04, s)
	
	camera_pivot.position = camera_pivot.position.lerp(player.position, delta * 9.0)

func _on_punch_pressed() -> void:
	if game_over: return
	if player.position.distance_to(enemy.position) <= 2.6:
		enemy_hp = max(0.0, enemy_hp - 16.0)
		enemy_hp_bar.value = enemy_hp
		if enemy_hp <= 0.0: game_over = true

func _on_blast_pressed() -> void:
	if game_over: return
	enemy_hp = max(0.0, enemy_hp - 26.0)
	enemy_hp_bar.value = enemy_hp
	if enemy_hp <= 0.0: game_over = true

func _restart_game() -> void:
	player_hp = PLAYER_MAX_HP
	enemy_hp = ENEMY_MAX_HP
	player_hp_bar.value = player_hp
	enemy_hp_bar.value = enemy_hp
	game_over = false
	end_panel.visible = false
