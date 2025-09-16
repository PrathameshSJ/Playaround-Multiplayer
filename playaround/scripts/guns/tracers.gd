extends MeshInstance3D

@onready var muzzle = $"../body/muzzle"


func init(pos2):
	var pos1 = muzzle.position
	var draw_mesh = ImmediateMesh.new()
	mesh =draw_mesh
	draw_mesh.surface_begin(Mesh.PRIMITIVE_LINES,material_override)
	draw_mesh.surface_add_vertex(pos1)
	draw_mesh.surface_add_vertex(pos2)
	draw_mesh.surface_end()
