extends Control

var point_size := 5
var cell_size := 30

@onready var texture_rect : TextureRect = $HBoxContainer/Control/TextureRect
@onready var texture : NoiseTexture2D = texture_rect.get_texture()
@onready var noise := texture.get_noise()
@onready var node2d := $HBoxContainer/Control/SubViewportContainer/SubViewport/Node2D

var grid_points := []
var vertices := []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Create grid points
	var texture_rect_size := texture_rect.get_size()
	for x in range(cell_size/2., texture_rect_size.x, cell_size):
		var col := []
		for y in range(cell_size/2., texture_rect_size.y, cell_size):
			var point_position := Vector2(x, y)
			var point_color := get_noise_color(point_position)
			var point := create_point(point_position, point_color)
			col.append(point)
		grid_points.append(col)
	# Create potential vertices
	for x in range(len(grid_points) - 1):
		var col := []
		for y in range(len(grid_points[x]) - 1):
			# Place vertex
			var vertex := create_point(get_vertex_position(x, y), Color(1., 0., 0.))
			col.append(vertex)
		vertices.append(col)
	# Update vertices
	_on_noise_changed()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	pass


func _on_noise_changed() -> void:
	# Update color of each point
	for child in node2d.get_children():
		if not child.get_modulate() == Color(1., 0., 0.):
			child.set_modulate(get_noise_color(child.get_position()))
	# Update vertices
	for x in len(vertices):
		for y in len(vertices[x]):
			var vertex : MeshInstance2D = vertices[x][y]
			# Get grid points of cell
			var cell := [
				grid_points[x][y],
				grid_points[x + 1][y],
				grid_points[x][y + 1],
				grid_points[x + 1][y + 1]
			]
			# Check for sign change
			var cell_noise := [
				noise.get_noise_2dv(cell[0].get_position()),
				noise.get_noise_2dv(cell[1].get_position()),
				noise.get_noise_2dv(cell[2].get_position()),
				noise.get_noise_2dv(cell[3].get_position())
			]
			var inside : bool = (cell_noise[0] <= 0.) and (cell_noise[1] <= 0.) and (cell_noise[2] <= 0.) and (cell_noise[3] <= 0.)
			var outside : bool = (cell_noise[0] > 0.) and (cell_noise[1] > 0.) and (cell_noise[2] > 0.) and (cell_noise[3] > 0.)
			if not (inside or outside):
				# Update vertex position
				vertex.set_position(get_vertex_position(x, y))
				# Show vertex
				vertex.set_visible(true)
			else:
				# Hide vertex
				vertex.set_visible(false)
	# Clear old edges
	for child in node2d.get_children():
		if child is Line2D:
			child.queue_free()
	# Draw edges
	for x in range(len(vertices) - 1):
		for y in range(len(vertices[x]) - 1):
			var vertex : MeshInstance2D = vertices[x][y]
			# Check that vertex is in cell with sign change
			if vertex.is_visible():
				# Get grid points of cell
				var cell := [
					grid_points[x][y],
					grid_points[x + 1][y],
					grid_points[x][y + 1],
					grid_points[x + 1][y + 1]
				]
				# Check which edges have a sign change
				var cell_sign := [
					sign(noise.get_noise_2dv(cell[0].get_position())),
					sign(noise.get_noise_2dv(cell[1].get_position())),
					sign(noise.get_noise_2dv(cell[2].get_position())),
					sign(noise.get_noise_2dv(cell[3].get_position()))
				]
				var edges := [
					cell_sign[0] + cell_sign[1] == 0,
					cell_sign[1] + cell_sign[3] == 0,
					cell_sign[3] + cell_sign[2] == 0,
					cell_sign[2] + cell_sign[0] == 0
				]
				for i in len(edges):
					# If edge has sign change
					if edges[i]:
						# Get adjacent vertex across edge
						var coords := Vector2i(0, 0)
						if i == 0:
							coords = Vector2i(x, y - 1)
						elif i == 1:
							coords = Vector2i(x + 1, y)
						elif i == 2:
							coords = Vector2i(x, y + 1)
						elif i == 3:
							coords = Vector2i(x - 1, y)
						if coords.x >= 0 and coords.y >= 0:
							var adj_vertex : MeshInstance2D = vertices[coords.x][coords.y]
							# Draw line to adjacent vertex across edge
							var line := Line2D.new()
							line.add_point(vertex.get_position())
							line.add_point(adj_vertex.get_position())
							line.set_width(point_size / 2.)
							line.set_default_color(Color(1, 0, 0))
							node2d.add_child(line)


func create_point(v: Vector2, c: Color) -> MeshInstance2D:
	var mesh_instance := MeshInstance2D.new()
	mesh_instance.set_mesh(SphereMesh.new())
	mesh_instance.set_scale(Vector2(point_size, point_size))
	mesh_instance.set_position(v)
	mesh_instance.set_modulate(c)
	node2d.add_child(mesh_instance)
	return mesh_instance


func get_vertex_position(x: int, y: int) -> Vector2:
	var point_tl : MeshInstance2D = points[x][y]
	var point_tl_position := point_tl.get_position()
	return point_tl.get_position() + Vector2(cell_size / 2., cell_size / 2.)


func get_noise_color(v: Vector2) -> Color:
	var value := 0 if noise.get_noise_2dv(v) <= 0 else 1
	return Color(value, value, value)


func _on_seed_spin_box_value_changed(value) -> void:
	noise.set_seed(value)
	_on_noise_changed()


func _on_frequency_slider_value_changed(value) -> void:
	noise.set_frequency(value)
	_on_noise_changed()

