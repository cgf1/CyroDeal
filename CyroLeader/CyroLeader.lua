local CreateControlFromVirtual = CreateControlFromVirtual
local d = d
local dlater = CyroDeal.dlater
local dprint = CyroDeal.dprint
local dprintf = CyroDeal.dprintf
local EQUIP_SLOT_COSTUME = EQUIP_SLOT_COSTUME
local error = CyroDeal.error
local EVENT_MANAGER = EVENT_MANAGER
local GetControl = GetControl
local GetDateElementsFromTimestamp = GetDateElementsFromTimestamp
local GetGroupSize = GetGroupSize
local GetGroupUnitTagByIndex = GetGroupUnitTagByIndex
local GetGuildDescription = GetGuildDescription
local GetGuildId = GetGuildId
local GetGuildMemberIndexFromDisplayName = GetGuildMemberIndexFromDisplayName
local GetGuildMemberInfo = GetGuildMemberInfo
local GetGuildName = GetGuildName
local GetHeight = GetHeight
local GetItemCreatorName = GetItemCreatorName
local GetNumGuilds = GetNumGuilds
local GetString = GetString
local GetTimeStamp = GetTimeStamp
local GetUnitDisplayName = GetUnitDisplayName
local GetGroupLeaderUnitTag = GetGroupLeaderUnitTag
local GetUnitZone = GetUnitZone
local GroupLeave = GroupLeave
local GUILD_SHARED_INFO = GUILD_SHARED_INFO
local IsInCyrodiil = IsInCyrodiil
local IsUnitGrouped = IsUnitGrouped
local IsUnitInGroupSupportRange = IsUnitInGroupSupportRange
local lgr = LibGuildRoster
local os = os
local print = CyroDeal.print
local printf = CyroDeal.printf
local SetGuildMemberNote = SetGuildMemberNote
local SI_CHECK_BUTTON_ON = SI_CHECK_BUTTON_ON
local SLASH_COMMANDS = SLASH_COMMANDS
local split2 = CyroDeal.split2
local TOPLEFT = TOPLEFT
local TOPRIGHT = TOPRIGHT
local watch = CyroDeal.Watch
local zo_callLater = zo_callLater
local ZO_CheckButton_SetToggleFunction = ZO_CheckButton_SetToggleFunction
local ZO_GuildHistory = ZO_GuildHistory
local ZO_GuildRosterHideOffline = ZO_GuildRosterHideOffline
local ZO_GuildRosterSearchLabel = ZO_GuildRosterSearchLabel
local ZO_CheckButton_SetCheckState = ZO_CheckButton_SetCheckState

setfenv(1, CyroDeal)
local myname = "CyroLeader"
local x = {
    __index = _G,
    name = myname
}
local version = "1.01"

CyroLeader = setmetatable(x, x)
local cl = CyroLeader
cl.CyroLeader = cl

local log, lsc, saved
local iam = GetUnitDisplayName("player")

local pvppat = "^(PVP:%d%d%d%d/%d%d/%d%d ?)(.*)"
local gcol

function cl.SaveDefaults()
    return {leaderonly = true, pvpguild = {}}
end

local function isleader()
    if not saved.leaderonly then
	return true
    end
    local leadertag = GetGroupLeaderUnitTag()
    if not leadertag then
	return false
    end
    local dname = GetUnitDisplayName(leadertag)
    return dname == iam
end

local function lam()
    local a = {{
	type = "checkbox",
	name = "Only update guild notes when leader",
	tooltip = "Only update guild notes with date when when you're the leader of a group",
	getFunc = function()
	    return saved.leaderonly or false
	end,
	setFunc = function(val)
	    saved.leaderonly = val
	end
    }}
    return a
end

local lastdate
local running = false
local seen = {}
function update()
    if not IsUnitGrouped('player') then
	dprint("not grouped")
    elseif not isleader() then
	dprint("not leader")
    elseif not IsInCyrodiil() then
	dprint("not in Cyrodiil")
    else
	dprint("scanning")
	scan()
    end
end

function update_maybe()
    if running then
	dprint("update_maybe not gonna do it")
    else
	dprint("update_maybe calling update")
	update()
    end
end

function again(note)
    dprintf("again %s", note)
    running = true
    zo_callLater(update, 10000)
end

function scan()
    local pvpdate = os.date("!PVP:%Y/%m/%d")
    if pvpdate ~= lastdate then
	lastdate = pvpdate
	seen = {}
    end
    dprintf("Group size %d, date %s", GetGroupSize(), pvpdate)
    local already_updated = false
    local sawguild = false
    local later = false
    running = false
    for _, guid in ipairs(saved.pvpguild) do
	for i = 1, GetGroupSize() do
	    local unit = GetGroupUnitTagByIndex(i)
	    local name = GetUnitDisplayName(unit)
	    if seen[name] then
		dprint("seen", name)
		sawguild = true
	    else
		sawguild = true
		local guix = GetGuildMemberIndexFromDisplayName(guid, name)
		if guix then
		    local guin = GetGuildName(guid)
		    dprintf("checking %s %s, unit %s, guild %s pvpdate:%s, seen:%s", tostring(name), GetUnitZone(unit), unit, guin, pvpdate, tostring(seen[name] or false))
		    local _, note = GetGuildMemberInfo(guid, guix)
		    if note and note:find('^' .. pvpdate) then
			seen[name] = true
			dprintf("%s already updated with %s", name, pvpdate)
		    elseif not IsUnitInGroupSupportRange(unit) then
			dprintf("%s not in support range", name)
			later = true
		    elseif already_updated then
			again("restarting because need to rescan " .. name)
			return
		    else
			seen[name] = true
			note = note:gsub(pvppat, "")
			if note:len() > 0 then
			    pvpdate = pvpdate .. " "
			end
			SetGuildMemberNote(guid, guix, pvpdate .. note)
			dprintf("updated %s in %s", name, guin)
			already_updated = true
		    end
		end
	    end
	end
    end
    if later then
	again("restarting because later is true")
    elseif not sawguild then
	print("ALERT: Never saw a guild to register PVP attendance")
	d("pvpguild", saved.pvpguild)
    end
    if running then
	dprintf("still running")
    end
end

function cyl(what)
    if what == nil then
	return '/cyl', cyl, "CyroDeal: Refresh guild notes for group members in Cyrodiil"
    end
    update_maybe()
end

local function spoof_cyrodiil(what)
    if what == nil then
	return '/cylcyrodiil', spoof_cyrodiil, "CyroDeal: Assert that we are actually in Cyrodiil"
    end
    IsInCyrodiil = function() return true end
end

local function spoof_isleader(what)
    if what == nil then
	return '/cylleader', spoof_isleader, "CyroDeal: Assert that we are the group leader"
    end
    isleader = function() return true end
end

function cl.Init(init)
    log, lsc, saved = init.log, init.lsc, init.saved
    saved.pvpguild = saved.pvpguild or {}
    saved.recordpvp = nil
    saved.GuildNotes = nil
    lsc:Register(cyl())
    lam(init.options)
    EVENT_MANAGER:RegisterForEvent(myname, EVENT_GROUP_UPDATE, update_maybe)
    EVENT_MANAGER:RegisterForEvent(myname, EVENT_GROUP_MEMBER_JOINED, update_maybe)
    EVENT_MANAGER:RegisterForEvent(myname, EVENT_GROUP_MEMBER_REMOVED, update_maybe)
    EVENT_MANAGER:RegisterForEvent(myname, EVENT_LEADER_UPDATE, update_maybe)
    update_maybe()
    local ref = ZO_GuildRosterHideOffline
    -- local ref = ZO_GuildRosterSearchLabel,
    local button = CreateControlFromVirtual(nil, ref, "ZO_CheckButton")
    local text = CreateControlFromVirtual(nil, button, "ZO_CheckButtonLabel")
    text:SetText("Record PVP");
    button:SetAnchor(TOPLEFT, ref, TOPLEFT, 0, -(text:GetHeight() + 2))
    text:SetAnchor(TOPLEFT, button, TOPRIGHT, 5, -2)
    -- ZO_CheckButton_SetCheckState(button, true)
    local count = GetControl(GUILD_SHARED_INFO.control, "Count")
    count:SetHandler("OnTextChanged", function(self, currentFrameTimeSeconds)
	local guid = GUILD_SHARED_INFO.guildId
	local check = false
	for _, g in ipairs(saved.pvpguild) do
	    if g  == guid then
		check = true
		break
	    end
	end
	ZO_CheckButton_SetCheckState(button, check)
    end)
    ZO_CheckButton_SetToggleFunction(button, function(control, checked)
	local guid = GUILD_SHARED_INFO.guildId
	local n
	for i, g in ipairs(saved.pvpguild) do
	    if g == guid then
		n = i
		break
	    end
	end
	if n and not checked then
	    table.remove(saved.pvpguild, n, 1)
	    gcol:SetGuildFilter(saved.pvpguild)
	elseif not n and checked then
	    table.insert(saved.pvpguild, guid)
	    gcol:SetGuildFilter(saved.pvpguild)
	    update_maybe()
	end
    end)
    lsc:Register(spoof_cyrodiil())
    lsc:Register(spoof_isleader())
    gcol = lgr:AddColumn({
	key = myname,
	width = 80,
	guildFilter = saved.pvpguild,
	header = {
	    title = 'PVPed',
	    tootip = 'The time when a member was last seen in a group in Cyrodiil'
	},
	row = {
	    data = function(gid, data, index)
		local note = data.note
		local _, _, pvp, rest = note:find(pvppat)
		if not pvp then
		    return ''
		else
		    note = rest
		    return pvp:sub(5)
		end
	    end
	}
    })
    return lam()
end
