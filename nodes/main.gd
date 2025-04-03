extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_node("MainMenu/SettingMenu").visible = false
	GameStatus.status = "in_game"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event):
	if event.is_action_pressed("ui_cancel") and (GameStatus.status == "setting" or GameStatus.status == "in_game"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED)
		GameStatus.status = "setting" if GameStatus.status == "in_game" else "in_game"
		get_node("MainMenu/SettingMenu").visible = GameStatus.status == "setting"
	if event.is_action_pressed("ui_cancel") and (GameStatus.status == "graphics" or GameStatus.status == "controls"):
		get_node("MainMenu/GraphicSetting").visible = false
		get_node("MainMenu/ControlSettings").visible = false
		get_node("MainMenu/SettingMenu").visible = true
		GameStatus.status = "setting"



func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_graphic_setting_back() -> void:
	get_node("MainMenu/GraphicSetting").visible = false
	get_node("MainMenu/SettingMenu").visible = true
	GameStatus.status = "setting"


func _on_graphics_pressed() -> void:
	get_node("MainMenu/GraphicSetting").visible = true
	get_node("MainMenu/SettingMenu").visible = false
	GameStatus.status = "graphics"


func _on_control_pressed() -> void:
	get_node("MainMenu/ControlSettings").visible = true
	get_node("MainMenu/SettingMenu").visible = false
	GameStatus.status = "controls"


func _on_continue_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED)
	GameStatus.status = "setting" if GameStatus.status == "in_game" else "in_game"
	get_node("MainMenu/SettingMenu").visible = GameStatus.status == "setting"
