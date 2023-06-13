extends Control

var point_size := 5
var cell_size := 20
var vertex_color := Color(1, 0, 0)
var line_color := Color(1, 0, 0)

@onready var texture_rect : TextureRect = $HBoxContainer/Control/TextureRect
@onready var texture : NoiseTexture2D = texture_rect.get_texture()
@onready var noise := texture.get_noise()
@onready var node2d := $HBoxContainer/Control/SubViewportContainer/SubViewport/Node2D

var grid_points := []
var vertices := []
var edges := []

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
			var vertex := create_point(get_vertex_position(x, y), vertex_color)
			col.append(vertex)
		vertices.append(col)
	# Create potential edges
	for x in range(len(vertices) - 1):
		var col := []
		for y in range(len(vertices[x]) - 1):
			var cell := []
			var vertex : Vector2 = vertices[x][y].get_position()
			var adj_vertices := [
				vertices[x][y - 1].get_position(),
				vertices[x + 1][y].get_position(),
				vertices[x][y + 1].get_position(),
				vertices[x - 1][y].get_position()
			]
			for adj_vertex in adj_vertices:
				# Draw line to adjacent vertex
				var line := create_line(vertex, adj_vertex)
				cell.append(line)
			col.append(cell)
		edges.append(col)
	# Update vertices
	_on_noise_changed()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	pass


func _on_noise_changed() -> void:
	# Update color of each point
	for child in node2d.get_children():
		if not child.get_modulate() == vertex_color:
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
			var inside := true
			var outside := true
			for c_n in cell_noise:
				if c_n > 0.:
					inside = false
				if c_n <= 0.:
					outside = false
			if not (inside or outside):
				# Update vertex position
				vertex.set_position(get_vertex_position(x, y))
				# Show vertex
				vertex.set_visible(true)
			else:
				# Hide vertex
				vertex.set_visible(false)
	# Hide all edges
	for col in edges:
		for cell in col:
			for line in cell:
				line.set_visible(false)
	# Update edges
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
				# Get lines of cell
				var cell_lines = edges[x][y]
				# Check which edges have a sign change
				var cell_sign := [
					sign(noise.get_noise_2dv(cell[0].get_position())),
					sign(noise.get_noise_2dv(cell[1].get_position())),
					sign(noise.get_noise_2dv(cell[2].get_position())),
					sign(noise.get_noise_2dv(cell[3].get_position()))
				]
				var edge_sign := [
					cell_sign[0] + cell_sign[1] == 0,
					cell_sign[1] + cell_sign[3] == 0,
					cell_sign[3] + cell_sign[2] == 0,
					cell_sign[2] + cell_sign[0] == 0
				]
				for i in len(edge_sign):
					# If edge has sign change
					if edge_sign[i]:
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
							# Update line to adjacent vertex across edge
							var cell_line : Line2D = cell_lines[i]
							var start := vertex.get_position()
							var end := adj_vertex.get_position()
							cell_line.set_point_position(0, start)
							cell_line.set_point_position(1, end)
							cell_line.set_visible(true)


func create_point(v: Vector2, c: Color) -> MeshInstance2D:
	var mesh_instance := MeshInstance2D.new()
	mesh_instance.set_mesh(SphereMesh.new())
	mesh_instance.set_scale(Vector2(point_size, point_size))
	mesh_instance.set_position(v)
	mesh_instance.set_modulate(c)
	node2d.add_child(mesh_instance)
	return mesh_instance


func create_line(start: Vector2, end: Vector2) -> Line2D:
	var line := Line2D.new()
	line.add_point(start)
	line.add_point(end)
	line.set_width(point_size / 2.)
	line.set_modulate(line_color)
	node2d.add_child(line)
	return line


func get_vertex_position(x: int, y: int) -> Vector2:
	# Get grid points of cell
	var cell := [
		grid_points[x][y],
		grid_points[x + 1][y],
		grid_points[x][y + 1],
		grid_points[x + 1][y + 1]
	]
	# Get positions of grid points of cell
	var cell_positions := []
	for grid_point in cell:
		cell_positions.append(grid_point.get_position())
	# Get noise values
	var cell_noise := []
	for pos in cell_positions:
		cell_noise.append(abs(noise.get_noise_2dv(pos)))
	var cell_noise_max : float = cell_noise.max()
	# Determine weights
	var cell_weights := []
	for cn in cell_noise:
		var weight : float = cell_noise_max - cn
		cell_weights.append(weight)
	# Normalize weights
	var sum := 0.
	for weight in cell_weights:
		sum += weight
	var norm_weights := []
	for weight in cell_weights:
		norm_weights.append(weight / sum)
	# Find weighted average
	var pos := Vector2(0, 0)
	for i in range(4):
		pos += norm_weights[i] * cell_positions[i]
	return pos


func get_noise_color(v: Vector2) -> Color:
	var value := 0 if noise.get_noise_2dv(v) <= 0 else 1
	return Color(value, value, value)


func _on_seed_spin_box_value_changed(value) -> void:
	noise.set_seed(value)
	_on_noise_changed()


func _on_frequency_slider_value_changed(value) -> void:
	noise.set_frequency(value)
	_on_noise_changed()

