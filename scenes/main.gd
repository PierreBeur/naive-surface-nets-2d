extends Control

var point_size := 10
var cell_size := 20

@onready var texture_rect : TextureRect = $HBoxContainer/Control/TextureRect
@onready var texture : NoiseTexture2D = texture_rect.get_texture()
@onready var noise := texture.get_noise()
@onready var node2d := $HBoxContainer/Control/SubViewportContainer/SubViewport/Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var texture_rect_size := texture_rect.get_size()
	for x in range(cell_size/2., texture_rect_size.x, cell_size):
		for y in range(cell_size/2., texture_rect_size.y, cell_size):
			var mesh_instance := MeshInstance2D.new()
			mesh_instance.set_mesh(SphereMesh.new())
			mesh_instance.set_scale(Vector2(point_size, point_size))
			mesh_instance.set_position(Vector2(x, y))
			mesh_instance.set_modulate(get_noise_color(Vector2(x, y)))
			node2d.add_child(mesh_instance)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_noise_changed():
	for child in node2d.get_children():
		child.set_modulate(get_noise_color(child.get_position()))


func get_noise_color(v: Vector2):
#	var value := noise.get_noise_2dv(child.get_position()) + 1. * 0.5
	var value := 0. if noise.get_noise_2dv(v) <= 0 else 1.
	return Color(value, value, value)


func _on_seed_spin_box_value_changed(value):
	noise.set_seed(value)
	_on_noise_changed()


func _on_frequency_slider_value_changed(value):
	noise.set_frequency(value)
	_on_noise_changed()

