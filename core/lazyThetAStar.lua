-- ThetaStar implementation
-- See: http://aigamedev.com/open/tutorials/theta-star-any-angle-paths for reference

local Heuristics = require ("heuristics")
local heap = require ("heap")
local lazyThetAStar = class("lazyThetAStar")

local abs = math.abs

-- Line Of Sight (Bresenham's line marching algorithm)
-- http://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
function lazyThetAStar:lineOfSight(finder, node, neighbour)
	local x0, y0 = node._x, node._y
	local x1, y1 = neighbour._x, neighbour._y
	local dx = abs(x1 - x0)
	local dy = abs(y1 - y0)
	local err = dx - dy
	local sx = (x0 < x1) and 1 or -1
	local sy = (y0 < y1) and 1 or -1		

	while true do
		if not finder._grid:isWalkable(x0, y0, finder._walkable) then 
			return false 
		end
		if x0 == x1 and y0 == y1 then
			break
		end
		local e2 = 2*err
		if e2 > -dy then
			err = err - dy
			x0 = x0 + sx
		end
		if e2 < dx then
			err = err + dx
			y0 = y0 + sy
		end
	end
	return true
end

-- Updates vertex node-neighbour
function lazyThetAStar:setVertex(finder, openList, node)
	if node._parent then
		print("lazyThetAStar:setVertex lineOfSight", node:getKey(), node._parent:getKey(), self:lineOfSight(finder, node, node._parent))
	end
	if node._parent and not self:lineOfSight(finder, node, node._parent) then
		local minG, minParent
		local neighbours = finder._grid:getNeighbours(node, finder._walkable)
		for i, neighbour in pairs(neighbours) do
			if neighbour._closed and neighbour ~= node then
				local g = neighbour._g + Heuristics.EUCLIDIAN(neighbour, node)
				if not minG or g < minG then
					minG = g
					minParent = neighbour
				end
			end	
		end
		if minG then
			print("thetAStar parent", node:getKey(), "==>", minParent:getKey())
			node._parent = minParent
			node._g = minG
			node._f = node._g + node._h
			-- openList:heapify(node)
		else
			print("lazyThetAStar:setVertex error")
		end
	end
end

-- Updates vertex node-neighbour
function lazyThetAStar:updateVertex(finder, openList, node, neighbour, endNode, heuristic)
	local node2 = node._parent or node
	local g = node2._g + Heuristics.EUCLIDIAN(neighbour, node2)
	if openList:isIn(neighbour) then
		if neighbour._g > g then
			print("thetAStar parent", neighbour:getKey(), "=>", node2:getKey())
			neighbour._parent = node2
			neighbour._g = g
			neighbour._f = neighbour._g + neighbour._h
			openList:heapify(neighbour)
		end
	else
		print("thetAStar parent", neighbour:getKey(), "=>", node2:getKey())
		neighbour._parent = node2
		neighbour._g = g
		neighbour._h = heuristic(neighbour, endNode)
		neighbour._f = neighbour._g + neighbour._h
		neighbour._opened = true
		openList:push(neighbour)
	end
end

-- Calculates a path.
-- Returns the path from location `<startX, startY>` to location `<endX, endY>`.
function lazyThetAStar:getPath(finder, startNode, endNode, toClear)
	local heuristic = finder._heuristic
	local openList = heap.new()
	startNode._g = 0
	startNode._h = heuristic(startNode, endNode)
	startNode._f = startNode._g + startNode._h
	startNode._opened = true
	openList:push(startNode)
	toClear[startNode] = true

	local node
	while not openList:empty() do
		node = openList:pop()
		node._closed = true
		self:setVertex(finder, openList, node)
		if node == endNode then
			return node
		end
		local neighbours = finder._grid:getNeighbours(node, finder._walkable)
		for i, neighbour in pairs(neighbours) do
			if not neighbour._closed then
				toClear[neighbour] = true
				self:updateVertex(finder, openList, node, neighbour, endNode, heuristic)
			end	
		end	
	end
	return nil 
end

return lazyThetAStar