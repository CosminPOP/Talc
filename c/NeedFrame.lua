local db, core, tokenRewards
local _G = _G
NeedFrame = CreateFrame("Frame")

NeedFrame.numItems = 0
NeedFrame.itemFrames = {}
NeedFrame.execs = 0

NeedFrame.withAddon = {}
NeedFrame.withAddonCount = 0
NeedFrame.withoutAddonCount = 0
NeedFrame.olderAddonCount = 0

function NeedFrame:init()
    core = TALC
    db = TALC_DB
    tokenRewards = TALC_TOKENS

    --self:ShowAnchor() --dev
    self:HideAnchor() --dev

    TalcNeedFrame:SetScale(db['NEED_SCALE'])

    self:ResetVars()

    talc_print('TALC NeedFrame Loaded. Type |cfffff569/talc |cff69ccf0need |cffffffffto show the Anchor window.')
end

function NeedFrame:cacheItem(data)
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

function NeedFrame:addItem(data)
    local item = core.split("=", data)

    self.countdown.timeToNeed = core.int(item[6])
    self.countdown.C = self.countdown.timeToNeed

    self.execs = self.execs + 1

    local index = core.int(item[2])
    local texture = item[3]
    local link = item[5]

    local buttons = 'mo'
    if item[7] then
        buttons = item[7]
    end

    local _, _, itemLink = core.find(link, "(item:%d+:%d+:%d+:%d+)");
    local itemID = core.int(core.split(':', itemLink)[2])

    local name, _, quality, il, _, _, _, itemSlot = GetItemInfo(itemLink)

    if not name or not quality then
        talc_debug(' name or quality not found for data :' .. data)
        talc_debug(' going to delay add item ')
        self.delayAddItem.data[index] = data
        self.delayAddItem:Show()
        return false
    end

    --hide xmog button for necks, rings, trinkets
    if itemSlot and core.find(buttons, 'x', 1, true) then
        if itemSlot == 'INVTYPE_NECK' or itemSlot == 'INVTYPE_FINGER' or itemSlot == 'INVTYPE_TRINKET' or itemSlot == 'INVTYPE_RELIC' then
            buttons = core.gsub(buttons, 'x', '')
        end
    end

    self.execs = 0

    if not self.itemFrames[index] then
        self.itemFrames[index] = CreateFrame("Frame", "NeedFrame" .. index, TalcNeedFrame, "TalcNeedFrameItemTemplate")
    end

    _G["NeedFrame" .. index]:Hide()

    local backdrop = {
        bgFile = "Interface\\Addons\\Talc\\images\\need\\need_" .. quality,
        tile = false,
    }

    _G['NeedFrame' .. index .. 'BgImage']:SetBackdrop(backdrop)

    _G['NeedFrame' .. index .. 'QuestRewardsReward1']:Hide()
    _G['NeedFrame' .. index .. 'QuestRewardsReward2']:Hide()
    _G['NeedFrame' .. index .. 'QuestRewardsReward3']:Hide()
    _G['NeedFrame' .. index .. 'QuestRewardsReward4']:Hide()

    self.itemFrames[index]:Show()
    self.itemFrames[index]:SetAlpha(0)

    self.itemFrames[index]:ClearAllPoints()
    if index < 0 then
        --test items
        self.itemFrames[index]:SetPoint("TOP", TalcNeedFrame, "TOP", 0, 20 + (80 * index * -1))
    else
        self.itemFrames[index]:SetPoint("TOP", TalcNeedFrame, "TOP", 0, 20 + (80 * index))
    end
    self.itemFrames[index].link = link

    _G['NeedFrame' .. index .. 'ItemIcon']:SetNormalTexture(texture);
    _G['NeedFrame' .. index .. 'ItemIcon']:SetPushedTexture(texture);
    _G['NeedFrame' .. index .. 'ItemIconItemName']:SetText(link);
    _G['NeedFrame' .. index .. 'ItemIconItemLevel']:SetText(ITEM_QUALITY_COLORS[quality].hex .. il);

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

    local m = 38
    if core.len(buttons) == 2 then
        m = 38 * 2
    end

    if core.len(buttons) == 3 then
        m = 38 + 38 / 3
    end

    if core.find(buttons, 'b', 1, true) then
        buttonIndex = buttonIndex + 1
        _G['NeedFrame' .. index .. 'BISButton']:Show()
        _G['NeedFrame' .. index .. 'BISButton']:SetPoint('TOPLEFT', 318 - 64 + buttonIndex * m, -40)
    end
    if core.find(buttons, 'm', 1, true) then
        buttonIndex = buttonIndex + 1
        _G['NeedFrame' .. index .. 'MSUpgradeButton']:Show()
        _G['NeedFrame' .. index .. 'MSUpgradeButton']:SetPoint('TOPLEFT', 318 - 64 + buttonIndex * m, -40)
    end
    if core.find(buttons, 'o', 1, true) then
        buttonIndex = buttonIndex + 1
        _G['NeedFrame' .. index .. 'OSButton']:Show()
        _G['NeedFrame' .. index .. 'OSButton']:SetPoint('TOPLEFT', 318 - 64 + buttonIndex * m, -40)
    end
    if core.find(buttons, 'x', 1, true) then
        buttonIndex = buttonIndex + 1
        _G['NeedFrame' .. index .. 'XMOGButton']:Show()
        _G['NeedFrame' .. index .. 'XMOGButton']:SetPoint('TOPLEFT', 318 - 64 + buttonIndex * m, -40)
    end

    buttonIndex = buttonIndex + 1
    _G['NeedFrame' .. index .. 'PassButton']:Show()
    _G['NeedFrame' .. index .. 'PassButton']:SetPoint('TOPLEFT', 318 - 64 + buttonIndex * m, -40)

    local r, g, b = GetItemQualityColor(quality)

    _G['NeedFrame' .. index .. 'TimeLeftBar']:SetBackdropColor(r, g, b, .76)

    core.addButtonOnEnterTooltip(_G['NeedFrame' .. index .. 'ItemIcon'], link, nil, true)

    _G['NeedFrame' .. index .. 'QuestRewards']:Hide()

    local _, class = UnitClass('player')
    class = core.lower(class)

    local classes = ""
    local forMe = false

    GameTooltip:SetOwner(TalcNeedFrame, "ANCHOR_NONE");
    GameTooltip:SetHyperlink(itemLink)
    for i = 1, 20 do
        if _G["GameTooltipTextLeft" .. i] and _G["GameTooltipTextLeft" .. i]:GetText() then
            if core.find(_G["GameTooltipTextLeft" .. i]:GetText(), "Classes:", 1, true) then
                classes = _G["GameTooltipTextLeft" .. i]:GetText()
                print(classes)
                if core.find(core.lower(classes), class, 1, true) then
                    forMe = true
                end
                break
            end
        end
    end
    GameTooltip:Hide()

    if not forMe and classes ~= "" then
        SetDesaturation(_G['NeedFrame' .. index .. 'ItemIcon']:GetNormalTexture(), 1)
    end

    local hasRewards = false
    if tokenRewards[itemID] and (core.find(core.lower(classes), class, 1, true) or classes == "") then
        hasRewards = true
    end

    if hasRewards and tokenRewards[itemID].rewards then
        -- only show my rewards
        local hasRewardsForMe = false
        local foundClasses = false

        GameTooltip:SetOwner(TalcNeedFrame, "ANCHOR_NONE");
        GameTooltip:SetHyperlink(itemLink)

        for i = 1, 5 do
            if _G["GameTooltipTextLeft" .. i] and _G["GameTooltipTextLeft" .. i]:GetText() then
                local itemText = _G["GameTooltipTextLeft" .. i]:GetText()
                if core.find(itemText, "Classes:", 1, true) then
                    foundClasses = true
                    if core.find(core.lower(itemText), class, 1, true) then
                        hasRewardsForMe = true
                        break
                    end
                end
            end
        end

        if hasRewardsForMe or not foundClasses then
            _G['NeedFrame' .. index .. 'QuestRewards']:Show()
            local rewardSpot = 0
            for i, rewardID in next, tokenRewards[itemID].rewards do

                if i < 5 then

                    local set, il, frame = NeedFrame:SetQuestRewardLink(rewardID, _G['NeedFrame' .. index .. 'QuestRewardsReward' .. i])

                    if not set then
                        talc_debug(' quest reward ' .. i .. ' name or quality not found for data :' .. rewardID)
                        talc_debug(' going to delay add item ')
                        self.delayAddItem.data[index] = data
                        self.delayAddItem:Show()
                        return false
                    end

                    GameTooltip:SetOwner(TalcNeedFrame, "ANCHOR_NONE");
                    GameTooltip:SetHyperlink(il)

                    local showReward = false

                    if foundClasses then
                        for j = 1, 20 do
                            if _G["GameTooltipTextLeft" .. j] and _G["GameTooltipTextLeft" .. j]:GetText() then
                                local itemText = _G["GameTooltipTextLeft" .. j]:GetText()
                                if core.find(itemText, "Classes:", 1, true) then
                                    if core.find(core.lower(itemText), class, 1, true) then
                                        showReward = true
                                        rewardSpot = rewardSpot + 1
                                        frame:SetPoint("TOPLEFT", 20 + 23 * (rewardSpot - 1) , -32)
                                        break
                                    end
                                end
                            end
                        end
                    else
                        showReward = true
                    end

                    if not showReward then
                        _G['NeedFrame' .. index .. 'QuestRewardsReward' .. i]:Hide()
                    end

                end
            end
        end

        GameTooltip:Hide()
    end

    self:fadeInFrame(index)
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

function NeedFrame:fadeInFrame(id)
    self.fadeInAnimationFrame.ids[id] = true
    self.fadeInAnimationFrame:Show()
end

function NeedFrame:fadeOutFrame(id, need)
    self.fadeOutAnimationFrame.ids[id] = true
    self.fadeOutAnimationFrame.need[id] = need
    self.fadeOutAnimationFrame:Show()
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

function NeedFrame:ResetVars()

    self:HideAnchor()

    for index, _ in next, self.itemFrames do
        self.itemFrames[index]:Hide()
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

    --TalcNeedFrame:Hide() --dev

    self.countdown:Hide()
    self.countdown.T = 1
    self.numItems = 0

end

function NeedFrame:handleSync(arg1, msg, arg3, sender)

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

                self.withAddon[sender]['v'] = verColor .. i[4]

                self.withAddonCount = self.withAddonCount + 1
                self.withoutAddonCount = self.withoutAddonCount - 1
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
    end
    if core.find(msg, 'sendgear=', 1, true) then
        self:SendGear(sender)
        return
    end
    if core.isRL(sender) then
        if core.find(msg, 'loot=', 1, true) then
            self.numItems = self.numItems + 1
            self:addItem(msg)
            if not TalcNeedFrame:IsVisible() then
                TalcNeedFrame:Show()
                self.countdown:Show()
            end
            return
        end

        if core.find(msg, 'preSend=', 1, true) then
            self:cacheItem(msg)
            return
        end

        if core.find(msg, 'doneSending=', 1, true) then
            local nrItems = core.split('=', msg)
            if not nrItems[2] or not nrItems[3] then
                talc_debug('wrong doneSending syntax')
                talc_debug(msg)
                return
            end

            core.asend("received=" .. self.numItems .. "=items")
            return
        end

        if core.find(msg, 'needframe=', 1, true) then
            local command = core.split('=', msg)
            if command[2] == "reset" then
                self:ResetVars()
            end
            return
        end
    end
end

function NeedFrame:ScaleWindow(dir)
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

function NeedFrame:Close()
    talc_print('Anchor window closed. Type |cfffff569/talc |cff69ccf0need |rto show the Anchor window.')
    self:HideAnchor()
end

function NeedFrame:SetQuestRewardLink(id, frame)

    local _, link, _, _, _, _, _, _, _, tex = GetItemInfo(id)
    if link then
        local _, _, itemLink = core.find(link, "(item:%d+:%d+:%d+:%d+)");
        core.addButtonOnEnterTooltip(frame, link)
        frame:SetNormalTexture(tex)
        frame:SetPushedTexture(tex)
        frame:Show()
        return true, itemLink, frame
    else
        GameTooltip:SetHyperlink(id)
        GameTooltip:Hide()
        return false, false, frame
    end
end

function NeedFrame:NeedClick(id, need)

    if need == 'autopass' then
        self:fadeOutFrame(id)
        return false
    end

    if id < 0 then
        self:fadeOutFrame(id)
        return
    end --test items

    local gearscore = 0
    for i = 0, 19 do
        if GetInventoryItemLink("player", i) then
            local _, _, _, itemLevel = GetItemInfo(GetInventoryItemLink("player", i));
            gearscore = gearscore + itemLevel
        end
    end

    local myItem1 = "0"
    local myItem2 = "0"
    local myItem3 = "0"

    local _, _, itemLink = core.find(self.itemFrames[id].link, "(item:%d+:%d+:%d+:%d+)");
    local itemID = core.int(core.split(':', itemLink)[2])
    local name, _, _, _, _, _, _, _, equip_slot = GetItemInfo(itemLink)
    if equip_slot then
        --talc_debug('player need equip_slot frame : ' .. equip_slot) --todo check this
    else
        talc_debug(' nu am gasit item slot wtffff : ' .. itemLink)

        core.asend(need .. "=" .. id .. "=" .. myItem1 .. "=" .. myItem2 .. "=" .. myItem3 .. "= " .. gearscore)
        _G['NewItemTooltip' .. id]:Hide()
        NeedFrame:fadeOutFrame(id, need)

        return
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
                    talc_debug('cant get inventory item ' .. i)
                end
            end
        end

        -- token fix
        if tokenRewards[itemID] and tokenRewards[itemID].rewards then
            local _, _, _, _, _, _, _, _, r_equip_slot = GetItemInfo(tokenRewards[itemID].rewards[1])
            local _, _, eqItemLink = core.find(GetInventoryItemLink('player', core.equipSlotsDetails[r_equip_slot].id), "(item:%d+:%d+:%d+:%d+)");
            myItem1 = eqItemLink
        end

        --mh/oh fix
        if equip_slot == 'INVTYPE_WEAPON' or equip_slot == 'INVTYPE_SHIELD' or equip_slot == 'INVTYPE_WEAPONMAINHAND'
                or equip_slot == 'INVTYPE_WEAPONOFFHAND' or equip_slot == 'INVTYPE_HOLDABLE' or equip_slot == 'INVTYPE_2HWEAPON' then
            --mh
            if GetInventoryItemLink('player', 16) then
                local _, _, eqItemLink = core.find(GetInventoryItemLink('player', 16), "(item:%d+:%d+:%d+:%d+)");
                myItem1 = eqItemLink
            end
            --oh
            if GetInventoryItemLink('player', 17) then
                local _, _, eqItemLink = core.find(GetInventoryItemLink('player', 17), "(item:%d+:%d+:%d+:%d+)");
                myItem2 = eqItemLink
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
    end

    core.asend(need .. "=" .. id .. "=" .. myItem1 .. "=" .. myItem2 .. "=" .. myItem3 .. "=" .. gearscore)
    _G['NewItemTooltip' .. id]:Hide()
    self:fadeOutFrame(id, need)
end

NeedFrame.countdown = CreateFrame("Frame")
NeedFrame.countdown:Hide()
NeedFrame.countdown.timeToNeed = 30 --default, will be gotten via addonMessage
NeedFrame.countdown.T = 1
NeedFrame.countdown.C = 30

NeedFrame.countdown:SetScript("OnUpdate", function()
    local plus = 0.03
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        if (NeedFrame.countdown.T ~= NeedFrame.countdown.timeToNeed + plus) then

            for index in next, NeedFrame.itemFrames do
                if core.floor(NeedFrame.countdown.C - NeedFrame.countdown.T + plus) < 0 then
                    _G['NeedFrame' .. index .. 'TimeLeftBarText']:SetText("CLOSED")
                else
                    _G['NeedFrame' .. index .. 'TimeLeftBarText']:SetText(core.ceil(NeedFrame.countdown.C - NeedFrame.countdown.T + plus) .. "s")
                end

                _G['NeedFrame' .. index .. 'TimeLeftBar']:SetWidth((NeedFrame.countdown.C - NeedFrame.countdown.T + plus) * 190 / NeedFrame.countdown.timeToNeed)
            end
        end
        NeedFrame.countdown:Hide()
        if (NeedFrame.countdown.T < NeedFrame.countdown.C + plus) then
            --still tick
            NeedFrame.countdown.T = NeedFrame.countdown.T + plus
            NeedFrame.countdown:Show()
        elseif (NeedFrame.countdown.T > NeedFrame.countdown.timeToNeed + plus) then

            -- hide frames and send auto pass
            for index in next, NeedFrame.itemFrames do
                if NeedFrame.itemFrames[index]:GetAlpha() == 1 then
                    NeedFrame:NeedClick(index, 'autopass')
                end
            end
            -- end hide frames

            NeedFrame.countdown:Hide()
            NeedFrame.countdown.T = 1

        end
    end
end)

NeedFrame.fadeInAnimationFrame = CreateFrame("Frame")
NeedFrame.fadeInAnimationFrame:Hide()
NeedFrame.fadeInAnimationFrame.ids = {}
NeedFrame.fadeInAnimationFrame:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
NeedFrame.fadeInAnimationFrame:SetScript("OnUpdate", function()
    if GetTime() >= this.startTime + 0.03 then

        this.startTime = GetTime()

        local atLeastOne = false
        for id in next, this.ids do
            if this.ids[id] then
                atLeastOne = true
                local frame = _G["NeedFrame" .. id]
                if frame:GetAlpha() < 1 then
                    frame:SetAlpha(frame:GetAlpha() + 0.1)

                    _G["NeedFrame" .. id .. "GlowFrame"]:SetAlpha(1 - frame:GetAlpha())
                else
                    this.ids[id] = false
                    this.ids[id] = nil
                end
                return
            end
        end
        if not atLeastOne then
            this:Hide()
        end
    end
end)

NeedFrame.fadeOutAnimationFrame = CreateFrame("Frame")
NeedFrame.fadeOutAnimationFrame:Hide()
NeedFrame.fadeOutAnimationFrame.ids = {}
NeedFrame.fadeOutAnimationFrame.need = {}
NeedFrame.fadeOutAnimationFrame:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
NeedFrame.fadeOutAnimationFrame:SetScript("OnUpdate", function()
    if GetTime() >= this.startTime + 0.03 then

        this.startTime = GetTime()

        local atLeastOne = false
        for id in next, this.ids do
            if this.ids[id] then
                atLeastOne = true
                local frame = _G["NeedFrame" .. id]
                if frame:GetAlpha() > 0 then
                    frame:SetAlpha(frame:GetAlpha() - 0.15)
                    --_G["NeedFrame" .. id .. "GlowFrame"]:SetAlpha(frame:GetAlpha() - 0.15)
                else
                    this.ids[id] = false
                    this.ids[id] = nil
                    frame:Hide()
                end
            end
        end
        if not atLeastOne then
            this:Hide()
        end
    end
end)

NeedFrame.delayAddItem = CreateFrame("Frame")
NeedFrame.delayAddItem:Hide()
NeedFrame.delayAddItem.data = {}

NeedFrame.delayAddItem:SetScript("OnShow", function()
    this.startTime = GetTime();
end)
NeedFrame.delayAddItem:SetScript("OnUpdate", function()
    local plus = 0.5
    local gt = GetTime() * 1000 --22.123 -> 22123
    local st = (this.startTime + plus) * 1000 -- (22.123 + 0.1) * 1000 =  22.223 * 1000 = 22223
    if gt >= st then

        local atLeastOne = false
        for id, data in next, NeedFrame.delayAddItem.data do
            if NeedFrame.delayAddItem.data[id] then
                atLeastOne = true
                talc_debug('delay add item on update for item id ' .. id .. ' data:[' .. data)
                NeedFrame.delayAddItem.data[id] = nil
                NeedFrame:addItem(data)
            end
        end

        if not atLeastOne then
            NeedFrame.delayAddItem:Hide()
        end
    end
end)
NeedFrame.countdown:SetScript("OnShow", function()
    this.startTime = GetTime();
end)



function Talc_NeedFrame_Test()


    local linkStrings = {
        '\124cffa335ee\124Hitem:40610:0:0:0:0:0:0:0:0\124h[Chestguard of the Lost Conqueror]\124h\124r',
        '\124cff0070dd\124Hitem:10399:0:0:0:0:0:0:0:0\124h[Blackened Defias Armor]\124h\124r',
        '\124cff1eff00\124Hitem:10402:0:0:0:0:0:0:0:0\124h[Blackened Defias Boots]\124h\124r',
        '\124cffa335ee\124Hitem:21221:0:0:0:0:0:0:0:0\124h[Eye of C\'Thun]\124h\124r',
        '\124cffa335ee\124Hitem:40611:0:0:0:0:0:0:0:0\124h[Chestguard of the Lost Protector]\124h\124r',
        '\124cffa335ee\124Hitem:44569:0:0:0:0:0:0:0:0\124h[Key to the Focusing Iris]\124h\124r',
        '\124cffff8000\124Hitem:17204:0:0:0:0:0:0:0:0\124h[Eye of Sulfuras]\124h\124r'
    }

    for i = 1, 7 do
        local _, _, itemLink = core.find(linkStrings[i], "(item:%d+:%d+:%d+:%d+)");
        local name, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)

        if name and tex then
            NeedFrame:addItem('loot=-' .. i .. '=' .. tex .. '=' .. name .. '=' .. linkStrings[i] .. '=60') --todo add button options
            if not TalcNeedFrame:IsVisible() then
                TalcNeedFrame:Show()
                NeedFrame.countdown:Show()
            end
        else
            talc_print('Caching items... please try again.')
            GameTooltip:SetHyperlink(itemLink)
            GameTooltip:Hide()
        end
    end
end

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
