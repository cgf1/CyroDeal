local AcceptGroupInvite = AcceptGroupInvite
local CHAT_CHANNEL_PARTY = CHAT_CHANNEL_PARTY
local CHAT_SYSTEM = CHAT_SYSTEM
local EQUIP_SLOT_COSTUME = EQUIP_SLOT_COSTUME
local dlater = CyroDeal.dlater
local error = CyroDeal.error
local GetGuildDescription = GetGuildDescription
local GetGuildId = GetGuildId
local GetGuildMotD = GetGuildMotD
local GetGuildName = GetGuildName
local GetItemCreatorName = GetItemCreatorName
local GetNumGuilds = GetNumGuilds
local GroupLeave = GroupLeave
local print = CyroDeal.print
local printf = CyroDeal.printf
local split2 = CyroDeal.split2
local watch = CyroDeal.Watch
local zo_callLater = zo_callLater
local ZO_PreHook = ZO_PreHook

setfenv(1, CyroDeal)
local myname = "CyroGroup"
local x = {
    __index = _G,
    name = myname
}

CyroGroup = setmetatable(x, x)
local cg = CyroGroup
cg.CyroGroup = cg

local log, lsc, saved

local JUMP1 = 'JUMP_TO_GROUP_LEADER_WORLD_PROMPT'
local JUMP2 = 'JUMP_TO_GROUP_LEADER_OCCURANCE_PROMPT'

local discord

local hooked = false
local suppress = false
local function nodialog(name, data)
    watch("nodialog", name, data)
    if (name == JUMP1 or name == JUMP2) and suppress then
	suppress = false
	return true
    end
end


local function on_invite(_, charname, displayname)
    watch("on_invite", charname, displayname)
    if saved.AutoAccept[charname] or saved.AutoAccept[displayname] then
	suppress = true
	if not hooked then
	    ZO_PreHook("ZO_Dialogs_ShowDialog", nodialog)
	    hooked = true
	end
	AcceptGroupInvite()
	printf("accepted invite from %s", charname)
    end
end

local function autoaccept(what)
    if what == nil then
	return '/cyaccept', autoaccept, 'Automatically accept requests from given person'
    end

    local kw, rest = split2(what)
    if kw == 'clear' then
	what = rest
    end
    if kw == 'clear' then
	if what == '' then
	    saved.AutoAccept = {}
	    print("clearing all auto accept group invites")
	elseif saved.AutoAccept[what] then
	    saved.AutoAccept[what] = nil
	    printf("clearing auto accept group invite for %s", what)
	else
	    error('"%s" was not found in auto accept list', what)
	end
    elseif what:len() > 0 then
	saved.AutoAccept[what] = true
	printf("automatically accept group invites from %s", what)
    else
	local keys = {}
	for n in pairs(saved.AutoAccept) do
	    keys[#keys + 1] = n
	end
	if #keys == 0 then
	    error("not accepting group invites from anyone")
	else
	    print("accepting group invites from:")
	    table.sort(keys)
	    for _, n in ipairs(keys) do
		print(n)
	    end
	end
    end
end

local function leave(what)
    if what == nil then
	return '/cyleave', leave, "Leave group"
    end
    GroupLeave()
end

local function finddiscord()
    local link
    if discord.Text then
	link = discord.Text
    elseif discord.FromGuild then
	local guild
	if saved.MainGuild then
	    guild = saved.MainGuild
	else
	    guild = GetItemCreatorName(0, EQUIP_SLOT_COSTUME)
	end
	local message
	if not guild or guild == "" then
	    message = "no main guild found and no guild tabard for finding discord info%0.s"
	    guild = ""
	else
	    local n = GetNumGuilds()
	    for i = 1, n do
		local id = GetGuildId(i)
		if GetGuildName(id) == guild then
		    local desc = GetGuildDescription(id) .. GetGuildMotD(id)
		    _, _, link = desc:find("(https://discord%.%S+)")
		    if not link then
			message = "couldn't find discord info for guild \"%s\""
		    else
			link = string.format("Please join us on discord voice chat - %s (push-to-talk %srequired, microphone %srequired)", link,
					      (discord.P2T and "") or "not ", (discord.Mic and "") or "not ");
		    end
		    break
		end
	    end
	    message = "couldn't find guild \"%s\" in your list of active guilds"
	end
	if not link then
	    error(message, guild)
	end
    end
    return link
end

function cg.SendText(n)
    local channel = CHAT_CHANNEL_PARTY
    local message
    if n == 0 then
	message = finddiscord()
    else
	message = saved.Texts[n]
    end
    if message then
	CHAT_SYSTEM:StartTextEntry(message, CHAT_CHANNEL_PARTY)
    else
	error("no message assigned to that slot")
    end
end

function cg.SaveDefaults()
    return {AutoAccept = {}, Discord = {FromGuild = true, Mic = false, P2T = true}, Texts = {}}
end

local function lam()
    local a = {{
	type = "submenu",
	name = "Discord",
	tooltip = "Control how discord information is sent to group chat",
	controls = {
	    {
		type = "editbox",
		name = "Discord text to send",
		tooltip = "Optional text to send when key is depressed.	 Defaults to text found in guild info if not set.",
		isMultiline = false,
		isExtraWide = true,
		getFunc = function()
		    return discord.Text or ""
		end,
		setFunc = function(val)
		    discord.Text = val
		end
	    },
	    {
		type = "checkbox",
		name = "Search for discord link in guild info",
		tooltip = "Enable if discord link should be found in a) any \"Main Guild\" set or b) from the currenly equipped guild tabard.",
		getFunc = function()
		    return discord.FromGuild
		end,
		setFunc = function(val)
		    discord.FromGuild = val
		end
	    },
	    {
		type = "checkbox",
		name = "Is a microphone required?",
		tooltip = "Enable if a microphone is required for Discord participation.",
		getFunc = function()
		    return discord.Mic
		end,
		setFunc = function(val)
		    discord.Mic = val
		end
	    },
	    {
		type = "checkbox",
		name = "Is push-to-talk required?",
		tooltip = "Enable if a push-to-talk is required for Discord participation.",
		getFunc = function()
		    return discord.P2T
		end,
		setFunc = function(val)
		    discord.P2T = val
		end
	    }
	}
    }}
    print("AAAAA", #a)
    return a
end

function cg.Init(init)
    log, lsc, saved = init.log, init.lsc, init.saved
    discord = saved.Discord
    lam(init.options)
    EVENT_MANAGER:RegisterForEvent(myname, EVENT_GROUP_INVITE_RECEIVED, on_invite)
    local aa = lsc:Register(autoaccept())
    aa:AddAlias('/cya')
    local l = lsc:Register(leave())
    l:AddAlias('/leave')
    return lam()
end
ZO_CreateStringId("SI_BINDING_NAME_CYRODEAL_SEND_DISCORD", "Send Discord Link")
ZO_CreateStringId("SI_BINDING_NAME_CYRODEAL_SEND_TEXT1", "Send Arbitrary Text")
ZO_CreateStringId("SI_BINDING_NAME_CYRODEAL_SEND_TEXT2", "Send Arbitrary Text")
