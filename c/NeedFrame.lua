local db, core, tokenRewards
local _G = _G
NeedFrame = CreateFrame("Frame")
NeedFrame.numItems = 0
NeedFrame.itemFrames = {}

function NeedFrame:init()
    core = TALC
    db = TALC_DB
    tokenRewards = TALC_TOKENS

    TalcNeedFrame:SetScale(db['NEED_SCALE'])

    self:ResetVars()

    talc_print('NeedFrame Loaded. Type |cfffff569/talc |cff69ccf0need |cffffffffto show the Anchor window.')
end

function NeedFrame:addItem(data)
    local item = core.split("=", data)

    self.countdown.timeToNeed = db['VOTE_TTN']
    self.countdown.C = self.countdown.timeToNeed

    local index = core.int(item[2])
    local texture = item[3]
    --local name = item[4]
    local link = item[5]

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

    if not self.itemFrames[index] then
        self.itemFrames[index] = CreateFrame("Frame", "NeedFrame" .. index, TalcNeedFrame, "TalcNeedFrameItemTemplate")
    end
    local frame = "NeedFrame" .. index

    _G[frame]:Show()
    _G[frame .. 'BISButton']:SetID(index);
    _G[frame .. 'BISButton']:Hide()
    _G[frame .. 'MSUpgradeButton']:SetID(index);
    _G[frame .. 'MSUpgradeButton']:Hide()
    _G[frame .. 'OSButton']:SetID(index);
    _G[frame .. 'OSButton']:Hide()
    _G[frame .. 'XMOGButton']:SetID(index);
    _G[frame .. 'XMOGButton']:Hide()
    _G[frame .. 'PassButton']:SetID(index);
    _G[frame .. 'PassButton']:Show()

    if db['VOTE_CONFIG']['NeedButtons']['BIS'] then
        _G[frame .. 'BISButton']:Show()
    end
    if db['VOTE_CONFIG']['NeedButtons']['MS'] then
        _G[frame .. 'MSUpgradeButton']:Show()
    end
    if db['VOTE_CONFIG']['NeedButtons']['OS'] then
        _G[frame .. 'OSButton']:Show()
    end
    if db['VOTE_CONFIG']['NeedButtons']['XMOG'] then
        _G[frame .. 'XMOGButton']:Show()
    end

    --hide xmog button for necks, rings, trinkets
    if itemSlot and db['VOTE_CONFIG']['NeedButtons']['XMOG'] then
        if itemSlot == 'INVTYPE_NECK' or itemSlot == 'INVTYPE_FINGER' or itemSlot == 'INVTYPE_TRINKET' or itemSlot == 'INVTYPE_RELIC' then
            _G[frame .. 'XMOGButton']:Hide()
        end
    end

    _G[frame .. 'BgImage']:SetBackdrop({
        bgFile = "Interface\\Addons\\Talc\\images\\need\\need_" .. quality,
        tile = false,
    })

    _G[frame]:SetAlpha(0)

    _G[frame]:ClearAllPoints()
    if index < 0 then
        --test items
        _G[frame]:SetPoint("TOP", TalcNeedFrame, "TOP", 0, 20 + (80 * index * -1))
    else
        _G[frame]:SetPoint("TOP", TalcNeedFrame, "TOP", 0, 20 + (80 * index))
    end
    _G[frame].link = link

    _G[frame .. 'ItemIcon']:SetNormalTexture(texture);
    _G[frame .. 'ItemIcon']:SetPushedTexture(texture);
    _G[frame .. 'ItemIconItemName']:SetText(link);
    _G[frame .. 'ItemIconItemLevel']:SetText(ITEM_QUALITY_COLORS[quality].hex .. il);

    _G[frame .. 'TimeLeftBar']:SetBackdropColor(ITEM_QUALITY_COLORS[quality].r, ITEM_QUALITY_COLORS[quality].g, ITEM_QUALITY_COLORS[quality].b, .76)

    core.addButtonOnEnterTooltip(_G[frame .. 'ItemIcon'], link, nil, true)

    _G[frame .. 'QuestRewards']:Hide()

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
                if core.find(core.lower(classes), class, 1, true) then
                    forMe = true
                end
                break
            end
        end
    end
    GameTooltip:Hide()

    if not forMe and classes ~= "" then
        SetDesaturation(_G[frame .. 'ItemIcon']:GetNormalTexture(), 1)
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

        GameTooltip:Hide()

        if hasRewardsForMe or not foundClasses then
            _G[frame .. 'QuestRewards']:Show()
            local rewardIndex = 0
            for i, rewardID in next, tokenRewards[itemID].rewards do

                local _, rewardLink, _, _, _, _, _, _, _, tex = GetItemInfo(rewardID)
                local _, _, rewardIL = core.find(rewardLink, "(item:%d+:%d+:%d+:%d+)");

                GameTooltip:SetOwner(TalcNeedFrame, "ANCHOR_NONE");
                GameTooltip:SetHyperlink(rewardIL)

                if foundClasses then
                    for j = 1, 20 do
                        if _G["GameTooltipTextLeft" .. j] and _G["GameTooltipTextLeft" .. j]:GetText() then
                            local itemText = _G["GameTooltipTextLeft" .. j]:GetText()
                            if core.find(itemText, "Classes:", 1, true) then
                                if core.find(core.lower(itemText), class, 1, true) then
                                    showReward = true
                                    rewardIndex = rewardIndex + 1
                                    _G[frame .. 'QuestRewardsReward' .. rewardIndex]:SetPoint("TOPLEFT", 20 + 23 * (rewardIndex - 1), -32)

                                    core.addButtonOnEnterTooltip(_G[frame .. 'QuestRewardsReward' .. rewardIndex], rewardIL)
                                    _G[frame .. 'QuestRewardsReward' .. rewardIndex]:SetNormalTexture(tex)
                                    _G[frame .. 'QuestRewardsReward' .. rewardIndex]:SetPushedTexture(tex)
                                    _G[frame .. 'QuestRewardsReward' .. rewardIndex]:Show()

                                    break
                                end
                            end
                        end
                    end
                end

                GameTooltip:Hide()

            end
        end
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

function NeedFrame:showAnchor()
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

function NeedFrame:hideAnchor()
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

    self:hideAnchor()

    for index, _ in next, self.itemFrames do
        self.itemFrames[index]:Hide()
    end

    for i = 1, 15 do
        _G['NewItemTooltip' .. i]:Hide()
    end

    TalcNeedFrame:Hide()

    self.countdown:Hide()
    self.countdown.T = 1
    self.numItems = 0

end

function NeedFrame:handleSync(arg1, msg, arg3, sender)

    if core.find(msg, 'needframe=', 1, true) then
        local command = core.split('=', msg)
        if command[2] == "reset" and core.isRL(sender) then
            self:ResetVars()
            return
        end
        return
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

        if core.find(msg, 'cacheItem=', 1, true) then
            local item = core.split("=", msg)
            core.cacheItem(item[2])
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
    end
end

function NeedFrame:ScaleWindow(dir)
    if dir == 'up' then
        if TalcNeedFrame:GetScale() < 1.4 then
            TalcNeedFrame:SetScale(TalcNeedFrame:GetScale() + 0.05)
        end
    elseif dir == 'down' then
        if TalcNeedFrame:GetScale() > 0.4 then
            TalcNeedFrame:SetScale(TalcNeedFrame:GetScale() - 0.05)
        end
    end

    db['NEED_SCALE'] = TalcNeedFrame:GetScale()

    talc_print('Frame re-scaled. Type |cfffff569/talc |cff69ccf0need resetscale |rif the frame is offscreen')
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
        self:fadeOutFrame(id, need)

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

function NeedFrame:Test()

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
            self:addItem('loot=-' .. i .. '=' .. tex .. '=' .. name .. '=' .. linkStrings[i] .. '=60')
            if not TalcNeedFrame:IsVisible() then
                TalcNeedFrame:Show()
                self.countdown:Show()
            end
        else
            talc_print('Caching items... please try again.')
            GameTooltip:SetHyperlink(itemLink)
            GameTooltip:Hide()
        end
    end
end

NeedFrame.countdown = CreateFrame("Frame")
NeedFrame.countdown:Hide()
NeedFrame.countdown.timeToNeed = 30 --default, will be gotten via addonMessage
NeedFrame.countdown.T = 1
NeedFrame.countdown.C = 30

NeedFrame.countdown:SetScript("OnShow", function()
    this.startTime = GetTime();
end)
NeedFrame.countdown:SetScript("OnUpdate", function()
    local plus = 0.03
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        if this.T ~= this.timeToNeed + plus then

            for index in next, NeedFrame.itemFrames do
                if core.floor(this.C - this.T + plus) < 0 then
                    _G['NeedFrame' .. index .. 'TimeLeftBarText']:SetText("CLOSED")
                else
                    _G['NeedFrame' .. index .. 'TimeLeftBarText']:SetText(core.ceil(this.C - this.T + plus) .. "s")
                end

                _G['NeedFrame' .. index .. 'TimeLeftBar']:SetWidth((this.C - this.T + plus) * 190 / this.timeToNeed)
            end
        end
        this:Hide()
        if this.T < this.C + plus then
            --still tick
            this.T = this.T + plus
            this:Show()
        elseif this.T > this.timeToNeed + plus then

            -- hide frames and send auto pass
            for index in next, NeedFrame.itemFrames do
                if NeedFrame.itemFrames[index]:GetAlpha() == 1 then
                    NeedFrame:NeedClick(index, 'autopass')
                end
            end
            -- end hide frames

            this:Hide()
            this.T = 1

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
        for id, data in next, this.data do
            if this.data[id] then
                atLeastOne = true
                talc_debug('delay add item on update for item id ' .. id .. ' data:[' .. data)
                this.data[id] = nil
                NeedFrame:addItem(data)
            end
        end

        if not atLeastOne then
            this:Hide()
        end
    end
end)


