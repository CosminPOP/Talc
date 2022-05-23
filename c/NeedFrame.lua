local db, core, tokenRewards
local _G = _G
NeedFrame = CreateFrame("Frame")
NeedFrame.numItems = 0
NeedFrame.itemFrames = {}

function NeedFrame:init()
    core = TALC
    db = TALC_DB
    tokenRewards = TALC_TOKENS

    self:ResetVars()
end

function NeedFrame:addItem(data)
    local item = core.split("=", data)

    local index = core.int(item[2])
    local texture = item[3]
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

    _G[frame]:SetID(index)
    _G[frame].need = 'autopass'
    _G[frame].elapsed = 0
    _G[frame].link = link

    _G[frame .. 'BISButton']:Hide()
    _G[frame .. 'MSUpgradeButton']:Hide()
    _G[frame .. 'OSButton']:Hide()
    _G[frame .. 'XMOGButton']:Hide()
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

    _G[frame .. 'Background']:SetTexture("Interface\\Addons\\Talc\\images\\need\\need_" .. quality)

    _G[frame]:ClearAllPoints()
    _G[frame]:SetPoint("TOP", TalcNeedFrame, "TOP", 0, 20 + (100 * index))

    _G[frame .. 'ItemIcon']:SetNormalTexture(texture);
    _G[frame .. 'ItemIcon']:SetPushedTexture(texture);
    _G[frame .. 'ItemIconItemName']:SetText(link);
    _G[frame .. 'ItemIconItemLevel']:SetText(ITEM_QUALITY_COLORS[quality].hex .. il);

    _G[frame .. 'TimeLeftBar']:SetVertexColor(ITEM_QUALITY_COLORS[quality].r, ITEM_QUALITY_COLORS[quality].g, ITEM_QUALITY_COLORS[quality].b, .76)

    _G[frame].inWishlist = false
    for _, wishItem in next, db['NEED_WISHLIST'] do
        local wName = GetItemInfo(wishItem)
        if wishItem == name or (wName and wName == name) then
            _G[frame].inWishlist = true
            break
        end
    end

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
                else
                    rewardIndex = rewardIndex + 1
                    _G[frame .. 'QuestRewardsReward' .. rewardIndex]:SetPoint("TOPLEFT", 20 + 23 * (rewardIndex - 1), -32)

                    core.addButtonOnEnterTooltip(_G[frame .. 'QuestRewardsReward' .. rewardIndex], rewardIL)
                    _G[frame .. 'QuestRewardsReward' .. rewardIndex]:SetNormalTexture(tex)
                    _G[frame .. 'QuestRewardsReward' .. rewardIndex]:SetPushedTexture(tex)
                    _G[frame .. 'QuestRewardsReward' .. rewardIndex]:Show()
                end

                GameTooltip:Hide()

            end
        end
    end

    self:fadeInFrame(_G[frame])
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

function NeedFrame:fadeInFrame(frame)
    frame:Show();
    frame.animIn:Stop();
    frame.animIn.animIn:SetStartDelay(frame:GetID() * 0.2);
    frame.animIn:Play();

    frame.glow.animIn.animIn:SetStartDelay(frame:GetID() * 0.2);
    frame.glow.animIn:Play();

    frame.shine.animIn.animIn:SetStartDelay(frame:GetID() * 0.2);
    frame.shine.animIn:Play();

    -- wishlist pulse
    if frame.inWishlist then
        frame.glow.wishPulse:Play();
    end
end

function NeedFrame:animInFinished()
    local frame = this:GetRegionParent()
    print(frame:GetName())

    _G[frame:GetName() .. "TimeLeftBar"].countdown:Stop();
    _G[frame:GetName() .. "TimeLeftBar"].countdown.animIn:SetStartDelay(0);
    _G[frame:GetName() .. "TimeLeftBar"].countdown.countdown:SetDuration(db['VOTE_TTN']);
    _G[frame:GetName() .. "TimeLeftBar"].countdown:Play();
end

function NeedFrame:fadeOutFrame(frame)
    -- can reach here from need click too
    _G[frame:GetName() .. "TimeLeftBar"].countdown:Stop();

    frame.animOut:Stop();
    frame.animOut.animOut:SetStartDelay(0);
    frame.animOut:Play();
end

function NeedFrame:animOutFinished()
    local frame = this:GetRegionParent()
    print(frame:GetName() .. " finished")
    frame:Hide();
    if frame.need == 'autopass' then
        NeedFrame:NeedClick(nil, frame)
        print("auto pass click")
    else
        if db['NEED_FRAME_COLLAPSE'] then
            NeedFrame:repositionFrames()
        end
    end
end

function NeedFrame:countdownFinished()
    local frame = this:GetRegionParent():GetParent()
    NeedFrame:fadeOutFrame(frame)
end

function NeedFrame:SetCountdownWidth()
    local frame = this:GetRegionParent():GetParent()
    frame.elapsed = frame.elapsed + core.int(arg1)
    this:GetRegionParent():SetWidth(260 - frame.elapsed * 260 / db['VOTE_TTN'])
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

    for _, frame in next, self.itemFrames do
        frame:Hide()
        frame = nil
    end

    for i = 1, 15 do
        _G['NewItemTooltip' .. i]:Hide()
    end

    self.numItems = 0
end

function NeedFrame:handleSync(arg1, msg, arg3, sender)

    if core.find(msg, 'needframe=', 1, true) then
        local command = core.split('=', msg)
        if command[2] == "reset" and core.isRaidLeader(sender) then
            self:ResetVars()
            return
        end
        return
    end

    if core.find(msg, 'sendgear=', 1, true) then
        self:SendGear(sender)
        return
    end

    if core.isRaidLeader(sender) then
        if core.find(msg, 'loot=', 1, true) then
            self.numItems = self.numItems + 1
            self:addItem(msg)
            if not TalcNeedFrame:IsVisible() then
                TalcNeedFrame:Show()
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

function NeedFrame:NeedClick(need, f)

    local frame = nil

    if f then
        frame = f --coming from end countdown, autopass
    else
        frame = this:GetParent() --coming from click
    end

    local id = frame:GetID()

    if need then
        frame.need = need
    else
        need = frame.need
    end

    if need == 'autopass' then
        self:fadeOutFrame(frame)
        return false
    end

    local gearscore = 0
    for i = 0, 18 do
        if GetInventoryItemLink("player", i) and i ~=4 then
            local _, _, _, itemLevel = GetItemInfo(GetInventoryItemLink("player", i));
            gearscore = gearscore + itemLevel
        end
    end

    local myItem = { '0', '0', '0', '0' }

    local _, _, itemLink = core.find(self.itemFrames[id].link, "(item:%d+:%d+:%d+:%d+)");
    local itemID = core.int(core.split(':', itemLink)[2])
    local _, _, _, _, _, _, t1, _, equip_slot = GetItemInfo(itemLink)

    if need ~= 'pass' and need ~= 'autopass' then
        for i = 1, 19 do
            if GetInventoryItemLink('player', i) then
                local _, _, eqItemLink = core.find(GetInventoryItemLink('player', i), "(item:%d+:%d+:%d+:%d+)");
                local _, _, _, _, _, _, _, _, itemSlot = GetItemInfo(eqItemLink)

                if itemSlot then
                    if core.equipSlots[equip_slot] == core.equipSlots[itemSlot] then
                        if myItem[1] == '0' then
                            myItem[1] = eqItemLink
                        else
                            myItem[2] = eqItemLink
                        end
                    end
                else
                    talc_debug('cant get inventory item ' .. i) -- shouldn't really get here cause player gear should be cached
                end
            end
        end

        -- token fix
        if tokenRewards[itemID] and tokenRewards[itemID].rewards then
            local _, _, _, _, _, _, _, _, r_equip_slot = GetItemInfo(tokenRewards[itemID].rewards[1])
            local _, _, eqItemLink = core.find(GetInventoryItemLink('player', core.equipSlotsDetails[r_equip_slot].id), "(item:%d+:%d+:%d+:%d+)");
            myItem[1] = eqItemLink

            if t1 == "Quest" then
                local ringsSet = false
                local trinketsSet = false

                local rewardIndex = 0
                local itemSet = {}
                for i, rewardID in next, tokenRewards[itemID].rewards do
                    local _, _, _, _, _, _, _, _, q_equip_slot = GetItemInfo(rewardID)
                    if q_equip_slot == 'INVTYPE_FINGER' then
                        if not ringsSet then
                            local _, _, ring1Link = core.find(GetInventoryItemLink('player', core.equipSlotsDetails['INVTYPE_FINGER0'].id), "(item:%d+:%d+:%d+:%d+)");
                            rewardIndex = rewardIndex + 1
                            myItem[rewardIndex] = ring1Link
                            local _, _, ring2Link = core.find(GetInventoryItemLink('player', core.equipSlotsDetails['INVTYPE_FINGER1'].id), "(item:%d+:%d+:%d+:%d+)");
                            rewardIndex = rewardIndex + 1
                            myItem[rewardIndex] = ring2Link
                            ringsSet = true
                        end
                    elseif q_equip_slot == 'INVTYPE_TRINKET' then
                        --todo
                    else
                        if not itemSet[core.equipSlotsDetails[q_equip_slot].id] then
                            local _, _, eqIL = core.find(GetInventoryItemLink('player', core.equipSlotsDetails[q_equip_slot].id), "(item:%d+:%d+:%d+:%d+)");
                            rewardIndex = rewardIndex + 1
                            myItem[rewardIndex] = eqIL
                            itemSet[core.equipSlotsDetails[q_equip_slot].id] = true
                        end
                    end
                end
            end
        end

        --mh/oh fix
        if equip_slot == 'INVTYPE_WEAPON' or equip_slot == 'INVTYPE_SHIELD' or equip_slot == 'INVTYPE_WEAPONMAINHAND'
                or equip_slot == 'INVTYPE_WEAPONOFFHAND' or equip_slot == 'INVTYPE_HOLDABLE' or equip_slot == 'INVTYPE_2HWEAPON' then
            --mh
            if GetInventoryItemLink('player', 16) then
                local _, _, eqItemLink = core.find(GetInventoryItemLink('player', 16), "(item:%d+:%d+:%d+:%d+)");
                myItem[1] = eqItemLink
            end
            --oh
            if GetInventoryItemLink('player', 17) then
                local _, _, eqItemLink = core.find(GetInventoryItemLink('player', 17), "(item:%d+:%d+:%d+:%d+)");
                myItem[2] = eqItemLink
            end
        end

    end

    local inWishlist = self.itemFrames[id].inWishlist and '1' or '0'
    core.asend(need .. "=" .. id .. "=" .. myItem[1] .. "=" .. myItem[2] .. "=" .. myItem[3] .. "=" .. myItem[4] .. "=" .. gearscore .. "=" .. inWishlist)

    self:fadeOutFrame(frame)
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
            self:addItem('testloot=' .. i .. '=' .. tex .. '=' .. name .. '=' .. linkStrings[i] .. '=60')
            if not TalcNeedFrame:IsVisible() then
                TalcNeedFrame:Show()
            end
        else
            talc_print('Caching items... please try again.')
            GameTooltip:SetHyperlink(itemLink)
            GameTooltip:Hide()
        end
    end
end

NeedFrame.delayAddItem = CreateFrame("Frame")
NeedFrame.delayAddItem:Hide()
NeedFrame.delayAddItem.data = {}

NeedFrame.delayAddItem:SetScript("OnShow", function()
    this.startTime = GetTime();
end)
NeedFrame.delayAddItem:SetScript("OnUpdate", function()
    local plus = 0.5
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
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
