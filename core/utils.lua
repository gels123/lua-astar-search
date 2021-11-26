-- Various utilities for Jumper top-level modules

-- Dependencies
local path = require ("path")
local Node = require ("node")

local utils = {}

-- Local references
local lua_type = type
local pairs = pairs
local tb_insert = table.insert
local assert = assert
local floor = math.floor
local concat = table.concat
local next = next
local coroutine = coroutine

-- Raw array items count
utils.arraySize = function (t)
	local count = 0
	for k,v in pairs(t) do
		count = count+1
	end
	return count
end

-- Parses a string map and builds an array map
utils.strToMap = function (str)
	local map = {}
	local w, h
	for line in str:gmatch('[^\n\r]+') do
		if line then
			w = not w and #line or w
			assert(#line == w, 'Error parsing map, rows must have the same size!')
			h = (h or 0) + 1
			map[h] = {}
			for char in line:gmatch('.') do
				map[h][#map[h]+1] = char
			end
		end
	end
	return map
end

-- Collects and returns the keys of a given array
utils.getKeys = function (t)
	local keys = {}
	for k,v in pairs(t) do
		keys[#keys+1] = k 
	end
	return keys
end

-- Calculates the bounds of a 2d array
utils.getArrayBounds = function (map)
	local min_x, max_x
	local min_y, max_y
	for y,_ in pairs(map) do
		min_y = not min_y and y or (y<min_y and y or min_y)
		max_y = not max_y and y or (y>max_y and y or max_y)
		for x in pairs(map[y]) do
			min_x = not min_x and x or (x<min_x and x or min_x)
			max_x = not max_x and x or (x>max_x and x or max_x)
		end
	end
	return min_x, max_x, min_y, max_y
end

-- Converts an array to a set of nodes
utils.arrayToNodes = function (map)
	local min_x, max_x
	local min_y, max_y
	local nodes = {}
	for y,_ in pairs(map) do
		y = floor(y)
		min_y = not min_y and y or (y < min_y and y or min_y)
		max_y = not max_y and y or (y > max_y and y or max_y)
		nodes[y] = {}
		for x,_ in pairs(map[y]) do
			x = floor(x)
			min_x = not min_x and x or (x < min_x and x or min_x)
			max_x = not max_x and x or (x > max_x and x or max_x)
			nodes[y][x] = Node.new(x, y)
		end
	end
	return nodes, (min_x or 0), (max_x or 0), (min_y or 0), (max_y or 0)
end

-- Iterator, wrapped within a coroutine
-- Iterates around a given position following the outline of a square
utils.around = function ()
	local iterf = function(x0, y0, s)
		local x, y = x0-s, y0-s
		coroutine.yield(x, y)
		repeat
			x = x + 1
			coroutine.yield(x,y)
		until x == x0+s
		repeat
			y = y + 1
			coroutine.yield(x,y)
		until y == y0 + s
		repeat
			x = x - 1
			coroutine.yield(x, y)
		until x == x0-s
		repeat
			y = y - 1
			coroutine.yield(x,y)
		until y == y0-s+1
	end
	return coroutine.create(iterf)
end

-- Extract a path from a given start/end position
utils.traceBackPath = function (finder, node, startNode)
	local path = path:new()
	path._grid = finder._grid
	while true do
	  if node._parent then
	    tb_insert(path._nodes, 1, node)
	    node = node._parent
	  else
	    tb_insert(path._nodes, 1, startNode)
	    return path
	  end
	end
end

-- Is i out of range
utils.outOfRange = function (i, low, up)
	return (i < low or i > up)
end

-- Is I an integer ?
utils.isInteger = function (i)
	return lua_type(i) == ('number') and (floor(i) == i)
end

-- Override lua_type to return integers
utils.type = function (v)
	return utils.isInteger(v) and 'int' or lua_type(v)
end

-- Does the given array contents match a predicate type ?
utils.arrayContentsMatch = function (t, ...)
	local n_count = utils.arraySize(t)
	if n_count < 1 then
		return false
	end
	local init_count = t[0] and 0 or 1
	local n_count = (t[0] and n_count-1 or n_count)
	local types = {...}
	if types then
		types = concat(types)
	end
	for i = init_count, n_count, 1 do
		if not t[i] then 
			return false
		end
		if types then
			if not types:match(utils.type(t[i])) then 
				return false
			end
		end
	end
	return true
end	

-- Checks if arg is a valid array map
utils.isMap = function (m)
	if not utils.arrayContentsMatch(m, 'table') then
		return false 
	end
	local lsize = utils.arraySize(m[next(m)])
	for k, v in pairs(m) do
		if not utils.arrayContentsMatch(m[k], 'string', 'int') then
			return false 
		end
		if utils.arraySize(v) ~= lsize then
			return false
		end
	end
	return true
end	

-- Checks if s is a valid string map
utils.isStrMap = function (s)
	if lua_type(s) ~= 'string' then
		return false
	end
	local w
	for row in s:gmatch('[^\n\r]+') do
		if not row then
			return false
		end
		w = w or #row
		if w ~= #row then
			return false
		end
	end
	return true
end

-- Does instance derive straight from class
utils.derives = function (instance, class)
	return getmetatable(instance) == class
end

-- Does instance inherits from class	
utils.inherits= function (instance, class)
	return (getmetatable(getmetatable(instance)) == class)
end

-- Is arg a boolean
utils.isBool = function (b) 
	return (b==true or b==false)
end

-- Is arg nil ?
utils.isNil = function (n)
	return (n == nil)
end

utils.matchType = function (value, types)
	return types:match(utils.type(value))	
end

return utils
