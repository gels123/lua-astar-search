-- Jump Point search algorithm

local Heuristics = require ("heuristics")
local heap = require ("heap")
local jpsPrune = class("jpsPrune")

-- Internalization
local max, abs, floor = math.max, math.abs, math.floor

-- Local helpers, these routines will stay private
-- As they are internally used by the public interface

-- Resets properties of nodes expanded during a search
-- This is a lot faster than resetting all nodes
-- between consecutive pathfinding requests

--[[
  Looks for the neighbours of a given node.
  Returns its natural neighbours plus forced neighbours when the given
  node has no parent (generally occurs with the starting node).
  Otherwise, based on the direction of move from the parent, returns
  neighbours while pruning directions which will lead to symmetric paths.

  In case diagonal moves are forbidden, when the given node has no
  parent, we return straight neighbours (up, down, left and right).
  Otherwise, we add left and right node (perpendicular to the direction
  of move) in the neighbours list.
--]]
function jpsPrune:findNeighbours(finder, node)
  if node._parent then
    local neighbours = {}
    local x, y = node._x, node._y
    -- Node have a parent, we will prune some neighbours
    -- Gets the direction of move
    local dx = (x-node._parent._x)/max(abs(x-node._parent._x), 1)
    local dy = (y-node._parent._y)/max(abs(y-node._parent._y), 1)

    -- Diagonal move case
    if dx~=0 and dy~=0 then
      local walkY, walkX
      -- Natural neighbours
      -- 当前方向的垂直分量可走, 沿着当前方向的垂直分量寻找跳点
      if finder._grid:isWalkable(x, y+dy, finder._walkable) then
        neighbours[#neighbours+1] = finder._grid:getNodeAt(x, y+dy)
        walkY = true
      end
      -- 当前方向的水平分量可走, 沿着当前方向的水平分量寻找跳点
      if finder._grid:isWalkable(x+dx, y, finder._walkable) then
        neighbours[#neighbours+1] = finder._grid:getNodeAt(x+dx, y)
        walkX = true
      end
      -- 当前方向可走, 沿着当前方向寻找跳点
      if walkX or walkY then
        neighbours[#neighbours+1] = finder._grid:getNodeAt(x+dx, y+dy)
      end
      -- Forced neighbours
      -- if (not finder._grid:isWalkable(x-dx, y, finder._walkable)) and walkY then
      --   neighbours[#neighbours+1] = finder._grid:getNodeAt(x-dx, y+dy)
      -- end
      -- if (not finder._grid:isWalkable(x, y-dy, finder._walkable)) and walkX then
      --   neighbours[#neighbours+1] = finder._grid:getNodeAt(x+dx, y-dy)
      -- end
    else
      -- Move along Y-axis case
      if dx==0 then
        -- 当前方向可走, 沿着当前方向寻找跳点
        if finder._grid:isWalkable(x, y+dy, finder._walkable) then
          neighbours[#neighbours+1] = finder._grid:getNodeAt(x, y+dy)
        end
        -- 左后方不可走且左方可走, 沿着左方、左前方寻找跳点 Forced neighbours
        if (not finder._grid:isWalkable(x-1, y-dy, finder._walkable) and finder._grid:isWalkable(x-1, y, finder._walkable)) then
          neighbours[#neighbours+1] = finder._grid:getNodeAt(x-1, y)
          neighbours[#neighbours+1] = finder._grid:getNodeAt(x-1, y+dy)
        end
        -- 右后方不可走且右方可走, 沿着右方、右前方寻找跳点 Forced neighbours
        if (not finder._grid:isWalkable(x+1, y-dy, finder._walkable) and finder._grid:isWalkable(x+1, y, finder._walkable)) then
          neighbours[#neighbours+1] = finder._grid:getNodeAt(x+1, y)
          neighbours[#neighbours+1] = finder._grid:getNodeAt(x+1, y+dy)
        end
      else
      -- Move along X-axis case
        -- 当前方向可走, 沿着当前方向寻找跳点
        if finder._grid:isWalkable(x+dx, y, finder._walkable) then
          neighbours[#neighbours+1] = finder._grid:getNodeAt(x+dx, y)
        end
        -- 左后方不可走且左方可走, 沿着左方、左前方寻找跳点 Forced neighbours
        if (not finder._grid:isWalkable(x-dx, y-1, finder._walkable) and finder._grid:isWalkable(x, y-1, finder._walkable)) then
          neighbours[#neighbours+1] = finder._grid:getNodeAt(x, y-1)
          neighbours[#neighbours+1] = finder._grid:getNodeAt(x+dx, y-1)
        end
        -- 右后方不可走且右方可走, 沿着右方、右前方寻找跳点 Forced neighbours
        if (not finder._grid:isWalkable(x-dx, y+1, finder._walkable) and finder._grid:isWalkable(x, y+1, finder._walkable)) then
          neighbours[#neighbours+1] = finder._grid:getNodeAt(x, y+1)
          neighbours[#neighbours+1] = finder._grid:getNodeAt(x+dx, y+1)
        end
      end
    end
    return neighbours
  end
  -- Node do not have parent, we return all neighbouring nodes
  return finder._grid:getNeighbours(node, finder._walkable)
end

--[[
  Searches for a jump point (or a turning point) in a specific direction.
  This is a generic translation of the algorithm 2 in the paper:
    http://users.cecs.anu.edu.au/~dharabor/data/papers/harabor-grastien-aaai11.pdf
  The current expanded node is a jump point if near a forced node

  In case diagonal moves are forbidden, when lateral nodes (perpendicular to
  the direction of moves are walkable, we force them to be turning points in other
  to perform a straight move.
--]]
function jpsPrune:jump(finder, node, parent, endNode)
  print("jpsPrune:jump", parent:getKey(), "=>", node and node:getKey())
  if not node then
    return
  end
  -- If the node to be examined is the endNode, return this node
  if node == endNode then
    return node
  end
  local x, y = node._x, node._y
  -- If the node to be examined is unwalkable, return nil
  if not finder._grid:isWalkable(x, y, finder._walkable) then
    return
  end
  local dx, dy = x - parent._x, y - parent._y
  -- 对角线方向
  if dx~=0 and dy~=0 then
    -- Current node is a jump point if one of his leftside/rightside neighbours ahead is forced
    -- if ((not finder._grid:isWalkable(x-dx, y, finder._walkable)) and finder._grid:isWalkable(x-dx, y+dy, finder._walkable)) or
    --    ((not finder._grid:isWalkable(x, y-dy, finder._walkable)) and finder._grid:isWalkable(x+dx, y-dy, finder._walkable)) then
    --   return node
    -- end
  -- 直线方向
  else
    if dx ~= 0 then
      -- 直线X轴方向, 左后方不可走且左方可走 或 右后方不可走且右方可走, 则为跳点
      if ((not finder._grid:isWalkable(x-dx, y+1, finder._walkable)) and finder._grid:isWalkable(x, y+1, finder._walkable)) or
         ((not finder._grid:isWalkable(x-dx, y-1, finder._walkable)) and finder._grid:isWalkable(x, y-1, finder._walkable)) then
        return node
      end
    else
      -- 直线Y轴方向, 左后方不可走且左方可走 或 右后方不可走且右方可走, 则为跳点
      if ((not finder._grid:isWalkable(x+1, y-dy, finder._walkable)) and finder._grid:isWalkable(x+1, y, finder._walkable)) or
         ((not finder._grid:isWalkable(x-1, y-dy, finder._walkable)) and finder._grid:isWalkable(x-1, y, finder._walkable)) then
          return node
      end
    end
  end

  -- 对角线方向, 优先延沿着直线方向寻找跳点
  if dx~=0 and dy~=0 then
    if self:jump(finder, finder._grid:getNodeAt(x+dx, y), node, endNode) then
      return node
    end
    if self:jump(finder, finder._grid:getNodeAt(x, y+dy), node, endNode) then
      return node
    end
  end
  -- 直线方向/对角线方向, 均沿着原方向寻找跳点
  if (dx~=0 and finder._grid:isWalkable(x+dx, y, finder._walkable)) or (dy~=0 and finder._grid:isWalkable(x, y+dy, finder._walkable)) then
    return self:jump(finder,finder._grid:getNodeAt(x+dx, y+dy), node, endNode)
  end
end

--[[
  Searches for successors of a given node in the direction of each of its neighbours.
  This is a generic translation of the algorithm 1 in the paper:
    http://users.cecs.anu.edu.au/~dharabor/data/papers/harabor-grastien-aaai11.pdf

  Also, we notice that processing neighbours in a reverse order producing a natural
  looking path, as the PathFinder tends to keep heading in the same direction.
--]]
function jpsPrune:identifySuccessors(finder, openList, node, endNode, toClear)
  -- Gets the valid neighbours of the given node
  -- Looks for a jump point in the direction of each neighbour
  local neighbours = self:findNeighbours(finder, node)
  local str = ""
  for _,n in pairs(neighbours) do
    str = str .. n:getKey() .. ";"
  end
  print("jpsPrune:identifySuccessors node=", node:getKey(), "findNeighbours=", str)
  for i = 1, #neighbours, 1 do
    local neighbour = neighbours[i]
    local jumpNode = self:jump(finder, neighbour, node, endNode)
    print("jpsPrune:identifySuccessors node=", node:getKey(), "pick neighbour=", neighbour:getKey(), "jumpNode=", jumpNode and jumpNode:getKey())
    -- Performs regular A-star on a set of jump points
    if jumpNode then
      -- Update the jump node and move it in the closed list if it wasn't there
      if not jumpNode._closed then			
				local g = node._g + Heuristics.EUCLIDIAN(jumpNode, node)
				if not jumpNode._opened or g < jumpNode._g then
					toClear[jumpNode] = true -- Records this node to reset its properties later.
          jumpNode._parent = node
					jumpNode._g = g
          if not jumpNode._h then
            jumpNode._h = finder._heuristic(jumpNode, endNode)
          end
          jumpNode._f = jumpNode._g + jumpNode._h
					if not jumpNode._opened then
            jumpNode._opened = true
						openList:push(jumpNode)
					else
						openList:heapify(jumpNode)
					end
				end
			end
    end
  end
end

-- Calculates a path.
-- Returns the path from location `<startX, startY>` to location `<endX, endY>`.
function jpsPrune:getPath(finder, startNode, endNode, toClear)
  local openList = heap.new()
  startNode._g = 0
  startNode._h = 0
  startNode._f = startNode._g + startNode._h
  startNode._opened = true
  openList:push(startNode)
  toClear[startNode] = true

  local node
  while not openList:empty() do
    -- Pops the lowest F-cost node, moves it in the closed list
    node = openList:pop()
    node._closed = true

    -- If the popped node is the endNode, return it
    if node == endNode then
      return node
    end

    -- otherwise, identify successors of the popped node
    self:identifySuccessors(finder, openList, node, endNode, toClear)
  end

  -- No path found, return nil
  return nil
end

return jpsPrune