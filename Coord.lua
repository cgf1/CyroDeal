--[[
-------------------------------------------------------------------------------
-- CyroDoorCoord, by Ayantir
-------------------------------------------------------------------------------
This software is under : CreativeCommons CC BY-NC-SA 4.0
Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

You are free to:

    Share — copy and redistribute the material in any medium or format
    Adapt — remix, transform, and build upon the material
    The licensor cannot revoke these freedoms as long as you follow the license terms.


Under the following terms:

    Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
    NonCommercial — You may not use the material for commercial purposes.
    ShareAlike — If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
    No additional restrictions — You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.


Please read full licence at :
http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
]]
local GPS = LibStub("LibGPS2")
setfenv(1, CyroDoor)

local COORD

local MAPCOORDS_MAP = 1
local MAPCOORDS_GLOBAL = 2
local saved

--local functions -------------------------------------------------------------
local function FormatCoords(number)
    return ("%05.02f"):format(zo_round(number * 10000)/100)
end
local function FormatGPSCoords(number)
    return zo_round(number*100000)
end

function mysplit(inputstr, sep)
    if sep == nil then
	sep = "%s"
    end
    local t = {}
    for str in inputstr:gmatch("([^"..sep.."]+)") do
	t[#t + 1] = str
    end
    return unpack(t)
end

--slash command ---------------------------------------------------------------
SLASH_COMMANDS["/coords"] = function(name)
    if SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
	CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
    end

    local mapName = GetMapName()
    local mapId = GetCurrentMapIndex()
    local mapX, mapY = GetMapPlayerPosition("player")
    local zoneName, zoneX, zoneY = mapName, mapX, mapY

    if GetMapContentType() == MAP_CONTENT_DUNGEON or GetMapType() == MAPTYPE_SUBZONE then
	MapZoomOut()
	zoneName = GetMapName()
	zoneMapId = GetCurrentMapIndex()
	zoneX, zoneY = GetMapPlayerPosition("player")
    end
    if not (mapId == 23 or zoneMapId == 23) then --Coldharbour
	SetMapToMapListIndex(1)						 --Tamriel
    end
    local worldName = GetMapName()
    local worldX, worldY = GetMapPlayerPosition("player")

    if SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
	CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
    end

    local x = mapX -- FormatCoords(mapX)
    local y = mapY -- FormatCoords(mapY)
    CHAT_SYSTEM:AddMessage(zo_strformat("Map (|cDC8122<<1>>|r): |cFFFFFF<<2>>|r\195\151|cFFFFFF<<3>>|r", mapName, x, y))
    CHAT_SYSTEM:AddMessage(zo_strformat("Zone (|cDC8122<<1>>|r): |cFFFFFF<<2>>|r\195\151|cFFFFFF<<3>>|r", zoneName, FormatCoords(zoneX), FormatCoords(zoneY)))
    CHAT_SYSTEM:AddMessage(zo_strformat("World (|cDC8122<<1>>|r): |cFFFFFF<<2>>|r\195\151|cFFFFFF<<3>>|r", worldName, FormatCoords(worldX), FormatCoords(worldY)))
    if name:len() > 0 then
	CyroDoor.SaveCoords(mapName, name, x, y)
    end
end

-- definition if Coord object ---------------------------------------------
local Coord = ZO_Object:Subclass()

function Coord:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

local function Sanitize(value)
    return value:gsub("[-*+?^$().[%]%%]", "%%%0") -- escape meta characters
end

local function ValidMapPoint(x, y)
    return (x > 1 and y > 1 and x <= 100 and y <= 100)
end

local function ValidGPSPoint(x, y)
    return (x >= -1 and y >= -1 and x <= 1 and y <= 1)
end

local function IsValidCoords(dest)

    local isValid, mode
    local locX, locY

    for x, y in dest:gmatch("^(.+)x(.+)$") do	
	locX = x
	locY = y
    end

    local x, y = tonumber(locX), tonumber(locY)

    if type(x) == "number" and type(y) == "number" then
	if ValidMapPoint(x, y) then
		mode = MAPCOORDS_MAP
		isValid = true
	elseif ValidGPSPoint(x, y) then
		mode = MAPCOORDS_GLOBAL
		isValid = true
	end
    end

    return isValid, mode, x, y

end

local function OnEnter(self)
    local search = self:GetText()
    local isValid, mode, locX, locY = IsValidCoords(search)

    if isValid then
	if mode == MAPCOORDS_MAP then
		
		locX = locX / 100
		locY = locY / 100
		PingMap(MAP_PIN_TYPE_RALLY_POINT, MAP_TYPE_LOCATION_CENTERED, locX, locY)
		PingMap(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_TYPE_LOCATION_CENTERED, locX, locY)
		GPS:PanToMapPosition(locX, locY)
		
	elseif mode == MAPCOORDS_GLOBAL then
		
		local mapIndex = 1 -- Tamriel
		local wouldProcess
		
		ZO_WorldMap_SetMapByIndex(mapIndex)
		
		PingMap(MAP_PIN_TYPE_RALLY_POINT, MAP_TYPE_LOCATION_CENTERED, locX, locY)
		PingMap(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_TYPE_LOCATION_CENTERED, locX, locY)
		
		wouldProcess, mapIndex = WouldProcessMapClick(locX, locY)
		
		if wouldProcess then
		
			ZO_WorldMap_SetMapByIndex(mapIndex)
			local x, y = GPS:GlobalToLocal(locX, locY)
			zo_callLater(function()	GPS:PanToMapPosition(x, y) end, 200)
		end
		
	end
    end

end

function Coord:Initialize(parent)
    self.attachedTo = ZO_WorldMapScroll

    self.control = parent
    self.control:SetHidden(true)

    self:OnGamepadPreferredModeChanged()

    self.cursorLabel = WINDOW_MANAGER:CreateControl(nil, self.control, CT_LABEL)
    self.cursorLabel:SetAnchor(TOPLEFT, self.control, TOPLEFT, 0, 0)
    self.cursorLabel:SetFont("ZoFontWinH3")
    self.cursorLabel:SetColor(ZO_CONTRAST_TEXT:UnpackRGBA())

    self.playerLabel = WINDOW_MANAGER:CreateControl(nil, self.control, CT_LABEL)
    self.playerLabel:SetAnchor(TOPRIGHT, self.control, TOPRIGHT, 0, 0)
    self.playerLabel:SetFont("ZoFontWinH3")
    self.playerLabel:SetColor(ZO_CONTRAST_TEXT:UnpackRGBA())

    self.coordsSearch = WINDOW_MANAGER:CreateControlFromVirtual("Search", self.control, "CyroDoor_Coord_Research_Template")
    self.coordsSearchBox = GetControl(self.coordsSearch, "Box")
    self.coordsSearchBox:SetHandler("OnEnter", OnEnter)
    self.coordsSearch:SetCenterColor(0, 0, 0, 0)
    self.coordsSearch:SetEdgeColor(0, 0, 0, 0)

end

function Coord:AttachTo(attachedTo)
    if attachedTo and type(attachedTo) == "userdata" then
	self.attachedTo = attachedTo
	self.control:ClearAnchors()
	self.control:SetAnchor(TOPLEFT, attachedTo, BOTTOMLEFT, 4, self.yDelta)
	self.control:SetAnchor(TOPRIGHT, attachedTo, BOTTOMRIGHT, -4, self.yDelta)
    end
end

function Coord:UpdatePlayerPosition()
    local x, y = GetMapPlayerPosition("player")
    self.playerLabel:SetText(zo_strformat("Player: |cFFFFFF<<1>>|r\195\151|cFFFFFF<<2>>|r", FormatCoords(x), FormatCoords(y)))
end

function Coord:OnUpdate()
    self:UpdatePlayerPosition()

    local control
    local text = ""

    if MouseIsOver(ZO_WorldMapScroll) then
	control = ZO_WorldMapContainer
	self.coordsSearch:SetHidden(true)
    else
	self.coordsSearch:SetHidden(false)
    end

    if control then
	local normalizedX, normalizedY = NormalizeMousePositionToControl(control)
	text = zo_strformat("Cursor: |cFFFFFF<<1>>|r\195\151|cFFFFFF<<2>>|r", FormatCoords(normalizedX), FormatCoords(normalizedY))
    end

    self.cursorLabel:SetText(text)
end

function Coord:OnGamepadPreferredModeChanged()
    if IsInGamepadPreferredMode() then
	self.yDelta = 7
    else
	self.yDelta = 0
    end
    self:AttachTo(ZO_WorldMapScroll)
end

function InitCoord(_saved)
    saved = _saved
    ZO_CreateStringId("CYRODOOR_COORD_SEARCH_PLACEHOLDER", "Coords:")

    --create instance of Coord object
    COORD = Coord:New(WINDOW_MANAGER:CreateTopLevelWindow())

    --add scene fragment
    WORLD_MAP_SCENE:AddFragment(ZO_HUDFadeSceneFragment:New(COORD.control))
    GAMEPAD_WORLD_MAP_SCENE:AddFragment(ZO_HUDFadeSceneFragment:New(COORD.control))

    --update coordinates only when world map is active
    WORLD_MAP_SCENE:RegisterCallback("StateChange",
	    function(oldState, newState)
		    if newState == SCENE_SHOWING then
			    --OnUpdate handler does not work if window is not defined in XML, I have to use EVENT_MANAGER:
			    EVENT_MANAGER:RegisterForUpdate("CyroDoorCoord_OnUpdate", 50, function() COORD:OnUpdate() end)
		    elseif newState == SCENE_HIDING then
			    EVENT_MANAGER:UnregisterForUpdate("CyroDoorCoord_OnUpdate")
		    end
	    end)

    --update coordinates only when world map is active
    GAMEPAD_WORLD_MAP_SCENE:RegisterCallback("StateChange",
	    function(oldState, newState)
		    if newState == SCENE_SHOWING then
			    COORD:UpdatePlayerPosition()
			    --OnUpdate handler does not work if window is not defined in XML, I have to use EVENT_MANAGER:
			    EVENT_MANAGER:RegisterForUpdate("CyroDoorCoord_OnUpdate", 50, function() COORD:OnUpdate() end)
		    elseif newState == SCENE_HIDING then
			    EVENT_MANAGER:UnregisterForUpdate("CyroDoorCoord_OnUpdate")
		    end
	    end)

    --refresh player position when map is changed
    CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", function() COORD:UpdatePlayerPosition() end)

    EVENT_MANAGER:RegisterForEvent(Name, EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() COORD:OnGamepadPreferredModeChanged() end)

    --unregister event after initialization
    EVENT_MANAGER:UnregisterForEvent(Name, EVENT_ADD_ON_LOADED)
end
