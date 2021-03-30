
#TODO refactor so that this is only one of multiple potential 
# heightmappers, this one in particular does random walks
class_name Heightmapper
#
#var rng = RandomNumberGenerator.new()
#
#const ocean_percent = 0.5
#
#const random_walks = 10
#
## min and max values for the distance travelled by a random 
## walk on the sphere
#const min_walk_distance = 0.8
#const max_walk_distance = 4.5
#
#const min_activity_force = 0.05
#const max_activity_force = 0.20
#
#const width_multiplier = 0.2
#
#var forces := []
#
#func _init():
#	rng.randomize()
#
#func _choose_index_from_continuations(direction: Vector3, verts: PoolVector3Array, next: Array, d: DelaunaySweep) -> int: 
#
#	# choose an angle from a normal distribution with std deviation of 30 degrees
#	# and mean 0
#	var target_angle : float = rng.randfn(0.0, PI / 6)
#
#	var best_index = 0
#	var best_diff = direction.angle_to(verts[d.triangles[0]])
#
#	for i in range(0, next.size()):
#		var angle = direction.angle_to(_edge_to_vector(d, verts, next[i]))
#
#		if (abs(angle - target_angle) < best_diff):
#			best_index = i
#			best_diff = angle
#
#	return best_index
#
#func _assign_point_height_from_visited_edge(edge: int, \
#	walk_distance: float, \
#	walk_force: float, \
#	d: DelaunaySweep, \
#	verts: PoolVector3Array) -> PoolVector3Array:
#
#	var vertex_index = d.triangles[edge]
#	verts[vertex_index] *= 1.0 + walk_force
#
#	#TODO correctly update the XY component of a point as well 
#	# (shouldn't cause issues right now as it's only used for triangulation)
#	return verts
#
#func _direction_update(d_old: Vector3, d_new: Vector3) -> Vector3:
#	 return d_new
#
#func _edge_to_vector(d: DelaunaySweep, verts: PoolVector3Array, e: int) -> Vector3: 
#	var root_point = verts[d.triangles[e]]
#
#	var end_point = verts[d.triangles[DelaunaySweep.next_half_edge(e)]]
#
#	return end_point - root_point
#
## TODO
#func _spread_along_width(next: Array, width: float, d: DelaunaySweep, verts: PoolVector3Array) -> PoolVector3Array:
#
#	for edge in next:
#		if (_edge_to_vector(d, verts, edge).length() < width):
#
#			var next_rec = d.all_continuations(edge)
#
#	return verts
#
#func assign_height_to_triangulation(d: DelaunaySweep, verts: PoolVector3Array) -> PoolVector3Array: 
#	for _i in range(0, random_walks):
#
#
#		var current_edge : int = rng.randi_range(0, d.half_edges.size() - 1)
#		var distance_walked := 0.0
#		var direction := _edge_to_vector(d, verts, current_edge)
#
#		# TODO a more differentiated treatment of walks seen as representing
#		# areas of geologic activity
#
#		# the distance is the first parameter of a walk, used to 
#		# determine some other parameters
#		var walk_distance : float = rng.randf_range(min_walk_distance, max_walk_distance)
#
#		# force is varied with small distances, but distribution
#		# is narrower with longer distances
#		var normalized_distance : float = walk_distance / max_walk_distance
#
#		# TODO decide what parameters are really important (less is often better)
#		# walk width is a normally distributed variable (truncated to [0, walk_distance])
#		var walk_width = min(walk_distance, abs(rng.randfn(\
#			normalized_distance, 
#			min(walk_distance / 2, 1.0 / normalized_distance))))
#
#		# walk force is inverseley proportional to the normalized
#		# width (width / distance)
#		var walk_force : float = min(\
#			max_activity_force, \
#			walk_distance / walk_width - (1.0 - min_activity_force))
#
#
#		while distance_walked < walk_distance: 
#			distance_walked += direction.length()
#
#			verts = _assign_point_height_from_visited_edge(current_edge, walk_distance, walk_force, d, verts)
#
#			var next_edges = d.all_continuations(current_edge)
#
#			var next_edge_index = _choose_index_from_continuations(\
#				direction, verts, next_edges, d)
#
#			current_edge = next_edges[next_edge_index]
#
#			# spread along width, so along every possible edge apart
#			# from the actual ridge direction
#			next_edges.remove(next_edge_index)
#
#			direction = _edge_to_vector(d, verts, current_edge)
#
#	return verts
