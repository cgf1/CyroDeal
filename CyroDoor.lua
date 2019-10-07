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
local gatehouses, posterns

local t = "esoui/art/floatingmarkers/repeatablequest_icon_door_assisted.dds"
local where

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

function mysplit(inputstr, sep)
    if sep == nil then
	sep = "%s"
    end
    local first
    local rest = ''
    for str in inputstr:gmatch("([^"..sep.."]+)") do
	if first == nil then
	    first = str
	else
	    rest = rest + ' ' + str
	end
    end
    return first:sub(1, 1):lower(), rest:sub(2)
end

function CyroDoor.SaveCoords(mapname, s, x, y)
    if mapname ~= 'Cyrodiil' then
	return -- for now?
    end
    local loc = GetPlayerLocationName()
    local doortype, text = mysplit(s)
    local door
    if doortype == 'p' then
	door = posterns
    else
	door = gatehouses
    end
    local key
    if text and text:len() > 0 then
	key = loc .. ' ' .. text
    else
	key = loc
    end

    door[key] = {x, y}
    lmp:RefreshPins(nil)
    cmp:RefreshPins(nil)
end

local function create(what, name, func, doortab)
    local zone = lmp:GetZoneAndSubzone()
    local CreatePin = what.CreatePin
    if zone == 'cyrodiil' then
	for n, c in pairs(doortab) do
	    if func(n) then
		CreatePin(what, name, {}, unpack(c))
		df("%s: created pin %s for '%s' at %f, %f", what.Name, name, n, c[1], c[2])
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
    saved.doors = saved.doors or {}
    if not saved.doors.Cyrodiil then
	saved.doors.Cyrodiil = {}
    end
    local cyrodoors = saved.doors.Cyrodiil
    if not cyrodoors.gatehouses then
	cyrodoors.gatehouses = {}
    end
    if not cyrodoors.posterns then
	cyrodoors.posterns = {}
    end
    gatehouses = cyrodoors.gatehouses
    posterns = cyrodoors.posterns
    where = {
	{
	    name = "Cyrodiil Keep Postern",
	    door = posterns,
	    find = function (n) return true end,
	    layout = {level = 200, maxDistance = 0.012, size = 4, texture = "CyroDoor/icons/postern.dds"},
	},
	{
	    name = "Cyrodiil Keep Gatehouse",
	    door = gatehouses,
	    find = function (n) return true end,
	    layout = {level = 200, maxDistance = 0.012, size = 8, texture = "CyroDoor/icons/gatehouse.dds"},
	}
    }
    df('posterns %s', tostring(posterns))
    df('gatehouses %s', tostring(gatehouses))
    lmp.Name = 'LibMapPins'
    cmp.pinManager.Name = 'CustomCompassPins'
    for _, x in ipairs(where) do
	local name, door, find, layout = x.name, x.door, x.find, x.layout
	local pid = lmp:AddPinType(name, function() create(lmp, name, find, door) end)
	lmp:SetLayoutData(pid, layout)
	color(pid)

	cmp:AddCustomPin(name, function(pm) create(pm, name, find, door) end, layout)
	cmp:RefreshPins(name)
	df("created pins for %s, texture %s, size %d", name, layout.texture, layout.size)
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

