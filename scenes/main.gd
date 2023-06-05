extends Control

@onready var texture_rect : TextureRect = $HBoxContainer/TextureRect
@onready var texture : NoiseTexture2D = texture_rect.get_texture()
@onready var noise := texture.get_noise()


# Called when the node enters the scene tree for the first time.
func _ready():
	set_texture_size()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_texture_size():
	if texture_rect:
		var texture_rect_size := texture_rect.get_size()
		texture.set_width(texture_rect_size.x)
		texture.set_height(texture_rect_size.y)


func _on_texture_rect_resized():
	set_texture_size()


func _on_seed_spin_box_value_changed(value):
	noise.set_seed(value)


func _on_frequency_slider_value_changed(value):
	noise.set_frequency(value)

