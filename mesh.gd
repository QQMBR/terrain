
# a class for managing a half edge data structure (also called
# doubly connected edge list), the data contained is irrelevant
# of the type of vertices used, so this can be used in 2D as well 
# as 3D (or whatever)
class_name HalfEdgeStruct

var triangles := []
var half_edges := []

# get the next half edge from e that starts at the point where e ends 
# and is in the same triangle as e
static func next_half_edge(e: int):
	if e % 3 == 2:
		return e - 2
	else:
		return e + 1

static func previous_half_edge(e: int):
	if e % 3 == 0:
		return e + 2
	else:
		return e - 1

# takes an edge e and returns which triangle it belongs to 
static func triangle_number(e: int) -> int:
	# warning-ignore:integer_division
	return e / 3

func opposite_point(e: int) -> int:
	return triangles[previous_half_edge(half_edges[e])]

# takes a half edge and returns the indices of the root / base ("Begin") of the 
# half edge and the end ("End") in a dictionary with the respective entries
func half_edge_to_points(e: int) -> Dictionary:
	return {"Begin": triangles[e], "End": triangles[next_half_edge(e)]}

func next_edges(e: int) -> Array:
	var array := []
	
	# the next edge in our triangle is always a possible continuation
	var current_edge : int = next_half_edge(e)
	
	while half_edges[current_edge] != e:
		array.append(current_edge)
		
		# get the edge after the opposite edge, this always starts
		# at the same point as the current edge, which starts at
		# the point that e points to
		current_edge = next_half_edge(half_edges[current_edge])
	
	return array

func extend_half_edge_with_point(\
	e: int, \
	new_point: int, \
	opp1: int, \
	opp2: int) -> void:
		
	var new_half_edge = triangles.size()
	
	# add a triangle starting from the end of the base edge, going to 
	# the beginning of the base edge and finally to the new point
	triangles.append(triangles[next_half_edge(e)])
	triangles.append(triangles[e])
	triangles.append(new_point)
	
	# link the base edge e to its newly constructed opposite
	_link(e, new_half_edge)
	_link(opp1, new_half_edge + 1)
	_link(opp2, new_half_edge + 2)

func flip(a: int) -> int:
	var b = half_edges[a]
	
	if a == -1 or b == -1:
		return -1
	
	var new_mid_a = previous_half_edge(a)
	var new_mid_b = previous_half_edge(b)
	
	var b_opposite_point = triangles[new_mid_a]
	var a_opposite_point = triangles[new_mid_b]
	
	var new_opposite_a = half_edges[new_mid_b]
	var new_opposite_b = half_edges[new_mid_a]
	
	triangles[a] = a_opposite_point
	triangles[b] = b_opposite_point
	
	_link(new_mid_a, new_mid_b)
	_link(a, new_opposite_a)
	_link(b, new_opposite_b)
	
	return new_mid_b

func add_tri(a : int, b: int, c: int, onto_a: int = -1, onto_b: int = -1, onto_c: int = -1) -> void:
	triangles.append(a)
	triangles.append(b)
	triangles.append(c)
	
	var i = half_edges.size()
	
	_link(i, onto_a)
	_link(i + 1, onto_b)
	_link(i + 2, onto_c)

# clear any information stored in this class
func clear() -> void:
	triangles.clear()
	half_edges.clear()

# check whether the half edges array is logically sound 
func half_edges_correct() -> bool:
	for i in range(0, half_edges.size()):
		if half_edges[i] != -1 and half_edges[half_edges[i]] != i:
			return false
	
	return true

# links two half edges together so they are opposite to each other
# TODO tidy up and add parameter info
func _link(a: int, b: int) -> void:
	
	# nothing to do in this case
	if a == -1 and b == -1:
		return
	
	var size = half_edges.size()
	
	# handle the case where edge a doesn't yet exist
	if a != -1: 
		if a == size:
			half_edges.append(b)
		else:
			half_edges[a] = b
	else:
		_link(b, a)

	if b != -1:
		size = half_edges.size()
		
		if (b == size):
			half_edges.append(a)
		else: 
			half_edges[b] = a

func temp(a: int, b: int) -> void:
	_link(a, b)
