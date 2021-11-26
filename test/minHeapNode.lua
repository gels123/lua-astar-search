--[[
    最小堆-节点形态
    eg:
        local minHeap = require("minHeapNode").new(function (node1, node2)
            return node1 and node2 and node1.num < node2.num
        end)
        minHeap:push({num = 55})
        minHeap:push({num = 1})
        minHeap:push({num = 45})
        print("top1=", minHeap:remove().num)
]]
local minHeapNode = class("minHeapNode")

function minHeapNode:ctor(cmp)
    self._data = {}
    self._dataLen = 0
    -- 比较函数
    assert((cmp and type(cmp) == "function"), "minHeapNode:ctor error: cmp invalid")
    self._cmp = cmp
end

function minHeapNode:push(node)
    table.insert(self._data, node)
    self._dataLen = self._dataLen  +  1
    self:sortHeap(#self._data) 
end

function minHeapNode:sortHeap(nIndex)
    if nIndex <= 1 then
        if nIndex ~= 1 then
            print("minHeapNode:sortHeap: sort error")
        end
        return true
    end
    local fIndex
    if nIndex % 2 == 0 then
        fIndex = nIndex / 2
    else
        fIndex = (nIndex - 1) / 2
    end
    if self._cmp(self._data[nIndex], self._data[fIndex]) then
        self._data[nIndex], self._data[fIndex] = self._data[fIndex], self._data[nIndex]
        return self:sortHeap(fIndex)
    else
        return true
    end
end

function minHeapNode:remove()
    local ret = self._data[1]
    local endNum = table.remove(self._data, self._dataLen)
    self._dataLen = self._dataLen  -  1
    self._data[1] = endNum
    self:sortHeap2(1)    
    return ret
end

function minHeapNode:sortHeap2(nIndex)
    local cIndex = nIndex * 2
    if cIndex <= self._dataLen and self._cmp(self._data[cIndex], self._data[nIndex]) then
        self._data[nIndex], self._data[cIndex] = self._data[cIndex], self._data[nIndex]
        self:sortHeap2(cIndex)
        cIndex = nIndex * 2 + 1
        if self._cmp(self._data[cIndex], self._data[nIndex]) then
            self._data[nIndex], self._data[cIndex] = self._data[cIndex], self._data[nIndex]
            self:sortHeap2(cIndex)
        end
    end
    cIndex = nIndex * 2 + 1
    if cIndex <= self._dataLen and self._cmp(self._data[cIndex], self._data[nIndex]) then
        self._data[nIndex], self._data[cIndex] = self._data[cIndex], self._data[nIndex]
        self:sortHeap2(cIndex)
    end
    return true
end

function minHeapNode:size()
    return self._dataLen
end

return minHeapNode