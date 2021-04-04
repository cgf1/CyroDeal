local x = {
    __index = _G,
}
CyroDeal = setmetatable(x, x)
CyroDeal.CyroDeal = CyroDeal
setfenv(1, CyroDeal)

local myname = "CyroDeal"

local function _init(_, name)
    if name ~= myname then
	return
    end
    EVENT_MANAGER:UnregisterForEvent(name, EVENT_ADD_ON_LOADED)
    saved = ZO_SavedVars:NewAccountWide(name .. 'Saved', 1, nil, {Visible = true})
    CyroDoor._init(saved)
end
EVENT_MANAGER:RegisterForEvent(myname, EVENT_ADD_ON_LOADED, _init)
