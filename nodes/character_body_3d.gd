extends CharacterBody3D

# 移动参数
@export var walk_speed = 3.3
@export var sprint_speed = 5.0
@export var jump_velocity = 4.5
@export var acceleration = 10.0
@export var deceleration = 15.0

# 视角参数
@export var mouse_sensitivity = 0.002
@export var max_look_up = deg_to_rad(89)
@export var max_look_down = deg_to_rad(-89)

# 倾斜参数
@export var tilt_max_angle := deg_to_rad(15.0)  # 最大倾斜角度
@export var tilt_sensitivity := 0.005           # 倾斜敏感度
@export var tilt_smooth_speed := 3.0            # 倾斜平滑速度
@export var tilt_return_speed := 5.0            # 回正速度

# 摄像机晃动参数
@export var walk_shake_angle := deg_to_rad(0.5)  # 走路时X轴旋转幅度
@export var sprint_shake_angle := deg_to_rad(1.0) # 跑步时X轴旋转幅度
@export var shake_frequency := 3.0               # 晃动频率（Hz）
@export var shake_smooth := 3.0                 # 晃动幅度变化的平滑速度

# 节点引用
@onready var neck := $Neck
@onready var camera := $Neck/ShakePivot/Camera3D
@onready var shake_pivot := $Neck/ShakePivot

# 物理参数
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed = walk_speed

# 控制变量
var current_tilt := 0.0
var target_tilt := 0.0
var shake_time := 0.0
var current_shake_angle := 0.0
var target_shake_angle := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# 初始化节点位置
	shake_pivot.position = Vector3.ZERO
	shake_pivot.rotation = Vector3.ZERO

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# 基础视角旋转
		rotate_y(-event.relative.x * mouse_sensitivity)
		neck.rotate_x(-event.relative.y * mouse_sensitivity)
		neck.rotation.x = clamp(neck.rotation.x, max_look_down, max_look_up)
		
		# Bodycam倾斜计算
		target_tilt = clamp(-event.relative.x * tilt_sensitivity, -tilt_max_angle, tilt_max_angle)

func _physics_process(delta):
	# 重力与跳跃
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# 目标速度计算
	current_speed = sprint_speed if Input.is_action_pressed("move_sprint") else walk_speed
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var target_velocity = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() * current_speed
	
	# 使用lerp平滑过渡水平速度
	var current_h_velocity = Vector3(velocity.x, 0, velocity.z)
	var target_h_velocity = target_velocity
	var blend_weight = acceleration * delta if input_dir != Vector2.ZERO else deceleration * delta
	
	var new_h_velocity = current_h_velocity.lerp(target_h_velocity, blend_weight)
	velocity.x = new_h_velocity.x
	velocity.z = new_h_velocity.z
	
	move_and_slide()

func _process(delta):
	# 倾斜平滑处理
	current_tilt = lerp(current_tilt, target_tilt, delta * tilt_smooth_speed)
	target_tilt = lerp(target_tilt, 0.0, delta * tilt_return_speed)
	
	# 摄像机晃动处理
	var is_moving = Input.get_vector("move_left", "move_right", "move_forward", "move_back") != Vector2.ZERO && is_on_floor()
	var desired_shake_angle = 0.0
	
	if is_moving:
		desired_shake_angle = sprint_shake_angle if Input.is_action_pressed("move_sprint") else walk_shake_angle
		shake_time += delta * shake_frequency
	else:
		desired_shake_angle = 0.0
		shake_time = 0.0  # 静止时重置时间
	
	target_shake_angle = desired_shake_angle
	current_shake_angle = lerp(current_shake_angle, target_shake_angle, delta * shake_smooth)
	
	# 计算X轴晃动（使用正弦波模拟步伐节奏）
	var shake_rotation_x = sin(shake_time * TAU) * current_shake_angle
	
	# 应用组合效果（X轴晃动 + Z轴倾斜）
	shake_pivot.rotation = Vector3(
		shake_rotation_x,  # X轴步伐晃动
		0,                 # Y轴保持不动
		current_tilt       # Z轴鼠标倾斜
	)
