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

local saved = nil

local xxx

local texture

local posterns = {
"CyroDoor/icons/archway1.dds",
"CyroDoor/icons/archway2.dds",
"CyroDoor/icons/archway3.dds",
"CyroDoor/icons/archway4.dds",
"CyroDoor/icons/door.dds",
"CyroDoor/icons/door1.dds",
"CyroDoor/icons/door2.dds",
"CyroDoor/icons/door3.dds",
"CyroDoor/icons/door4.dds",
"CyroDoor/icons/door5.dds"
}

local doors = {
"CyroDoor/icons/postern2.dds",
"CyroDoor/icons/postern2.dds",
"CyroDoor/icons/postern2.dds",
"CyroDoor/icons/postern2.dds",
"CyroDoor/icons/postern2.dds",
"CyroDoor/icons/postern2.dds",
"CyroDoor/icons/postern2.dds",
"CyroDoor/icons/postern2.dds",
"CyroDoor/icons/postern2.dds",
"CyroDoor/icons/postern2.dds"
}

local function prev_texture(nid, tryprev)
    if not saved.doorix or not doors[saved.doorix] or saved.doorix == 1 then
	saved.doorix = 1
    elseif tryprev then
	saved.doorix = saved.doorix - 1
    end
    lmp:SetLayoutKey(nid, "texture", doors[saved.doorix])
    lmp:RefreshPins(nid)
    if tryprev then
	df("%d) %s", saved.doorix, doors[saved.doorix])
    end
end

local layout = {maxDistance = 0.05}

local function next_texture(n, trynext, x, y)
    if not saved.doorix or not doors[saved.doorix] or (trynext and not doors[saved.doorix + 1]) then
	saved.doorix = 1
    elseif trynext then
	saved.doorix = saved.doorix + 1
    end
    local texture
    if n:find("Postern") then
	texture = posterns[saved.doorix]
    else
	texture = doors[saved.doorix]
    end
    if x ~= nil then
	lmp:AddPinType(n, function ()
df("AddPinType %s called", n)
	    lmp:CreatePin(n, {}, x, y)
	end)
	layout['texture'] = texture
	cmp:AddCustomPin(n, function(pm)
df("AddCustomPin %s called", n)
	    pm:CreatePin(n, nil, x, y)
	end, layout)
    end
    lmp:SetLayoutKey(n, "texture", texture)
    -- lmp:RefreshPins(nid)
    if true or trynext then
	df("%d) %s", saved.doorix, texture)
    end
end

local function color(nid, r, g, b, a)
    if r then
	saved.color = {r, g, b, a}
    elseif not saved.color or not saved.color[1] then
	saved.color = {0, 1, 0, 1}
    end
    -- df("color %d, %d, %d, %d", unpack(saved.color))
    local color = ZO_ColorDef:New(unpack(saved.color))
    lmp:SetLayoutKey(nid, "tint", color)
    lmp:RefreshPins(nid)
end


local door_ix
function _init(_, name)
    if name ~= myname then
	return
    end
    EVENT_MANAGER:UnregisterForEvent(name, EVENT_ADD_ON_LOADED)
    saved = ZO_SavedVars:NewAccountWide(name .. 'Saved', 1, nil, {coords = {}})
    InitCoord(saved)
    xxx = WINDOW_MANAGER:CreateControl("MyAddonExampleTexture", ZO_StatsPanel, CT_TEXTURE) -- Create a texture control
    xxx:SetDimensions(40,40)  -- Set the size of the texture control
    xxx:SetAnchor(TOPLEFT, ZO_StatsPanelTitleSection, TOPLEFT, 350, -10)  -- Set the position in relation to the topleft corner of the character screen
    -- xxx:SetTexture("/esoui/art/compass/quest_icon_door.dds")	 -- Set the actual texture to use
    xxx:SetTexture(texture)  -- Set the actual texture to use
    xxx:SetHidden(false)

    for n, c in pairs(saved.coords.Cyrodiil) do
	next_texture(n, false, unpack(c))
	lmp:SetLayoutKey(id, "level", 200)
	local size
	if n:find("Postern") then
	    size = 4
	else
	    size = 10
	end
	lmp:SetLayoutKey(n, "size", size)
	color(n)
	local x = lmp:IsEnabled(id)
	df("%s(%d) %f, %f; enabled = %s; size = %d", n, id, c[1], c[2], tostring(x), tonumber(lmp:GetLayoutKey(n, "size")))
    end
    SLASH_COMMANDS["/cdn"] = function()
	local trynext = true
	for n in pairs(saved.coords.Cyrodiil) do
	    next_texture(n, trynext)
	    trynext = false
	end
    end
    SLASH_COMMANDS["/cdp"] = function()
	local tryprev = true
	for n in pairs(saved.coords.Cyrodiil) do
	    prev_texture(n, tryprev)
	    tryprev = false
	end
    end
    SLASH_COMMANDS["/cdw"] = function()
	for n in pairs(saved.coords.Cyrodiil) do
	    color(n, 1, 1, 1, 1)
	end
    end
    SLASH_COMMANDS["/cdg"] = function()
	for n in pairs(saved.coords.Cyrodiil) do
	    color(n, 0, 1, 0, 1)
	end
    end
    SLASH_COMMANDS["/cdb"] = function()
	for n in pairs(saved.coords.Cyrodiil) do
	    color(n, 0.2, 0.6, 1, 1)
	end
    end
    SLASH_COMMANDS["/cdr"] = function()
	for n in pairs(saved.coords.Cyrodiil) do
	    color(n, 1, 0, 0, 1)
	end
    end
    SLASH_COMMANDS["/cdi"] = function(x)
	local i = tonumber(x)
	saved.doorix = i
	df("%s %d", x, saved.doorix)
	for n in pairs(saved.coords.Cyrodiil) do
	    next_texture(n, false)
	end
	df("%d) %s", saved.doorix, doors[saved.doorix])
    end
end

EVENT_MANAGER:RegisterForEvent(myname, EVENT_ADD_ON_LOADED, _init)

