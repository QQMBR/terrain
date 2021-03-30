
# TODO statically type pretty much everything and make most functions private
class_name Poisson

const width = 1
const height = 1
const r_epsilon = 1e-7
const k = 6

var grid = []
var queue = []

# variables dependant on the radius, which is defined on a per instance basis
var radius: float
var radius_2: float
var cell_size: float
var grid_width: float
var grid_height: float

func _init(r: float):
	radius = r + r_epsilon
	radius_2 = pow(r, 2)
	cell_size = radius / sqrt(2)
	grid_width = ceil(width / cell_size)
	grid_height = ceil(height / cell_size)
	
	grid.resize(grid_width * grid_height)

# handle a new sample
func add_sample_at(x, y):
	var s = Vector2(x, y)
	
	grid[grid_width * floor(y / cell_size) + floor(x / cell_size)] = s
	queue.push_back(s)
	return s

# check that there are no samples too close to the point at (x, y)
func far(x: float, y: float):
	# find the grid coordinates of this point
	var i = floor(x / cell_size)
	var j = floor(y / cell_size)
	
	# calculate the boundaries of the valid grid cells for a candidate
	var i0 = max(i - 2, 0)
	var j0 = max(j - 2, 0)
	var i1 = min(i + 3, grid_width)
	var j1 = min(j + 3, grid_height)
	
	for col in range(j0, j1):
		var col_start_index = col * grid_width
		
		for row in range(i0, i1):
			var s = grid[col_start_index + row]
			if s:
				# if there is a sample that is too close in one of the nearby
				# cells, return false, otherwise check the remaining cells
				var dx = s.x - x
				var dy = s.y - y
				if dx * dx + dy * dy < radius_2: return false
	# if false wasn't returned by this point, there cannot already be a sample
	# too close to the point (x, y)
	return true


func max_poisson_sample():
	grid.resize(grid_width * grid_height)
	
	# start with a sample in the middle
	add_sample_at(float(width) / 2, float(height) / 2)
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var accepted: bool
	
	while not queue.empty():
		
		accepted = false
		var i = floor(rng.randf() * queue.size())
		
		# for the case that the random float is exactly 1.0
		if (i == queue.size()): i -= 1
		
		var parent = queue[i]
		
		var s = rng.randf()
		
		# make new candidate
		for j in range(0, k):
			var a = 2 * PI * (s + float(j) / float(k))
			
			var x = parent.x + radius * cos(a)
			var y = parent.y + radius * sin(a)
			
			# accept candidate if it is inside the boundaries set by width
			# and height and if it is not within the radius of other samples
			if 0 <= x and x < width and 0 <= y and y < height and far(x, y):
				add_sample_at(x, y)
				accepted = true
				break
		
		# if none of the candidates were accepted, remove it from the queue
		if not accepted:
			queue.remove(i)


func get_all_points() -> Array:
	max_poisson_sample()
	
	var points = []
	for i in range(0, grid_height):
		var col_index = i * grid_width
		for j in range(0, grid_width):
			var v = grid[col_index + j]
			
			if v: 
				points.append(v)
	
	return points
