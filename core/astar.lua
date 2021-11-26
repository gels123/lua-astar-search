-- Astar algorithm
-- This actual implementation of A-star is based on
-- [Nash A. & al. pseudocode](http://aigamedev.com/open/tutorials/theta-star-any-angle-paths/)

local heap = require ("heap")
local Heuristics = require ("heuristics")
local aStar = class("aStar")

-- Updates vertex node-neighbour
function aStar:updateVertex(finder, openList, node, neighbour, endNode, heuristic)
	local g = node._g + Heuristics.EUCLIDIAN(neighbour, node) --Heuristics.CARDINTCARD(neighbour, node)
	if openList:isIn(neighbour) then
		if neighbour._g > g then
			neighbour._parent = node
			neighbour._g = g
			neighbour._f = neighbour._g + neighbour._h
			openList:heapify(neighbour)
		end
	else
		neighbour._parent = node
		neighbour._g = g
		neighbour._h = heuristic(neighbour, endNode)
		neighbour._f = neighbour._g + neighbour._h
		neighbour._opened = true
		openList:push(neighbour)
	end
end

-- Calculates a path.
-- Returns the path from location `<startX, startY>` to location `<endX, endY>`.
function aStar:getPath(finder, startNode, endNode, toClear)
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

return aStar