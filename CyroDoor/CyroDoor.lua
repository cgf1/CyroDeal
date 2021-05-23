local cmp = COMPASS_PINS
local GetKeepAlliance = GetKeepAlliance
local GetKeepKeysByIndex = GetKeepKeysByIndex
local GetKeepName = GetKeepName
local GetKeepType = GetKeepType
local GetNumKeeps = GetNumKeeps
local GetPlayerLocationName = GetPlayerLocationName
local GetTimeStamp = GetTimeStamp
local GetUnitAlliance = GetUnitAlliance
local KEEPTYPE_KEEP = KEEPTYPE_KEEP
local lmp = LibMapPins
local print = CyroDeal.print
local printf = CyroDeal.printf
local SLASH_COMMANDS = SLASH_COMMANDS
local split2 = split2
local tprint = CyroDeal.tprint
local ZO_ColorDef = ZO_ColorDef
local ZO_CreateStringId = ZO_CreateStringId

local myname = 'CyroDoor'

setfenv(1, CyroDeal)
local x = {
    __index = _G,
    name = myname,
}

CyroDoor = setmetatable(x, x)
local CyroDoor = CyroDoor
CyroDoor.CyroDoor = CyroDoor

local log, lsc, saved
local visible

local saved
local texture
local gatehouses, posterns
local myalliance
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

function CyroDoor.SaveCoords(mapname, s, x, y)
    df("%s %s, %f, %f", mapname, s, x, y)
    log:Info("%s %s, %f, %f", mapname, s, x, y)
    if mapname ~= 'Cyrodiil' then
	d("Not in Cyrodiil?")
	log:Info("Not in Cyrodiil???")
	return -- for now?
    end
    local loc = GetPlayerLocationName()
    if not keepnames[loc] then
    df("%s %s, %f, %f, %s", mapname, s, x, y, loc)
	log:Info("%s doesn't match any keep names?", loc)
	for x in pairs(keepnames) do
	    d(x)
	end
	return
    end
    local kid = keepnames[loc]

    local door
    local doortype, text = split2(s)
    doortype = doortype:sub(1, 1):lower()
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
    log:Info("door type %s %s %f, %f", doortype, key, x, y)
    lmp:RefreshPins(nil)
    cmp:RefreshPins(nil)
end

local function create(pm, pintype, func, doortab)
    local zone, subzone = lmp:GetZoneAndSubzone()
    if visible and zone == 'cyrodiil' and subzone == 'ava_whole' then
	local CreatePin = pm.CreatePin
	for n, c in pairs(doortab) do
	    if func(n, c) then
		CreatePin(pm, pintype, {}, c[1], c[2])
		-- printf("%s: created pin %s for '%s' at %f, %f", pm.Name, pintype, n, c[1], c[2])
	    end
	end
    end
end

function refreshpins()
    for pintype, x in pairs(where) do
	lmp:Enable(pintype)
	cmp:AddCustomPin(pintype, x.cmpfunc, x.layout)
	cmp:RefreshPins(pintype)
    end
end

function makepins()
    for pintype, x in pairs(where) do
	local door, find, layout = x.door, x.find, x.layout
	lmp:AddPinType(pintype, function() create(lmp, pintype, find, door) end, nil, layout)
	x.cmpfunc = function(pm) create(pm, pintype, find, door) end
	cmp:AddCustomPin(pintype, x.cmpfunc, layout)
	cmp:RefreshPins(pintype)
    end
    makepins = refreshpins
end

function removepins()
    for pintype in pairs(where) do
	lmp:Disable(pintype)
	cmp.pinManager:RemovePins(pintype)
    end
end

local lastdown
function CyroDoor.Show(down)
    local now = GetTimeStamp()
    local wasvisible = visible
    if down then
	lastdown = now
	visible = true
    else
	if (now - lastdown) < 5 then
	    visible = false
	end
	lastdown = nil
    end
    if visible then
	makepins()
    else
	removepins()
    end
end

function mykeep(n, c)
    local res = GetKeepAlliance(c[3], 1) == myalliance
    -- df("returning %s for %d == %d", tostring(res), GetKeepAlliance(c[3], 1), myalliance)
    return res
end

function theirkeep(n, c)
    local res = GetKeepAlliance(c[3], 1) ~= myalliance
    -- df("returning %s for %d ~= %d", tostring(res), GetKeepAlliance(c[3], 1), myalliance)
    return res
end

function CyroDoor.SaveDefaults()
    return {doors = {
	    Cyrodiil = {
		gatehouses = {
		    ["Farragut Keep"] = {
			0.8455066681,
			0.3380022347,
			12
		    },
		    ["Fort Aleswell"] = {
			0.4058488905,
			0.2836955488,
			7,
		    },
		    ["Castle Roebeck"] = {
			0.4125644565,
			0.5635200143,
			17,
		    },
		    ["Kingscrest Keep"] = {
			0.7224155664,
			0.1905688941,
			11,
		    },
		    ["Fort Glademist"] = {
			0.2742755413,
			0.2845066786,
			5,
		    },
		    ["Chalman Keep"] = {
			0.5808110833,
			0.2885622084,
			9,
		    },
		    ["Castle Faregyl"] = {
			0.4990933239,
			0.6756311059,
			16,
		    },
		    ["Castle Brindle"] = {
			0.2352333367,
			0.5677310824,
			18,
		    },
		    ["Fort Ash"] = {
			0.3394044340,
			0.4275177717,
			6,
		    },
		    ["Castle Black Boot"] = {
			0.4077311158,
			0.7661533356,
			19,
		    },
		    ["Castle Bloodmayne"] = {
			0.5747555494,
			0.7615799904,
			20,
		    },
		    ["Fort Warden"] = {
			0.2315533310,
			0.1650066674,
			3,
		    },
		    ["Fort Rayles"] = {
			0.1847555488,
			0.3272688985,
			4,
		    },
		    ["Arrius Keep"] = {
			0.7024000287,
			0.3124800026,
			10,
		    },
		    ["Blue Road Keep"] = {
			0.6531955600,
			0.4289399981,
			13,
		    },
		    ["Fort Dragonclaw"] = {
			0.4911622107,
			0.1181688905,
			8,
		    },
		    ["Drakelowe Keep"] = {
			0.7673555613,
			0.5829377770,
			14,
		    },
		    ["Castle Alessia"] = {
			0.5707377791,
			0.5571466684,
			15,
		    }
		},
		posterns = {
		    ["Fort Ash SW"] = {
			0.3265288770,
			0.4275066555,
			6,
		    },
		    ["Castle Faregyl NW"] = {
			0.4871244431,
			0.6756733060,
			16,
		    },
		    ["Castle Roebeck NE"] = {
			0.4193600118,
			0.5645777583,
			17,
		    },
		    ["Fort Aleswell W"] = {
			0.4034111202,
			0.2772777677,
			7,
		    },
		    ["Fort Aleswell S"] = {
			0.4159289002,
			0.2831377685,
			7,
		    },
		    ["Drakelowe Keep NW"] = {
			0.7703266740,
			0.5684400201,
			14,
		    },
		    ["Chalman Keep N"] = {
			0.5811466575,
			0.2708599865,
			9,
		    },
		    ["Fort Ash N"] = {
			0.3300488889,
			0.4124955535,
			6,
		    },
		    ["Fort Dragonclaw E"] = {
			0.5023199916,
			0.1089266688,
			8,
		    },
		    ["Arrius Keep W"] = {
			0.6934755445,
			0.3212355673,
			10,
		    },
		    ["Fort Warden S"] = {
			0.2329999954,
			0.1861466616,
			3,
		    },
		    ["Fort Glademist W"] = {
			0.2663066685,
			0.2753466666,
			5,
		    },
		    ["Blue Road Keep W"] = {
			0.6524800062,
			0.4221133292,
			13,
		    },
		    ["Castle Roebeck SE"] = {
			0.4217711091,
			0.5799177885,
			17,
		    },
		    ["Fort Ash E"] = {
			0.3410355449,
			0.4208599925,
			6,
		    },
		    ["Castle Brindle S"] = {
			0.2272622287,
			0.5801733136,
			18,
		    },
		    ["Fort Glademist E"] = {
			0.2836066782,
			0.2753466666,
			5,
		    },
		    ["Castle Bloodmayne SE"] = {
			0.5829799771,
			0.7777799964,
			20,
		    },
		    ["Drakelowe Keep SE"] = {
			0.7820733190,
			0.5818399787,
			14,
		    },
		    ["Arrius Keep E"] = {
			0.7113022208,
			0.3213022351,
			10,
		    },
		    ["Kingscrest Keep E"] = {
			0.7367911339,
			0.1795399934,
			11,
		    },
		    ["Castle Bloodmayne SW"] = {
			0.5651533604,
			0.7769711018,
			20,
		    },
		    ["Fort Rayles N"] = {
			0.1726444513,
			0.3140622079,
			4,
		    },
		    ["Castle Alessia E"] = {
			0.5760733485,
			0.5688489079,
			15,
		    },
		    ["Chalman Keep W"] = {
			0.5700155497,
			0.2815644443,
			9,
		    },
		    ["Castle Roebeck W"] = {
			0.4080800116,
			0.5725688934,
			17,
		    },
		    ["Blue Road Keep NE"] = {
			0.6666799784,
			0.4158377647,
			13,
		    },
		    ["Castle Alessia SW"] = {
			0.5609666705,
			0.5719000101,
			15,
		    },
		    ["Castle Black Boot S"] = {
			0.4073888958,
			0.7873399854,
			19,
		    },
		    ["Castle Faregyl SE"] = {
			0.4992911220,
			0.6879977584,
			16,
		    },
		    ["Fort Rayles SW"] = {
			0.1669066697,
			0.3303999901,
			4,
		    },
		    ["Fort Aleswell NE"] = {
			0.4153066576,
			0.2680288851,
			7,
		    },
		    ["Blue Road Keep S"] = {
			0.6631022096,
			0.4309622347,
			13,
		    },
		    ["Castle Brindle NW"] = {
			0.2211022228,
			0.5634511113,
			18,
		    },
		    ["Farragut Keep NW"] = {
			0.8361355662,
			0.3184333444,
			12,
		    },
		    ["Kingscrest Keep NW"] = {
			0.7203999758,
			0.1725488901,
			11,
		    },
		    ["Chalman Keep E"] = {
			0.5858177543,
			0.2838599980,
			9,
		    },
		    ["Castle Alessia NW"] = {
			0.5639911294,
			0.5584155321,
			15,
		    },
		    ["Fort Dragonclaw NW"] = {
			0.4860622287,
			0.1046577767,
			8
		    }
		}
	    }
	}}
end

function CyroDoor.Init(init)
    tprint(init)
    log, lsc, saved = init.log, init.lsc, init.saved

    -- CyroDoor.InitCoord(saved)
    local doors = saved.doors
    gatehouses = doors.Cyrodiil.gatehouses
    posterns = doors.Cyrodiil.posterns
    myalliance = GetUnitAlliance("player")
    -- lmp.Name = 'LibMapPins'
    -- cmp.pinManager.Name = 'CustomCompassPins'
    where = {
	["My Keep Postern"] = {
	    door = posterns,
	    find = mykeep,
	    layout = {level = 100, maxDistance = 0.012, size = 4, texture = "CyroDoor/icons/our-postern.dds"},
	},
	["My Keep Gatehouse"] = {
	    door = gatehouses,
	    find = mykeep,
	    layout = {level = 100, maxDistance = 0.012, size = 8, texture = "CyroDoor/icons/our-gatehouse.dds"},
	},
	["Their Keep Postern"] = {
	    door = posterns,
	    find = theirkeep,
	    layout = {level = 100, maxDistance = 0.012, size = 4, texture = "CyroDoor/icons/their-postern.dds"},
	},
	["Their Keep Gatehouse"] = {
	    door = gatehouses,
	    find = theirkeep,
	    layout = {level = 100, maxDistance = 0.012, size = 8, texture = "CyroDoor/icons/their-gatehouse.dds"},
	}
    }

    for i = 1, GetNumKeeps() do
	local kid = GetKeepKeysByIndex(i)
	if GetKeepType(kid) == KEEPTYPE_KEEP then
	    keepnames[GetKeepName(kid)] = kid
	end
    end
    saved.keepnames = keepnames
    EVENT_MANAGER:RegisterForEvent(myname, EVENT_KEEP_ALLIANCE_OWNER_CHANGED, function ()
	lmp:RefreshPins(nil)
	cmp:Update(nil)
    end)

    SLASH_COMMANDS["/cdl"] = function(x)
	local i = tonumber(x)
	if i then
	    for pintype in pairs(where) do
		lmp:SetLayoutKey(pintype, "level", i)
	    end
	    lmp:RefreshPins(nil)
	end
    end

    SLASH_COMMANDS["/cdw"] = function()
	for pintype in pairs(where) do
	    color(pintype, 1, 1, 1, 1)
	end
    end
    SLASH_COMMANDS["/cdg"] = function()
	for n in pairs(saved.coords.Cyrodiil) do
	    color(x.pintype, 0, 1, 0, 1)
	end
    end
    SLASH_COMMANDS["/cdb"] = function()
	for pintype in pairs(where) do
	    color(pintype, 0.2, 0.6, 1, 1)
	end
    end
    SLASH_COMMANDS["/cdr"] = function()
	for pintype in pairs(where) do
	    color(pintype, 1, 0, 0, 1)
	end
    end
end

ZO_CreateStringId("SI_BINDING_NAME_CYRODOOR_HOLDDOWN", "Show/hide doors on keeps while key is depressed")
