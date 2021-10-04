extends Reference
class_name Matrix

# 2d array of matrix contents
var p: Array

# the augment matrix
var q: Array


func _init(rows: int, cols: int, value: float = 0):
	for i in range(rows):
		p.append([])
		for j in range(cols):
			p[i].append(value)


# assumes it will be passed a 2d array of the appropriate size
func fill(data: Array):
	for i in range(p.size()):
		p[i] = data[i]


static func mult(m: Matrix, n: Matrix):
	var product = []
	var r1 = m.p.size()
	var c2 = n.p[0].size()
	
	for i in range(m.p.size()):
		product.append([])
		
		for j in range(n.p[0].size()):
			product[i].append(0)
			
			for k in range(n.p.size()):
				product[i][j] += m.p[i][k] * n.p[k][j]
				
	return product


func copy():
	return p.duplicate(true)


func add_scalar(a: int, scalar: float, b: int):
	for i in range(p.size()):
		p[b][i] += p[a][i] * scalar
		q[b][i] += q[a][i] * scalar


# assumes that the row being inserted is the same length and the Matrix
func insert_row(row: int, numbers: Array):
	p[row] = numbers


func swap_row(a: int, b: int):
	var tmp = p[a]
	p[a] = p[b]
	p[b] = tmp
	
	# manipulate the augmented matrix if it exists
	if q.size() > 0:
		tmp = q[a]
		q[a] = q[b]
		q[b] = tmp


func identity():
	var id = []
	for i in range(p.size()):
		id.append([])
		for j in range(p.size()):
			if i == j:
				id[i].append(1)
			else:
				id[i].append(0)
	return id


func print():
	var line
	for i in range(p.size()):
		line = ""
		for j in range(p[0].size()):
			line += "%s " % p[i][j]
		if q.size() > 0:
			line += " | "
			for j in range(q[0].size()):
				line += "%s " % q[i][j]
		line += "\n"
		print(line)


func multiply_row(n: int, x: float):
	for i in p[n].size():
		p[n][i] *= float(x)
		
	# manipulate the augmented matrix if it exists
	if q.size() > 0:
		for i in q[n].size():
			q[n][i] *= float(x)


func augment_by(m: Array):
	q = m


func get_augment():
	return q


func get_augmented():
	var aug = p
	if q.size() > 0:
		for i in range(q.size()):
			for j in range(q[0].size()):
				aug[i].append(q[i][j])
	return aug


func inverse():
	# augment m by i
	var copy = copy()
	augment_by(identity())
	
	# gauss jordan elimination
	#   1. Swap the rows so that all rows with all zero entries are on the bottom
	_zero_rows_to_bottom()

	#	2. Swap the rows so that the row with the largest, n-th leftmost nonzero entry is on top.
	var n: int = 0
	var row: int = 0
	var value
	while n < p.size():
		value = null
		row = n
		
		for i in range(n, p.size()):
			if value == null or  p[i][n] > value: 
				value = p[i][n]
				row = i
		
		if row != n: swap_row(n, row)

		#   3. Multiply the top row by a scalar so that top row's leading entry becomes 1.
		multiply_row(n, 1.0 / p[n][n] if p[n][n] != 0.0 else 0)

		#   4. Add/subtract multiples of the top row to the other rows so that all other entries 
		#	in the column containing the top row's leading entry are all zero.
		for i in range(p.size()):
			if i != n:
				if p[i][n] != 0:
					add_scalar(n, - float(p[i][n]) / float(p[n][n]), i)
		
		#   5. Repeat steps 2-4 for the next leftmost nonzero entry until all the leading entries are 1.
		n += 1
		
	var inverse = q
	q = []
	fill(copy)
	
	return inverse


func _is_zero_row(row: int):
	for n in range(p[row].size()):
		if p[row][n] != 0: return false
	return true


func _zero_rows_to_bottom():
	var current: int = 0
	var last: int = p.size() - 1
	
	# find the lowest non-zero row
	while _is_zero_row(last):
		last -= 1
	
	# put all non-zero rows at the top and zero rows on the bottom
	while current < last:
		if _is_zero_row(current):
			swap_row(current, last)
			while _is_zero_row(last):
				last -= 1
		current += 1
