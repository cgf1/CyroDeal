local lmp = LibStub("LibMapPins-1.0")
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

local doors = {
"CyroDoor/icons/door.dds",
"art/fx/texture/sigil_icdoor_boneshard.dds",
"art/fx/texture/sigil_icdoor_darkether.dds",
"art/fx/texture/sigil_icdoor_motl.dds",
"art/fx/texture/sigil_icdoor_tinyclaw.dds",
"art/fx/texture/sigil_icdoor_tooth.dds",
"art/fx/texture/sigil_icpdoor_daedricshackles.dds",
"art/fx/texture/sigil_imperialcitydoor.dds",
"art/fx/texture/sigil_spellcraftingdoor.dds",
"art/fx/texture/sigil_wgtdoor_daedricembers.dds",
"art/fx/texture/modelfxtextures/mq6_rockwalldoorlava_d.dds",
"art/fx/texture/modelfxtextures/mq6_rockwalldoorlava_n.dds",
"art/fx/texture/modelfxtextures/mq6_rockwalldoormelt_bw.dds",
"art/fx/texture/modelfxtextures/mq6_rockwalldoormelt_d.dds",
"art/fx/texture/modelfxtextures/mq6_rockwalldoormelt_n.dds",
"art/fx/texture/modelfxtextures/mq6_rockwalldoor_d.dds",
"art/fx/texture/modelfxtextures/mq6_rockwalldoor_n.dds",
"art/fx/texture/modelfxtextures/xanmeerdoorglow.dds",
"art/icons/housing_arg_str_dbhdoor001.dds",
"art/icons/housing_ayl_duc_bookcasedoorlarge002.dds",
"art/icons/housing_ayl_duc_bookcasedoorsmall001.dds",
"art/icons/housing_bre_str_doorlocklrg001.dds",
"art/icons/housing_bre_str_doorlocklrggate001.dds",
"art/icons/housing_bre_str_doorlocksmll001.dds",
"art/icons/housing_col_inc_dbhkegdoor001.dds",
"art/icons/housing_col_str_dbhdoor001.dds",
"art/icons/housing_gen_inc_soulgemdoormarkerssmall001.dds",
"art/icons/housing_gen_inc_soulgemdoormarkerssmall002.dds",
"art/icons/housing_gen_inc_soulgemdoormarkerssmall003.dds",
"art/icons/housing_orc_duc_puzzledoorplatebagrakh001.dds",
"art/icons/housing_orc_duc_puzzledoorplatefharhun001.dds",
"art/icons/housing_orc_duc_puzzledoorplateigron001.dds",
"art/icons/housing_orc_duc_puzzledoorplatemorkul001.dds",
"art/icons/housing_orc_duc_puzzledoorplateshatul001.dds",
"art/icons/housing_orc_duc_puzzledoorplatetumnosh001.dds",
"art/icons/housing_orc_duc_puzzledoorweight002.dds",
"art/icons/housing_red_duc_yokudanpuzzledoortumbler001.dds",
"art/icons/housing_vrd_duc_standdooraltar001.dds",
"art/icons/housing_vrd_fur_hlachinacabinetdoor001.dds",
"art/icons/quest_grinddoorkey_bone.dds",
"art/icons/quest_grinddoorkey_clawed.dds",
"art/icons/quest_grinddoorkey_embers.dds",
"art/icons/quest_grinddoorkey_enamel.dds",
"art/icons/quest_grinddoorkey_ethereal.dds",
"art/icons/quest_grinddoorkey_legionary.dds",
"art/icons/quest_grinddoorkey_planar.dds",
"art/icons/quest_grinddoorkey_shackles.dds",
"art/tutorial/examples/help-ic_door-1024x512.dds",
"esoui/art/compass/groupleader_door.dds",
"esoui/art/compass/groupmember_door.dds",
"esoui/art/compass/quest_icon_door.dds",
"esoui/art/compass/quest_icon_door_assisted.dds",
"esoui/art/compass/repeatablequest_icon_door.dds",
"esoui/art/compass/repeatablequest_icon_door_assisted.dds",
"esoui/art/floatingmarkers/quest_icon_door.dds",
"esoui/art/floatingmarkers/quest_icon_door_assisted.dds",
"esoui/art/floatingmarkers/repeatablequest_icon_door.dds",
"esoui/art/floatingmarkers/repeatablequest_icon_door_assisted.dds"
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

local function next_texture(nid, trynext)
    if not saved.doorix or not doors[saved.doorix] or (trynext and not doors[saved.doorix + 1]) then
	saved.doorix = 1
    elseif trynext then
	saved.doorix = saved.doorix + 1
    end
    lmp:SetLayoutKey(nid, "texture", doors[saved.doorix])
    lmp:RefreshPins(nid)
    if trynext then
	df("%d) %s", saved.doorix, doors[saved.doorix])
    end
end

local function color(nid, r, g, b, a)
    if r then
	saved.color = {r, g, b, a}
    elseif not saved.color or not saved.color[1] then
	saved.color = {0, 1, 0, 1}
    end
    df("color %d, %d, %d, %d", unpack(saved.color))
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
	local id = lmp:AddPinType(n, function ()
	    lmp:CreatePin(n, {}, c[1], c[2])
	end)
	lmp:SetLayoutKey(id, "level", 200)
	lmp:SetLayoutKey(id, "size", 14)
	color(n)
	next_texture(id, false)
	local x = lmp:IsEnabled(id)
	df("%s(%d) %f, %f %s", n, id, c[1], c[2], tostring(x))
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
	    color(n, 0, 0, 0, 1)
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

