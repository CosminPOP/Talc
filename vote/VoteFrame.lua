local db, core, tokenRewards
local _G = _G

local ContestantDropdownMenu = CreateFrame('Frame', 'ContestantDropdownMenu', UIParent, 'UIDropDownMenuTemplate')
ContestantDropdownMenu.currentContestantId = 0

TalcFrame = CreateFrame("Frame")

TalcFrame.VotedItemsFrames = {}
TalcFrame.CurrentVotedItem = nil --slotIndex
TalcFrame.currentPlayersList = {} --all
TalcFrame.itemVotes = {}
TalcFrame.LCVoters = 0
TalcFrame.playersWhoWantItems = {}
TalcFrame.voteTiePlayers = ''
TalcFrame.currentItemWinner = ''
TalcFrame.currentItemMaxVotes = 0
TalcFrame.currentRollWinner = ''
TalcFrame.currentMaxRoll = {}

TalcFrame.numPlayersThatWant = 0
TalcFrame.namePlayersThatWants = 0

TalcFrame.waitResponses = {}
TalcFrame.receivedResponses = 0
TalcFrame.pickResponses = {}

TalcFrame.lootHistoryMinRarity = 3
TalcFrame.selectedPlayer = {}

TalcFrame.lootHistoryFrames = {}
TalcFrame.peopleWithAddon = ''

TalcFrame.doneVoting = {} --self / item
TalcFrame.clDoneVotingItem = {}
TalcFrame.CLVoted = {}

TalcFrame.itemsToPreSend = {}
TalcFrame.sentReset = false

TalcFrame.numItems = 0

TalcFrame.CLVotedFrames = {}
TalcFrame.RaidBuffs = {}

TalcFrame.assistTriggers = 0

TalcFrame.HistoryId = 0

TalcFrame.NEW_ROSTER = {}

TalcFrame.contestantsFrames = {}
TalcFrame.bagItems = {}
TalcFrame.inspectPlayerGear = {}

TalcFrame.durationNotification = 1000 * 60 -- 10 * 60 -- s

TalcFrame.welcomeItemsFrames = {}

function TalcFrame:init()

    db = TALC_DB
    core = TALC
    tokenRewards = TALC_TOKENS

    self:ResetVars()
end

function TalcFrame:ResetVars()

    self.LootCountdown:Hide()
    self.VoteCountdown:Hide()

    self.CurrentVotedItem = nil
    self.currentPlayersList = {}
    self.playersWhoWantItems = {}

    self.waitResponses = {}
    self.pickResponses = {}
    self.receivedResponses = 0

    self.itemVotes = {}

    self.myVotes = {}
    self.LCVoters = 0
    self.CLVoted = {}

    self.selectedPlayer = {}
    self.inspectPlayerGear = {}

    self.doneVoting = {}
    self.clDoneVotingItem = {}

    self.itemsToPreSend = {}

    self.numItems = 0
    self.assistTriggers = 0

    self.bagItems = {}

    self.LootCountdown.currentTime = 1
    self.VoteCountdown.currentTime = 1
    self.VoteCountdown.votingOpen = false

    self.LootCountdown.countDownFrom = db['VOTE_TTN']
    self.VoteCountdown.countDownFrom = db['VOTE_TTV']

    self:Resized()
    self:SetTitle()

    TalcVoteFrame:SetScale(db['VOTE_SCALE'])

    TalcVoteFrameVotesLabel:SetText('Votes');
    TalcVoteFrameContestantCount:SetText()
    TalcVoteFrameWinnerStatus:Hide()

    TalcVoteFrameMLToWinner:Disable()
    TalcVoteFrameMLToWinnerNrOfVotes:SetText()
    TalcVoteFrameWinnerStatusNrOfVotes:SetText()

    for _, frame in next, self.VotedItemsFrames do
        frame:Hide()
    end

    for _, frame in next, self.contestantsFrames do
        frame:Hide()
    end

    TalcVoteFrameTimeLeftBar:SetWidth(TalcVoteFrame:GetWidth() - 8)
    TalcVoteFrameTimeLeftBarBG:SetWidth(TalcVoteFrame:GetWidth() - 8)

    TalcVoteFrameCurrentVotedItemButton:Hide()
    TalcVoteFrameVotedItemName:Hide()
    TalcVoteFrameVotedItemType:Hide()

    for i = 1, #self.itemRewardsFrames do
        self.itemRewardsFrames[i]:Hide()
    end

    TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()

    TalcVoteFrameDoneVoting:Disable();
    TalcVoteFrameDoneVotingCheck:Hide();
    TalcVoteFrameContestantScrollListFrame:Hide()
    TalcVoteFrameContestantScrollListFrameScrollBar:SetAlpha(0)

    TalcVoteFrameTradableItemsFrame:Hide()

    TalcVoteFrameContestantScrollListFrame:SetPoint("TOPLEFT", TalcVoteFrame, "TOPLEFT", 5, -109)
    TalcVoteFrameContestantScrollListFrame:SetPoint("BOTTOMRIGHT", TalcVoteFrame, "BOTTOMRIGHT", -5, 28)

    TalcVoteFrameMLToEnchanter:Hide()

    TalcVoteFrameRLExtraFrameDragLoot:SetText("Drag Loot")
    TalcVoteFrameRLExtraFrameDragLoot:Enable()

    if core.isRL() then
        TalcVoteFrameRLExtraFrame:Show()

        TalcVoteFrameMLToEnchanter:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", -100, 0);
            if db['VOTE_DESENCHANTER'] == nil then
                GameTooltip:AddLine("Enchanter not set. Type /talc set enchanter [name]")
            else
                GameTooltip:AddLine("ML to " .. db['VOTE_DESENCHANTER'] .. " to disenchant.")
            end
            GameTooltip:Show()
        end)

        TalcVoteFrameMLToEnchanter:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        self.tradableItemsCheck:Show()
    else
        TalcVoteFrameRLExtraFrame:Hide()
    end

    self:HideVotingElements()

    self:ShowWelcomeScreen()
    --self:HideWelcomeScreen()

    self:HideSettingsScreen()

end

TalcFrame.closeVoteFrameFromSettings = false

function TalcFrame:ShowSettingsScreen(a)
    self:HideWelcomeScreen()
    TalcFrame.closeVoteFrameFromSettings = a
    TalcVoteFrame:Show()
    TalcVoteFrameSettingsFrame:Show()
end

function TalcFrame:HideSettingsScreen(showWelcome)
    TalcVoteFrameSettingsFrame:Hide()
    if TalcFrame.closeVoteFrameFromSettings then
        TalcVoteFrame:Hide()
        TalcFrame.closeVoteFrameFromSettings = false
    end
    if showWelcome then
        self:ShowWelcomeScreen()
    end
end

function TalcFrame:ShowWelcomeScreen()

    if GetGuildInfo('player') then
        db['VOTE_ROSTER_GUILD_NAME'] = GetGuildInfo('player')
    end

    if db['VOTE_ROSTER'][core.me] ~= nil then
        local allMembers = ''
        for name in next, db['VOTE_ROSTER'] do
            if name ~= core.me then
                allMembers = allMembers .. name .. ", "
            end
        end
        TalcVoteFrameWelcomeLCStatus:SetText("You are part of the " .. ITEM_QUALITY_COLORS[5].hex .. db['VOTE_ROSTER_GUILD_NAME'] .. " |rLoot Council.")
    else
        if GetGuildInfo('player') then
            TalcVoteFrameWelcomeLCStatus:SetText("You are not part of the " .. ITEM_QUALITY_COLORS[5].hex .. db['VOTE_ROSTER_GUILD_NAME'] .. " |rLoot Council.")
        else
            TalcVoteFrameWelcomeLCStatus:SetText("You are not part of a guild.")
        end
    end

    self:ShowWelcomeItems()
    TalcVoteFrameWelcome:Show()
end

function TalcFrame:HideWelcomeScreen()
    TalcVoteFrameWelcome:Hide()
end

function TalcFrame:HideVotingElements()
    TalcVoteFrameTimeLeftBar:Hide()
    TalcVoteFrameLabelsBackground:Hide()
    TalcVoteFrameNameLabel:Hide()
    TalcVoteFrameGearScoreLabel:Hide()
    TalcVoteFramePickLabel:Hide()
    TalcVoteFrameReplacesLabel:Hide()
    TalcVoteFrameRollLabel:Hide()
    TalcVoteFrameVotesLabel:Hide()
    TalcVoteFrameContestantCount:Hide()
    TalcVoteFrameTimeLeft:Hide()
    TalcVoteFrameDoneVoting:Hide()

    TalcVoteFrameWinnerStatus:Hide()
    TalcVoteFrameMLToWinner:Hide()
    TalcVoteFrameCLThatVotedList:Hide()
end

function TalcFrame:ShowVotingElements()
    TalcVoteFrameTimeLeftBar:Show()
    TalcVoteFrameLabelsBackground:Show()
    TalcVoteFrameNameLabel:Show()
    TalcVoteFrameGearScoreLabel:Show()
    TalcVoteFramePickLabel:Show()
    TalcVoteFrameReplacesLabel:Show()
    TalcVoteFrameRollLabel:Show()
    TalcVoteFrameVotesLabel:Show()
    TalcVoteFrameContestantCount:Show()
    TalcVoteFrameTimeLeft:Show()
    TalcVoteFrameTimeLeft:SetText('')
    TalcVoteFrameDoneVoting:Show()

    if core.isRL() then
        TalcVoteFrameMLToWinner:Show()
    else
        TalcVoteFrameWinnerStatus:Show()
    end

    TalcVoteFrameCLThatVotedList:Show()
end

function TalcFrame:ShowWelcomeItems()
    local index = 0

    for i = 1, #self.welcomeItemsFrames do
        self.welcomeItemsFrames[i]:Hide()
    end

    local totalItems = 0
    for _ in next, db['VOTE_LOOT_HISTORY'] do
        totalItems = totalItems + 1
    end

    if totalItems == 0 then
        TalcVoteFrameWelcomeNoRecentItems:Show()
    else
        TalcVoteFrameWelcomeNoRecentItems:Hide()
    end

    local x = TalcVoteFrameWelcome:GetWidth()
    local y = TalcVoteFrameWelcome:GetHeight()
    local numCols = core.floor(x / 185)
    local numRows = core.floor((y - 30) / 46)
    local col, row = 1, 1
    local day = 0
    for timestamp, item in core.pairsByKeysReverse(db['VOTE_LOOT_HISTORY']) do
        if timestamp then
            index = index + 1

            if day ~= date("%d/%m", timestamp) then
                day = date("%d/%m", timestamp)
                if col ~= 1 then
                    row = row + 1
                end
                col = 1
            end

            if row == numRows then
                break
            end

            if not self.welcomeItemsFrames[index] then
                self.welcomeItemsFrames[index] = CreateFrame('Button', 'WelcomeItem' .. index, TalcVoteFrameWelcome, 'Talc_WelcomeItemTemplate')
            end
            local frame = 'WelcomeItem' .. index
            _G[frame]:SetPoint('TOPLEFT', 'TalcVoteFrameWelcome', 'TOPLEFT', -180 + 185 * col, -10 - 34 - 44 * row)
            _G[frame .. 'Name']:SetText(item.item)
            _G[frame .. 'PlayerName']:SetText(core.classColors[core.getPlayerClass(item.player)].colorStr .. item.player .. " " ..
                    (date("%d/%m", timestamp) == date("%d/%m", time()) and core.classColors['hunter'].colorStr or '|r') .. date("%d/%m", timestamp))

            local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(item.item)
            _G[frame .. 'Icon']:SetTexture(tex)
            core.addButtonOnEnterTooltip(_G[frame], item.item)

            _G[frame]:Show()

            col = col + 1

            if col > numCols then
                col = 1
                row = row + 1
            end
        end
    end
end

function TalcFrame:SetTitle(to)
    if not to then
        TalcVoteFrameTitle:SetText('|cfffff569T|rhunder |cfffff569A|rle Brewing Co |cfffff569L|root |cfffff569C|rouncil v' .. core.addonVer)
    else
        TalcVoteFrameTitle:SetText('Thunder Ale Brewing Co Loot Council v' .. core.addonVer .. ' - ' .. to)
    end
end

function TalcFrame:Resizing()
    TalcVoteFrame:SetAlpha(0.5)
end

function TalcFrame:Resized()

    local ratio = TalcVoteFrame:GetWidth() / 600;
    TalcVoteFrameNameLabel:SetPoint("TOPLEFT", TalcVoteFrame, core.floor(8 * ratio), -92)
    TalcVoteFrameGearScoreLabel:SetPoint("TOPLEFT", TalcVoteFrame, core.floor(100 * ratio), -92)
    TalcVoteFramePickLabel:SetPoint("TOPLEFT", TalcVoteFrame, core.floor(165 * ratio), -92)
    TalcVoteFrameReplacesLabel:SetPoint("TOPLEFT", TalcVoteFrame, core.floor(225 * ratio), -92)
    TalcVoteFrameRollLabel:SetPoint("TOPLEFT", TalcVoteFrame, core.floor(285 * ratio), -92)
    TalcVoteFrameVotesLabel:SetPoint("TOPLEFT", TalcVoteFrame, core.floor(406 * ratio), -92)

    TalcVoteFrameTimeLeftBar:SetWidth(TalcVoteFrame:GetWidth() - 8)
    TalcVoteFrameTimeLeftBarBG:SetWidth(TalcVoteFrame:GetWidth() - 8)

    TalcVoteFrame:SetAlpha(db['VOTE_ALPHA'])

    if TalcVoteFrameWelcome:IsVisible() then
        self:ShowWelcomeItems()
    end

    self:VoteFrameListUpdate()
end

function TalcFrame:SyncLootHistory()
    local totalItems = 0
    for _ in next, db['VOTE_LOOT_HISTORY'] do
        totalItems = totalItems + 1
    end

    TalcVoteFrameRLWindowFrameTab2ContentsSyncLootHistory:Disable()

    talc_print('Starting History Sync, ' .. totalItems .. ' entries...')
    core.bsend("BULK", "loot_history_sync;start")
    for lootTime, item in next, db['VOTE_LOOT_HISTORY'] do
        core.bsend("BULK", "loot_history_sync;" .. lootTime .. ";" .. item.player .. ";" .. item.item .. ";" .. item.class)
    end
    core.bsend("BULK", "loot_history_sync;end")
    talc_print('History Sync finished. Sent ' .. totalItems .. ' entries.')
end

function TalcFrame:ToggleMainWindow()

    if TalcVoteFrame:IsVisible() then
        self:CloseWindow()
    else
        if not core.canVote() and not core.isRL() then
            return false
        end
        TalcVoteFrame:Show()
    end
end

function TalcFrame:SendReset()
    core.asend("voteframe=reset")
    core.asend("needframe=reset")
    core.asend("rollframe=reset")
end

function TalcFrame:SendCloseWindow()
    core.asend("voteframe=close")
end

function TalcFrame:CloseWindow()
    TalcVoteFrame:Hide()
    TalcVoteFrameRaiderDetailsFrame:Hide()
    TalcVoteFrameRLWindowFrame:Hide()
end

function TalcFrame:showWindow()
    if not TalcVoteFrame:IsVisible() then
        TalcVoteFrame:Show()
    end
end

function TalcFrame:ResetClose()
    self:SendReset()
    self:SendCloseWindow()
    self.sentReset = false
    SetLootMethod("master", core.me)
end

function TalcFrame:SetCL(id, to)
    if to then
        core.addToRoster(self.RLFrame.assistFrames[id].name)
    else
        core.remFromRoster(self.RLFrame.assistFrames[id].name)
    end
end

function TalcFrame:SetAssist(id, to)
    for i = 0, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) then
            local n = GetRaidRosterInfo(i);
            if n == self.RLFrame.assistFrames[id].name then
                if to then
                    talc_debug('promote ')
                    PromoteToAssistant(n)
                else
                    talc_debug('demote ')
                    DemoteAssistant(n)
                end
                return true
            end
        end
    end
    return false
end

function TalcFrame:ToggleRLOptions()

    if TalcVoteFrameRLWindowFrame:IsVisible() then
        HideUIPanel(TalcVoteFrameRLWindowFrame)
    else
        if TalcVoteFrameRaiderDetailsFrame:IsVisible() then
            self:RaiderDetailsClose()
        end

        local totalItems = 0
        for _ in next, db['VOTE_LOOT_HISTORY'] do
            totalItems = totalItems + 1
        end

        TalcVoteFrameRLWindowFrameTab2ContentsSyncLootHistory:SetText('Sync Loot History (' .. totalItems .. ')')

        ShowUIPanel(TalcVoteFrameRLWindowFrame)

        self.RLFrame:ChangeTab(1)

    end
end

function TalcFrame:BroadcastLoot()

    local lootMethod = GetLootMethod()
    if lootMethod ~= 'master' then
        talc_print('Looting method is not master looter. (' .. lootMethod .. ')')
        return false
    end

    local target = UnitName('target')
    if UnitIsPlayer('target') or not UnitExists('target') then
        target = 'Chest'
    end
    core.asend('boss&' .. target)

    if GetNumLootItems() == 0 then
        talc_print('There are no items in the loot frame.')
        return
    end

    if not self.sentReset then
        -- disable broadcast until roster is synced
        TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()

        core.SetDynTTN(GetNumLootItems())
        core.SetDynTTV(GetNumLootItems())
        self.LootCountdown.countDownFrom = db['VOTE_TTN']

        self:SendTimersAndButtons()

        -- send button configuration to CLs
        local buttons = ''
        if db['VOTE_CONFIG']['NeedButtons']['BIS'] then
            buttons = buttons .. 'b'
        end
        if db['VOTE_CONFIG']['NeedButtons']['MS'] then
            buttons = buttons .. 'm'
        end
        if db['VOTE_CONFIG']['NeedButtons']['OS'] then
            buttons = buttons .. 'o'
        end
        if db['VOTE_CONFIG']['NeedButtons']['XMOG'] then
            buttons = buttons .. 'x'
        end

        core.asend('NeedButtons=' .. buttons)

        self:SendReset()

        for id = 0, GetNumLootItems() do
            if GetLootSlotInfo(id) and GetLootSlotLink(id) then
                local lootIcon, lootName = GetLootSlotInfo(id)

                local _, _, itemLink = core.find(GetLootSlotLink(id), "(item:%d+:%d+:%d+:%d+)");
                local _, _, quality = GetItemInfo(itemLink)
                if quality >= 0 then
                    --send to officers
                    core.bsend("BULK", "preloadInVoteFrame=" .. id .. "=" .. lootIcon .. "=" .. lootName .. "=" .. GetLootSlotLink(id))
                end
            end
        end

        core.syncRoster()
        self.sentReset = true

        TalcVoteFrameRLExtraFrameBroadcastLoot:SetText('Waiting sync...')

        return false
    end

    TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()

    self.LootCountdown:Show()
    core.asend('countdownframe=show')

    local numLootItems = 0
    for id = 0, GetNumLootItems() do
        if GetLootSlotInfo(id) and GetLootSlotLink(id) then
            local lootIcon, lootName = GetLootSlotInfo(id)

            local _, _, itemLink = core.find(GetLootSlotLink(id), "(item:%d+:%d+:%d+:%d+)");
            local _, _, quality = GetItemInfo(itemLink)
            if quality >= 0 then
                local buttons = ''
                if db['VOTE_CONFIG']['NeedButtons']['BIS'] then
                    buttons = buttons .. 'b'
                end
                if db['VOTE_CONFIG']['NeedButtons']['MS'] then
                    buttons = buttons .. 'm'
                end
                if db['VOTE_CONFIG']['NeedButtons']['OS'] then
                    buttons = buttons .. 'o'
                end
                if db['VOTE_CONFIG']['NeedButtons']['XMOG'] then
                    buttons = buttons .. 'x'
                end
                --send to c
                core.bsend("ALERT", "loot=" .. id .. "=" .. lootIcon .. "=" .. lootName .. "=" .. GetLootSlotLink(id))
                numLootItems = numLootItems + 1
            end
        end
    end
    core.bsend("ALERT", "doneSending=" .. numLootItems .. "=items")
    TalcVoteFrameMLToWinner:Disable();

    TalcVoteFrameRLExtraFrameBroadcastLoot:SetText(numLootItems .. " items sent")
end

function TalcFrame:addVotedItem(index, texture, link)

    self.itemVotes[index] = {}

    self.doneVoting[index] = false

    self.selectedPlayer[index] = ''

    if not self.VotedItemsFrames[index] then
        self.VotedItemsFrames[index] = CreateFrame("Button", "VotedItem" .. index,
                TalcVoteFrameVotedItemsFrame, "Talc_VotedItemButtonTemplate")
    end

    local frame = 'VotedItem' .. index

    TalcVoteFrameVotedItemsFrame:SetHeight(40 * index + 35)

    _G[frame]:SetPoint("TOPLEFT", TalcVoteFrameVotedItemsFrame, "TOPLEFT", 8, 30 - (40 * index))

    _G[frame]:Show()
    _G[frame].link = link
    _G[frame].texture = texture
    _G[frame].awardedTo = ''
    _G[frame].rolled = false
    _G[frame].pickedByEveryone = false

    core.addButtonOnEnterTooltip(_G[frame], link)

    _G[frame]:SetID(index)
    _G[frame]:SetNormalTexture(texture)
    _G[frame]:SetPushedTexture(texture)
    _G[frame]:SetHighlightTexture(texture)

    _G[frame .. 'Check']:Hide()
    _G[frame]:SetHighlightTexture(texture)

    if index ~= 1 then
        SetDesaturation(_G[frame]:GetNormalTexture(), 1)
    end

    if not self.CurrentVotedItem then
        TalcFrame:VotedItemButton(index)
    end
end

function TalcFrame:VotedItemButton(id)

    TalcVoteFrameMLToWinner:Hide()
    if core.isRL() then
        TalcVoteFrameMLToWinner:Show()
    end
    if core.canVote() and not core.isRL() then
        TalcVoteFrameWinnerStatus:Show()
    end

    SetDesaturation(_G['VotedItem' .. id]:GetNormalTexture(), 0)
    for index, _ in next, self.VotedItemsFrames do
        if index ~= id then
            SetDesaturation(_G['VotedItem' .. index]:GetNormalTexture(), 1)
        end
    end
    self:SetCurrentVotedItem(id)
end

TalcFrame.itemRewardsFrames = {}

function TalcFrame:SetCurrentVotedItem(id)

    self.CurrentVotedItem = id

    TalcVoteFrameCurrentVotedItemButton:Show()
    TalcVoteFrameVotedItemName:Show()
    TalcVoteFrameVotedItemType:Show()

    TalcVoteFrameCurrentVotedItemButton:SetNormalTexture(self.VotedItemsFrames[id].texture)
    TalcVoteFrameCurrentVotedItemButton:SetPushedTexture(self.VotedItemsFrames[id].texture)

    local link = self.VotedItemsFrames[id].link
    TalcVoteFrameVotedItemName:SetText(link)
    core.addButtonOnEnterTooltip(TalcVoteFrameCurrentVotedItemButton, link, 'playerHistory')

    local _, _, itemLink = core.find(link, "(item:%d+:%d+:%d+:%d+)");
    local itemID = core.split(':', itemLink)
    itemID = core.int(itemID[2])
    local _, _, q, iLevel, _, _, t2, _, equip_slot = GetItemInfo(itemLink)
    local votedItemType = ''

    if t2 then
        if not core.find(core.lower(t2), 'misc', 1, true)
                and not core.find(core.lower(t2), 'shields', 1, true) then
            votedItemType = votedItemType .. t2
        end
    end

    if equip_slot then
        votedItemType = core.getEquipSlot(equip_slot) .. " " .. votedItemType
    end

    if core.find(votedItemType, 'Relic', 1, true) then

        if t2 == 'Idols' then
            votedItemType = "Druid" .. votedItemType
        end
        if t2 == 'Librams' then
            votedItemType = "Paladin" .. votedItemType
        end
        if t2 == 'Sigils' then
            votedItemType = "Deathknight" .. votedItemType
        end
        if t2 == 'Totems' then
            votedItemType = "Shaman" .. votedItemType
        end
        votedItemType = core.gsub(votedItemType, "Relic", "")
        votedItemType = core.sub(votedItemType, 1, core.len(votedItemType) - 1)
    end

    if core.find(votedItemType, 'Cloak Cloth', 1, true) then
        votedItemType = 'Cloak'
    end

    if core.find(votedItemType, 'Junk', 1, true) then
        votedItemType = 'Token'
        for tokenId, tokenData in next, tokenRewards do
            if itemID == tokenId and tokenData.rewards then
                votedItemType = votedItemType .. " for " .. tokenData.classes
                local _, _, qq, il = GetItemInfo(tokenData.rewards[1])
                iLevel = il
                q = qq
                break
            end
        end
    end

    votedItemType = core.fixClassColorsInStr(votedItemType)

    TalcVoteFrameCurrentVotedItemButtonItemLevel:SetText(ITEM_QUALITY_COLORS[q].hex .. iLevel)

    if core.find(votedItemType, 'Quest', 1, true) or core.find(votedItemType, 'Token', 1, true) then
        votedItemType = core.trim(votedItemType) .. ' awards:'
    end

    for i = 1, #self.itemRewardsFrames do
        self.itemRewardsFrames[i]:Hide()
    end

    local showDe = true

    if tokenRewards[itemID] and tokenRewards[itemID].rewards then
        showDe = false
        if not self.itemRewardsFrames[1] then
            self.itemRewardsFrames[1] = CreateFrame("Button", "TALCItemReward1", TalcVoteFrame, 'UIPanelButtonTemplate2')
        end

        _G["TALCItemReward1"]:SetPoint("TOPLEFT", TalcVoteFrameVotedItemType, "TOPRIGHT", 5, 8)

        for i, rewardID in next, tokenRewards[itemID].rewards do
            local _, il, _, _, _, _, _, _, _, tex = GetItemInfo(rewardID)
            if il then

                if not self.itemRewardsFrames[i] then
                    self.itemRewardsFrames[i] = CreateFrame("Button", "TALCItemReward" .. i, TalcVoteFrame, 'UIPanelButtonTemplate2')
                end
                local frame = "TALCItemReward" .. i
                if i > 1 then
                    _G[frame]:SetPoint("TOPLEFT", _G["TALCItemReward" .. (i - 1)], "TOPRIGHT", 1, 0)
                end

                _G[frame]:SetSize(24, 24)

                _G[frame]:SetNormalTexture(tex)
                _G[frame]:SetHighlightTexture(tex)
                _G[frame]:SetPushedTexture(tex)
                _G[frame]:Show()

                core.addButtonOnEnterTooltip(_G[frame], il)

            end
        end
    end

    TalcVoteFrameVotedItemType:SetText(votedItemType)

    if showDe then
        TalcVoteFrameMLToEnchanter:Show()
    else
        TalcVoteFrameMLToEnchanter:Hide()
    end

    self:VoteFrameListUpdate()
end

function TalcFrame:DoneVoting()
    self.doneVoting[self.CurrentVotedItem] = true
    TalcVoteFrameDoneVoting:Disable();
    TalcVoteFrameDoneVotingCheck:Show();
    core.asend("doneVoting;" .. self.CurrentVotedItem)
    self:VoteFrameListUpdate()
end

function TalcFrame:GetPlayerInfo(playerIndexOrName)
    --returns itemIndex, name, need, votes, ci1, ci2, ci3, roll, k, gearscore
    if core.type(playerIndexOrName) == 'string' then
        for k, player in next, self.currentPlayersList do
            if player['name'] == playerIndexOrName then
                return player['itemIndex'], player['name'], player['need'], player['votes'], player['ci1'], player['ci2'], player['ci3'], player['roll'], k, player['gearscore']
            end
        end
    end
    local player = self.currentPlayersList[playerIndexOrName]
    if player then
        return player['itemIndex'], player['name'], player['need'], player['votes'], player['ci1'], player['ci2'], player['ci3'], player['roll'], playerIndexOrName, player['gearscore']
    else
        return false
    end
end

function TalcFrame:ChangePlayerPickTo(playerName, newPick, itemIndex)
    for pIndex, data in next, self.playersWhoWantItems do
        if data['itemIndex'] == itemIndex and data['name'] == playerName then
            self.playersWhoWantItems[pIndex]['need'] = newPick
            break
        end
    end
    if core.isRL() then
        core.asend("changePickTo@" .. playerName .. "@" .. newPick .. "@" .. itemIndex)
    end

    self:VoteFrameListUpdate()
end

function TalcFrame:GetTradableItems()
    local items = {}
    for bag = 0, 4 do
        for slot = 0, GetContainerNumSlots(bag) do
            local itemID = GetContainerItemID(bag, slot)
            if itemID then
                local _, itemLink = GetItemInfo(itemID)

                local tradable, duration = self:IsTradable(bag, slot)

                if tradable then
                    core.insert(items, {
                        itemLink = itemLink,
                        bag = bag,
                        slot = slot,
                        duration = duration
                    })
                end
            end
        end
    end
    return items
end

function TalcFrame:IsTradable(bag, slot)

    GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    GameTooltip:SetBagItem(bag, slot)

    local format = REFUND_TIME_REMAINING --BIND_TRADE_TIME_REMAINING

    for i = 1, GameTooltip:NumLines() do
        if core.find(_G["GameTooltipTextLeft" .. i]:GetText(), core.format(format, ".*")) then
            local _, _, hour = core.find(_G["GameTooltipTextLeft" .. i]:GetText(), "(%d+ hour)");
            local _, _, min = core.find(_G["GameTooltipTextLeft" .. i]:GetText(), "(%d+ min)");
            local _, _, sec = core.find(_G["GameTooltipTextLeft" .. i]:GetText(), "(%d+ sec)");

            local duration = 0 --seconds

            if hour then
                local h = core.split(' ', hour)
                duration = duration + core.int(h[1]) * 3600
            end
            if min then
                local m = core.split(' ', min)
                duration = duration + core.int(m[1]) * 60
            end
            if sec then
                local s = core.split(' ', sec)
                duration = duration + core.int(s[1])
            end

            return true, duration
        end
    end
    GameTooltip:Hide()
    return false, nil
end

function TalcFrame:SendTimersAndButtons()

    -- send button configuration to CLs
    local buttons = ''
    if db['VOTE_CONFIG']['NeedButtons']['BIS'] then
        buttons = buttons .. 'b'
    end
    if db['VOTE_CONFIG']['NeedButtons']['MS'] then
        buttons = buttons .. 'm'
    end
    if db['VOTE_CONFIG']['NeedButtons']['OS'] then
        buttons = buttons .. 'o'
    end
    if db['VOTE_CONFIG']['NeedButtons']['XMOG'] then
        buttons = buttons .. 'x'
    end

    core.asend('Timers:ttn=' .. db['VOTE_TTN'] .. '=ttv=' .. db['VOTE_TTV'] .. '=ttr=' .. db['VOTE_TTR'] .. '=NeedButtons=' .. buttons)
end

function TalcFrame:ReceiveDrag()

    if CursorHasItem() then

        local infoType, id, itemLink = GetCursorInfo()
        if infoType == "item" then

            self:GetTradableItems()

            core.insert(self.bagItems, {
                preloaded = false,
                id = id,
                itemLink = itemLink
            })

            for i, d in next, self.bagItems do
                local name, l, quality, _, _, _, _, _, _, tex = GetItemInfo(d.itemLink)
                if quality >= 0 and not d.preloaded then
                    core.bsend("BULK", "preloadInVoteFrame=" .. i .. "=" .. tex .. "=" .. name .. "=" .. l)
                    d.preloaded = true
                end
            end

        end

    else
        -- load and broadcast logic
        if #self.bagItems > 0 then

            core.SetDynTTN(#self.bagItems)
            core.SetDynTTV(#self.bagItems)
            self.LootCountdown.countDownFrom = db['VOTE_TTN']

            self:SendTimersAndButtons()

            self.LootCountdown:Show()
            core.asend('countdownframe=show')

            local numLootItems = 0
            for i, d in next, self.bagItems do

                local name, l, quality, _, _, _, _, _, _, tex = GetItemInfo(d.itemLink)

                if quality >= 0 then
                    --send to c
                    core.bsend("ALERT", "loot=" .. i .. "=" .. tex .. "=" .. name .. "=" .. l)
                    numLootItems = numLootItems + 1
                end
            end
            core.bsend("ALERT", "doneSending=" .. numLootItems .. "=items")
            TalcVoteFrameMLToWinner:Disable()

            TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()

            TalcVoteFrameRLExtraFrameDragLoot:Disable()
            TalcVoteFrameRLExtraFrameDragLoot:SetText(numLootItems .. " Item(s) sent")

            return
        end
    end

    if #self.bagItems > 0 then
        TalcVoteFrameRLExtraFrameDragLoot:SetText("Send " .. #self.bagItems .. " Item(s)")
    end

    ClearCursor()

end

function Talc_LootHistory_Update()
    local itemOffset = FauxScrollFrame_GetOffset(TalcVoteFrameRaiderDetailsFrameLootHistoryFrameScrollFrame);

    local id = TalcFrame.HistoryId

    TalcFrame.selectedPlayer[TalcFrame.CurrentVotedItem] = _G['TalcVoteFrameContestantFrame' .. id].name

    local totalItems = 0

    local historyPlayerName = _G['TalcVoteFrameContestantFrame' .. id].name
    for _, item in next, db['VOTE_LOOT_HISTORY'] do
        if historyPlayerName == item.player then
            totalItems = totalItems + 1
        end
    end

    for index in next, TalcFrame.lootHistoryFrames do
        TalcFrame.lootHistoryFrames[index]:Hide()
    end

    if totalItems > 0 then

        local index = 0
        for lootTime, item in core.pairsByKeysReverse(db['VOTE_LOOT_HISTORY']) do
            if historyPlayerName == item['player'] then

                index = index + 1

                if index > itemOffset and index <= itemOffset + 11 then

                    if not TalcFrame.lootHistoryFrames[index] then
                        TalcFrame.lootHistoryFrames[index] = CreateFrame('Frame', 'HistoryItem' .. index, TalcVoteFrameRaiderDetailsFrame, 'Talc_HistoryItemTemplate')
                    end

                    TalcFrame.lootHistoryFrames[index]:SetPoint("TOPLEFT", TalcVoteFrameRaiderDetailsFrame, "TOPLEFT", 10, -8 - 22 * (index - itemOffset) - 50)
                    TalcFrame.lootHistoryFrames[index]:Show()

                    local today = ''
                    if date("%d/%m") == date("%d/%m", lootTime) then
                        today = core.classColors['mage'].colorStr
                    end

                    local _, _, itemLink = core.find(item['item'], "(item:%d+:%d+:%d+:%d+)");
                    local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)

                    _G['HistoryItem' .. index .. 'Date']:SetText(core.classColors['rogue'].colorStr .. today .. date("%d/%m", lootTime))
                    _G['HistoryItem' .. index .. 'Item']:SetNormalTexture(tex)
                    _G['HistoryItem' .. index .. 'Item']:SetPushedTexture(tex)
                    core.addButtonOnEnterTooltip(_G['HistoryItem' .. index .. 'Item'], item['item'])
                    _G['HistoryItem' .. index .. 'ItemName']:SetText(item['item'])
                end
            end
        end
    end

    TalcVoteFrameRaiderDetailsFrame:Show()

    -- ScrollFrame update
    FauxScrollFrame_Update(TalcVoteFrameRaiderDetailsFrameLootHistoryFrameScrollFrame, totalItems, 11, 22);
end

function TalcFrame:RaiderDetailsClose()
    if self.selectedPlayer[self.CurrentVotedItem] then
        self.selectedPlayer[self.CurrentVotedItem] = ''
    end
    TalcVoteFrameRaiderDetailsFrame:Hide()
end

function Talc_BuildContestantDropdownMenu()
    local id = ContestantDropdownMenu.currentContestantId
    local separator = {};
    separator.text = ""
    separator.disabled = true

    local title = {};
    title.text = _G['TalcVoteFrameContestantFrame' .. id].name .. ' ' .. _G['TalcVoteFrameContestantFrame' .. id .. 'Need']:GetText()
    title.disabled = false
    title.notCheckable = true
    title.isTitle = true
    UIDropDownMenu_AddButton(title);
    UIDropDownMenu_AddButton(separator);

    local award = {};
    if TalcFrame.VotedItemsFrames[TalcFrame.CurrentVotedItem].awardedTo ~= '' then
        award.text = "Awarded " .. TalcVoteFrameVotedItemName:GetText()
    else
        award.text = "Award " .. TalcVoteFrameVotedItemName:GetText()
    end
    award.disabled = TalcFrame.VotedItemsFrames[TalcFrame.CurrentVotedItem].awardedTo ~= ''
    award.isTitle = false
    award.notCheckable = true
    award.tooltipTitle = 'Award'
    award.tooltipText = 'Send item to player'
    award.justifyH = 'LEFT'
    award.func = function()
        TalcFrame:AwardPlayer(_G['TalcVoteFrameContestantFrame' .. id].name, TalcFrame.CurrentVotedItem)
    end
    UIDropDownMenu_AddButton(award);
    UIDropDownMenu_AddButton(separator);

    local changeToBIS = {}
    changeToBIS.text = "Change to " .. core.needs['bis'].colorStr .. core.needs['bis'].text
    changeToBIS.disabled = _G['TalcVoteFrameContestantFrame' .. id].need == 'bis' or TalcFrame.VotedItemsFrames[TalcFrame.CurrentVotedItem].awardedTo ~= ''
    changeToBIS.isTitle = false
    changeToBIS.notCheckable = true
    changeToBIS.tooltipTitle = 'Change choice'
    changeToBIS.tooltipText = 'Change contestant\'s choice to ' .. core.needs['bis'].colorStr .. core.needs['bis'].text
    changeToBIS.justifyH = 'LEFT'
    changeToBIS.func = function()
        TalcFrame:ChangePlayerPickTo(_G['TalcVoteFrameContestantFrame' .. id].name, 'bis', TalcFrame.CurrentVotedItem)
    end
    UIDropDownMenu_AddButton(changeToBIS);

    local changeToMS = {}
    changeToMS.text = "Change to " .. core.needs['ms'].colorStr .. core.needs['ms'].text
    changeToMS.disabled = _G['TalcVoteFrameContestantFrame' .. id].need == 'ms' or TalcFrame.VotedItemsFrames[TalcFrame.CurrentVotedItem].awardedTo ~= ''
    changeToMS.isTitle = false
    changeToMS.notCheckable = true
    changeToMS.tooltipTitle = 'Change choice'
    changeToMS.tooltipText = 'Change contestant\'s choice to ' .. core.needs['ms'].colorStr .. core.needs['ms'].text
    changeToMS.justifyH = 'LEFT'
    changeToMS.func = function()
        TalcFrame:ChangePlayerPickTo(_G['TalcVoteFrameContestantFrame' .. id].name, 'ms', TalcFrame.CurrentVotedItem)
    end
    UIDropDownMenu_AddButton(changeToMS);

    local changeToOS = {}
    changeToOS.text = "Change to " .. core.needs['os'].colorStr .. core.needs['os'].text
    changeToOS.disabled = _G['TalcVoteFrameContestantFrame' .. id].need == 'os' or TalcFrame.VotedItemsFrames[TalcFrame.CurrentVotedItem].awardedTo ~= ''
    changeToOS.isTitle = false
    changeToOS.notCheckable = true
    changeToOS.tooltipTitle = 'Change choice'
    changeToOS.tooltipText = 'Change contestant\'s choice to ' .. core.needs['os'].colorStr .. core.needs['os'].text
    changeToOS.justifyH = 'LEFT'
    changeToOS.func = function()
        TalcFrame:ChangePlayerPickTo(_G['TalcVoteFrameContestantFrame' .. id].name, 'os', TalcFrame.CurrentVotedItem)
    end
    UIDropDownMenu_AddButton(changeToOS);

    local changeToXMOG = {}
    changeToXMOG.text = "Change to " .. core.needs['xmog'].colorStr .. core.needs['xmog'].text
    changeToXMOG.disabled = _G['TalcVoteFrameContestantFrame' .. id].need == 'xmog' or TalcFrame.VotedItemsFrames[TalcFrame.CurrentVotedItem].awardedTo ~= ''
    changeToXMOG.isTitle = false
    changeToXMOG.notCheckable = true
    changeToXMOG.tooltipTitle = 'Change choice'
    changeToXMOG.tooltipText = 'Change contestant\'s choice to ' .. core.needs['xmog'].colorStr .. core.needs['xmog'].text
    changeToXMOG.justifyH = 'LEFT'
    changeToXMOG.func = function()
        TalcFrame:ChangePlayerPickTo(_G['TalcVoteFrameContestantFrame' .. id].name, 'xmog', TalcFrame.CurrentVotedItem)
    end
    UIDropDownMenu_AddButton(changeToXMOG);

    UIDropDownMenu_AddButton(separator);

    local close = {};
    close.text = "Close"
    close.disabled = false
    close.notCheckable = true
    close.isTitle = false
    UIDropDownMenu_AddButton(close);
end

function TalcFrame:ShowContestantDropdownMenu(id)

    if not core.isRL() then
        return
    end

    ContestantDropdownMenu.currentContestantId = id

    UIDropDownMenu_Initialize(ContestantDropdownMenu, Talc_BuildContestantDropdownMenu, "MENU");
    ToggleDropDownMenu(1, nil, ContestantDropdownMenu, "cursor", 2, 3);
end

function TalcFrame:VoteFrameListUpdate()

    if not self.CurrentVotedItem then
        return false
    end

    self:RefreshContestantsList()
    self:CalculateVotes()
    self:UpdateLCVoters()
    self:CalculateWinner()

    if not self.pickResponses[self.CurrentVotedItem] then
        self.pickResponses[self.CurrentVotedItem] = 0
    end
    if not self.waitResponses[self.CurrentVotedItem] then
        self.waitResponses[self.CurrentVotedItem] = 0
    end

    if self.pickResponses[self.CurrentVotedItem] == core.getNumOnlineRaidMembers() then

        local bis, ms, os, pass, xmog = 0, 0, 0, 0, 0
        for _, pwwi in next, self.playersWhoWantItems do
            if pwwi['itemIndex'] == self.CurrentVotedItem then
                if pwwi['need'] == 'bis' then
                    bis = bis + 1
                elseif pwwi['need'] == 'ms' then
                    ms = ms + 1
                elseif pwwi['need'] == 'os' then
                    os = os + 1
                elseif pwwi['need'] == 'xmog' then
                    xmog = xmog + 1
                elseif pwwi['need'] == 'pass' or pwwi['need'] == 'autopass' then
                    pass = pass + 1
                end
            end
        end

        TalcVoteFrameContestantCount:SetText('Everyone(' .. self.pickResponses[self.CurrentVotedItem]
                .. ') has picked(' .. pass .. ' passes).')
        self.VotedItemsFrames[self.CurrentVotedItem].pickedByEveryone = true
    else
        TalcVoteFrameContestantCount:SetText('Waiting picks ' ..
                self.pickResponses[self.CurrentVotedItem] .. '/' ..
                core.getNumOnlineRaidMembers())
        self.VotedItemsFrames[self.CurrentVotedItem].pickedByEveryone = false
    end

    for _, frame in next, self.contestantsFrames do
        frame:Hide()
    end

    local frameHeight = 23 + 1
    local framesPerPage = core.floor(TalcVoteFrameContestantScrollListFrame:GetHeight() / frameHeight)
    local maxFrames = 40
    FauxScrollFrame_Update(TalcVoteFrameContestantScrollListFrame, maxFrames, framesPerPage, frameHeight);
    local offset = FauxScrollFrame_GetOffset(TalcVoteFrameContestantScrollListFrame)

    local index = 0

    for _ in next, self.currentPlayersList do

        index = index + 1

        if index > offset and index <= offset + framesPerPage then

            if self:GetPlayerInfo(index) then

                if not self.contestantsFrames[index] then
                    self.contestantsFrames[index] = CreateFrame('Frame', 'TalcVoteFrameContestantFrame' .. index, TalcVoteFrameContestantScrollListFrame, 'Talc_ContestantFrame')
                end

                local frame = 'TalcVoteFrameContestantFrame' .. index

                _G[frame]:ClearAllPoints()
                _G[frame]:SetPoint("TOPLEFT", TalcVoteFrameContestantScrollListFrame, 0, 23 - 24 * (index - offset))
                _G[frame]:SetPoint("TOPRIGHT", TalcVoteFrameContestantScrollListFrame, 0, 23 - 24 * (index - offset))
                _G[frame]:SetID(index)

                local ratio = TalcVoteFrame:GetWidth() / 600;
                _G[frame .. 'Name']:SetPoint("LEFT", _G[frame], core.floor(8 * ratio) + 20, 0)
                _G[frame .. 'GearScore']:SetPoint("LEFT", _G[frame], core.floor(100 * ratio) - 5, 0)
                _G[frame .. 'Need']:SetPoint("LEFT", _G[frame], core.floor(165 * ratio) - 5, 0)
                _G[frame .. 'ReplacesItem1']:SetPoint("TOPLEFT", _G[frame], core.floor(225 * ratio) - 5, -2)
                _G[frame .. 'ReplacesItem2']:SetPoint("TOPLEFT", _G[frame], core.floor(225 * ratio) - 5 + 21, -2)
                _G[frame .. 'ReplacesItem3']:SetPoint("TOPLEFT", _G[frame], core.floor(225 * ratio) - 5 + 22 + 20, -2)
                _G[frame .. 'Roll']:SetPoint("LEFT", _G[frame], core.floor(285 * ratio) - 5, 0)
                _G[frame .. 'RollPass']:SetPoint("LEFT", _G[frame], core.floor(285 * ratio), 0)
                _G[frame .. 'RollWinner']:SetPoint("LEFT", _G[frame], core.floor(270 * ratio), -2)
                _G[frame .. 'Votes']:SetPoint("LEFT", _G[frame], core.floor(406 * ratio) - 5, 0)
                _G[frame .. 'VoteButton']:SetPoint("TOPLEFT", _G[frame], core.floor(380 * ratio) - 80, -2)
                _G[frame .. 'CLVote1']:SetPoint("TOPLEFT", _G[frame], core.floor(470 * ratio) - 80, -1)

                _G[frame]:Show()

                local currentItem = {}
                local _, name, need, votes, cv1, cv2, cv3, roll, _, gearscore = self:GetPlayerInfo(index);
                currentItem[1] = cv1
                currentItem[2] = cv2
                currentItem[3] = cv3

                _G[frame].name = name;
                _G[frame].need = need;
                _G[frame].gearscore = gearscore;

                local class = core.getPlayerClass(name)
                local color = core.classColors[class]
                _G[frame]:SetBackdropColor(color.r, color.g, color.b, 0.5)

                _G[frame .. 'Name']:SetText(color.colorStr .. name)
                _G[frame .. 'Need']:SetText(core.needs[need].colorStr .. core.needs[need].text)
                _G[frame .. 'GearScore']:SetText(gearscore)
                _G[frame .. 'RollPass']:Hide()
                _G[frame .. 'Votes']:SetText(votes)
                _G[frame .. 'VoteButton']:SetText('VOTE')
                _G[frame .. 'VoteButtonCheck']:Hide()
                _G[frame .. 'Roll']:SetText()

                if roll == -1 then
                    _G[frame .. 'RollPass']:Show()
                    _G[frame .. 'Roll']:SetText(' -')
                elseif roll == -2 then
                    _G[frame .. 'Roll']:SetText('...')
                elseif roll > 0 then
                    _G[frame .. 'Roll']:SetText(roll)
                end

                if votes == self.currentItemMaxVotes and self.currentItemMaxVotes > 0 then
                    _G[frame .. 'Votes']:SetText('|cff1fba1f' .. votes);
                end

                local canVote = true
                if self.VotedItemsFrames[self.CurrentVotedItem].awardedTo ~= '' or --not awarded
                        self.numPlayersThatWant == 1 or --only one player wants
                        self.VotedItemsFrames[self.CurrentVotedItem].rolled or --item being rolled
                        roll ~= 0 or --waiting rolls
                        self.doneVoting[self.CurrentVotedItem] == true then
                    --doneVoting is pressed
                    canVote = false
                end

                if not self.VoteCountdown.votingOpen then
                    canVote = false
                end

                local voted = false
                if self.itemVotes[self.CurrentVotedItem][name] then
                    if self.itemVotes[self.CurrentVotedItem][name][core.me] then
                        if self.itemVotes[self.CurrentVotedItem][name][core.me] == '+' then
                            voted = true
                        end
                    end
                end

                if canVote then
                    _G[frame .. 'VoteButton']:Enable()
                else
                    _G[frame .. 'VoteButton']:Disable()
                end
                if voted then
                    _G[frame .. 'VoteButtonCheck']:Show()
                    _G[frame .. 'VoteButton']:SetText('')
                else
                    _G[frame .. 'VoteButtonCheck']:Hide()
                    _G[frame .. 'VoteButton']:SetText('VOTE')
                end

                local lastItem = ''
                for lootTime, item in core.pairsByKeysReverse(db['VOTE_LOOT_HISTORY']) do
                    if item.player == name then
                        lastItem = item.item .. '(' .. date("%d/%m", lootTime) .. ')'
                        break
                    end
                end

                _G[frame .. 'RollWinner']:Hide()
                if self.currentMaxRoll[self.CurrentVotedItem] == roll and roll > 0 then
                    _G[frame .. 'RollWinner']:Show()
                end
                _G[frame .. 'WinnerIcon']:Hide();
                if self.VotedItemsFrames[self.CurrentVotedItem].awardedTo == name then
                    _G[frame .. 'WinnerIcon']:Show()
                end

                --hide all CL icons / tooltip buttons
                for w = 1, 10 do
                    _G[frame .. 'CLVote' .. w]:Hide()
                end
                if self.itemVotes[self.CurrentVotedItem][name] then
                    local w = 0
                    for voter, vote in next, self.itemVotes[self.CurrentVotedItem][name] do
                        if vote == '+' then
                            w = w + 1
                            local voterClass = core.getPlayerClass(voter)
                            local texture = "Interface\\AddOns\\Talc\\images\\classes\\" .. voterClass

                            _G[frame .. 'CLVote' .. w]:SetNormalTexture(texture)
                            _G[frame .. 'CLVote' .. w]:SetID(w)
                            _G[frame .. 'CLVote' .. w]:Show()

                            -- add tooltips
                            local tooltipNames = {}
                            tooltipNames[w] = voter;

                            local CLIconButton = _G[frame .. 'CLVote' .. w]

                            CLIconButton:SetScript("OnEnter", function(self)
                                GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -(this:GetWidth() / 4), -(this:GetHeight() / 4));
                                GameTooltip:AddLine(core.classColors[core.getPlayerClass(tooltipNames[this:GetID()])].colorStr .. tooltipNames[this:GetID()])
                                GameTooltip:Show();
                            end)

                            CLIconButton:SetScript("OnLeave", function(self)
                                GameTooltip:Hide();
                            end)
                        end
                    end
                end

                _G[frame .. 'VoteButton']:SetID(index);

                _G[frame .. 'ClassIcon']:SetTexture('Interface\\AddOns\\Talc\\images\\classes\\' .. class);

                _G[frame .. 'VoteButton']:Show();
                if need == 'pass' or need == 'autopass' or need == 'wait' then
                    _G[frame .. 'VoteButton']:Hide();
                end

                for i = 1, 3 do
                    if currentItem[i] ~= "0" then
                        local _, _, itemLink = core.find(currentItem[i], "(item:%d+:%d+:%d+:%d+)");
                        local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)

                        if not tex then
                            tex = 'Interface\\Icons\\INV_Misc_QuestionMark'
                        end

                        _G[frame .. 'ReplacesItem' .. i]:SetNormalTexture(tex)
                        _G[frame .. 'ReplacesItem' .. i]:SetPushedTexture(tex)
                        core.addButtonOnEnterTooltip(_G[frame .. 'ReplacesItem' .. i], itemLink)
                        _G[frame .. 'ReplacesItem' .. i]:Show()
                    else
                        _G[frame .. 'ReplacesItem' .. i]:Hide()
                    end
                end

            end
        end
    end

    if self.doneVoting[self.CurrentVotedItem] then
        TalcVoteFrameDoneVoting:Disable()
        TalcVoteFrameDoneVotingCheck:Show()
    else
        if self.pickResponses[self.CurrentVotedItem] then
            if self.pickResponses[self.CurrentVotedItem] > 1 then
                TalcVoteFrameDoneVoting:Enable()
                TalcVoteFrameDoneVotingCheck:Hide()
            else
                TalcVoteFrameDoneVoting:Disable()
                TalcVoteFrameDoneVotingCheck:Hide()
            end
        else
            TalcVoteFrameDoneVoting:Disable()
            TalcVoteFrameDoneVotingCheck:Hide()
        end
    end

    self:UpdateCLVotedButtons()

end

function TalcFrame:updateVotedItemsFrames()
    for index, _ in next, self.VotedItemsFrames do
        _G['VotedItem' .. index .. 'VotedItemButtonCheck']:Hide()
        if self.VotedItemsFrames[index].awardedTo ~= '' then
            _G['VotedItem' .. index .. 'VotedItemButtonCheck']:Show()
        end
    end

    self:VoteFrameListUpdate()
end

function TalcFrame:handleSync(pre, t, ch, sender)
    talc_debug(sender .. ' says: ' .. t)

    if core.find(t, 'boss&', 1, true) then
        if not core.canVote() then
            return false
        end
        if not core.isRL(sender) then
            return false
        end

        local bossName = core.split('&', t)
        if not bossName[2] then
            return false
        end

        self:SetTitle(bossName[2])
        return
    end

    if core.find(t, 'doneSending=', 1, true) and core.canVote() then
        if not core.isRL(sender) then
            return false
        end
        local nrItems = core.split('=', t)
        if not nrItems[2] or not nrItems[3] then
            talc_error('wrong doneSending syntax')
            talc_error(t)
            return false
        end
        TalcVoteFrameContestantCount:SetText('Loot sent. Waiting picks...')
        core.asend("CLreceived=" .. self.numItems .. "=items")
        return
    end

    if core.sub(t, 1, 11) == 'CLreceived=' then
        if not core.isRL() then
            return
        end

        local nrItems = core.split('=', t)
        if not nrItems[2] or not nrItems[3] then
            talc_error('wrong CLreceived syntax')
            talc_error(t)
            return false
        end

        if core.int(nrItems[2]) ~= self.numItems then
            talc_error('Officer ' .. sender .. ' got ' .. nrItems[2] .. '/' .. self.numItems .. ' items.')
        end
        return
    end

    if core.sub(t, 1, 9) == 'received=' then
        if not core.canVote() then
            return
        end

        local nrItems = core.split('=', t)
        if not nrItems[2] or not nrItems[3] then
            talc_error('wrong received syntax')
            talc_error(t)
            return false
        end

        if core.int(nrItems[2]) ~= self.numItems then
            talc_error('Player ' .. sender .. ' got ' .. nrItems[2] .. '/' .. self.numItems .. ' items.')
        else
            self.receivedResponses = self.receivedResponses + 1
        end
        return
    end

    if core.find(t, 'playerRoll:', 1, true) then

        if not core.isRL(sender) or sender == core.me then
            return
        end
        if not core.canVote() then
            return
        end

        local indexEx = core.split(':', t)

        if not indexEx[2] or not indexEx[3] then
            talc_error('bad playerRoll syntax')
            talc_error(t)
            return false
        end
        if not core.int(indexEx[3]) then
            return false
        end

        self.playersWhoWantItems[core.int(indexEx[2])]['roll'] = core.int(indexEx[3])
        self.VotedItemsFrames[core.int(indexEx[4])].rolled = true
        self:VoteFrameListUpdate()
        return
    end

    if core.find(t, 'changePickTo@', 1, true) then

        if not core.isRL(sender) or sender == core.me then
            return
        end
        if not core.canVote() then
            return
        end

        local pickEx = core.split('@', t)
        if not pickEx[2] or not pickEx[3] or not pickEx[4] then
            talc_error('bad changePick syntax')
            talc_error(t)
            return
        end

        if not core.int(pickEx[4]) then
            talc_error('bad changePick itemIndex')
            talc_error(t)
            return
        end

        self:ChangePlayerPickTo(pickEx[2], pickEx[3], core.int(pickEx[4]))
        return
    end

    if core.find(t, 'rollChoice=', 1, true) then

        if not core.canVote() then
            return
        end

        local r = core.split('=', t)
        if not r[2] or not r[3] then
            talc_debug('bad rollChoice syntax')
            talc_debug(t)
            return
        end

        if core.int(r[3]) == -1 then

            local name = sender
            local roll = core.int(r[3])

            for pwIndex, pwPlayer in next, self.playersWhoWantItems do
                if pwPlayer['name'] == name and pwPlayer['roll'] == -2 then
                    self.playersWhoWantItems[pwIndex]['roll'] = roll
                    self:updateVotedItemsFrames()
                    break
                end
            end
        else
            talc_debug('ROLLCATCHER ' .. sender .. ' rolled for ' .. r[2])
        end
        return
    end

    if core.find(t, 'itemVote:', 1, true) then

        if not core.canVote(sender) or sender == core.me then
            return
        end
        if not core.canVote() then
            return
        end

        local itemVoteEx = core.split(':', t)

        if not itemVoteEx[2] or not itemVoteEx[3] or not itemVoteEx[4] then
            talc_error('bad itemVote syntax')
            talc_error(t)
            return false
        end

        local votedItem = core.int(itemVoteEx[2])
        local votedPlayer = itemVoteEx[3]
        local vote = itemVoteEx[4]
        if not self.itemVotes[votedItem][votedPlayer] then
            self.itemVotes[votedItem][votedPlayer] = {}
        end
        self.itemVotes[votedItem][votedPlayer][sender] = vote
        self:VoteFrameListUpdate()
        return
    end

    if core.find(t, 'doneVoting;', 1, true) then
        if not core.canVote(sender) or not core.canVote() then
            return
        end

        local itemEx = core.split(';', t)
        if not itemEx[2] then
            talc_error('bad doneVoting syntax')
            talc_error(t)
            return
        end

        if not self.clDoneVotingItem[sender] then
            self.clDoneVotingItem[sender] = {}
        end
        self.clDoneVotingItem[sender][core.int(itemEx[2])] = true

        self:VoteFrameListUpdate()
        return
    end

    if core.find(t, 'versionQuery=', 1, true) then
        core.asend("versionReplay=" .. sender .. "=" .. core.addonVer)
        return
    end

    if core.find(t, 'versionReplay=', 1, true) then
        local i = core.split("=", t)
        if i[2] == core.me then
            if i[3] then
                local verColor = ''
                local ver = i[3]
                if core.ver(ver) == core.ver(core.addonVer) then
                    verColor = core.classColors['hunter'].colorStr
                end
                if core.ver(ver) < core.ver(core.addonVer) then
                    verColor = '|cffff1111'
                end
                if core.ver(ver) + 1 == core.ver(core.addonVer) then
                    verColor = '|cffff8810'
                end

                self.withAddon[sender].v = verColor .. ver

                self:updateWithAddon()
            end
        end
        return
    end

    if core.find(t, 'voteframe=', 1, true) then
        local command = core.split('=', t)

        if not command[2] then
            talc_error('bad voteframe syntax')
            talc_error(t)
            return
        end

        if not core.isRL(sender) or not core.canVote() then
            return
        end

        if command[2] == "reset" then
            self:ResetVars()
        end
        if command[2] == "close" then
            self:CloseWindow()
        end
        if command[2] == "show" then
            self:showWindow()
        end
        return
    end

    if core.find(t, 'preloadInVoteFrame=', 1, true) then

        if not core.isRL(sender) then
            return
        end

        local item = core.split("=", t)

        if not item[2] or not item[3] or not item[4] or not item[5] then
            talc_error('bad loot syntax')
            talc_error(t)
            return
        end

        if not core.int(item[2]) then
            talc_error('bad loot index')
            talc_error(t)
            return
        end

        self.numItems = self.numItems + 1

        local index = core.int(item[2])
        local texture = item[3]
        local link = item[5]
        self:addVotedItem(index, texture, link)

        self:HideWelcomeScreen()
        self:HideSettingsScreen()
        self:ShowVotingElements()

        return
    end

    if core.find(t, 'countdownframe=', 1, true) then

        if not core.isRL(sender) or not core.canVote() then
            return
        end

        local action = core.split("=", t)

        if not action[2] then
            talc_error('bad countdownframe syntax')
            talc_error(t)
            return
        end

        if action[2] == 'show' then
            self.LootCountdown:Show()
        end
        return
    end
    --ms=1=item:123=item:323
    if core.sub(t, 1, 4) == 'bis='
            or core.sub(t, 1, 3) == 'ms='
            or core.sub(t, 1, 3) == 'os='
            or core.sub(t, 1, 5) == 'xmog='
            or core.sub(t, 1, 5) == 'pass='
            or core.sub(t, 1, 9) == 'autopass=' then

        if core.canVote() then

            local needEx = core.split('=', t)

            if not needEx[2] or not needEx[3] or not needEx[4] or not needEx[5] or not needEx[6] then
                talc_error('bad need syntax')
                talc_error(t)
                return false
            end

            if core.sub(t, 1, 9) == 'autopass=' then
                return false
            end

            if #self.playersWhoWantItems > 0 then
                for i = 1, #self.playersWhoWantItems do
                    if self.playersWhoWantItems[i].itemIndex == core.int(needEx[2]) and
                            self.playersWhoWantItems[i].name == sender then
                        return
                    end
                end
            end

            if self.waitResponses[core.int(needEx[2])] then
                self.waitResponses[core.int(needEx[2])] = self.waitResponses[core.int(needEx[2])] + 1
            else
                self.waitResponses[core.int(needEx[2])] = 1
            end

            core.insert(self.playersWhoWantItems, {
                itemIndex = core.int(needEx[2]),
                name = sender,
                need = 'wait',
                ci1 = needEx[3],
                ci2 = needEx[4],
                ci3 = needEx[5],
                votes = 0,
                roll = 0,
                gearscore = core.int(needEx[6])
            })

            self.itemVotes[core.int(needEx[2])] = {}
            self.itemVotes[core.int(needEx[2])][sender] = {}

            if self.pickResponses[core.int(needEx[2])] then
                if self.pickResponses[core.int(needEx[2])] < self.waitResponses[core.int(needEx[2])] then
                    self.pickResponses[core.int(needEx[2])] = self.pickResponses[core.int(needEx[2])] + 1
                end
            else
                self.pickResponses[core.int(needEx[2])] = 1
            end

            for index, player in next, self.playersWhoWantItems do
                if player.name == sender and player.itemIndex == core.int(needEx[2]) then
                    self.playersWhoWantItems[index].need = needEx[1]
                    self.playersWhoWantItems[index].ci1 = needEx[3]
                    self.playersWhoWantItems[index].ci2 = needEx[4]
                    self.playersWhoWantItems[index].ci3 = needEx[5]
                    break
                end
            end

            self:VoteFrameListUpdate()
        else
            self:CloseWindow()
        end
        return
    end

    -- roster sync
    if core.find(t, 'syncRoster=', 1, true) then
        if not core.isRL(sender) then
            return
        end
        if sender == core.me and t == 'syncRoster=end' then
            TalcVoteFrameRLExtraFrameBroadcastLoot:SetText('Send Loot (' .. db['VOTE_TTN'] .. 's)')
            TalcVoteFrameRLExtraFrameBroadcastLoot:Enable()
            return
        end
        if sender == core.me then
            return
        end

        local command = core.split('=', t)

        if not command[2] then
            talc_error('bad syncRoster syntax')
            talc_error(t)
            return false
        end

        if command[2] == "start" then
            self.NEW_ROSTER = {}
        elseif command[2] == "end" then
            db['VOTE_ROSTER'] = self.NEW_ROSTER
            talc_print('Roster updated.')
        else
            self.NEW_ROSTER[command[2]] = false
        end
        return
    end

    --using playerWon instead, to let other CL know who got loot
    if core.find(t, 'playerWon#', 1, true) then
        if not core.canVote(sender) then
            return
        end
        local wonData = core.split("#", t) --playerWon#unitName#link#votedItem

        if not wonData[2] or not wonData[3] then
            talc_error('bad playerWon syntax')
            talc_error(t)
            return false
        end

        self.VotedItemsFrames[core.int(wonData[3])].awardedTo = wonData[2]
        self:updateVotedItemsFrames()

        --save loot in history
        db['VOTE_LOOT_HISTORY'][time()] = {
            class = core.getPlayerClass(wonData[2]),
            player = wonData[2],
            item = self.VotedItemsFrames[core.int(wonData[3])].link
        }
        return
    end

    if core.find(t, 'Timers:ttn', 1, true) then
        if not core.isRL(sender) then
            return
        end

        local data = core.split("=", t)

        if not data[8] then
            talc_error('bad timers syntax')
            talc_error(t)
            return
        end

        db['VOTE_TTN'] = core.int(data[2]) --might be useless ?
        self.LootCountdown.countDownFrom = db['VOTE_TTN']

        db['VOTE_TTV'] = core.int(data[4])
        self.VoteCountdown.countDownFrom = db['VOTE_TTV']

        db['VOTE_TTR'] = core.int(data[6])

        db['VOTE_CONFIG']['NeedButtons']['BIS'] = core.find(data[8], 'b', 1, true) ~= nil
        db['VOTE_CONFIG']['NeedButtons']['MS'] = core.find(data[8], 'm', 1, true) ~= nil
        db['VOTE_CONFIG']['NeedButtons']['OS'] = core.find(data[8], 'o', 1, true) ~= nil
        db['VOTE_CONFIG']['NeedButtons']['XMOG'] = core.find(data[8], 'x', 1, true) ~= nil
        return
    end

    if core.find(t, 'withAddonVF=', 1, true) then
        local n = core.split("=", t)

        if not n[4] then
            talc_error('bad withAddonVF syntax')
            talc_error(t)
            return false
        end

        if n[2] == core.me then
            --i[2] = who requested the who
            local verColor = ""
            if core.ver(n[4]) == core.ver(core.addonVer) then
                verColor = core.classColors['hunter'].colorStr
            end
            if core.ver(n[4]) < core.ver(core.addonVer) then
                verColor = '|cffff222a'
            end
            local star = ' '
            if core.len(n[4]) < 7 then
                n[4] = '0.' .. n[4]
            end
            if core.isRLorAssist(sender) then
                star = '*'
            end
            self.peopleWithAddon = self.peopleWithAddon .. star ..
                    core.classColors[core.getPlayerClass(sender)].colorStr ..
                    sender .. ' ' .. verColor .. n[4] .. '\n'
            TalcVoteFrameWhoTitle:SetText('TALC With Addon')
            TalcVoteFrameWhoText:SetText(self.peopleWithAddon)
        end
        return
    end

    if core.find(t, 'loot_history_sync;', 1, true) then

        if core.isRL(sender) and sender == core.me and t == 'loot_history_sync;end' then
            talc_print('History Sync complete.')
            TalcVoteFrameRLWindowFrameTab2ContentsSyncLootHistory:Enable()
        end

        if not core.isRL(sender) or sender == core.me then
            return
        end
        local lh = core.split(";", t)

        if not lh[2] or not lh[3] or not lh[4] or not lh[5] then
            if t ~= 'loot_history_sync;start' and t ~= 'loot_history_sync;end' then
                talc_error('bad loot_history_sync syntax')
                talc_error(t)
                return false
            end
        end

        if lh[2] == 'start' then
        elseif lh[2] == 'end' then
            talc_debug('loot history synced.')
        else
            db['VOTE_LOOT_HISTORY'][core.int(lh[2])] = {
                class = core.getPlayerClass(lh[3]),
                player = lh[3],
                item = lh[4],
            }
        end
        return
    end

    if core.find(t, 'sending=gear', 1, true) then

        if core.find(t, '=start', 1, true) then
            self.inspectPlayerGear[sender] = {}
            return
        end

        if core.find(t, '=end', 1, true) then
            self:RaiderDetailsShowGear()
            return
        end

        local tEx = core.split('=', t)
        local gearEx = core.split(':', tEx[3])

        self.inspectPlayerGear[sender][core.int(gearEx[6])] = {
            item = gearEx[1] .. ":" .. gearEx[2] .. ":" .. gearEx[3] .. ":" .. gearEx[4] .. ":" .. gearEx[5],
            slot = gearEx[7]
        }

        return
    end
end

function TalcFrame:RefreshContestantsList()
    --getto ordering
    local tempTable = self.playersWhoWantItems
    self.playersWhoWantItems = {}
    local j = 0
    for _, d in next, tempTable do
        if d.need == 'bis' then
            j = j + 1
            self.playersWhoWantItems[j] = d
        end
    end
    for _, d in next, tempTable do
        if d.need == 'ms' then
            j = j + 1
            self.playersWhoWantItems[j] = d
        end
    end
    for _, d in next, tempTable do
        if d.need == 'os' then
            j = j + 1
            self.playersWhoWantItems[j] = d
        end
    end
    for _, d in next, tempTable do
        if d.need == 'xmog' then
            j = j + 1
            self.playersWhoWantItems[j] = d
        end
    end
    for _, d in next, tempTable do
        if d.need == 'pass' then
            j = j + 1
            self.playersWhoWantItems[j] = d
        end
    end
    for _, d in next, tempTable do
        if d.need == 'autopass' then
            j = j + 1
            self.playersWhoWantItems[j] = d
        end
    end
    for _, d in next, tempTable do
        if d.need == 'wait' then
            j = j + 1
            self.playersWhoWantItems[j] = d
        end
    end
    -- sort
    self.currentPlayersList = {}
    for i = 1, #self.contestantsFrames do
        _G['TalcVoteFrameContestantFrame' .. i]:Hide();
    end
    for pIndex, data in next, self.playersWhoWantItems do
        if data.itemIndex == self.CurrentVotedItem then
            core.insert(self.currentPlayersList, self.playersWhoWantItems[pIndex])
        end
    end
end

function TalcFrame:VoteButton(id)
    local _, name = self:GetPlayerInfo(id)

    if not self.itemVotes[self.CurrentVotedItem][name] then
        self.itemVotes[self.CurrentVotedItem][name] = {
            [core.me] = '+'
        }
        core.asend("itemVote:" .. self.CurrentVotedItem .. ":" .. name .. ":+")
    else
        if self.itemVotes[self.CurrentVotedItem][name][core.me] == '+' then
            self.itemVotes[self.CurrentVotedItem][name][core.me] = '-'
            core.asend("itemVote:" .. self.CurrentVotedItem .. ":" .. name .. ":-")
        else
            self.itemVotes[self.CurrentVotedItem][name][core.me] = '+'
            core.asend("itemVote:" .. self.CurrentVotedItem .. ":" .. name .. ":+")
        end
    end

    self:VoteFrameListUpdate()
end

function TalcFrame:CalculateVotes()

    --init votes to 0
    for _, list in next, self.currentPlayersList do
        list.votes = 0
    end

    if self.CurrentVotedItem ~= nil then
        for n, _ in next, self.itemVotes[self.CurrentVotedItem] do
            if self:GetPlayerInfo(n) then
                local _, _, _, _, _, _, _, _, pIndex = TalcFrame:GetPlayerInfo(n)
                for _, vote in next, self.itemVotes[self.CurrentVotedItem][n] do
                    if vote == '+' then
                        self.currentPlayersList[pIndex].votes = self.currentPlayersList[pIndex].votes + 1
                    end
                end
            else
                talc_error('TalcFrame:GetPlayerInfo(' .. n .. ') Not Found. Please report this.')
            end
        end
    end
end

function TalcFrame:CalculateWinner()

    if not self.CurrentVotedItem then
        return false
    end

    self.currentRollWinner = ''
    self.currentMaxRoll[self.CurrentVotedItem] = 0

    for _, d in next, self.currentPlayersList do
        if d.itemIndex == self.CurrentVotedItem and d.roll > 0 and d.roll > self.currentMaxRoll[self.CurrentVotedItem] then
            self.currentMaxRoll[self.CurrentVotedItem] = d.roll
            self.currentRollWinner = d.name
        end
    end

    if self.VotedItemsFrames[self.CurrentVotedItem].awardedTo ~= '' then
        TalcVoteFrameMLToWinner:Disable();
        local color = core.classColors[core.getPlayerClass(self.VotedItemsFrames[self.CurrentVotedItem].awardedTo)]
        TalcVoteFrameMLToWinner:SetText('Awarded to ' .. color.colorStr .. self.VotedItemsFrames[self.CurrentVotedItem].awardedTo);
        TalcVoteFrameWinnerStatus:SetText('Awarded to ' .. color.colorStr .. self.VotedItemsFrames[self.CurrentVotedItem].awardedTo);
        return
    end

    -- roll tie detection
    local rollTie = 0
    for _, d in next, self.currentPlayersList do
        if d.itemIndex == self.CurrentVotedItem and d.roll > 0 and d.roll == self.currentMaxRoll[self.CurrentVotedItem] then
            rollTie = rollTie + 1
        end
    end

    if rollTie ~= 0 then
        if rollTie == 1 then
            TalcVoteFrameMLToWinner:Enable();
            local color = core.classColors[core.getPlayerClass(self.currentRollWinner)]
            TalcVoteFrameMLToWinner:SetText('Award ' .. color.colorStr .. self.currentRollWinner);
            TalcVoteFrameWinnerStatus:SetText('Winner: ' .. color.colorStr .. self.currentRollWinner);

            self.currentItemWinner = self.currentRollWinner
            self.voteTiePlayers = ''
        else
            TalcVoteFrameMLToWinner:Enable()
            TalcVoteFrameMLToWinner:SetText('ROLL VOTE TIE')
            TalcVoteFrameWinnerStatus:SetText('VOTE TIE')
        end
        return
    else

        -- calc vote winner
        self.currentItemWinner = ''
        self.currentItemMaxVotes = 0
        self.voteTiePlayers = '';
        self.numPlayersThatWant = 0
        self.namePlayersThatWants = ''
        for _, d in next, self.currentPlayersList do
            if d.itemIndex == self.CurrentVotedItem then

                -- calc winner if only one exists with bis, ms, os, xmog
                if d.need == 'bis' or d.need == 'ms' or d.need == 'os' or d.need == 'xmog' then
                    self.numPlayersThatWant = self.numPlayersThatWant + 1
                    self.namePlayersThatWants = d.name
                end

                if d.votes > 0 and d.votes > self.currentItemMaxVotes then
                    self.currentItemMaxVotes = d.votes
                    self.currentItemWinner = d.name
                end
            end
        end

        if self.numPlayersThatWant == 1 then
            self.currentItemWinner = self.namePlayersThatWants
            TalcVoteFrameMLToWinner:Enable();
            local color = core.classColors[core.getPlayerClass(self.currentItemWinner)]
            TalcVoteFrameMLToWinner:SetText('Award single picker ' .. color.colorStr .. self.currentItemWinner);
            TalcVoteFrameWinnerStatus:SetText('Single picker ' .. color.colorStr .. self.currentItemWinner);
            return
        end

        --    talc_debug('maxVotes = ' .. maxVotes)
        --tie check
        local ties = 0
        for _, d in next, self.currentPlayersList do
            if d.itemIndex == self.CurrentVotedItem then
                if d.votes == self.currentItemMaxVotes and self.currentItemMaxVotes > 0 then
                    self.voteTiePlayers = self.voteTiePlayers .. d.name .. ' '
                    ties = ties + 1
                end
            end
        end
        self.voteTiePlayers = core.trim(self.voteTiePlayers)

        if ties > 1 then
            TalcVoteFrameMLToWinner:Enable()
            TalcVoteFrameMLToWinner:SetText('ROLL VOTE TIE') -- .. voteTies
            TalcVoteFrameWinnerStatus:SetText('VOTE TIE') -- .. voteTies
        else
            --no tie
            self.voteTiePlayers = ''
            if self.currentItemWinner ~= '' then
                TalcVoteFrameMLToWinner:Enable();
                local color = core.classColors[core.getPlayerClass(self.currentItemWinner)]
                TalcVoteFrameMLToWinner:SetText('Award ' .. color.colorStr .. self.currentItemWinner);
                TalcVoteFrameWinnerStatus:SetText('Winner: ' .. color.colorStr .. self.currentItemWinner);
            else
                TalcVoteFrameMLToWinner:Disable()
                TalcVoteFrameMLToWinner:SetText('Waiting votes...')
                TalcVoteFrameWinnerStatus:SetText('Waiting votes...')
            end
        end
    end
end

function TalcFrame:UpdateLCVoters()

    if not self.CurrentVotedItem then
        return false
    end

    if not self.CLVoted[self.CurrentVotedItem] then
        self.CLVoted[self.CurrentVotedItem] = {}
    end

    -- reset
    local nr = 0
    for officer, _ in next, db['VOTE_ROSTER'] do
        self.CLVoted[self.CurrentVotedItem][officer] = false
    end
    for n, _ in next, self.itemVotes[self.CurrentVotedItem] do
        for voter, vote in next, self.itemVotes[self.CurrentVotedItem][n] do
            for officer, _ in next, db['VOTE_ROSTER'] do
                if voter == officer and vote == '+' then
                    self.CLVoted[self.CurrentVotedItem][officer] = true
                    nr = nr + 1
                end
            end
        end
    end

    for officer, voted in next, self.CLVoted[self.CurrentVotedItem] do
        if not voted then
            --check if he clicked done voting for this itme
            if self.clDoneVotingItem[officer] then
                for itemIndex, doneVoting in next, self.clDoneVotingItem[officer] do
                    if itemIndex == self.CurrentVotedItem and doneVoting then
                        nr = nr + 1
                    end
                end
            end
        end
    end

    local numOfficersInRaid = 0
    for officer in next, db['VOTE_ROSTER'] do
        if core.onlineInRaid(officer) then
            numOfficersInRaid = numOfficersInRaid + 1
        end
    end

    if nr == numOfficersInRaid then
        TalcVoteFrameMLToWinnerNrOfVotes:SetText('|cff1fba1fEveryone voted!')
        TalcVoteFrameWinnerStatusNrOfVotes:SetText('|cff1fba1fEveryone voted!')
        TalcVoteFrameMLToWinner:Enable()
        TalcVoteFrameVotesLabel:SetText('Votes |cff1fba1f' .. nr .. '/' .. numOfficersInRaid);
    elseif nr >= core.floor(numOfficersInRaid / 2) then
        TalcVoteFrameVotesLabel:SetText('Votes |cfffff569' .. nr .. '/' .. numOfficersInRaid);
    else
        TalcVoteFrameMLToWinnerNrOfVotes:SetText('|cffa53737' .. nr .. '/' .. numOfficersInRaid .. ' votes')
        TalcVoteFrameWinnerStatusNrOfVotes:SetText('|cffa53737' .. nr .. '/' .. numOfficersInRaid .. ' votes')
        TalcVoteFrameVotesLabel:SetText('Votes |cffa53737' .. nr .. '/' .. numOfficersInRaid);
    end
end

function TalcFrame:MLToWinner()
    --    talc_debug(self.voteTiePlayers)
    if self.voteTiePlayers ~= '' then
        self.VotedItemsFrames[self.CurrentVotedItem].rolled = true
        local players = core.split(' ', self.voteTiePlayers)
        for _, d in next, self.currentPlayersList do
            for _, tieName in next, players do
                if d.itemIndex == self.CurrentVotedItem and d.name == tieName then

                    local linkString = self.VotedItemsFrames[self.CurrentVotedItem].link
                    local _, _, itemLink = core.find(linkString, "(item:%d+:%d+:%d+:%d+)");
                    local name, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)

                    for pwIndex, pwPlayer in next, self.playersWhoWantItems do
                        if pwPlayer.name == tieName and pwPlayer.itemIndex == self.CurrentVotedItem then
                            self.playersWhoWantItems[pwIndex].roll = -2
                            --send to officers
                            core.asend("playerRoll:" .. pwIndex .. ":-2:" .. self.CurrentVotedItem)
                            --send to raiders
                            core.asend('rollFor=' .. self.CurrentVotedItem .. '=' .. tex .. '=' .. name .. '=' .. linkString .. '=' .. tieName)
                            break
                        end
                    end
                end
            end
        end
        TalcVoteFrameMLToWinner:Disable();
        self:VoteFrameListUpdate()
    else
        self:AwardPlayer(self.currentItemWinner, self.CurrentVotedItem)
    end
end

function TalcFrame:MLToEnchanter()
    if db['VOTE_ENCHANTER'] == nil then
        talc_print('Enchanter not set. Use /talc set enchanter [name] to set it.')
        return false;
    end

    local foundInRaid = false

    for i = 0, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) then
            local n = GetRaidRosterInfo(i);
            if n == db['VOTE_ENCHANTER'] then
                foundInRaid = true
            end
        end
    end
    if not foundInRaid then
        talc_print('Enchanter ' .. db['VOTE_ENCHANTER'] .. ' is not in raid. Use /talc set enchanter [name] to set a new one.')
        return false;
    end
    for i = 0, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) then
            local n, _, _, _, _, _, z = GetRaidRosterInfo(i);
            if n == db['VOTE_ENCHANTER'] and z == 'Offline' then
                talc_print('Enchanter ' .. db['VOTE_ENCHANTER'] .. ' is offline. Use /talc set enchanter [name] to set a new one.')
                return
            end
        end
    end
    self:AwardPlayer(db['VOTE_ENCHANTER'], self.CurrentVotedItem, true)
end

function TalcFrame:ContestantClick(id)

    local playerOffset = FauxScrollFrame_GetOffset(TalcVoteFrameRaiderDetailsFrameLootHistoryFrameScrollFrame);
    id = id - playerOffset

    if arg1 == 'RightButton' then
        self:ShowContestantDropdownMenu(id)
        return
    end

    if TalcVoteFrameRaiderDetailsFrame:IsVisible() and self.selectedPlayer[self.CurrentVotedItem] == _G['TalcVoteFrameContestantFrame' .. id].name then
        self:RaiderDetailsClose()
    else
        self.selectedPlayer[self.CurrentVotedItem] = _G['TalcVoteFrameContestantFrame' .. id].name
        if not self.inspectPlayerGear[self.selectedPlayer[self.CurrentVotedItem]] then
            self.inspectPlayerGear[self.selectedPlayer[self.CurrentVotedItem]] = {}
        end
        self.HistoryId = id
        local totalItems = 0
        for _, item in next, db['VOTE_LOOT_HISTORY'] do
            if _G['TalcVoteFrameContestantFrame' .. id].name == item.player then
                totalItems = totalItems + 1
            end
        end
        self:RaiderDetailsChangeTab(1, _G['TalcVoteFrameContestantFrame' .. id].name);
    end
end

function TalcFrame:ContestantOnEnter()
    local frame = _G['TalcVoteFrameContestantFrame' .. this:GetID()]
    local r, g, b = frame:GetBackdropColor()
    frame:SetBackdropColor(r, g, b, 1)
end

function TalcFrame:ContestantOnLeave()
    for i = 1, #self.contestantsFrames do
        local r, g, b = _G['TalcVoteFrameContestantFrame' .. i]:GetBackdropColor()
        if self.selectedPlayer[self.CurrentVotedItem] ~= _G['TalcVoteFrameContestantFrame' .. i].name then
            _G['TalcVoteFrameContestantFrame' .. i]:SetBackdropColor(r, g, b, 0.5)
        end
    end
end

function TalcFrame:AwardPlayer(playerName, cvi, disenchant)

    if not playerName or playerName == '' then
        talc_error('TalcFrame:AwardPlayer: playerName is nil.')
        return
    end

    -- todo maybe better bagitem detection
    if #self.bagItems > 0 then
        local _, _, need = TalcFrame:GetPlayerInfo(playerName);

        core.asend("playerWon#" .. playerName .. "#" .. cvi)

        if db['VOTE_SCREENSHOT_LOOT'] then
            Screenshot()
        end

        if disenchant then
            SendChatMessage(playerName .. ' was awarded with ' .. self.VotedItemsFrames[cvi].link .. ' for Dissenchant!', "RAID")
        else
            SendChatMessage(playerName .. ' was awarded with ' .. self.VotedItemsFrames[cvi].link .. ' for ' .. core.needs[need].text .. '!', "RAID")
        end

        self.VotedItemsFrames[cvi].awardedTo = playerName
        self:updateVotedItemsFrames()
        return
    end

    local unitIndex = 0

    for i = 1, 40 do
        if GetMasterLootCandidate(i) == playerName then
            talc_debug('found: loot candidate' .. GetMasterLootCandidate(i) .. ' ==  arg1:' .. playerName)
            unitIndex = i
            break
        end
    end

    if unitIndex == 0 then
        talc_print("Something went wrong, " .. playerName .. " is not on loot list.")
    else
        local link = self.VotedItemsFrames[cvi].link
        local itemIndex = cvi

        talc_debug('ML item should be ' .. link)
        local foundItemIndexInLootFrame = false
        for id = 0, GetNumLootItems() do
            if GetLootSlotInfo(id) and GetLootSlotLink(id) then
                if link == GetLootSlotLink(id) then
                    foundItemIndexInLootFrame = true
                    itemIndex = id
                end
            end
        end

        if foundItemIndexInLootFrame then

            local index, _, need, _, _, _, _, _ = TalcFrame:GetPlayerInfo(GetMasterLootCandidate(unitIndex));

            core.asend("playerWon#" .. GetMasterLootCandidate(unitIndex) .. "#" .. link .. "#" .. cvi .. "#" .. need)

            GiveMasterLoot(index, unitIndex);

            if db['VOTE_SCREENSHOT_LOOT'] then
                Screenshot()
            end

            if disenchant then
                SendChatMessage(GetMasterLootCandidate(unitIndex) .. ' was awarded with ' .. link .. ' for Dissenchant!', "RAID")
            else
                SendChatMessage(GetMasterLootCandidate(unitIndex) .. ' was awarded with ' .. link .. ' for ' .. core.needs[need].text .. '!', "RAID")
            end

            self.VotedItemsFrames[cvi].awardedTo = playerName
            self:updateVotedItemsFrames()

        else
            talc_error('Item not found. Is the loot window opened ?')
        end
    end
end

function TalcFrame:UpdateCLVotedButtons()

    for _, frame in next, self.CLVotedFrames do
        frame:Hide()
    end

    local index = 0
    for officer, voted in next, self.CLVoted[self.CurrentVotedItem] do
        index = index + 1
        local class = core.getPlayerClass(officer)
        if not self.CLVotedFrames[index] then
            self.CLVotedFrames[index] = CreateFrame('Button', 'CLVotedButton' .. index, TalcVoteFrameCLThatVotedList, 'Talc_CLVotedButton')
        end

        local frame = self.CLVotedFrames[index]

        frame:SetPoint("TOPLEFT", TalcVoteFrameCLThatVotedList, "TOPLEFT", index * 21 - 20, 0)
        frame:Show()
        frame.name = officer

        frame:SetNormalTexture("Interface\\AddOns\\Talc\\images\\classes\\" .. class)
        frame:SetPushedTexture("Interface\\AddOns\\Talc\\images\\classes\\" .. class)
        frame:SetHighlightTexture("Interface\\AddOns\\Talc\\images\\classes\\" .. class)

        frame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -(this:GetWidth() / 4), -(this:GetHeight() / 4));
            GameTooltip:AddLine(this.name)
            GameTooltip:Show();
        end)

        frame:SetScript("OnLeave", function(self)
            GameTooltip:Hide();
        end)

        frame:SetAlpha(0.3)

        --normal votes
        for n, _ in next, self.itemVotes[self.CurrentVotedItem] do
            for voter, vote in next, self.itemVotes[self.CurrentVotedItem][n] do
                if voter == officer and vote == '+' then
                    frame:SetAlpha(1)
                end
            end
        end

        --done voting
        if not voted then
            --check if he clicked done voting for this itme
            if self.clDoneVotingItem[officer] then
                for itemIndex, doneVoting in next, self.clDoneVotingItem[officer] do
                    if itemIndex == self.CurrentVotedItem and doneVoting then
                        frame:SetAlpha(1)
                    end
                end
            end
        end

    end
    TalcVoteFrameMLToWinnerNrOfVotes:Hide()
    TalcVoteFrameWinnerStatusNrOfVotes:Hide()
end

function TalcFrame:RaiderDetailsShowGear()

    for _, d in next, core.equipSlotsDetails do
        if _G['TalcVoteFrameRaiderDetailsFrameInspectGearFrame' .. d.slot .. 'Slot'] then

            local frame = _G['Character' .. d.slot .. 'SlotIconTexture']
            if frame then
                local tex = frame:GetTexture()
                _G['TalcVoteFrameRaiderDetailsFrameInspectGearFrame' .. d.slot .. 'Slot']:SetNormalTexture(tex)
                --_G['TalcVoteFrameRaiderDetailsFrameInspectGearFrame' .. d.slot .. 'Slot']:SetPushedTexture(tex)
                --_G['TalcVoteFrameRaiderDetailsFrameInspectGearFrame' .. d.slot .. 'Slot']:SetHighlightTexture(tex)
                _G['TalcVoteFrameRaiderDetailsFrameInspectGearFrame' .. d.slot .. 'SlotItemLevel']:SetText('')

                core.remButtonOnEnterTooltip(_G['TalcVoteFrameRaiderDetailsFrameInspectGearFrame' .. d.slot .. 'Slot'])
            else
                talc_debug('no frame Character' .. d.slot .. 'SlotIconTexture RaiderDetailsShowGear')
            end

        end
    end

    for _, d in next, self.inspectPlayerGear[self.selectedPlayer[self.CurrentVotedItem]] do
        local _, link, q, il, _, _, _, _, _, tex = GetItemInfo(d.item)

        local frame = _G['TalcVoteFrameRaiderDetailsFrameInspectGearFrame' .. d.slot .. 'Slot']

        if frame then

            _G['TalcVoteFrameRaiderDetailsFrameInspectGearFrame' .. d.slot .. 'SlotItemLevel']:SetText(ITEM_QUALITY_COLORS[q].hex .. il)

            frame:SetNormalTexture(tex)
            --frame:SetPushedTexture(tex)
            --frame:SetHighlightTexture(tex)

            core.addButtonOnEnterTooltip(frame, link)
        end
    end
end

function TalcFrame:RaiderDetailsChangeTab(tab, playerName)

    TalcVoteFrameRLWindowFrame:Hide()

    if tab == 1 then

        if not playerName then
            if self.selectedPlayer[self.CurrentVotedItem] then
                playerName = self.selectedPlayer[self.CurrentVotedItem]
            else
                talc_debug("no player name")
                return
            end
        end

        for _, d in next, core.equipSlotsDetails do
            local frame = _G['Character' .. d.slot .. 'SlotIconTexture']
            if frame then
                local tex = frame:GetTexture()
                _G['TalcVoteFrameRaiderDetailsFrameInspectGearFrame' .. d.slot .. 'Slot']:SetNormalTexture(tex)
            else
                talc_debug('no frame Character' .. d.slot .. 'SlotIconTexture')
            end
        end

        if #self.inspectPlayerGear[playerName] == 0 then
            core.wsend("ALERT", "sendgear=", playerName)
        else
            TalcFrame:RaiderDetailsShowGear()
        end

        for i = 0, GetNumRaidMembers() do
            if GetRaidRosterInfo(i) then
                local n = GetRaidRosterInfo(i)
                if n == playerName then
                    TalcVoteFrameRaiderDetailsFrameInspectGearFrameModelFrame:SetUnit('raid' .. i)
                    break
                end
            end
        end

        TalcVoteFrameRaiderDetailsFrameTab1:SetText('|rGear')
        TalcVoteFrameRaiderDetailsFrameTab2:SetText('|cff696969Loot History')

        TalcVoteFrameRaiderDetailsFrameInspectGearFrame:Show()
        TalcVoteFrameRaiderDetailsFrameLootHistoryFrame:Hide()

        for index in next, self.lootHistoryFrames do
            self.lootHistoryFrames[index]:Hide()
        end
    end

    if tab == 2 then
        TalcVoteFrameRaiderDetailsFrameTab1:SetText('|cff696969Gear')
        TalcVoteFrameRaiderDetailsFrameTab2:SetText('|rLoot History')

        TalcVoteFrameRaiderDetailsFrameInspectGearFrame:Hide()
        TalcVoteFrameRaiderDetailsFrameLootHistoryFrame:Show()

        for index in next, self.lootHistoryFrames do
            self.lootHistoryFrames[index]:Hide()
        end

        Talc_LootHistory_Update()
    end

    TalcVoteFrameRaiderDetailsFrame:Show()
end

TalcFrame.tradableItemsCheck = CreateFrame("Frame")
TalcFrame.tradableItemsCheck:Hide()
TalcFrame.tradableItemsCheck.items = {}
TalcFrame.tradableItemsCheck.frames = {}
TalcFrame.tradableItemsCheck:SetScript("OnShow", function()
    this.startTime = GetTime();
end)
TalcFrame.tradableItemsCheck:SetScript("OnUpdate", function()
    local plus = 60
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then

        local items = TalcFrame:GetTradableItems()

        if #this.items > 0 then
            if #this.items > #items then
                for _, j in next, this.items do
                    local found = false
                    for _, l in next, items do
                        if j.itemLink == l.itemLink then
                            found = true
                            break
                        end
                    end
                    if not found then
                        talc_print(j.itemLink .. ' expired.')
                    end
                end
            end
        end

        this.items = items

        for _, frame in next, this.frames do
            frame:Hide()
        end
        TalcVoteFrameTradableItemsFrame:SetHeight(30)

        local maxDuration = 2 * 3600

        for i, item in next, this.items do

            if item.duration <= TalcFrame.durationNotification then

                if not this.frames[i] then
                    this.frames[i] = CreateFrame('Frame', 'TalcTradableItem' .. i, TalcVoteFrameTradableItemsFrame, 'Talc_TradableItemTemplate')
                end

                local frame = 'TalcTradableItem' .. i

                _G[frame]:SetPoint("TOP", TalcVoteFrameTradableItemsFrame, "TOP", 0, -4 - 22 * i)
                _G[frame]:Show()
                _G[frame]:SetID(i)

                _G[frame .. 'Name']:SetText(item.itemLink)
                _G[frame .. 'Duration']:SetText(core.SecondsToClock(item.duration))

                _G[frame .. 'DurationBar']:SetWidth(240 * (item.duration / maxDuration))
            end
        end

        TalcVoteFrameTradableItemsFrame:SetHeight(40 + #this.items * 21)

        if #this.items > 0 then
            TalcVoteFrameTradableItemsFrame:Show()
        else
            TalcVoteFrameTradableItemsFrame:Hide()
        end

        this.startTime = GetTime()
    end
end)
function TalcFrame.tradableItemsCheck:ItemClick(id)
    if TalcVoteFrame:IsVisible() and TalcVoteFrameRLExtraFrameDragLoot:IsEnabled() then

        local link = self.items[id].itemLink
        local _, _, itemLink = core.find(link, "(item:%d+:%d+:%d+:%d+)");
        local itemID = core.split(':', itemLink)

        core.insert(TalcFrame.bagItems, {
            preloaded = false,
            id = itemID,
            itemLink = link
        })

        for i, d in next, TalcFrame.bagItems do
            local name, l, quality, _, _, _, _, _, _, tex = GetItemInfo(d.itemLink)
            if quality >= 0 and not d.preloaded then
                core.bsend("BULK", "preloadInVoteFrame=" .. i .. "=" .. tex .. "=" .. name .. "=" .. l)
                d.preloaded = true
            end
        end
    end
end

TalcFrame.RLFrame = CreateFrame("Frame")
TalcFrame.RLFrame.assistFrames = {}
TalcFrame.RLFrame.currentTab = 1

function TalcFrame.RLFrame:CheckAssists()

    local assistsAndCL = {}
    --get assists
    for i = 0, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) then
            local n, r = GetRaidRosterInfo(i);
            if r == 2 or r == 1 then
                assistsAndCL[n] = false
            end
        end
    end
    --getcls
    if db['VOTE_ROSTER'] then
        for clName in next, db['VOTE_ROSTER'] do
            assistsAndCL[clName] = false
        end
    end

    for i = 1, #self.assistFrames, 1 do
        self.assistFrames[i]:Hide()
    end

    local people = {}

    local j = 0
    for name, _ in next, assistsAndCL do
        j = j + 1

        people[j] = {
            y = -60 - 25 * j - 10,
            color = core.classColors[core.getPlayerClass(name)].colorStr,
            name = name,
            assist = core.isRLorAssist(name),
            cl = db['VOTE_ROSTER'][name] ~= nil
        }
    end

    TalcVoteFrameRLWindowFrame:SetHeight(110 + #people * 25)

    for i, d in next, people do
        if not self.assistFrames[i] then
            self.assistFrames[i] = CreateFrame('Frame', 'AssistFrame' .. i, TalcVoteFrameRLWindowFrame, 'Talc_CLFrameTemplate')
        end

        self.assistFrames[i]:SetPoint("TOPLEFT", TalcVoteFrameRLWindowFrame, "TOPLEFT", 4, d.y)
        self.assistFrames[i]:Show()
        self.assistFrames[i].name = d.name

        _G['AssistFrame' .. i .. 'AName']:SetText(d.color .. d.name)

        _G['AssistFrame' .. i .. 'StatusIconOnline']:Hide()
        _G['AssistFrame' .. i .. 'StatusIconOffline']:Show()

        if core.onlineInRaid(d.name) then
            _G['AssistFrame' .. i .. 'StatusIconOnline']:Show()
            _G['AssistFrame' .. i .. 'StatusIconOffline']:Hide()
        end

        _G['AssistFrame' .. i .. 'CLCheck']:SetID(i)
        _G['AssistFrame' .. i .. 'CLCheck']:SetChecked(d.cl)

        _G['AssistFrame' .. i .. 'AssistCheck']:SetID(i)
        _G['AssistFrame' .. i .. 'AssistCheck']:SetChecked(d.assist)

        _G['AssistFrame' .. i .. 'CLCheck']:Enable()
        if d.name == core.me then
            if _G['AssistFrame' .. i .. 'CLCheck']:GetChecked() then
                _G['AssistFrame' .. i .. 'CLCheck']:Disable()
            end
            _G['AssistFrame' .. i .. 'AssistCheck']:Disable()
        end
    end


end

function TalcFrame.RLFrame:SaveLootButton(button, value)
    db['VOTE_CONFIG']['NeedButtons'][button] = value;
end

function TalcFrame.RLFrame:SaveSetting(key, value)

    if key == 'WIN_ENABLE_SOUND' then
        if value then
            TalcVoteFrameSettingsFrameWinSoundHigh:Enable()
            TalcVoteFrameSettingsFrameWinSoundLow:Enable()
        else
            TalcVoteFrameSettingsFrameWinSoundHigh:Disable()
            TalcVoteFrameSettingsFrameWinSoundLow:Disable()
        end
    elseif key == 'WIN_VOLUME' then
        if value == 'high' then
            TalcVoteFrameSettingsFrameWinSoundLow:SetChecked(false)
        else
            TalcVoteFrameSettingsFrameWinSoundHigh:SetChecked(false)
        end
        db[key] = value
        return
    elseif key == 'WIN_THRESHOLD' then
        local t = ''
        t = t .. (TalcVoteFrameSettingsFrameWinCommon:GetChecked() and '1' or '0')
        t = t .. (TalcVoteFrameSettingsFrameWinUncommon:GetChecked() and '2' or '0')
        t = t .. (TalcVoteFrameSettingsFrameWinRare:GetChecked() and '3' or '0')
        t = t .. (TalcVoteFrameSettingsFrameWinEpic:GetChecked() and '4' or '0')
        t = t .. (TalcVoteFrameSettingsFrameWinLegendary:GetChecked() and '5' or '0')
        db[key] = t
        return
    elseif key == 'ROLL_ENABLE_SOUND' then
        if value then
            TalcVoteFrameSettingsFrameRollSoundHigh:Enable()
            TalcVoteFrameSettingsFrameRollSoundLow:Enable()
            TalcVoteFrameSettingsFrameRollTrombone:Enable()
        else
            TalcVoteFrameSettingsFrameRollSoundHigh:Disable()
            TalcVoteFrameSettingsFrameRollSoundLow:Disable()
            TalcVoteFrameSettingsFrameRollTrombone:Disable()
        end
    elseif key == 'ROLL_VOLUME' then
        if value == 'high' then
            TalcVoteFrameSettingsFrameRollSoundLow:SetChecked(false)
        else
            TalcVoteFrameSettingsFrameRollSoundHigh:SetChecked(false)
        end
        db[key] = value
        return
    end

    db[key] = value == 1;
end

function TalcFrame.RLFrame:ChangeTab(tab)

    TalcVoteFrameRaiderDetailsFrame:Hide()
    _G['TalcVoteFrameRLWindowFrameTab1Contents']:Hide()
    _G['TalcVoteFrameRLWindowFrameTab2Contents']:Hide()
    _G['TalcVoteFrameRLWindowFrameTab3Contents']:Hide()

    _G['TalcVoteFrameRLWindowFrameTab' .. tab .. 'Contents']:Show()

    if tab == 1 then
        TalcVoteFrameRLWindowFrameTab1:SetText(FONT_COLOR_CODE_CLOSE .. 'Officers')
        TalcVoteFrameRLWindowFrameTab2:SetText('|cff696969Loot')
        TalcVoteFrameRLWindowFrameTab3:SetText('|cff696969Unused')

        for i = 1, #self.assistFrames, 1 do
            self.assistFrames[i]:Hide()
        end
        self:CheckAssists()
    end
    if tab == 2 then
        TalcVoteFrameRLWindowFrameTab1:SetText('|cff696969Officers')
        TalcVoteFrameRLWindowFrameTab2:SetText(FONT_COLOR_CODE_CLOSE .. 'Loot')
        TalcVoteFrameRLWindowFrameTab3:SetText('|cff696969Unused')

        for i = 1, #self.assistFrames, 1 do
            self.assistFrames[i]:Hide()
        end
    end
    if tab == 3 then
        TalcVoteFrameRLWindowFrameTab1:SetText('|cff696969Officers')
        TalcVoteFrameRLWindowFrameTab2:SetText('|cff696969Loot')
        TalcVoteFrameRLWindowFrameTab3:SetText(FONT_COLOR_CODE_CLOSE .. 'Unused')

        for i = 1, #self.assistFrames, 1 do
            self.assistFrames[i]:Hide()
        end
    end
end

TalcFrame.VoteCountdown = CreateFrame("Frame")
TalcFrame.VoteCountdown:Hide()
TalcFrame.VoteCountdown.currentTime = 1
TalcFrame.VoteCountdown.votingOpen = false
TalcFrame.VoteCountdown:SetScript("OnShow", function()
    this.startTime = GetTime();
end)
TalcFrame.VoteCountdown:SetScript("OnUpdate", function()
    local plus = 0.03
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        if this.currentTime ~= this.countDownFrom + plus then

            if this.countDownFrom - this.currentTime >= 0 then
                TalcVoteFrameTimeLeft:Show()

                if TalcFrame.doneVoting[TalcFrame.CurrentVotedItem] == true then
                    TalcVoteFrameTimeLeft:SetText('')
                else
                    TalcVoteFrameTimeLeft:SetText('Please VOTE ! ' .. core.SecondsToClock(core.floor((this.countDownFrom - this.currentTime))))
                end

                local w = core.floor(((this.countDownFrom - this.currentTime) / this.countDownFrom) * 1000) / 1000

                TalcVoteFrameTimeLeftBarBG:SetWidth((TalcVoteFrame:GetWidth() - 8) - (TalcVoteFrame:GetWidth() - 8) * w)
            end

            this:Hide()
            if this.currentTime < this.countDownFrom + plus then
                this.currentTime = this.currentTime + plus
                this:Show()
            elseif this.currentTime > this.countDownFrom + plus then
                this:Hide()
                this.currentTime = 1

                TalcVoteFrameTimeLeft:Show()
                TalcVoteFrameTimeLeft:SetText('')
                TalcVoteFrameMLToWinner:Enable()
            end
        end
    end
end)

TalcFrame.LootCountdown = CreateFrame("Frame")
TalcFrame.LootCountdown:Hide()
TalcFrame.LootCountdown.currentTime = 1
TalcFrame.LootCountdown:SetScript("OnShow", function()
    this.startTime = GetTime();
end)
TalcFrame.LootCountdown:SetScript("OnUpdate", function()
    local plus = 0.03
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        if this.currentTime ~= this.countDownFrom + plus then

            if core.floor(this.countDownFrom - this.currentTime) >= 1 then
                TalcVoteFrameTimeLeft:Show()
            else
                TalcVoteFrameTimeLeft:Hide()
            end

            TalcVoteFrameTimeLeft:SetText(core.SecondsToClock(core.floor(this.countDownFrom - this.currentTime)))

            local w = core.floor(((this.countDownFrom - this.currentTime) / this.countDownFrom) * 1000) / 1000

            TalcVoteFrameTimeLeftBarBG:SetWidth((TalcVoteFrame:GetWidth() - 8) - (TalcVoteFrame:GetWidth() - 8) * w)
        end

        this:Hide()

        if this.currentTime < this.countDownFrom + plus then
            this.currentTime = this.currentTime + plus
            this:Show()
        elseif this.currentTime > this.countDownFrom + plus then

            this:Hide()
            this.currentTime = 1

            TalcVoteFrameMLToWinner:Enable()

            for raidi = 0, GetNumRaidMembers() do
                if GetRaidRosterInfo(raidi) then
                    local n, _, _, _, _, _, z = GetRaidRosterInfo(raidi);
                    if z ~= 'Offline' then

                        for index, _ in next, TalcFrame.VotedItemsFrames do
                            local picked = false
                            for i = 1, #TalcFrame.playersWhoWantItems do
                                if TalcFrame.playersWhoWantItems[i].itemIndex == index and TalcFrame.playersWhoWantItems[i].name == n then
                                    picked = true
                                    break
                                end
                            end
                            if not picked then
                                --add players without addon to playersWhoWant with autopass
                                --can be disabled to hide autopasses
                                core.insert(TalcFrame.playersWhoWantItems, {
                                    itemIndex = index,
                                    name = n,
                                    need = 'autopass',
                                    ci1 = '0',
                                    ci2 = '0',
                                    ci3 = '0',
                                    votes = 0,
                                    roll = 0
                                })

                                --increment pick responses, even for autopass
                                if TalcFrame.pickResponses[index] then
                                    if TalcFrame.pickResponses[index] < core.getNumOnlineRaidMembers() then
                                        TalcFrame.pickResponses[index] = TalcFrame.pickResponses[index] + 1
                                    end
                                else
                                    TalcFrame.pickResponses[index] = 1
                                end
                            end
                        end
                    end
                end
            end

            TalcFrame.VoteCountdown.votingOpen = true
            TalcFrame:showWindow()

            TalcFrame:VoteFrameListUpdate()

            TalcFrame.VoteCountdown:Show()

        end
    end
end)

function TalcFrame:ShowMinimapDropdown()
    local TALCMinimapMenuFrame = CreateFrame('Frame', 'TALCMinimapMenuFrame', UIParent, 'UIDropDownMenuTemplate')
    UIDropDownMenu_Initialize(TALCMinimapMenuFrame, TalcFrame_BuildMinimapMenu, "MENU");
    ToggleDropDownMenu(1, nil, TALCMinimapMenuFrame, Talc_Minimap, 1, 1);
end

function TalcFrame_BuildMinimapMenu()
    local separator = {};
    separator.text = ""
    separator.disabled = true

    local title = {};
    title.text = "TALC"
    title.disabled = false
    title.isTitle = true
    UIDropDownMenu_AddButton(title);
    UIDropDownMenu_AddButton(separator);

    local menu_enabled = {};
    menu_enabled.text = "Enabled"
    menu_enabled.disabled = false
    menu_enabled.isTitle = false
    menu_enabled.tooltipTitle = 'Enabled'
    menu_enabled.tooltipText = 'Enable TALC when raid leading.'
    menu_enabled.checked = db['VOTE_ENABLED']
    menu_enabled.justifyH = 'LEFT'
    menu_enabled.func = function()
        db['VOTE_ENABLED'] = not db['VOTE_ENABLED']
        if db['VOTE_ENABLED'] then
            talc_print('Addon enabled.')
        else
            talc_print('Addon disabled.')
        end
    end
    UIDropDownMenu_AddButton(menu_enabled);
    local menu_settings = {};
    menu_settings.text = "Settings"
    menu_settings.isTitle = false
    menu_settings.justifyH = 'LEFT'
    menu_settings.func = function()
        TalcFrame:ShowSettingsScreen(true)
    end
    UIDropDownMenu_AddButton(menu_settings);
    UIDropDownMenu_AddButton(separator);

    local close = {};
    close.text = "Close"
    close.disabled = false
    close.isTitle = false
    UIDropDownMenu_AddButton(close);
end

function TestNeedButton_OnClick()


    local testItem1 = "\124cffa335ee\124Hitem:40610:0:0:0:0:0:0:0:0\124h[Chestguard of the Lost Conqueror]\124h\124r";
    local testItem2 = "\124cffa335ee\124Hitem:40612:0:0:0:0:0:0:0:0\124h[LEATHER BELT LVL 18]\124h\124r"

    local _, _, itemLink1 = core.find(testItem1, "(item:%d+:%d+:%d+:%d+)");
    local lootName1, _, quality1, _, _, _, _, _, _, lootIcon1 = GetItemInfo(itemLink1)

    local _, _, itemLink2 = core.find(testItem2, "(item:%d+:%d+:%d+:%d+)");
    local lootName2, _, quality2, _, _, _, _, _, _, lootIcon2 = GetItemInfo(itemLink2)

    if quality1 and lootIcon1 and quality2 and lootIcon2 then

        --SendChatMessage('This is a test, click whatever you want!', "RAID_WARNING")
        TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()

        core.SetDynTTN(2)
        core.SetDynTTV(2)
        TalcFrame.LootCountdown.countDownFrom = db['VOTE_TTN']

        TalcFrame:SendTimersAndButtons()

        TalcFrame:SendReset()

        TalcFrame.LootCountdown:Show()
        core.asend('countdownframe=show')

        core.bsend("ALERT", "preloadInVoteFrame=1=" .. lootIcon1 .. "=" .. lootName1 .. "=" .. testItem1)
        core.bsend("ALERT", "preloadInVoteFrame=2=" .. lootIcon2 .. "=" .. lootName2 .. "=" .. testItem2)

        local buttons = ''
        if db['VOTE_CONFIG']['NeedButtons']['BIS'] then
            buttons = buttons .. 'b'
        end
        if db['VOTE_CONFIG']['NeedButtons']['MS'] then
            buttons = buttons .. 'm'
        end
        if db['VOTE_CONFIG']['NeedButtons']['OS'] then
            buttons = buttons .. 'o'
        end
        if db['VOTE_CONFIG']['NeedButtons']['XMOG'] then
            buttons = buttons .. 'x'
        end

        core.bsend("ALERT", "loot=1=" .. lootIcon1 .. "=" .. lootName1 .. "=" .. testItem1)
        core.bsend("ALERT", "loot=2=" .. lootIcon2 .. "=" .. lootName2 .. "=" .. testItem2)
        core.bsend("ALERT", "doneSending=2=items")

        TalcVoteFrameMLToWinner:Disable()
    else

        local _, _, link1 = core.find(testItem1, "(item:%d+:%d+:%d+:%d+)");
        GameTooltip:SetHyperlink(link1)
        GameTooltip:Hide()

        local _, _, link2 = core.find(testItem2, "(item:%d+:%d+:%d+:%d+)");
        GameTooltip:SetHyperlink(link2)
        GameTooltip:Hide()

        talc_error(testItem1 .. ' or ' .. testItem2 .. ' was not seen before, try again...')
    end
end

TalcFrame.withAddon = {}
TalcFrame.withAddonFrames = {}

function TalcFrame:queryWho()

    if not UnitInRaid('player') then
        talc_print('You are not in a raid.')
        return
    end

    TalcVoteFrameWho:Show()

    core.asend("versionQuery=")

    TalcFrame.withAddon = {}
    TalcFrame.withAddonFrames = {}

    TalcVoteFrameWhoTitle:SetText('TALC v' .. core.addonVer)

    for i = 0, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) then
            local n, _, _, _, _, _, z = GetRaidRosterInfo(i);
            local _, class = UnitClass('raid' .. i)

            self.withAddon[n] = {
                class = core.lower(class),
                v = '-'
            }
            if z == 'Offline' then
                self.withAddon[n].v = '|cff777777offline'
            end
        end
    end

    self:updateWithAddon()
end

function TalcFrame:announceWithoutAddon()
    local withoutAddon = ''
    for n, d in next, self.withAddon do
        if core.find(d.v, '-', 1, true) then
            withoutAddon = withoutAddon .. n .. ', '
        end
    end
    if withoutAddon ~= '' then
        SendChatMessage('Players without TALC addon: ' .. withoutAddon, "RAID")
        SendChatMessage('Please check discord #annoucements channel or go to https://github.com/CosminPOP/Talc (latest version v' .. core.addonVer .. ')', "RAID")
    end
end

function TalcFrame:announceOlderAddon()
    local olderAddon = ''
    for n, d in next, self.withAddon do
        if not core.find(d.v, 'offline', 1, true) and not core.find(d.v, '-', 1, true) then
            if core.ver(core.sub(d.v, 11, 17)) < core.ver(core.addonVer) then
                olderAddon = olderAddon .. n .. ', '
            end
        end
    end
    if olderAddon ~= '' then
        SendChatMessage('Players with older versions of TALC addon: ' .. olderAddon, "RAID")
        SendChatMessage('Please check discord #annoucements channel or go to https://github.com/CosminPOP/Talc (latest version v' .. core.addonVer .. ')', "RAID")
    end
end

function TalcFrame:updateWithAddon()

    TalcFrame.withAddonFrames = {}

    local row, col = 1, 1

    local index = 0

    for name, data in next, self.withAddon do

        index = index + 1

        if not self.withAddonFrames[index] then
            self.withAddonFrames[index] = CreateFrame("Button", "TalcAddonStatus" .. index, TalcVoteFrameWho, "Talc_WhoButtonTemplate")
        end

        local frame = "TalcAddonStatus" .. index

        _G[frame]:SetSize(100, 32)

        _G[frame]:SetPoint('TOPLEFT', TalcVoteFrameWho, "TOPLEFT", 10 + (col - 1) * 101, -5 - 35 * row)

        _G[frame .. 'Status']:SetText(core.classColors[core.getPlayerClass(name)].colorStr .. name .. '\n' .. data.v)

        if data.v == '|cff777777offline' then
            _G[frame]:Disable()
        else
            _G[frame]:Enable()
        end


        col = col + 1
        if col == 6 then
            col = 1
            row = row + 1
        end

    end

    local without = 0
    local older = 0
    for _, data in next, self.withAddon do
        if data.v == '-' then
            without = without + 1
        elseif data.v ~= (core.classColors['hunter'].colorStr .. core.addonVer) and data.v ~= '|cff777777offline' then
            older = older + 1
        end
    end
    if without > 0 then
        TalcVoteFrameWhoAnnounceWithoutAddon:SetText('Without Addon (' .. without ..')')
        TalcVoteFrameWhoAnnounceWithoutAddon:Enable()
    else
        TalcVoteFrameWhoAnnounceWithoutAddon:SetText('Without Addon')
        TalcVoteFrameWhoAnnounceWithoutAddon:Disable()
    end
    if older > 0 then
        TalcVoteFrameWhoAnnounceOlderAddon:SetText('Older Versions (' .. older ..')')
        TalcVoteFrameWhoAnnounceOlderAddon:Enable()
    else
        TalcVoteFrameWhoAnnounceOlderAddon:SetText('Older Versions')
        TalcVoteFrameWhoAnnounceOlderAddon:Disable()
    end
end

function TalcFrame:PurgeLootHistory()
    db['VOTE_LOOT_HISTORY'] = {}
    talc_print('Loot History cleared.')
end