local lmp = LibStub("LibMapPins-1.0")
local cmp = COMPASS_PINS
local x = {
    __index = _G,
}
CyroDoor = setmetatable(x, x)
CyroDoor.CyroDoor = CyroDoor
setfenv(1, CyroDoor)

local myname = 'CyroDoor'
Name = myname

local saved
local texture
local coords

local t = "esoui/art/floatingmarkers/repeatablequest_icon_door_assisted.dds"
local where = {
    {
	name = "Cyrodiil Keep Postern",
	find = function (n) return n:find("Postern") end,
	layout = {level = 200, maxDistance = 0.012, size = 4, texture = "CyroDoor/icons/postern.dds"},
    },
    {
	name = "Cyrodiil Keep Front Gate",
	find = function (n) return not n:find("Postern") end,
	layout = {level = 200, maxDistance = 0.012, size = 8, texture = "CyroDoor/icons/frontgate.dds"},
    }
}

local function color(n, r, g, b, a)
    if r then
	saved.color = {r, g, b, a}
    elseif not saved.color or not saved.color[1] then
	saved.color = {0, 1, 0, 1}
    end
    -- df("%s: color %d, %d, %d, %d", n, unpack(saved.color))
    local color = ZO_ColorDef:New(unpack(saved.color))
    lmp:SetLayoutKey(n, "tint", color)
end

function CyroDoor.SaveCoords(mapname, name, x, y)
    saved.coords[mapname] = saved.coords[mapname] or {}
    saved.coords[mapname][name] = {x, y}
    lmp:RefreshPins(nil)
    cmp:RefreshPins(nil)
end

local function create(name, what, func, coords)
    local zone = lmp:GetZoneAndSubzone()
    local CreatePin = what.CreatePin
    if zone == 'cyrodiil' then
	for n, c in pairs(coords) do
	    if func(n) then
		CreatePin(what, name, {}, unpack(c))
		-- df("%s: created pin for '%s' at %f, %f", what.Name, n, c[1], c[2])
	    end
	end
    end
end

function _init(_, name)
    if name ~= myname then
	return
    end
    EVENT_MANAGER:UnregisterForEvent(name, EVENT_ADD_ON_LOADED)
    saved = ZO_SavedVars:NewAccountWide(name .. 'Saved', 1, nil, {coords = {}})
    InitCoord(saved)
    coords = saved.coords.Cyrodiil
    lmp.Name = 'LibMapPins'
    cmp.pinManager.Name = 'CustomCompassPins'
    for _, x in ipairs(where) do
	local name, find, layout = x.name, x.find, x.layout
	local pid = lmp:AddPinType(name, function() create(name, lmp, find, coords) end)
	lmp:SetLayoutData(pid, x.layout)
	color(pid)

	cmp:AddCustomPin(name, function(pm) create(name, pm, find, coords) end, layout)
	cmp:RefreshPins(name)
	-- df("created pins for %s, texture %s, size %d", name, texture, size)
    end

    SLASH_COMMANDS["/cdw"] = function()
	for _, x in ipairs(where) do
	    color(x.name, 1, 1, 1, 1)
	end
    end
    SLASH_COMMANDS["/cdg"] = function()
	for n in pairs(saved.coords.Cyrodiil) do
	    color(x.name, 0, 1, 0, 1)
	end
    end
    SLASH_COMMANDS["/cdb"] = function()
	for _, x in ipairs(where) do
	    color(x.name, 0.2, 0.6, 1, 1)
	end
    end
    SLASH_COMMANDS["/cdr"] = function()
	for _, x in ipairs(where) do
	    color(x.name, 1, 0, 0, 1)
	end
    end
end

EVENT_MANAGER:RegisterForEvent(myname, EVENT_ADD_ON_LOADED, _init)

