--[[
	寻路服务接口
]]
local skynet = require ("skynet")
local searchLib = class("searchLib")

-- 服务数量
searchLib.serviceNum = 4

-- 根据id返回服务id
function searchLib:svrIdx(id)
	return (id - 1) % searchLib.serviceNum + 1
end

-- 获取地址
function searchLib:getAddress(kid, id)
	return svrAddressMgr.getSvr(svrAddressMgr.searchSvr, kid, self:svrIdx(id))
end

--[[
    查询
    @kid            [必填]王国ID
    @id             [必填]一般传UID
    @startNode      [必填]寻路开始节点
    @endNode        [必填]寻路结束节点
]]
function searchLib:getPath(kid, id, startNode, endNode)
    return skynet.call(self:getAddress(kid, id), "lua", "getPath", id, startNode, endNode)
end

return searchLib