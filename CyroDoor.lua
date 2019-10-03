local x = {
    __index = _G,
}
CyroDoor = setmetatable(x, x)
x.CyroDoor = CyroDoor
setfenv(1, CyroDoor)

local myname = 'CyroDoor'
local saved = nil
local lmp = LibStub("LibMapPins-1.0")

function _init {
    EVENT_MANAGER:UnregisterForEvent(myname)
}

EVENT_MANAGER:RegisterForEvent(myname, EVENT_ADD_ON_LOADED, init)
