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
@export var tilt_sensitivity := 0.005            # 倾斜敏感度
@export var tilt_smooth_speed := 3.0            # 倾斜平滑速度
@export var tilt_return_speed := 5.0            # 回正速度

# 节点引用
@onready var neck := $Neck
@onready var camera := $Neck/ShakePivot/Camera3D
@onready var shake_pivot := $Neck/ShakePivot

# 物理参数
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed = walk_speed

# 倾斜控制变量
var current_tilt := 0.0
var target_tilt := 0.0

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
	var current_h_velocity = Vector3(velocity.x, 0, velocity.z)  # 当前水平速度
	var target_h_velocity = target_velocity                      # 目标水平速度
	
	# 动态选择插值系数：有输入时加速，无输入时减速
	var blend_weight = acceleration * delta if input_dir != Vector2.ZERO else deceleration * delta
	
	# 整体插值水平速度（保持Y轴速度不受影响）
	var new_h_velocity = current_h_velocity.lerp(target_h_velocity, blend_weight)
	velocity.x = new_h_velocity.x
	velocity.z = new_h_velocity.z
	
	move_and_slide()

func _process(delta):
	# 倾斜平滑处理
	current_tilt = lerp(current_tilt, target_tilt, delta * tilt_smooth_speed)
	target_tilt = lerp(target_tilt, 0.0, delta * tilt_return_speed)
	
	# 仅应用Z轴倾斜效果
	shake_pivot.rotation = Vector3(
		0,  # 清空X轴旋转
		0,  # 清空Y轴旋转
		current_tilt  # 仅保留Z轴倾斜
	)
