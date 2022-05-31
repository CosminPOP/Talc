local db, core, tokenRewards
local _G = _G

NeedFrame = CreateFrame("Frame")

----------------------------------------------------
--- Vars
----------------------------------------------------

NeedFrame.numItems = 0
NeedFrame.itemFrames = {}

----------------------------------------------------
--- Event Handler
----------------------------------------------------

function NeedFrame:HandleSync(_, msg, _, sender)

    if core.subFind(msg, 'NeedFrame=') then
        local command = core.split('=', msg)
        if command[2] == "Reset" and core.isRaidLeader(sender) then
            self:ResetVars()
            return
        end
        return
    end

    if core.subFind(msg, 'SendGear=', 1, true) then
        self:SendGear(sender)
        return
    end

    if core.subFind(msg, 'CacheItem=', 1, true) then
        local cEx = core.split('=', msg)
        core.CacheItem(core.int(cEx[2]))
        return
    end

    if core.isRaidLeader(sender) then
        if core.subFind(msg, 'Loot=') then
            self.numItems = self.numItems + 1
            self:AddItem(msg)
            if not TalcNeedFrame:IsVisible() then
                TalcNeedFrame:Show()
            end
            return
        end

        if core.find(msg, 'DoneSending=', 1, true) then
            local nrItems = core.split('=', msg)
            if not nrItems[2] then
                talc_debug('wrong doneSending syntax')
                talc_debug(msg)
                return
            end

            core.asend("Received=" .. self.numItems)
            return
        end
    end
end

----------------------------------------------------
--- Init
----------------------------------------------------

function NeedFrame:Init()
    core = TALC
    db = TALC_DB
    tokenRewards = TALC_TOKENS

    self:ResetVars()
end

function NeedFrame:ResetVars()

    self:HideAnchor()

    for _, frame in next, self.itemFrames do
        frame:Hide()
        frame = nil
    end

    for i = 1, 15 do
        _G['NewItemTooltip' .. i]:Hide()
    end

    self.numItems = 0
end


function NeedFrame:AddItem(data)
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
        return
    end

    if quality > 5 then
        return
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

    _G[frame .. 'ItemQuality2']:Hide()
    _G[frame .. 'ItemQuality3']:Hide()
    _G[frame .. 'ItemQuality4']:Hide()
    _G[frame .. 'ItemQuality5']:Hide()

    if quality < 2 then
        _G[frame .. 'ItemQuality2']:Show()
        SetDesaturation(_G[frame .. 'ItemQuality2'], 1)
    else
        _G[frame .. 'ItemQuality' .. quality]:Show()
    end

    _G[frame]:ClearAllPoints()
    _G[frame]:SetPoint("TOP", TalcNeedFrame, "TOP", 0, 20 + (100 * index))

    _G[frame .. 'Item']:SetNormalTexture(texture);
    _G[frame .. 'Item']:SetPushedTexture(texture);
    _G[frame .. 'ItemName']:SetText(link);
    _G[frame .. 'ItemLevel']:SetText(ITEM_QUALITY_COLORS[quality].hex .. il);

    _G[frame .. 'TimeLeftBar']:SetVertexColor(ITEM_QUALITY_COLORS[quality].r, ITEM_QUALITY_COLORS[quality].g, ITEM_QUALITY_COLORS[quality].b, .76)

    _G[frame].inWishlist = false
    for _, wishItem in next, db['NEED_WISHLIST'] do
        local wName = GetItemInfo(wishItem)
        if wishItem == name or (wName and wName == name) then
            _G[frame].inWishlist = true
            break
        end
    end

    core.addButtonOnEnterTooltip(_G[frame .. 'Item'], link, nil, true)

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
        SetDesaturation(_G[frame .. 'Item']:GetNormalTexture(), 1)
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

            if tokenRewards[itemID].count then
                _G[frame .. 'QuestRewardsReward1Count']:SetText(tokenRewards[itemID].count)
                _G[frame .. 'QuestRewardsReward1Count']:Show()
            else
                _G[frame .. 'QuestRewardsReward1Count']:Hide()
            end

            local rewardIndex = 0
            for _, rewardID in next, tokenRewards[itemID].rewards do

                if GetItemInfo(rewardID) then

                    local _, rewardLink, _, itemLevel, _, _, _, _, _, tex = GetItemInfo(rewardID)
                    local _, _, rewardIL = core.find(rewardLink, "(item:%d+:%d+:%d+:%d+)");

                    _G[frame .. 'ItemLevel']:SetText(ITEM_QUALITY_COLORS[quality].hex .. itemLevel);

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

                                        core.addButtonOnEnterTooltip(_G[frame .. 'QuestRewardsReward' .. rewardIndex], rewardIL, nil, true)
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

                        core.addButtonOnEnterTooltip(_G[frame .. 'QuestRewardsReward' .. rewardIndex], rewardIL, nil, true)
                        _G[frame .. 'QuestRewardsReward' .. rewardIndex]:SetNormalTexture(tex)
                        _G[frame .. 'QuestRewardsReward' .. rewardIndex]:SetPushedTexture(tex)
                        _G[frame .. 'QuestRewardsReward' .. rewardIndex]:Show()
                    end

                    -- quest item has Classes, reward doesnt
                    if rewardIndex == 0 then
                        rewardIndex = rewardIndex + 1
                        _G[frame .. 'QuestRewardsReward' .. rewardIndex]:SetPoint("TOPLEFT", 20 + 23 * (rewardIndex - 1), -32)

                        core.addButtonOnEnterTooltip(_G[frame .. 'QuestRewardsReward' .. rewardIndex], rewardIL, nil, true)
                        _G[frame .. 'QuestRewardsReward' .. rewardIndex]:SetNormalTexture(tex)
                        _G[frame .. 'QuestRewardsReward' .. rewardIndex]:SetPushedTexture(tex)
                        _G[frame .. 'QuestRewardsReward' .. rewardIndex]:Show()
                    end

                    GameTooltip:Hide()
                else
                    talc_debug("cant get info " .. rewardID)
                end
            end
        end
    end

    self:FadeInFrame(_G[frame])
end

function NeedFrame:SendGear(to)
    core.wsend("NORMAL", "SendingGear=Start", to)
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
            core.wsend("NORMAL", "SendingGear=" .. shortLink .. ":" .. i .. ":" .. slotString, to)
        end
    end
    core.wsend("NORMAL", "SendingGear=End", to)
end

function NeedFrame:FadeInFrame(frame)
    frame:Show();
    frame.animIn:Stop();
    frame.animIn.animIn:SetStartDelay(frame:GetID() * 0.2);
    frame.animIn:Play();

    frame.glow.animIn.animIn:SetStartDelay(frame:GetID() * 0.2);
    frame.glow.animIn:Play();

    _G[frame:GetName() .. "Item"].qualityGlow.animIn.animIn:SetStartDelay(frame:GetID() * 0.2);
    _G[frame:GetName() .. "Item"].qualityGlow.animIn:Play();

    frame.shine.animIn.animIn:SetStartDelay(frame:GetID() * 0.2);
    frame.shine.animIn:Play();

    _G[frame:GetName() .. "BISButton"].fade.animIn:Stop();
    _G[frame:GetName() .. "BISButton"].fade.animIn.animIn:SetStartDelay(frame:GetID() * 0.2 + 0.5);
    _G[frame:GetName() .. "BISButton"].fade.animIn:Play();

    _G[frame:GetName() .. "MSUpgradeButton"].fade.animIn:Stop();
    _G[frame:GetName() .. "MSUpgradeButton"].fade.animIn.animIn:SetStartDelay(frame:GetID() * 0.2 + 0.65);
    _G[frame:GetName() .. "MSUpgradeButton"].fade.animIn:Play();

    _G[frame:GetName() .. "OSButton"].fade.animIn:Stop();
    _G[frame:GetName() .. "OSButton"].fade.animIn.animIn:SetStartDelay(frame:GetID() * 0.2 + 0.8);
    _G[frame:GetName() .. "OSButton"].fade.animIn:Play();

    _G[frame:GetName() .. "XMOGButton"].fade.animIn:Stop();
    _G[frame:GetName() .. "XMOGButton"].fade.animIn.animIn:SetStartDelay(frame:GetID() * 0.2 + 0.95);
    _G[frame:GetName() .. "XMOGButton"].fade.animIn:Play();

    _G[frame:GetName() .. "PassButton"].fade.animIn:Stop();
    _G[frame:GetName() .. "PassButton"].fade.animIn.animIn:SetStartDelay(frame:GetID() * 0.2 + 1.1);
    _G[frame:GetName() .. "PassButton"].fade.animIn:Play();

    -- wishlist pulse
    if frame.inWishlist then
        frame.glow.wishPulse:Play();
    end
end

function NeedFrame:FadeIn_Finished()
    local frame = this:GetRegionParent()
    frame.timeleft.countdown:Stop();
    frame.timeleft.countdown.animIn:SetStartDelay(0);
    frame.timeleft.countdown.countdown:SetStartDelay(0);
    frame.timeleft.countdown.countdown:SetDuration(db['VOTE_TTN'] - 1);
    frame.timeleft.countdown:Play();
end

function NeedFrame:FadeOutFrame(frame)
    -- can reach here from need click too
    _G[frame:GetName() .. "TimeLeftBar"].countdown:Stop();

    frame.animOut:Stop();
    frame.animOut.animOut:SetStartDelay(0);
    frame.animOut:Play();
end

function NeedFrame:FadeOut_Finished()
    local frame = this:GetRegionParent()
    frame:Hide();
    if frame.need == 'autopass' then
        NeedFrame:NeedClick(nil, frame)
        talc_debug("auto pass click")
    else
        if db['NEED_FRAME_COLLAPSE'] then
            NeedFrame:RepositionFrames(frame:GetID())
        end
    end
end

function NeedFrame:Countdown_Finished()
    local frame = this:GetRegionParent():GetParent()
    NeedFrame:FadeOutFrame(frame)
end

function NeedFrame:SetCountdownWidth()
    local frame = this:GetRegionParent():GetParent()
    frame.elapsed = frame.elapsed + core.int(arg1)
    this:GetRegionParent():SetWidth(260 - frame.elapsed * 260 / db['VOTE_TTN'])
end

function NeedFrame:RepositionFrames(id)
    if id < #self.itemFrames then
        for i = id + 1, #self.itemFrames do
            local _, _, _, _, yOfs = self.itemFrames[i]:GetPoint()
            self.itemFrames[i]:SetPoint("TOP", TalcNeedFrame, "TOP", 0, yOfs - 100)
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
        self:FadeOutFrame(frame)
        return false
    end

    local gearscore = 0
    for i = 0, 18 do
        if GetInventoryItemLink("player", i) and i ~= 4 then
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
            if r_equip_slot ~= '' then
                local _, _, eqItemLink = core.find(GetInventoryItemLink('player', core.equipSlotsDetails[r_equip_slot].id), "(item:%d+:%d+:%d+:%d+)");
                myItem[1] = eqItemLink

                if t1 == "Quest" then
                    local ringsSet = false
                    local trinketsSet = false

                    local rewardIndex = 0
                    local itemSet = {}
                    for _, rewardID in next, tokenRewards[itemID].rewards do
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
                            if not trinketsSet then
                                local _, _, trinket1Link = core.find(GetInventoryItemLink('player', core.equipSlotsDetails['INVTYPE_TRINKET0'].id), "(item:%d+:%d+:%d+:%d+)");
                                rewardIndex = rewardIndex + 1
                                myItem[rewardIndex] = trinket1Link
                                local _, _, trinket2Link = core.find(GetInventoryItemLink('player', core.equipSlotsDetails['INVTYPE_TRINKET1'].id), "(item:%d+:%d+:%d+:%d+)");
                                rewardIndex = rewardIndex + 1
                                myItem[rewardIndex] = trinket2Link
                                trinketsSet = true
                            end
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

    self:FadeOutFrame(frame)
end

----------------------------------------------------
--- Delay/Cache Add
----------------------------------------------------

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
                NeedFrame:AddItem(data)
            end
        end

        if not atLeastOne then
            this:Hide()
        end
    end
end)


----------------------------------------------------
--- Test
----------------------------------------------------

function NeedFrame:Test()

    local linkStrings = {
        '\124cffa335ee\124Hitem:40610:0:0:0:0:0:0:0:0\124h[Chestguard of the Lost Conqueror]\124h\124r',
        '\124cff0070dd\124Hitem:10399:0:0:0:0:0:0:0:0\124h[Blackened Defias Armor]\124h\124r',
        '\124cff1eff00\124Hitem:10402:0:0:0:0:0:0:0:0\124h[Blackened Defias Boots]\124h\124r',
        '\124cffa335ee\124Hitem:46052:0:0:0:0:0:0:0:0\124h[Reply-Code Alpha]\124h\124r',
        '\124cffa335ee\124Hitem:40611:0:0:0:0:0:0:0:0\124h[Chestguard of the Lost Protector]\124h\124r',
        '\124cffa335ee\124Hitem:44569:0:0:0:0:0:0:0:0\124h[Key to the Focusing Iris]\124h\124r',
        '\124cffff8000\124Hitem:45038:0:0:0:0:0:0:0:0\124h[Fragment of Val\'anyr]\124h\124r'
    }

    for i = 1, 7 do
        local _, _, itemLink = core.find(linkStrings[i], "(item:%d+:%d+:%d+:%d+)");
        local name, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)

        if name and tex then
            self:AddItem('testloot=' .. i .. '=' .. tex .. '=' .. name .. '=' .. linkStrings[i] .. '=60')
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