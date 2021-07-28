--[[
	A星搜索算法
	eg.
		local aStarSearch = aStarSearch.new()
		aStarSearch:init()
		aStarSearch:search({x = 10, y = 4}, {x = 29, y = 8})
]]
local minHeapNode = require("minHeapNode")
local aStarSearch = class("aStarSearch")

local SPACE = "." -- 空地
local VISITED = "-" -- 已遍历的点
local ON_PATH = "@" -- 路径
local START = "S" -- 起点
local END = "E" -- 终点

function aStarSearch:ctor()

	-- 地图数据
	self._mapData = {}
end

function aStarSearch:init()
	-- 加载地图数据
	local strMap = {
		".......................................................",
		".......................................................",
		"........wwwwwwwwww.....................................",
		"................ww............www......................",
		"................ww...........ww........................",
		"................ww..........ww.........................",
		"................ww.........ww..........................",
		"................ww........ww...........................",
		"........wwwwwwwwww.........ww..........................",
		"................ww..........ww.........................",
		"................ww...........wwww......................",
		"...........wwwwwww..............ww.....................",
		".................................www...................",
		".......................................................",
	}
	for y,v in pairs(strMap) do
		if not self._mapData[y] then
			self._mapData[y] = {}
		end
		for x = 1, string.len(v), 1 do
			self._mapData[y][x] = string.sub(v, x, x)
		end
	end
end

--[[
	搜索算法
]]
function aStarSearch:search(startPnt, endPnt)
	print("aStarSearch:search enter=", startPnt and startPnt.x, startPnt and startPnt.y, endPnt and endPnt.x, endPnt and endPnt.y)
	if not startPnt or not startPnt.x or not startPnt.y or not endPnt or not endPnt.x or not endPnt.y then
		return false
	end
	self._mapData[startPnt.y][startPnt.x] = START
	self._mapData[endPnt.y][endPnt.x] = END
	local mapSizeX, mapSizeY = #self._mapData[1], #self._mapData
    -- 用最小堆来记录扩展的点
    local minHeap = minHeapNode.new(function (node1, node2)
    	return node1 and node2 and (node1.g + node1.h) < (node2.g + node2.h)
    end)
    -- 是否在最小堆中map
    local map = {}
    local directs = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}} -- 可以扩展的四个方向
    local startNode = {point = startPnt, g = 0, h = 0, parent = nil,} -- 起始节点
    local endNode = {point = endPnt, g = 0, h = 0, parent = nil,} -- 结束节点
    local lastNode = nil -- 最后一个节点
    -- 把起始点放入堆
    minHeap:push(startNode)
    local key = string.format("%s_%s", startNode.point.x, startNode.point.y)
    map[key] = startNode
    -- 扩展搜索
    local node, newX, newY = nil, nil, nil
    local finish = false
    local i = 0
    while (not finish and minHeap:size() > 0) do
    	i = i + 1
        -- 取出f值最小的点
        node = minHeap:remove()
        local key = string.format("%s_%s", node.point.x, node.point.y)
    	map[key] = nil
        
        if (self._mapData[node.point.y][node.point.x] == SPACE) then -- 将取出的点标识为已访问点
        	self._mapData[node.point.y][node.point.x] = VISITED
        end
        for _, d in pairs(directs) do -- 遍历四个方向的点
            local newX = node.point.x + d[1]
            local newY = node.point.y + d[2]
            if (newX >= 1 and newX <= mapSizeX and newY >= 1 and newY <= mapSizeY) then
                -- 如果是终点, 则跳出循环, 不用再找
                if (newX == endPnt.x and newY == endPnt.y) then
                    lastNode = node
                    finish = true
                    break
                end
                -- 如果是空地, 则扩展
                if self._mapData[newY][newX] == SPACE then
	                -- 将点标识为已访问点
	                self._mapData[newY][newX] = VISITED
	                local key = string.format("%s_%s", newX, newY)
	                local inNode = map[key]
	                if inNode then -- 如果在堆里, 则更新g值
	                	if inNode.g > node.g + 1 then
	                		inNode.g = node.g + 1
	                		inNode.parent = node
	                	end
	                else -- 如果不在堆里,则放入堆中
	                	local newPoint = {x = newX, y = newY}
	                    local h = self:h(newPoint, endPnt)
	                    local newNode = {point = newPoint, g = node.g + 1, h = h, parent = node,}
	                    minHeap:push(newNode)
	                    map[key] = newNode
	                end
	            end
            end
        end
        -- self:printMap()
    end

    -- 反向找出路径
    local path = lastNode
    while (path.parent) do
        if (self._mapData[path.point.y][path.point.x] == VISITED) then
            self._mapData[path.point.y][path.point.x] = ON_PATH
        end
        path = path.parent
    end

    -- 打印地图
    self:printMap()

    return true
end
    
--[[
	h函数
]]
function aStarSearch:h(pnt, endPnt)
	-- return self:hBFS(pnt, endPnt)
	-- return self:hManhattanDistance(pnt, endPnt)
	return self:hEuclidianDistance(pnt, endPnt)
	-- return self:hPowEuclidianDistance(pnt, endPnt)
end

--[[
	BFS的h值, 恒为0
]]
function aStarSearch:hBFS(pnt, endPnt)
    return 0
end

--[[
	曼哈顿距离, 小于等于实际值
]]
function aStarSearch:hManhattanDistance(pnt, endPnt)
    return math.abs(pnt.x - endPnt.x) + math.abs(pnt.y - endPnt.y)
end

--[[
	欧式距离, 小于等于实际值
]]
function aStarSearch:hEuclidianDistance(pnt, endPnt)
	-- return math.sqrt(math.pow(pnt.x - endPnt.x, 2) + math.pow(pnt.y - endPnt.y, 2))
	return math.sqrt((pnt.x - endPnt.x)^2 + (pnt.y - endPnt.y)^2)
end

--[[
	欧式距离平方, 大于等于实际值
]]
function aStarSearch:hPowEuclidianDistance(pnt, endPnt)
    -- return math.pow(pnt.x - endPnt.x, 2) + math.pow(pnt.y - endPnt.y, 2)
    return (pnt.x - endPnt.x)^2 + (pnt.y - endPnt.y)^2
end

--[[
	打印地图
]]
function aStarSearch:printMap()
	local str = "\n"
	local maxY = #self._mapData
	for y = 1, maxY, 1 do
		for x, c in pairs(self._mapData[y]) do
			str = string.format("%s%s", str, c)
		end
		str = string.format("%s\n", str)
	end
	print("aStarSearch:printMap =>", str)
end

return aStarSearch