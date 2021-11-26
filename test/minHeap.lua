--[[
    最小堆-数字形态
]]
local minHeap = class("minHeap")
 
function minHeap:ctor()
    self._data = {}
    self._dataLen = 0
end
 
function minHeap:push(num)
    table.insert(self._data, num)
    self._dataLen = self._dataLen  +  1
    self:sortHeap(#self._data) 
end
 
function minHeap:sortHeap(nIndex)
    if nIndex <= 1 then
        if nIndex ~= 1 then
            print("minHeap:sortHeap: sort error")
        end
        return true
    end
    local fIndex
    if nIndex % 2 == 0 then
        fIndex = nIndex / 2
    else
        fIndex = (nIndex - 1) / 2
    end
    if self._data[nIndex] < self._data[fIndex] then
        self._data[nIndex], self._data[fIndex] = self._data[fIndex], self._data[nIndex]
        return self:sortHeap(fIndex)
    else
        return true
    end
end
 
function minHeap:remove()
    local ret = self._data[1]
    local endNum = table.remove(self._data, self._dataLen)
    self._dataLen = self._dataLen  -  1
    self._data[1] = endNum
    self:sortHeap2(1)    
    return ret
end
 
function minHeap:sortHeap2(nIndex)
    local cIndex = nIndex * 2
    if cIndex <= self._dataLen and self._data[cIndex] < self._data[nIndex] then
        self._data[nIndex], self._data[cIndex] = self._data[cIndex], self._data[nIndex]
        self:sortHeap2(cIndex)
        cIndex = nIndex * 2 + 1
        if self._data[cIndex] < self._data[nIndex] then
            self._data[nIndex], self._data[cIndex] = self._data[cIndex], self._data[nIndex]
            self:sortHeap2(cIndex)
        end
    end
    cIndex = nIndex * 2 + 1
    if cIndex <= self._dataLen and self._data[cIndex] < self._data[nIndex] then
        self._data[nIndex], self._data[cIndex] = self._data[cIndex], self._data[nIndex]
        self:sortHeap2(cIndex)
    end
    return true
end

function minHeap:size()
    return self._dataLen
end

return minHeap