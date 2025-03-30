extends CharacterBody3D

# 移动参数
@export var walk_speed = 4.0
@export var sprint_speed = 7.0
@export var jump_velocity = 4.5
@export var acceleration = 10.0   # 加速度（lerp插值权重）
@export var deceleration = 15.0  # 减速度（lerp插值权重）

# 视角参数
@export var mouse_sensitivity = 0.002
@export var max_look_up = deg_to_rad(89)
@export var max_look_down = deg_to_rad(-89)

# 节点引用
@onready var neck := $Neck
@onready var camera := $Neck/Camera3D

# 物理参数
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed = walk_speed  # 当前目标速度

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		neck.rotate_x(-event.relative.y * mouse_sensitivity)
		neck.rotation.x = clamp(neck.rotation.x, max_look_down, max_look_up)
	
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# 重力与跳跃逻辑保持不变...
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# 目标速度计算
	current_speed = sprint_speed if Input.is_action_pressed("move_sprint") else walk_speed
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var target_velocity = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() * current_speed
	
	# 使用lerp平滑过渡水平速度
	var current_h_velocity = Vector3(velocity.x, 0, velocity.z)  # 当前水平速度
	var target_h_velocity = target_velocity                      # 目标水平速度
	
	# 动态选择插值系数：有输入时加速，无输入时减速
	var blend_weight = acceleration * delta if input_dir != Vector2.ZERO else deceleration * delta
	
	# 整体插值水平速度（保持Y轴速度不受影响）
	var new_h_velocity = current_h_velocity.lerp(target_h_velocity, blend_weight)
	velocity.x = new_h_velocity.x
	velocity.z = new_h_velocity.z
	
	move_and_slide()
