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
local alliance
local green = {0, 1, 0, 1}
local gray = {0.75, 0.75, 0.75, 1}
local green1
local gray1
local keepnames = {}

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
	    rest = rest .. ' ' .. str
	end
    end
    return first:sub(1, 1):lower(), rest:sub(2)
end

function CyroDoor.SaveCoords(mapname, s, x, y)
    if mapname ~= 'Cyrodiil' then
	return -- for now?
    end
    local loc = GetPlayerLocationName()
    if keepnames[loc] then
	return
    end
    local kid = keepnames[loc]

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

    door[key] = {x, y, kid}
    lmp:RefreshPins(nil)
    cmp:RefreshPins(nil)
end

local function create(what, name, func, doortab)
    local zone = lmp:GetZoneAndSubzone()
    local CreatePin = what.CreatePin
    if zone == 'cyrodiil' then
	for n, c in pairs(doortab) do
	    if func(n, c) then
		CreatePin(what, name, {}, c[1], c[2])
		-- df("%s: created pin %s for '%s' at %f, %f", what.Name, name, n, c[1], c[2])
	    end
	end
    end
end

local function set_green(pin)
    pin:GetNamedChild("Background"):SetColor(unpack(green))
end

local function set_gray(pin)
    pin:GetNamedChild("Background"):SetColor(unpack(gray))
end

function _init(_, name)
    if name ~= myname then
	return
    end

    green1 = ZO_ColorDef:New(unpack(green))
    gray1 = ZO_ColorDef:New(unpack(gray))

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
	    name = "My Keep Postern",
	    door = posterns,
	    find = function (n) return true end,
	    layout = {level = 100, maxDistance = 0.012, size = 4, texture = "CyroDoor/icons/postern.dds", tint = green1, additionalLayout = {set_green, set_green}},
	},
	{
	    name = "My Keep Gatehouse",
	    door = gatehouses,
	    find = function (n) return true end,
	    layout = {level = 100, maxDistance = 0.012, size = 8, texture = "CyroDoor/icons/gatehouse.dds", tint = green1, additionalLayout = {set_green, set_green}},
	},
	{
	    name = "Their Keep Postern",
	    door = posterns,
	    find = function (n) return true end,
	    layout = {level = 100, maxDistance = 0.012, size = 4, texture = "CyroDoor/icons/postern.dds", tint = gray1, additionalLayout = {set_gray, set_gray}},
	},
	{
	    name = "Their Keep Gatehouse",
	    door = gatehouses,
	    find = function (n) return true end,
	    layout = {level = 100, maxDistance = 0.012, size = 8, texture = "CyroDoor/icons/gatehouse.dds", tint = gray1, additionalLayout = {set_gray, set_gray}},
	}
    }
    alliance = GetUnitAlliance("player")
    lmp.Name = 'LibMapPins'
    cmp.pinManager.Name = 'CustomCompassPins'
    for _, x in ipairs(where) do
	local name, door, find, layout = x.name, x.door, x.find, x.layout
	local pid = lmp:AddPinType(name, function() create(lmp, name, find, door) end)
	lmp:SetLayoutData(pid, layout)
	color(pid)

	cmp:AddCustomPin(name, function(pm) create(pm, name, find, door) end, layout)
	cmp:RefreshPins(name)
	-- df("created pins for %s, texture %s, size %d", name, layout.texture, layout.size)
    end

    for i = 1, GetNumKeeps() do
	local kid = GetKeepKeysByIndex(i)
	if GetKeepType(kid) == KEEPTYPE_KEEP then
	    keepnames[GetKeepName(kid)] = kid
	end
    end
    saved.keepnames = keepnames
    saved.keepname = nil
    saved.coords = nil
    saved.doorix = nil
    for n, c in pairs(saved.doors.Cyrodiil.posterns) do
	if #c == 2 then
	    while true do
		local on = n
		n = n:gsub(' N', ' ')
		n = n:gsub(' S', ' ')
		n = n:gsub(' E', ' ')
		n = n:gsub(' W', ' ')
		n = n:gsub(' $', '')
		if n == on then
		    break
		end
	    end
	    if keepnames[n] == nil then
		df("Don't grok '%s' from posterns", n)
	    else
		c[#c + 1] = keepnames[n]
	    end
	end
    end
    for n, c in pairs(saved.doors.Cyrodiil.gatehouses) do
	if #c == 2 then
	    if keepnames[n] == nil then
		df("Don't grok '%s' from gatehouses", n)
	    else
		c[#c + 1] = keepnames[n]
	    end
	end
    end

    SLASH_COMMANDS["/cdl"] = function(x)
	local i = tonumber(x)
	if i then
	    for _, x in ipairs(where) do
		lmp:SetLayoutKey(x.name, "level", i)
	    end
	    lmp:RefreshPins(nil)
	end
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

