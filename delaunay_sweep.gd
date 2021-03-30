
#TODO long term implement sampling so that it's already sorted if more
# performance is needed
#TODO separate half edge structure and helper functions
# 	  into separate file
class_name DelaunaySweep

const epsilon = 3.3306690738754716e-16

var stack := []

var predicates = Predicates.new()
var mesh = HalfEdgeStruct.new()

var hull := []

var points: Array

## print out the vertices in matlab format
#func print_matlab(ps: PoolVector2Array = points) -> String:
#	var x = ""
#	var y = ""
#
#	for p in ps:
#		x += str(p.x) + " "
#		y += str(p.y) + " "
#
#	var tris = ""
#
#	# warning-ignore:integer_division
#	for i in range(0, triangles.size() / 3):
#		tris += "%s %s %s; " % [triangles[3*i], triangles[3*i+1], triangles[3*i+2]]
#
#	var all = x + ":" + y + ":" + tris
#	return all

# add a final point to the triangulation that gets connected to 
# all of the hull edges
func tie_hull() -> PoolIntArray:
	
	# TODO maybe separate triangle creation from legalization and
	# use the creation part to connect all the hull edges to a new, 
	# "ghost" point 
	
	var add = hull.size() * 3
	
	var new_point = points.size()
	var old_size = mesh.triangles.size()
	
	mesh.triangles.resize(old_size + add)
	mesh.half_edges.resize(mesh.half_edges.size() + add)
	
	for i in range(0, hull.size()):
		
		# make a cw triangle
		mesh.triangles[old_size + 3 * i] = new_point
		mesh.triangles[old_size + 3 * i + 1] = mesh.triangles[_next_half_edge(hull[i])]
		mesh.triangles[old_size + 3 * i + 2] = mesh.triangles[hull[i]]
		
		mesh.temp(hull[i], old_size + 3 * i + 1)
		mesh.temp(old_size + posmod(3 * i + 5, add), old_size + 3 * i)
	
	return PoolIntArray(mesh.triangles)


func _boundary_is_convex() -> bool:
	var sgn := 0
	
	for i in range(0, hull.size()):
		var a : Vector2 = points[mesh.triangles[hull[i]]]
		var b : Vector2 = points[mesh.triangles[hull[posmod(i+1, hull.size())]]]
		var c : Vector2 = points[mesh.triangles[hull[posmod(i+2, hull.size())]]]
		
		var dx1 = b.x - a.x
		var dy1 = b.y - a.y
		var dx2 = c.x - b.x
		var dy2 = c.y - b.y
		
		var z = sign(dx1 * dy2 - dy1 * dx2)
		
		# set the sign to the sign of the z component on the first run
		if sgn == 0:
			sgn = z
		
		# the sign must be non zero and the same all the way through
		if z == 0 or sgn != z:
				return false
	
	return true 


func triangulate_sorted(points_: PoolVector2Array) -> HalfEdgeStruct:
	
	points = points_
	
	_reset()
	
	# create the first triangle from the first three points
	_init_first_triangle()
	
	# iterate through the rest of the points
	for p in range(3, points.size()):
		var h := 0
		
		while _is_left_of_half_edge(hull[h], points[p]):
			h += 1
		
		# if the first edge is already part of a triangle with the new point
		# we must walk backwards through the hull as well
		if h == 0:
			while not _is_left_of_half_edge(hull[h], points[p]):
				h = posmod(h - 1, hull.size())
			
			# the last h doesn't face the edge anymore, so get the first one 
			# that does
			h = posmod(h + 1, hull.size())
		
		
		# walk forwards from the first relevant edge until the section
		# of the boundary facing "towards" the new point has been "triangulated"
		while not _is_left_of_half_edge(hull[h], points[p]):
			h = _create_triangle_along_hull_edge(h, p)
	
	return mesh


func _init_first_triangle():
	
	# add the first triangle so that it is in ccw order; the 
	# half edge data is empty for all edges
	if predicates.is_ccw(points[0], points[1], points[2]):
		mesh.add_tri(0, 1, 2)
	else: 
		mesh.add_tri(0, 2, 1)
	
	for i in range(0, 3):
		# the hull contains the first three half edges, order is already
		# determined by placement in the triangles array
		hull.append(i)


func _create_triangle_along_hull_edge(h: int, p: int) -> int:
	var e = hull[h]
	var new_half_edge = mesh.triangles.size()

	# we are trying to create a ccw triangle from a boundary edge
	# that is going ccw, so the boundary edge should be reversed
	# when creating the new triangle
	
	# add edge opposite to the new point which starts at the end of the 
	# hull edge
	#triangles.append(triangles[_next_half_edge(e)])
	
	# add first the lower and than the upper edge
	#triangles.append(triangles[e])
	#triangles.append(p)
	
	#_link(e, new_half_edge)

	hull.remove(h)
	
	var next_h = posmod(h, hull.size())
	var prev_h = posmod(h - 1, hull.size())
	
	# the opposite half edges for the non-base edges of the new 
	# triangle to be added; the lower edge can have an opposite
	# based on the hull, but the upper edge opposite will 
	# always stay -1, it's written here for clarity
	var lower_edge_opposite = -1
	var upper_edge_opposite = -1
	
	# check whether the lower of the new hull edges already exists (reversed)
	# in the hull
	if mesh.triangles[hull[prev_h]] == p:
		#_link(hull[prev_h], new_half_edge + 1)
		lower_edge_opposite = hull[prev_h]
		
		# remove the reverse edge from the hull and decrement the next hull
		# edge unless the value at it is unchanged because of wraparound
		hull.remove(prev_h)
		if prev_h < next_h:
			next_h = posmod(next_h - 1, hull.size())
	else:
		# the reverse edge doesn't exist, so we can add the lower edge
		# to the hull and it's opposite doesn't exist
		hull.insert(next_h, new_half_edge + 1)
		#_link(new_half_edge + 1, -1)
		
		next_h = posmod(next_h + 1, hull.size())
	
	# add the upper edge of the new triangle to the hull and link it empty
	hull.insert(next_h, new_half_edge + 2)
	#_link(new_half_edge + 2, -1)
	
	# add the new triangle to the mesh
	mesh.extend_half_edge_with_point(e, p, \
		lower_edge_opposite, upper_edge_opposite)
	
	var ar = _legalize(new_half_edge)
	hull[next_h] = ar
	
	next_h = posmod(next_h + 1, hull.size())
	
	return next_h

# get the next half edge from e that starts at the point where e ends 
# and is in the same triangle as e
static func _next_half_edge(e: int):
	if e % 3 == 2:
		return e - 2
	else:
		return e + 1

# whether p is to the left of the half edge (interpreted as a vector) e or not
func _is_left_of_half_edge(e: int, p: Vector2) -> bool:
	
	# get the indices of the beginning and end vertices of the half edge
	var indices = mesh.half_edge_to_points(e)
	
	return predicates.is_ccw(points[indices.Begin], points[indices.End], p)

# iteratively legalize triangles starting from the edge a 
func _legalize(a: int) -> int:
	
	var a0 := a - (a % 3)
	var ar := a0 + ((a + 2) % 3)
	
	while true:
		
		var b = mesh.half_edges[a]
		a0 = a - (a % 3)
		ar = a0 + ((a + 2) % 3)
		
		if b == -1:
			if stack.empty():
				break
			
			a = stack.pop_back()
			continue
		
		#TODO simplify these expressions by using next_half_edge etc.
		var al = a0 + ((a + 1) % 3)
		
		var b0 = b - (b % 3)
		var br = b0 + ((b + 1) % 3)
		var bl = b0 + ((b + 2) % 3)
		
		# NOTE order of triangles matter? is ar and al swapped if triangle order
		# different?
		# a0 is different... but then ar, al depend also on a
		# the only way in which the legalization code is different to delaunator
		# is the change of operator < to > in circumcircle check... why does
		# this need to be done?
		var p0 = mesh.triangles[ar]
		var pr = mesh.triangles[a]
		var pl = mesh.triangles[al]
		var p1 = mesh.triangles[bl]
		
		assert(predicates.is_ccw(points[p0], points[pr], points[pl]), "triangle isn't ccw")
		if predicates.in_circle(points[p0], \
			points[pr], points[pl], points[p1]):
			
			assert(predicates.is_ccw(points[p0], points[p1], points[pl]), "triangle isn't ccw")
			assert(predicates.is_ccw(points[p0], points[pr], points[p1]), "triangle isn't ccw")
			
			mesh.triangles[a] = p1
			mesh.triangles[b] = p0
			
			var hbl = mesh.half_edges[bl]
			
			# hull stuff
			if (hbl == -1):
				var h := 0
				
				
				while h < hull.size() and hull[h] != bl:
					h += 1
				
				if h != hull.size():
					hull[h] = a
			
			mesh.temp(a, hbl)
			mesh.temp(b, mesh.half_edges[ar])
			mesh.temp(ar, bl)
			
			stack.append(br)
		else:
			if stack.empty():
				break
			a = stack.pop_back()
			
	return ar

# check whether the half edges array is logically sound
func _half_edges_correct() -> bool:
	return mesh.half_edges_correct()

# check whether all half edges in the hull have no opposite half edges
func _hull_half_edges_correct() -> bool:
	for h in hull:
		if not mesh.half_edges[h] == -1:
			return false
	
	return true

# takes an edge e and returns which triangle it belongs to 
func _triangle(e: int) -> int:
	# warning-ignore:integer_division
	return e / 3

func _reset() -> void:
	mesh.clear()
