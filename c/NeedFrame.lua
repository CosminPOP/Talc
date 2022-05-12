local db, core
local _G = _G
NeedFrame = CreateFrame("Frame")

NeedFrame.init = function()
    core = TALC
    db = TALC_DB

    NeedFrame:HideAnchor()

    talc_print('TALC NeedFrame (v' .. core.addonVer .. ') Loaded. Type |cfffff569/talc |cff69ccf0need |cffffffffto show the Anchor window.')

    TalcNeedFrame:SetScale(db['NEED_SCALE'])

    NeedFrame:ResetVars()
end

local NeedFrameCountdown = CreateFrame("Frame")

NeedFrame.numItems = 0

NeedFrameComs = CreateFrame("Frame")

NeedFrameCountdown:Hide()
NeedFrameCountdown.timeToNeed = 30 --default, will be gotten via addonMessage

NeedFrameCountdown.T = 1
NeedFrameCountdown.C = NeedFrameCountdown.timeToNeed

local NeedFrames = CreateFrame("Frame")
NeedFrames.itemFrames = {}
NeedFrames.execs = 0

local fadeInAnimationFrame = CreateFrame("Frame")
fadeInAnimationFrame:Hide()
fadeInAnimationFrame.ids = {}

local fadeOutAnimationFrame = CreateFrame("Frame")
fadeOutAnimationFrame:Hide()
fadeOutAnimationFrame.ids = {}

local delayAddItem = CreateFrame("Frame")
delayAddItem:Hide()
delayAddItem.data = {}

delayAddItem:SetScript("OnShow", function()
    this.startTime = GetTime();
end)
delayAddItem:SetScript("OnUpdate", function()
    local plus = 0.5
    local gt = GetTime() * 1000 --22.123 -> 22123
    local st = (this.startTime + plus) * 1000 -- (22.123 + 0.1) * 1000 =  22.223 * 1000 = 22223
    if gt >= st then

        local atLeastOne = false
        for id, data in next, delayAddItem.data do
            if delayAddItem.data[id] then
                atLeastOne = true
                talc_debug('delay add item on update for item id ' .. id .. ' data:[' .. data)
                delayAddItem.data[id] = nil
                NeedFrames:addItem(data)
            end
        end

        if not atLeastOne then
            delayAddItem:Hide()
        end
    end
end)

NeedFrameCountdown:SetScript("OnShow", function()
    this.startTime = GetTime();
end)

NeedFrameCountdown:SetScript("OnUpdate", function()
    local plus = 0.03
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        if (NeedFrameCountdown.T ~= NeedFrameCountdown.timeToNeed + plus) then

            for index in next, NeedFrames.itemFrames do
                if core.floor(NeedFrameCountdown.C - NeedFrameCountdown.T + plus) < 0 then
                    _G['NeedFrame' .. index .. 'TimeLeftBarText']:SetText("CLOSED")
                else
                    _G['NeedFrame' .. index .. 'TimeLeftBarText']:SetText(core.ceil(NeedFrameCountdown.C - NeedFrameCountdown.T + plus) .. "s")
                end

                _G['NeedFrame' .. index .. 'TimeLeftBar']:SetWidth((NeedFrameCountdown.C - NeedFrameCountdown.T + plus) * 190 / NeedFrameCountdown.timeToNeed)
            end
        end
        NeedFrameCountdown:Hide()
        if (NeedFrameCountdown.T < NeedFrameCountdown.C + plus) then
            --still tick
            NeedFrameCountdown.T = NeedFrameCountdown.T + plus
            NeedFrameCountdown:Show()
        elseif (NeedFrameCountdown.T > NeedFrameCountdown.timeToNeed + plus) then

            -- hide frames and send auto pass
            for index in next, NeedFrames.itemFrames do
                if NeedFrames.itemFrames[index]:GetAlpha() == 1 then
                    PlayerNeedItemButton_OnClick(index, 'autopass')
                end
            end
            -- end hide frames

            NeedFrameCountdown:Hide()
            NeedFrameCountdown.T = 1

        end
    end
end)

function NeedFrames.cacheItem(data)
    local item = core.split("=", data)

    local index = core.int(item[2])
    local link = item[5]

    local _, _, itemLink = core.find(link, "(item:%d+:%d+:%d+:%d+)");

    _G['NewItemTooltip' .. index]:SetHyperlink(itemLink)
    _G['NewItemTooltip' .. index]:Show()

    local name, _, quality = GetItemInfo(itemLink)

    if not name or not quality then
        talc_debug('item ' .. data .. ' not cached yet ')
        return false
    else
        talc_debug('item ' .. data .. ' cached')
    end
end

function NeedFrames:addItem(data)
    local item = core.split("=", data)

    NeedFrameCountdown.timeToNeed = core.int(item[6])
    NeedFrameCountdown.C = NeedFrameCountdown.timeToNeed

    NeedFrames.execs = NeedFrames.execs + 1

    local index = core.int(item[2])
    local texture = item[3]
    local link = item[5]

    local buttons = 'mox'
    if item[7] then
        buttons = item[7]
    end

    local _, _, itemLink = core.find(link, "(item:%d+:%d+:%d+:%d+)");

    GameTooltip:SetHyperlink(itemLink)
    GameTooltip:Hide()

    local name, _, quality, _, _, _, _, itemSlot = GetItemInfo(itemLink)

    if not name or not quality then
        talc_debug(' name or quality not found for data :' .. data)
        talc_debug(' going to delay add item ')
        delayAddItem.data[index] = data
        delayAddItem:Show()
        return false
    end

    --hide xmog button for necks, rings, trinkets
    if itemSlot and core.find(buttons, 'x', 1, true) then
        if itemSlot == 'INVTYPE_NECK' or itemSlot == 'INVTYPE_FINGER' or itemSlot == 'INVTYPE_TRINKET' or itemSlot == 'INVTYPE_RELIC' then
            buttons = core.gsub(buttons, 'x', '')
        end
    end

    local reward1 = ''
    local reward2 = ''
    local reward3 = ''
    local reward4 = ''

    local _, class = UnitClass('player')
    class = core.lower(class)

    if name == 'Head of Nefarian' then
        reward1 = "\124cffa335ee\124Hitem:19383:0:0:0:0:0:0:0:0\124h[Master Dragonslayer's Medallion]\124h\124r"
        reward2 = "\124cffa335ee\124Hitem:19366:0:0:0:0:0:0:0:0\124h[Master Dragonslayer's Orb]\124h\124r"
        reward3 = "\124cffa335ee\124Hitem:19384:0:0:0:0:0:0:0:0\124h[Master Dragonslayer's Ring]\124h\124r"
    end

    --naxx tokens
    --bracer
    if name == "Desecrated Bindings" then
        if class == 'priest' then
            reward1 = "\124cffa335ee\124Hitem:22519:0:0:0:0:0:0:0:0\124h[Bindings of Faith]\124h\124r"
        end
        if class == 'mage' then
            reward1 = "\124cffa335ee\124Hitem:22503:0:0:0:0:0:0:0:0\124h[Frostfire Bindings]\124h\124r"
        end
        if class == 'warlock' then
            reward1 = "\124cffa335ee\124Hitem:22511:0:0:0:0:0:0:0:0\124h[Plagueheart Bindings]\124h\124r"
        end
    end
    if name == "Desecrated Wristguards" then
        if class == "paladin" then
            reward1 = "\124cffa335ee\124Hitem:22424:0:0:0:0:0:0:0:0\124h[Redemption Wristguards]\124h\124r"
        end
        if class == "hunter" then
            reward1 = "\124cffa335ee\124Hitem:22443:0:0:0:0:0:0:0:0\124h[Cryptstalker Wristguards]\124h\124r"
        end
        if class == "shaman" then
            reward1 = "\124cffa335ee\124Hitem:22471:0:0:0:0:0:0:0:0\124h[Earthshatter Wristguards]\124h\124r"
        end
        if class == "druid" then
            reward1 = "\124cffa335ee\124Hitem:22495:0:0:0:0:0:0:0:0\124h[Dreamwalker Wristguards]\124h\124r"
        end
    end
    if name == "Desecrated Bracers" then
        if class == 'warrior' then
            reward1 = "\124cffa335ee\124Hitem:22423:0:0:0:0:0:0:0:0\124h[Dreadnaught Bracers]\124h\124r";
        end
        if class == 'rogue' then
            reward1 = "\124cffa335ee\124Hitem:22483:0:0:0:0:0:0:0:0\124h[Bonescythe Bracers]\124h\124r";
        end
    end

    NeedFrames.execs = 0

    if not NeedFrames.itemFrames[index] then
        NeedFrames.itemFrames[index] = CreateFrame("Frame", "NeedFrame" .. index, TalcNeedFrame, "TalcNeedFrameItemTemplate")
    end

    _G["NeedFrame" .. index]:Hide()

    local backdrop = {
        bgFile = "Interface\\Addons\\Talc\\images\\need\\need_" .. quality,
        tile = false,
    };

    _G['NeedFrame' .. index .. 'BgImage']:SetBackdrop(backdrop)

    _G['NeedFrame' .. index .. 'QuestRewardsReward1']:Hide()
    _G['NeedFrame' .. index .. 'QuestRewardsReward2']:Hide()
    _G['NeedFrame' .. index .. 'QuestRewardsReward3']:Hide()
    _G['NeedFrame' .. index .. 'QuestRewardsReward4']:Hide()

    if reward1 ~= '' then
        if not SetQuestRewardLink(reward1, _G['NeedFrame' .. index .. 'QuestRewardsReward1']) then
            talc_debug(' quest reward 1 name or quality not found for data :' .. reward1)
            talc_debug(' going to delay add item ')
            delayAddItem.data[index] = data
            delayAddItem:Show()
            return false
        end
    end
    if reward2 ~= '' then
        if not SetQuestRewardLink(reward2,_G['NeedFrame' .. index .. 'QuestRewardsReward2']) then
            talc_debug(' quest reward 2 name or quality not found for data :' .. reward2)
            talc_debug(' going to delay add item ')
            delayAddItem.data[index] = data
            delayAddItem:Show()
            return false
        end
    end
    if reward3 ~= '' then
        if not SetQuestRewardLink(reward3,_G['NeedFrame' .. index .. 'QuestRewardsReward3']) then
            talc_debug(' quest reward 3 name or quality not found for data :' .. reward3)
            talc_debug(' going to delay add item ')
            delayAddItem.data[index] = data
            delayAddItem:Show()
            return false
        end
    end
    if reward4 ~= '' then
        if not SetQuestRewardLink(reward4,_G['NeedFrame' .. index .. 'QuestRewardsReward4']) then
            talc_debug(' quest reward 4 name or quality not found for data :' .. reward4)
            talc_debug(' going to delay add item ')
            delayAddItem.data[index] = data
            delayAddItem:Show()
            return false
        end
    end

    NeedFrames.itemFrames[index]:Show()
    NeedFrames.itemFrames[index]:SetAlpha(0)

    NeedFrames.itemFrames[index]:ClearAllPoints()
    if index < 0 then
        --test items
        NeedFrames.itemFrames[index]:SetPoint("TOP", TalcNeedFrame, "TOP", 0, 20 + (80 * index * -1))
    else
        NeedFrames.itemFrames[index]:SetPoint("TOP", TalcNeedFrame, "TOP", 0, 20 + (80 * index))
    end
    NeedFrames.itemFrames[index].link = link

    _G['NeedFrame' .. index .. 'ItemIcon']:SetNormalTexture(texture);
    _G['NeedFrame' .. index .. 'ItemIcon']:SetPushedTexture(texture);
    _G['NeedFrame' .. index .. 'ItemIconItemName']:SetText(link);

    _G['NeedFrame' .. index .. 'BISButton']:SetID(index);
    _G['NeedFrame' .. index .. 'MSUpgradeButton']:SetID(index);
    _G['NeedFrame' .. index .. 'OSButton']:SetID(index);
    _G['NeedFrame' .. index .. 'XMOGButton']:SetID(index);
    _G['NeedFrame' .. index .. 'PassButton']:SetID(index);

    local buttonIndex = -1

    _G['NeedFrame' .. index .. 'BISButton']:Hide()
    _G['NeedFrame' .. index .. 'MSUpgradeButton']:Hide()
    _G['NeedFrame' .. index .. 'OSButton']:Hide()
    _G['NeedFrame' .. index .. 'XMOGButton']:Hide()

    if core.find(buttons, 'b', 1, true) then
        buttonIndex = buttonIndex + 1
        _G['NeedFrame' .. index .. 'BISButton']:Show()
        _G['NeedFrame' .. index .. 'BISButton']:SetPoint('TOPLEFT', 318 + buttonIndex * 38, -40)
    end
    if core.find(buttons, 'm', 1, true) then
        buttonIndex = buttonIndex + 1
        _G['NeedFrame' .. index .. 'MSUpgradeButton']:Show()
        _G['NeedFrame' .. index .. 'MSUpgradeButton']:SetPoint('TOPLEFT', 318 + buttonIndex * 38, -40)
    end
    if core.find(buttons, 'o', 1, true) then
        buttonIndex = buttonIndex + 1
        _G['NeedFrame' .. index .. 'OSButton']:Show()
        _G['NeedFrame' .. index .. 'OSButton']:SetPoint('TOPLEFT', 318 + buttonIndex * 38, -40)
    end
    if core.find(buttons, 'x', 1, true) then
        buttonIndex = buttonIndex + 1
        _G['NeedFrame' .. index .. 'XMOGButton']:Show()
        _G['NeedFrame' .. index .. 'XMOGButton']:SetPoint('TOPLEFT', 318 + buttonIndex * 38, -40)
    end

    local r, g, b = GetItemQualityColor(quality)

    _G['NeedFrame' .. index .. 'TimeLeftBar']:SetBackdropColor(r, g, b, .76)

    core.addButtonOnEnterTooltip(_G['NeedFrame' .. index .. 'ItemIcon'], link)

    _G['NeedFrame' .. index .. 'QuestRewards']:Hide()
    if reward1 ~= '' then
        _G['NeedFrame' .. index .. 'QuestRewards']:Show()
    end

    fadeInFrame(index)
end

function PlayerNeedItemButton_OnClick(id, need)

    if need == 'autopass' then
        fadeOutFrame(id)
        return false
    end

    if id < 0 then
        fadeOutFrame(id)
        return
    end --test items

    local myItem1 = "0"
    local myItem2 = "0"
    local myItem3 = "0"

    local _, _, itemLink = core.find(NeedFrames.itemFrames[id].link, "(item:%d+:%d+:%d+:%d+)");
    local name, _, _, _, _, _, _, _, equip_slot = GetItemInfo(itemLink)
    if equip_slot then
        talc_debug('player need equip_slot frame : ' .. equip_slot)
    else
        talc_debug(' nu am gasit item slot wtffff : ' .. itemLink)

        core.asend(need .. "=" .. id .. "=" .. myItem1 .. "=" .. myItem2 .. "=" .. myItem3)
        _G['NewItemTooltip' .. id]:Hide()
        fadeOutFrame(id)

        return false
    end

    if need ~= 'pass' and need ~= 'autopass' then
        for i = 1, 19 do
            if GetInventoryItemLink('player', i) then
                local _, _, eqItemLink = core.find(GetInventoryItemLink('player', i), "(item:%d+:%d+:%d+:%d+)");
                local _, _, _, _, _, _, _, _, itemSlot = GetItemInfo(eqItemLink)

                if itemSlot then
                    if core.equipSlots[equip_slot] == core.equipSlots[itemSlot] then
                        if myItem1 == "0" then
                            myItem1 = eqItemLink
                        else
                            myItem2 = eqItemLink
                        end
                    end
                else
                    talc_debug(' !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! itemslot ')
                end
            end
        end

        --mh/oh fix
        if equip_slot == 'INVTYPE_WEAPON' or equip_slot == 'INVTYPE_SHIELD' or equip_slot == 'INVTYPE_WEAPONMAINHAND'
                or equip_slot == 'INVTYPE_WEAPONOFFHAND' or equip_slot == 'INVTYPE_HOLDABLE' or equip_slot == 'INVTYPE_2HWEAPON' then
            if GetInventoryItemLink('player', 16) then
                local _, _, eqItemLink = core.find(GetInventoryItemLink('player', 16), "(item:%d+:%d+:%d+:%d+)");
                myItem1 = eqItemLink
            end
            --ranged/relic weapon fix
            if GetInventoryItemLink('player', 17) then
                local _, _, eqItemLink = core.find(GetInventoryItemLink('player', 17), "(item:%d+:%d+:%d+:%d+)");
                myItem2 = eqItemLink
            end
        end

        --head
        if name == "Desecrated Circlet" or name == "Desecrated Headpiece" or name == "Desecrated Helmet" then
            if GetInventoryItemLink('player', 1) then
                local _, _, eqItemLink = string.find(GetInventoryItemLink('player', 1), "(item:%d+:%d+:%d+:%d+)");
                myItem1 = eqItemLink
            end
        end

        if name == "The Phylactery of Kel'Thuzad" then
            if GetInventoryItemLink('player', 13) then
                local _, _, eqItemLink = string.find(GetInventoryItemLink('player', 13), "(item:%d+:%d+:%d+:%d+)");
                myItem1 = eqItemLink
            end
            if GetInventoryItemLink('player', 14) then
                local _, _, eqItemLink = string.find(GetInventoryItemLink('player', 14), "(item:%d+:%d+:%d+:%d+)");
                myItem2 = eqItemLink
            end
        end

        -- end KT item
    end


    local gearscore = 0

    for i = 0, 19 do
        if GetInventoryItemLink("player", i) then
            local _, _, _, itemLevel = GetItemInfo(GetInventoryItemLink("player", i));
            gearscore = gearscore + itemLevel
        end
    end

    core.asend(need .. "=" .. id .. "=" .. myItem1 .. "=" .. myItem2 .. "=" .. myItem3 .. "=" .. gearscore)
    _G['NewItemTooltip' .. id]:Hide()
    fadeOutFrame(id)
end

function NeedFrame:SendGear(to)
    core.wsend("NORMAL", "sending=gear=start", to)
    for i = 1, 19 do
        if GetInventoryItemLink("player", i) then
            local _, iL, _, _, _, _, _, _, equip_slot = GetItemInfo(GetInventoryItemLink("player", i));
            local _, _, shortLink = core.find(iL, "(item:%d+:%d+:%d+:%d+)")
            local slotString = ''
            for slot, data in next, core.equipSlotsDetails do
                if (slot == equip_slot or slot == equip_slot .. "0" or slot == equip_slot .. "1") and i == data.id then
                    slotString = data.slot
                    break
                end
            end
            if slotString == '' then
                talc_debug("cant determine slot, send gear " .. equip_slot)
                return
            end
            core.wsend("NORMAL", "sending=gear=" .. shortLink .. ":" .. i .. ":" .. slotString, to)
        end
    end
    core.wsend("NORMAL", "sending=gear=end", to)
end

function fadeInFrame(id)
    fadeInAnimationFrame.ids[id] = true
    fadeInAnimationFrame:Show()
end

function fadeOutFrame(id)
    fadeOutAnimationFrame.ids[id] = true
    fadeOutAnimationFrame:Show()
end

fadeInAnimationFrame:SetScript("OnShow", function()
    this.startTime = GetTime()
end)

fadeOutAnimationFrame:SetScript("OnShow", function()
    this.startTime = GetTime()
end)

fadeInAnimationFrame:SetScript("OnUpdate", function()
    if GetTime() >= this.startTime + 0.03 then

        this.startTime = GetTime()

        local atLeastOne = false
        for id in next, fadeInAnimationFrame.ids do
            if fadeInAnimationFrame.ids[id] then
                atLeastOne = true
                local frame = _G["NeedFrame" .. id]
                if frame:GetAlpha() < 1 then
                    frame:SetAlpha(frame:GetAlpha() + 0.1)

                    _G["NeedFrame" .. id .. "GlowFrame"]:SetAlpha(1 - frame:GetAlpha())
                else
                    fadeInAnimationFrame.ids[id] = false
                    fadeInAnimationFrame.ids[id] = nil
                end
                return
            end
        end
        if not atLeastOne then
            fadeInAnimationFrame:Hide()
        end
    end
end)

fadeOutAnimationFrame:SetScript("OnUpdate", function()
    if GetTime() >= this.startTime + 0.03 then

        this.startTime = GetTime()

        local atLeastOne = false
        for id in next, fadeOutAnimationFrame.ids do
            if fadeOutAnimationFrame.ids[id] then
                atLeastOne = true
                local frame = _G["NeedFrame" .. id]
                if frame:GetAlpha() > 0 then
                    frame:SetAlpha(frame:GetAlpha() - 0.15)
                    _G["NeedFrame" .. id .. "GlowFrame"]:SetAlpha(frame:GetAlpha() - 0.15)
                else
                    fadeOutAnimationFrame.ids[id] = false
                    fadeOutAnimationFrame.ids[id] = nil
                    frame:Hide()
                end
            end
        end
        if not atLeastOne then
            fadeOutAnimationFrame:Hide()
        end
    end
end)

function NeedFrame:ResetVars()

    for index, _ in next, NeedFrames.itemFrames do
        NeedFrames.itemFrames[index]:Hide()
    end

    NewItemTooltip1:Hide()
    NewItemTooltip2:Hide()
    NewItemTooltip3:Hide()
    NewItemTooltip4:Hide()
    NewItemTooltip5:Hide()
    NewItemTooltip6:Hide()
    NewItemTooltip7:Hide()
    NewItemTooltip8:Hide()
    NewItemTooltip9:Hide()
    NewItemTooltip10:Hide()
    NewItemTooltip11:Hide()
    NewItemTooltip12:Hide()
    NewItemTooltip13:Hide()
    NewItemTooltip14:Hide()
    NewItemTooltip15:Hide()

    TalcNeedFrame:Hide()

    NeedFrameCountdown:Hide()
    NeedFrameCountdown.T = 1
    NeedFrame.numItems = 0

end

-- comms

function NeedFrameComs:handleSync(arg1, msg, arg3, sender)

    if core.find(msg, 'withAddonNF=', 1, true) then
        local i = core.split("=", msg)
        if i[2] == core.me then
            --i[2] = who requested the who
            if i[4] then
                local verColor = ""
                if core.ver(i[4]) == core.ver(core.addonVer) then
                    verColor = core.classColors['hunter'].colorStr
                end
                if core.ver(i[4]) < core.ver(core.addonVer) then
                    verColor = '|cffff1111'
                end
                if (core.ver(i[4]) + 1 == core.ver(core.addonVer)) then
                    verColor = '|cffff8810'
                end

                if core.strlen(i[4]) < 7 then
                    i[4] = '0.' .. i[4]
                end

                NeedFrame.withAddon[sender]['v'] = verColor .. i[4]

                NeedFrame.withAddonCount = NeedFrame.withAddonCount + 1
                NeedFrame.withoutAddonCount = NeedFrame.withoutAddonCount - 1
                updateWithAddon()
            end
        end
        return
    end
    if core.find(msg, 'needframe=', 1, true) then
        local command = core.split('=', msg)
        if command[2] == "whoNF" then
            core.asend("withAddonNF=" .. sender .. "=" .. core.me .. "=" .. core.addonVer)
        end
        return
    end
    if core.find(msg, 'sendgear=', 1, true) then
        NeedFrame:SendGear(sender)
        return
    end
    if core.isRL(sender) then
        if core.find(msg, 'loot=', 1, true) then
            NeedFrame.numItems = NeedFrame.numItems + 1
            NeedFrames:addItem(msg)
            if not TalcNeedFrame:IsVisible() then
                TalcNeedFrame:Show()
                NeedFrameCountdown:Show()
            end
            return
        end

        if core.find(msg, 'preSend=', 1, true) then
            NeedFrames.cacheItem(msg)
            return
        end

        if core.find(msg, 'doneSending=', 1, true) then
            local nrItems = core.split('=', msg)
            if not nrItems[2] or not nrItems[3] then
                talc_debug('wrong doneSending syntax')
                talc_debug(msg)
                return
            end

            core.asend("received=" .. NeedFrame.numItems .. "=items")
            return
        end

        if core.find(msg, 'needframe=', 1, true) then
            local command = core.split('=', msg)
            if command[2] == "reset" then
                NeedFrame.ResetVars()
            end
            return
        end
    end
end

function NeedFrame:ShowAnchor()
    TalcNeedFrame:Show()
    TalcNeedFrame:EnableMouse(true)
    TalcNeedFrameTitle:Show()
    TalcNeedFrameTestPlacement:Show()
    TalcNeedFrameClosePlacement:Show()
    TalcNeedFrameBackground:Show()
    TalcNeedFrameScaleDown:Show()
    TalcNeedFrameScaleUp:Show()
    TalcNeedFrameScaleText:Show()
end

function NeedFrame:HideAnchor()
    TalcNeedFrame:Hide()
    TalcNeedFrame:EnableMouse(false)
    TalcNeedFrameTitle:Hide()
    TalcNeedFrameTestPlacement:Hide()
    TalcNeedFrameClosePlacement:Hide()
    TalcNeedFrameBackground:Hide()
    TalcNeedFrameScaleDown:Hide()
    TalcNeedFrameScaleUp:Hide()
    TalcNeedFrameScaleText:Hide()
end

function NeedFrame_Scale(dir)
    if dir == 'up' then
        if TalcNeedFrame:GetScale() < 1.4 then
            TalcNeedFrame:SetScale(TalcNeedFrame:GetScale() + 0.05)
        end
    end
    if dir == 'down' then
        if TalcNeedFrame:GetScale() > 0.4 then
            TalcNeedFrame:SetScale(TalcNeedFrame:GetScale() - 0.05)
        end
    end

    db['NEED_SCALE'] = TalcNeedFrame:GetScale()

    talc_print('Frame re-scaled. Type |cfffff569/talc |cff69ccf0need resetscale |rif the frame is offscreen')
end

function need_frame_close()
    talc_print('Anchor window closed. Type |cfffff569/talc |cff69ccf0need |rto show the Anchor window.')
    NeedFrame:HideAnchor()
end

function Talc_NeedFrame_Test()

    local linkStrings = {
        '\124cffa335ee\124Hitem:22369:0:0:0:0:0:0:0:0\124h[Desecrated Bindings]\124h\124r',
        '\124cffa335ee\124Hitem:22362:0:0:0:0:0:0:0:0\124h[Desecrated Wristguards]\124h\124r',
        '\124cffa335ee\124Hitem:22355:0:0:0:0:0:0:0:0\124h[Desecrated Bracers]\124h\124r',
        '\124cffa335ee\124Hitem:21221:0:0:0:0:0:0:0:0\124h[Eye of C\'Thun]\124h\124r',
        '\124cffa335ee\124Hitem:19347:0:0:0:0:0:0:0:0\124h[Claw of Chromaggus]\124h\124r',
        '\124cffa335ee\124Hitem:19375:0:0:0:0:0:0:0:0\124h[Mish\'undare, Circlet of the Mind Flayer]\124h\124r',
        '\124cffff8000\124Hitem:17204:0:0:0:0:0:0:0:0\124h[Eye of Sulfuras]\124h\124r'
    }

    for i = 1, 7 do
        local _, _, itemLink = core.find(linkStrings[i], "(item:%d+:%d+:%d+:%d+)");
        local name, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)

        if name and tex then
            NeedFrames:addItem('loot=-' .. i .. '=' .. tex .. '=' .. name .. '=' .. linkStrings[i] .. '=60') --todo add button options
            if not TalcNeedFrame:IsVisible() then
                TalcNeedFrame:Show()
                NeedFrameCountdown:Show()
            end
        else
            talc_print('Caching items... please try again.')
            GameTooltip:SetHyperlink(itemLink)
            GameTooltip:Hide()
        end
    end
end

NeedFrame.withAddon = {}
NeedFrame.withAddonCount = 0
NeedFrame.withoutAddonCount = 0
NeedFrame.olderAddonCount = 0

NeedFrame.withCloak = 0
NeedFrame.withoutCloak = 0
NeedFrame.playersWithoutCloak = {}



function queryWho()
    NeedFrame.withAddon = {}
    NeedFrame.withAddonCount = 0
    NeedFrame.withoutAddonCount = 0

    TalcNeedFrameListTitle:SetText('NeedFrame v' .. core.addonVer)

    TalcNeedFrameList:Show()

    core.bsend("NORMAL", "needframe=whoNF=" .. core.addonVer)

    for i = 0, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) then
            local n, _, _, _, _, _, z = GetRaidRosterInfo(i);
            local _, class = UnitClass('raid' .. i)

            NeedFrame.withAddon[n] = {
                ['class'] = core.lower(class),
                ['v'] = '|cff888888   -   '
            }
            if z == 'Offline' then
                NeedFrame.withAddon[n]['v'] = '|cffff0000offline'
            else
                NeedFrame.withoutAddonCount = NeedFrame.withoutAddonCount + 1
            end
        end
    end

    updateWithAddon()
end

function announceWithoutAddon()
    local withoutAddon = ''
    for n, d in NeedFrame.withAddon do
        if core.find(d['v'], '-', 1, true) then
            withoutAddon = withoutAddon .. n .. ', '
        end
    end
    if withoutAddon ~= '' then
        SendChatMessage('Players without TALC addon: ' .. withoutAddon, "RAID")
        SendChatMessage('Please check discord #annoucements channel or go to https://github.com/CosminPOP/Talc (latest version v' .. core.addonVer .. ')', "RAID")
    end
end

function announceOlderAddon()
    local olderAddon = ''
    for n, d in NeedFrame.withAddon do
        if not core.find(d['v'], 'offline', 1, true) and not core.find(d['v'], '-', 1, true) then
            if core.ver(core.sub(d['v'], 11, 17)) < core.ver(core.addonVer) then
                olderAddon = olderAddon .. n .. ', '
            end
        end
    end
    if olderAddon ~= '' then
        SendChatMessage('Players with older versions of TALC addon: ' .. olderAddon, "RAID")
        SendChatMessage('Please check discord #annoucements channel or go to https://github.com/CosminPOP/Talc (latest version v' .. core.addonVer .. ')', "RAID")
    end
end

function hideNeedFrameList()
    NeedFrameList:Hide()
end

-- utils

function updateWithAddon()
    local rosterList = ''
    local i = 0
    for n, data in next, NeedFrame.withAddon do
        i = i + 1
        rosterList = rosterList .. core.classColors[data['class']].c .. n .. core.rep(' ', 12 - core.len(n)) .. ' ' .. data['v'] .. ' |cff888888| '
        if i == 3 then
            rosterList = rosterList .. '\n'
            i = 0
        end
    end
    TalcNeedFrameListText:SetText(rosterList)
    TalcNeedFrameListWith:SetText('With addon: ' .. NeedFrame.withAddonCount)
    if NeedFrame.withoutAddonCount == 0 then
        TalcNeedFrameListAnnounceWithoutAddon:SetText('Notify without ' .. NeedFrame.withoutAddonCount)
        TalcNeedFrameListAnnounceWithoutAddon:Disable()
    else
        TalcNeedFrameListAnnounceWithoutAddon:SetText('Notify without ' .. NeedFrame.withoutAddonCount)
        TalcNeedFrameListAnnounceWithoutAddon:Enable()
    end
end

--function addOnEnterTooltipNeedFrame(frame, itemLink)
--    local ex = string.split(itemLink, "|")
--
--    if not ex[3] then
--        return
--    end
--
--    frame:SetScript("OnEnter", function(self)
--        NeedFrameTooltip:SetOwner(this, "ANCHOR_RIGHT", 0, 0);
--        NeedFrameTooltip:SetHyperlink(string.sub(ex[3], 2, string.len(ex[3])));
--        NeedFrameTooltip:Show();
--    end)
--    frame:SetScript("OnClick", function(self)
--        if IsControlKeyDown() then
--            DressUpItemLink(itemLink)
--        end
--    end)
--    frame:SetScript("OnLeave", function(self)
--        NeedFrameTooltip:Hide();
--    end)
--end

function SetQuestRewardLink(reward, frame)

    local _, _, itemLink = core.find(reward, "(item:%d+:%d+:%d+:%d+)");
    local _, link, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)
    if link then
        core.addButtonOnEnterTooltip(frame, link)
        frame:SetNormalTexture(tex)
        frame:SetPushedTexture(tex)
        frame:Show()
        return true
    else
        GameTooltip:SetHyperlink(itemLink)
        GameTooltip:Hide()
        return false
    end
end

