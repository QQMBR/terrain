extends MeshInstance

const Poisson = preload("res://poisson.gd")

const NORTH = Vector3(0, 0, 1)

class Sorter:
	static func sort_ascending(a: Dictionary, b: Dictionary):
		return a.XY.x < b.XY.x


func _ready():
	
	# the grid will now contain all the samples so we can draw the sphere
	draw_sphere()


func stereo_project(v: Vector3) -> Vector2:
	
	#TODO handle case of v.z = 1
	var d : float = 1 - v.z
	
	var x = v.x / d
	var y = v.y / d
	
	return Vector2(x, y)


func stereo_project_all(vs: PoolVector3Array) -> PoolVector2Array:
	var arr = PoolVector2Array()
	
	for v in vs:
		arr.append(stereo_project(v))
	
	return arr

func calculate_rot(vert: Vector3, target: Vector3 = NORTH) -> Dictionary:
	var v = vert.cross(target)
	var c = vert.dot(target)
	
	# preform matrix-vector multiplication using vectors representing
	# the rows of the rotation matrix according to Rodrigues' formula
	# see https://math.stackexchange.com/questions/180418/
	var f = 1 / (1 + c)
	var row1 = Vector3(1, 0, 0) + Vector3(0, -v.z, v.y) \
		+ Vector3(-pow(v.z, 2) - pow(v.y, 2), v.y * v.x, v.z * v.x) * f
	var row2 = Vector3(0, 1, 0) + Vector3(v.z, 0, -v.x) \
		+ Vector3(v.x * v.y, -pow(v.z, 2) - pow(v.x, 2), v.z * v.y) * f
	var row3 = Vector3(0, 0, 1) + Vector3(-v.y, v.x, 0) \
		+ Vector3(v.z * v.x, v.y * v.z, -pow(v.y, 2) - pow(v.x, 2)) * f
	
	return {"R1": row1, "R2": row2, "R3": row3}


#TODO use GDScript Basis and Transform classes to rotate instead of 
#explicitly implementing it
func rotate_with(row1: Vector3, row2: Vector3, row3: Vector3, v: Vector3) -> Vector3:
	var x = v.dot(row1)
	var y = v.dot(row2)
	var z = v.dot(row3)
	
	return Vector3(x, y, z)


func project_onto_sphere(s: Vector2) -> Vector3:
	var theta = 2 * PI * s.x
	var phi = acos(1 - 2 * s.y)
	
	var x = sin(phi) * cos(theta)
	var y = sin(phi) * sin(theta)
	var z = cos(phi)
	
	return Vector3(x, y, z)


func process_sample(row1: Vector3, row2: Vector3, row3: Vector3, s: Vector2) -> Dictionary:
	var v = rotate_with(row1, row2, row3, project_onto_sphere(s))
	
	return {"XY": stereo_project(v), "XYZ": v, "Normal": v.normalized()}


func triangulate_3d(points_verts: Array) -> Array:
	
	points_verts.sort_custom(Sorter, "sort_ascending")
	
	var points := PoolVector2Array()
	var normals := PoolVector3Array()
	var verts := PoolVector3Array()
	
	for d in points_verts:
		points.append(d.XY)
		verts.append(d.XYZ)
		normals.append(d.Normal)
	
	var delaunay = DelaunaySweep.new()
	delaunay.triangulate_sorted(points)
	var mesh = delaunay.tie_hull()
	var indices = PoolIntArray(mesh.triangles) 
	
	
	# add the north pole to the sphere, this can't be in the sphere, 
	# since the stereographic projection is from the north pole
	verts.append(NORTH)
	normals.append(NORTH)
	
	# var heightmapper = Heightmapper.new()
	# verts = heightmapper.assign_height_to_triangulation(delaunay, verts)
	
	var arrays := []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	
	arrays[ArrayMesh.ARRAY_VERTEX] = verts
	arrays[ArrayMesh.ARRAY_NORMAL] = normals
	arrays[ArrayMesh.ARRAY_INDEX] = indices
	
	return arrays

func draw_sphere():
	mesh = Mesh.new()
	# Create array to hold vertice, uv, index, etc. data and resize as needed

	var verts := []
	
	var poisson := Poisson.new(0.1)
	var samples := poisson.get_all_points()
	
	var new_south: Vector2 = samples.pop_front()
	var matrix := calculate_rot(project_onto_sphere(new_south))
	
	for s in samples:
		verts.append(process_sample(matrix.R1, matrix.R2, matrix.R3, s))
	
	var arrays := triangulate_3d(verts)
	
#	# Create mesh surface from mesh array
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
