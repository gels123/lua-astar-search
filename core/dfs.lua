-- Depth-First search algorithm.
local bfs = class("bfs")

local t_remove = table.remove

function bfs:depth_first_search(finder, openList, node, endNode, toClear)
  local neighbours = finder._grid:getNeighbours(node, finder._walkable)
  for i = 1, #neighbours do
    local neighbour = neighbours[i]
    if (not neighbour._closed and not neighbour._opened) then
			openList[#openList+1] = neighbour
			neighbour._opened = true
			neighbour._parent = node
			toClear[neighbour] = true
    end
  end
end

-- Calculates a path.
-- Returns the path from location `<startX, startY>` to location `<endX, endY>`.
function bfs:getPath(finder, startNode, endNode, toClear)
  local openList = {} -- We'll use a LIFO queue (simple array)

  openList[1] = startNode
  startNode._opened = true
  toClear[startNode] = true

  local node
  while (#openList > 0) do
    node = openList[#openList]
    t_remove(openList)
    node._closed = true
    if node == endNode then return node end
    self:depth_first_search(finder, openList, node, endNode, toClear)
  end

  return nil
end

return bfs