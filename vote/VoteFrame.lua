local db, core
local _G = _G

local ContestantDropdownMenu = CreateFrame('Frame', 'ContestantDropdownMenu', UIParent, 'UIDropDownMenuTemplate')
ContestantDropdownMenu.currentContestantId = 0

TalcFrame = CreateFrame("Frame")

TalcFrame.VotedItemsFrames = {}
TalcFrame.CurrentVotedItem = nil --slotIndex
TalcFrame.currentPlayersList = {} --all
TalcFrame.playersPerPage = 10
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

TalcFrame.itemsToPreSend = {}
TalcFrame.sentReset = false

TalcFrame.numItems = 0

TalcFrame.LOOT_OPENED = false
TalcFrame.hordeLoot = {}

TalcFrame.CLVotedFrames = {}
TalcFrame.RaidBuffs = {}

TalcFrame.assistTriggers = 0

TalcFrame.HistoryId = 0

TalcFrame.NEW_ROSTER = {}

function TalcFrame:init()

    db = TALC_DB
    core = TALC

    TalcVoteFrameNameLabel:SetText('Name')

    TalcFrame.playersPerPage = db['VOTE_PPP']
    TalcVoteFrame:SetWidth(600)
    TalcVoteFrame:SetHeight(120 + TalcFrame.playersPerPage * 22 + 5)
    TalcVoteFrame:SetScale(db['VOTE_SCALE'])
    TalcFrame:Resized()

    TalcFrame.LootCountdown.countDownFrom = db['VOTE_TTN']
    TalcFrame.VoteCountdown.countDownFrom = db['VOTE_TTV']

    TalcVoteFrameTitle:SetText('Thunder Ale Brewing Co Loot Council2 v' .. core.addonVer)

    TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()
    TalcVoteFrameDoneVoting:Disable();

    if core.isRL(core.me) then
        TalcVoteFrameRLExtraFrameRLOptionsButton:Show()
        TalcVoteFrameRLExtraFrameResetClose:Show()
        TalcVoteFrameRLExtraFrame:Show()

        TalcVoteFrameMLToEnchanter:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", -100, 0);
            if db['VOTE_DESENCHANTER'] == '' then
                GameTooltip:AddLine("Enchanter not set. Type /talc set enchanter [name]")
            else
                GameTooltip:AddLine("ML to " .. db['VOTE_DESENCHANTER'] .. " to disenchant.")
            end
            GameTooltip:Show();
        end)

        TalcVoteFrameMLToEnchanter:SetScript("OnLeave", function(self)
            GameTooltip:Hide();
        end)
    else
        TalcVoteFrameRLExtraFrameRLOptionsButton:Hide()
        TalcVoteFrameRLExtraFrameResetClose:Hide()
        TalcVoteFrameRLExtraFrame:Hide()
    end
end

function TalcFrame:Resizing()
    TalcVoteFrame:SetAlpha(0.5)
end

function TalcFrame:Resized()

    TalcFrame.playersPerPage = core.floor((TalcVoteFrame:GetHeight() - 120) / 22)
    db['VOTE_PPP'] = TalcFrame.playersPerPage
    TalcVoteFrame:SetHeight(120 + TalcFrame.playersPerPage * 22 + 5)
    TalcVoteFrameContestantScrollListFrame:SetHeight(TalcFrame.playersPerPage * 22)
    TalcVoteFrameContestantScrollListBackground:SetHeight(TalcFrame.playersPerPage * 22 + 3)

    TalcVoteFrame:SetAlpha(db['VOTE_ALPHA'])

    TalcFrame_VoteFrameListScroll_Update()
end

function TalcFrame:RefreshWho()
    if not UnitInRaid('player') then
        talc_print('You are not in a raid.')
        return false
    end
    VoteFrameWho:Show()
    TalcFrame.peopleWithAddon = ''
    VoteFrameWhoText:SetText('Loading...')
    core.asend("voteframe=whoVF=" .. core.addonVer)
end

function TalcFrame:SyncLootHistory()
    local totalItems = #db['VOTE_LOOT_HISTORY']

    TalcVoteFrameRLWindowFrameSyncLootHistory:Disable()

    talc_print('Starting History Sync, ' .. totalItems .. ' entries...')
    core.bsend("BULK", "loot_history_sync;start")
    for lootTime, item in next, db['VOTE_LOOT_HISTORY'] do
        core.bsend("BULK", "loot_history_sync;" .. lootTime .. ";" .. item['player'] .. ";" .. item['item'])
    end
    core.bsend("BULK", "loot_history_sync;end")
    talc_print('History Sync finished. Sent ' .. totalItems .. ' entries.')
end

function TalcFrame:ToggleMainWindow()

    print("test")

    if TalcVoteFrame:IsVisible() then
        TalcVoteFrame:Hide()
        TalcVoteFrameRaiderDetailsFrame:Hide()
        TalcVoteFrameRLWindowFrame:Hide()
    else
        if not core.canVote(core.me) and not core.isRL(core.me) then
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
    TalcFrame:SendReset()
    TalcFrame:SendCloseWindow()
    TalcFrame.sentReset = false
    SetLootMethod("master", core.me)
end

function TalcFrame:SetCL(id, to)
    if to then
        core.addToRoster(TalcFrame.RLFrame.assistFrames[id].name)
    else
        core.remFromRoster(TalcFrame.RLFrame.assistFrames[id].name)
    end
end

function TalcFrame:SetAssist(id, to)
    for i = 0, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) then
            local n = GetRaidRosterInfo(i);
            if n == TalcFrame.RLFrame.assistFrames[id].name then
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

    if TalcVoteFrameRLWindowFrame:IsVisible() == 1 then
        HideUIPanel(TalcVoteFrameRLWindowFrame)
    else
        if TalcVoteFrameRaiderDetailsFrame:IsVisible() == 1 then
            TalcFrame:RaiderDetailsClose()
        end

        TalcVoteFrameRLWindowFrameSyncLootHistory:SetText('Sync Loot History (' .. #db['VOTE_LOOT_HISTORY'] .. ' entries)')

        ShowUIPanel(TalcVoteFrameRLWindowFrame)

        TalcFrame.RLFrame:ChangeTab(1)

    end
end

function TalcFrame:BroadcastLoot()

    local lootmethod = GetLootMethod()
    if lootmethod ~= 'master' then
        talc_print('Looting method is not master looter. (' .. lootmethod .. ')')
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

    if not TalcFrame.sentReset then
        -- disable broadcast until roster is synced
        TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()

        core.SetDynTTN(GetNumLootItems(), false)
        TalcFrame.LootCountdown.countDownFrom = db['VOTE_TTN']
        core.asend('ttn=' .. db['VOTE_TTN'])
        core.SetDynTTV(GetNumLootItems())
        core.asend('ttv=' .. db['VOTE_TTV'])
        core.asend('ttr=' .. db['VOTE_TTR'])

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

        TalcFrame:SendReset()

        for id = 0, GetNumLootItems() do
            if GetLootSlotInfo(id) and GetLootSlotLink(id) then
                local lootIcon, lootName = GetLootSlotInfo(id)

                local _, _, itemLink = core.find(GetLootSlotLink(id), "(item:%d+:%d+:%d+:%d+)");
                local _, _, quality = GetItemInfo(itemLink)
                if (quality >= 0) then
                    --send to officers
                    core.bsend("BULK", "preloadInVoteFrame=" .. id .. "=" .. lootIcon .. "=" .. lootName .. "=" .. GetLootSlotLink(id))
                end
            end
        end

        core.syncRoster()
        TalcFrame.sentReset = true

        TalcVoteFrameRLExtraFrameBroadcastLoot:SetText('Broadcast Loot (' .. db['VOTE_TTN'] .. ')')

        return false
    end

    TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()

    TalcFrame.LootCountdown:Show()
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
                --send to twneed
                core.bsend("ALERT", "loot=" .. id .. "=" .. lootIcon .. "=" .. lootName .. "=" .. GetLootSlotLink(id) .. "=" .. TalcFrame.LootCountdown.countDownFrom .. "=" .. buttons)
                numLootItems = numLootItems + 1
            end
        end
    end
    core.bsend("ALERT", "doneSending=" .. numLootItems .. "=items")
    TalcVoteFrameMLToWinner:Disable();
end

function TalcFrame:addVotedItem(index, texture, link)

    self.itemVotes[index] = {}

    self.doneVoting[index] = false

    self.selectedPlayer[index] = ''

    if not self.VotedItemsFrames[index] then
        self.VotedItemsFrames[index] = CreateFrame("Frame", "VotedItem" .. index,
                TalcVoteFrameVotedItemsFrame, "Talc_VotedItemsFrameTemplate")
    end

    local button = _G['VotedItem' .. index .. 'VotedItemButton']

    TalcVoteFrameVotedItemsFrame:SetHeight(40 * index + 35)

    self.VotedItemsFrames[index]:SetPoint("TOPLEFT", TalcVoteFrameVotedItemsFrame, "TOPLEFT", 8, 30 - (40 * index))

    self.VotedItemsFrames[index]:Show()
    self.VotedItemsFrames[index].link = link
    self.VotedItemsFrames[index].texture = texture
    self.VotedItemsFrames[index].awardedTo = ''
    self.VotedItemsFrames[index].rolled = false
    self.VotedItemsFrames[index].pickedByEveryone = false

    core.addButtonOnEnterTooltip(button, link)

    button:SetID(index)
    button:SetNormalTexture(texture)
    button:SetPushedTexture(texture)
    button:SetHighlightTexture(texture)

    _G['VotedItem' .. index .. 'VotedItemButtonCheck']:Hide()
    button:SetHighlightTexture(texture)

    if index ~= 1 then
        SetDesaturation(button:GetNormalTexture(), 1)
    end

    if not self.CurrentVotedItem then
        TalcFrame:VotedItemButton(index)
    end
end

function TalcFrame:VotedItemButton(id)

    TalcVoteFrameMLToWinner:Hide()
    if core.isRL(core.me) then
        TalcVoteFrameMLToWinner:Show()
    end
    if core.canVote(core.me) and not core.isRL(core.me) then
        TalcVoteFrameWinnerStatus:Show()
    end

    SetDesaturation(_G['VotedItem' .. id .. 'VotedItemButton']:GetNormalTexture(), 0)
    for index, _ in next, TalcFrame.VotedItemsFrames do
        if (index ~= id) then
            SetDesaturation(_G['VotedItem' .. index .. 'VotedItemButton']:GetNormalTexture(), 1)
        end
    end
    TalcFrame:SetCurrentVotedItem(id)
end

function TalcFrame:DoneVoting()
    TalcFrame.doneVoting[TalcFrame.CurrentVotedItem] = true
    TalcVoteFrameDoneVoting:Disable();
    TalcVoteFrameDoneVotingCheck:Show();
    core.asend( "doneVoting;" .. TalcFrame.CurrentVotedItem)
    TalcFrame_VoteFrameListScroll_Update()
end

function TalcFrame:SetCurrentVotedItem(id)

    TalcFrame.CurrentVotedItem = id

    TalcVoteFrameCurrentVotedItemIcon:Show()
    TalcVoteFrameVotedItemName:Show()
    TalcVoteFrameVotedItemType:Show()

    TalcVoteFrameCurrentVotedItemIcon:SetNormalTexture(TalcFrame.VotedItemsFrames[id].texture)
    TalcVoteFrameCurrentVotedItemIcon:SetPushedTexture(TalcFrame.VotedItemsFrames[id].texture)

    local link = TalcFrame.VotedItemsFrames[id].link
    TalcVoteFrameVotedItemName:SetText(link)
    core.addButtonOnEnterTooltip(TalcVoteFrameCurrentVotedItemIcon, link, 'playerHistory')

    local _, _, itemLink = core.find(link, "(item:%d+:%d+:%d+:%d+)");
    local name, _, _, iLevel, _, t1, t2, _, equip_slot = GetItemInfo(itemLink)
    local votedItemType = ''

    if t2 then
        if not core.find(core.lower(t2), 'misc', 1, true)
                and not core.find(core.lower(t2), 'shields', 1, true) then
            votedItemType = votedItemType .. t2 .. ' '
        end
    end
    if equip_slot then
        votedItemType = votedItemType .. core.getEquipSlot(equip_slot)
    end

    if votedItemType == 'Cloth Cloak' then
        votedItemType = 'Cloak'
    end

    if core.find(votedItemType, 'Junk', 1, true) then
        votedItemType = 'Token'
        -- todo get ilevel of reward
    end

    votedItemType = votedItemType .. ' (' .. iLevel .. ') '

    if core.find(votedItemType, 'Quest', 1, true) or core.find(votedItemType, 'Token', 1, true) then
        votedItemType = core.trim(votedItemType) .. ' rewards:'
    end

    TalcVoteFrameCurrentVotedItemQuestReward1:Hide()
    TalcVoteFrameCurrentVotedItemQuestReward2:Hide()
    TalcVoteFrameCurrentVotedItemQuestReward3:Hide()
    TalcVoteFrameCurrentVotedItemQuestReward4:Hide()
    TalcVoteFrameCurrentVotedItemQuestReward5:Hide()
    TalcVoteFrameCurrentVotedItemQuestReward6:Hide()
    TalcVoteFrameCurrentVotedItemQuestReward7:Hide()
    TalcVoteFrameCurrentVotedItemQuestReward8:Hide()
    TalcVoteFrameCurrentVotedItemQuestReward9:Hide()
    TalcVoteFrameCurrentVotedItemQuestReward10:Hide()

    local reward1 = ''
    local reward2 = ''
    local reward3 = ''
    local reward4 = ''
    local reward5 = ''
    local reward6 = ''
    local reward7 = ''
    local reward8 = ''
    local reward9 = ''
    local reward10 = ''

    local showDe = true

    if votedItemType == 'Junk ' and core.find(name, 'Desecrated', 1, true) then
        votedItemType = 'Quest rewards: '
    end

    if votedItemType == 'Junk ' and core.find(name, 'Splinter', 1, true) then
        votedItemType = 'Orange'
        showDe = false
    end

    if name == 'Head of Onyxia' then
        reward1 = "\124cffa335ee\124Hitem:18406:0:0:0:0:0:0:0:0\124h[Onyxia Blood Talisman]\124h\124r"
        reward2 = "\124cffa335ee\124Hitem:18403:0:0:0:0:0:0:0:0\124h[Dragonslayer's Signet]\124h\124r"
        reward3 = "\124cffa335ee\124Hitem:18404:0:0:0:0:0:0:0:0\124h[Onyxia Tooth Pendant]\124h\124r"
        showDe = false
    end

    if name == "Desecrated Bindings" then
        reward1 = "\124cffa335ee\124Hitem:22519:0:0:0:0:0:0:0:0\124h[Bindings of Faith]\124h\124r"
        reward2 = "\124cffa335ee\124Hitem:22503:0:0:0:0:0:0:0:0\124h[Frostfire Bindings]\124h\124r"
        reward3 = "\124cffa335ee\124Hitem:22511:0:0:0:0:0:0:0:0\124h[Plagueheart Bindings]\124h\124r"
        showDe = false
    end

    if reward1 ~= '' then
        TalcFrame:SetTokenRewardLink(reward1, 1)
    end
    if reward2 ~= '' then
        TalcFrame:SetTokenRewardLink(reward2, 2)
    end
    if reward3 ~= '' then
        TalcFrame:SetTokenRewardLink(reward3, 3)
    end
    if reward4 ~= '' then
        TalcFrame:SetTokenRewardLink(reward4, 4)
    end
    if reward5 ~= '' then
        TalcFrame:SetTokenRewardLink(reward5, 5)
    end
    if reward6 ~= '' then
        TalcFrame:SetTokenRewardLink(reward6, 6)
    end
    if reward7 ~= '' then
        TalcFrame:SetTokenRewardLink(reward7, 7)
    end
    if reward8 ~= '' then
        TalcFrame:SetTokenRewardLink(reward8, 8)
    end
    if reward9 ~= '' then
        TalcFrame:SetTokenRewardLink(reward9, 9)
    end
    if reward10 ~= '' then
        TalcFrame:SetTokenRewardLink(reward10, 10)
    end

    TalcVoteFrameVotedItemType:SetText(votedItemType)

    if showDe then
        TalcVoteFrameMLToEnchanter:Show()
    else
        TalcVoteFrameMLToEnchanter:Hide()
    end

    TalcFrame_VoteFrameListScroll_Update()
end

function TalcFrame:GetPlayerInfo(playerIndexOrName)
    --returns itemIndex, name, need, votes, ci1, ci2, ci3, roll, k
    if core.type(playerIndexOrName) == 'string' then
        for k, player in next, TalcFrame.currentPlayersList do
            if player['name'] == playerIndexOrName then
                return player['itemIndex'], player['name'], player['need'], player['votes'], player['ci1'], player['ci2'], player['ci3'], player['roll'], k
            end
        end
    end
    local player = TalcFrame.currentPlayersList[playerIndexOrName]
    if player then
        return player['itemIndex'], player['name'], player['need'], player['votes'], player['ci1'], player['ci2'], player['ci3'], player['roll'], playerIndexOrName
    else
        return false
    end
end

function TalcFrame:ChangePlayerPickTo(playerName, newPick, itemIndex)
    for pIndex, data in next, TalcFrame.playersWhoWantItems do
        if data['itemIndex'] == itemIndex and data['name'] == playerName then
            TalcFrame.playersWhoWantItems[pIndex]['need'] = newPick
            break
        end
    end
    if core.isRL(core.me) then
        core.asend( "changePickTo@" .. playerName .. "@" .. newPick .. "@" .. itemIndex)
    end

    TalcFrame_VoteFrameListScroll_Update()
end

function Talc_LootHistory_Update()
    local itemOffset = FauxScrollFrame_GetOffset(TalcVoteFrameRaiderDetailsFrameScrollFrame);

    local id = TalcFrame.HistoryId

    TalcFrame.selectedPlayer[TalcFrame.CurrentVotedItem] = _G['TalcVoteFrameContestantFrame' .. id].name

    local totalItems = 0

    local historyPlayerName = _G['TalcVoteFrameContestantFrame' .. id].name
    for _, item in next, db['VOTE_LOOT_HISTORY'] do
        if historyPlayerName == item['player'] then
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
    FauxScrollFrame_Update(TalcVoteFrameRaiderDetailsFrameScrollFrame, totalItems, 11, 22);
end

function TalcFrame:RaiderDetailsClose()
    if TalcFrame.selectedPlayer[TalcFrame.CurrentVotedItem] then
        TalcFrame.selectedPlayer[TalcFrame.CurrentVotedItem] = ''
    end
    TalcVoteFrameRaiderDetailsFrame:Hide()
    TalcFrame_VoteFrameListScroll_Update()
end

function buildContestantMenu()
    local id = ContestantDropdownMenu.currentContestantId
    local separator = {};
    separator.text = ""
    separator.disabled = true

    local title = {};
    title.text = _G['TalcVoteFrameContestantFrame' .. id].name .. ' ' ..  _G['TalcVoteFrameContestantFrame' .. id .. 'Need']:GetText()
    title.disabled = false
    title.notCheckable = true
    title.isTitle = true
    UIDropDownMenu_AddButton(title);
    UIDropDownMenu_AddButton(separator);

    local award = {};
    award.text = "Award " .. TalcVoteFrameVotedItemName:GetText()
    award.disabled = TalcFrame.VotedItemsFrames[TalcFrame.CurrentVotedItem].awardedTo ~= ''
    award.isTitle = false
    award.notCheckable = true
    award.tooltipTitle = 'Award Raider'
    award.tooltipText = 'Give him them loots'
    award.justifyH = 'LEFT'
    award.func = function()
        TalcFrame:AwardPlayer(_G['TalcVoteFrameContestantFrame' .. id].name, TalcFrame.CurrentVotedItem)
    end
    UIDropDownMenu_AddButton(award);
    UIDropDownMenu_AddButton(separator);

    local changeToBIS = {}
    changeToBIS.text = "Change to " .. core.needs['bis'].colorStr .. core.needs['bis'].text
    changeToBIS.disabled = _G['TalcVoteFrameContestantFrame' .. id].need == 'bis'
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
    changeToMS.disabled = _G['TalcVoteFrameContestantFrame' .. id].need == 'ms'
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
    changeToOS.disabled = _G['TalcVoteFrameContestantFrame' .. id].need == 'os'
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
    changeToXMOG.disabled = _G['TalcVoteFrameContestantFrame' .. id].need == 'xmog'
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
    close.func = function()
        --
    end
    UIDropDownMenu_AddButton(close);
end

function TalcFrame:ShowContestantDropdownMenu(id)

    if not core.isRL(core.me) then
        return
    end

    ContestantDropdownMenu.currentContestantId = id

    UIDropDownMenu_Initialize(ContestantDropdownMenu, buildContestantMenu, "MENU");
    ToggleDropDownMenu(1, nil, ContestantDropdownMenu, "cursor", 2, 3);
end

function TalcFrame:ShowMinimapDropdown()
    local TALCMinimapMenuFrame = CreateFrame('Frame', 'TALCMinimapMenuFrame', UIParent, 'UIDropDownMenuTemplate')
    UIDropDownMenu_Initialize(TALCMinimapMenuFrame, buildMinimapMenu, "MENU");
    ToggleDropDownMenu(1, nil, TALCMinimapMenuFrame, "cursor", 2, 3);
end

function TalcFrame_VoteFrameListScroll_Update()

    if not TalcFrame.CurrentVotedItem then
        return false
    end

    TalcFrame:RefreshContestantsList()
    TalcFrame:CalculateVotes()
    TalcFrame:UpdateLCVoters()
    TalcFrame:CalculateWinner()

    if not TalcFrame.pickResponses[TalcFrame.CurrentVotedItem] then
        TalcFrame.pickResponses[TalcFrame.CurrentVotedItem] = 0
    end
    if not TalcFrame.waitResponses[TalcFrame.CurrentVotedItem] then
        TalcFrame.waitResponses[TalcFrame.CurrentVotedItem] = 0
    end

    if TalcFrame.pickResponses[TalcFrame.CurrentVotedItem] == core.getNumOnlineRaidMembers() then

        local bis, ms, os, pass, xmog = 0, 0, 0, 0, 0
        for _, pwwi in next, TalcFrame.playersWhoWantItems do
            if pwwi['itemIndex'] == TalcFrame.CurrentVotedItem then
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

        TalcVoteFrameContestantCount:SetText('|cff1fba1fEveryone(' .. TalcFrame.pickResponses[TalcFrame.CurrentVotedItem]
                .. ') has picked(' .. pass .. ' passes).')
        TalcFrame.VotedItemsFrames[TalcFrame.CurrentVotedItem].pickedByEveryone = true
        TalcVoteFrameTimeLeftBar:Hide()

    else
        TalcVoteFrameContestantCount:SetText('Waiting picks ' ..
                TalcFrame.pickResponses[TalcFrame.CurrentVotedItem] .. '/' ..
                core.getNumOnlineRaidMembers())
        TalcFrame.VotedItemsFrames[TalcFrame.CurrentVotedItem].pickedByEveryone = false
        TalcVoteFrameTimeLeftBar:Show()
    end

    local itemIndex, name, need, votes, ci1, ci2, ci3, roll
    local playerIndex

    -- Scrollbar stuff
    local showScrollBar = false;
    if #TalcFrame.currentPlayersList > TalcFrame.playersPerPage then
        showScrollBar = true;
    end

    local playerOffset = FauxScrollFrame_GetOffset(TalcVoteFrameContestantScrollListFrame);

    --hide all 15 contestant frames
    for i = 1, 15 do
        _G['TalcVoteFrameContestantFrame' .. i]:Hide();
    end

    for i = 1, TalcFrame.playersPerPage, 1 do
        playerIndex = playerOffset + i;

        if TalcFrame:GetPlayerInfo(playerIndex) then

            _G['TalcVoteFrameContestantFrame' .. i]:SetID(playerIndex)
            _G['TalcVoteFrameContestantFrame' .. i].playerIndex = playerIndex;
            itemIndex, name, need, votes, ci1, ci2, ci3, roll = TalcFrame:GetPlayerInfo(playerIndex);
            _G['TalcVoteFrameContestantFrame' .. i].name = name;
            _G['TalcVoteFrameContestantFrame' .. i].need = need;

            local class = core.getPlayerClass(name)
            local color = core.classColors[class]
            --'enabled' --enabled, disabled, voted
            local canVote = true
            local voted = false

            _G['TalcVoteFrameContestantFrame' .. i .. 'Name']:SetText(color.colorStr .. name);
            _G['TalcVoteFrameContestantFrame' .. i .. 'Need']:SetText(core.needs[need].colorStr .. core.needs[need].text);

            if roll > 0 then
                _G['TalcVoteFrameContestantFrame' .. i .. 'Roll']:SetText(roll);
            else
                _G['TalcVoteFrameContestantFrame' .. i .. 'Roll']:SetText();
            end

            _G['TalcVoteFrameContestantFrame' .. i .. 'RollPass']:Hide();

            if roll == -1 then
                _G['TalcVoteFrameContestantFrame' .. i .. 'RollPass']:Show();
                _G['TalcVoteFrameContestantFrame' .. i .. 'Roll']:SetText(' -');
            end

            if (roll == -2) then
                _G['TalcVoteFrameContestantFrame' .. i .. 'Roll']:SetText('...');
            end

            _G['TalcVoteFrameContestantFrame' .. i .. 'RightClickMenuButton1']:SetID(playerIndex);
            _G['TalcVoteFrameContestantFrame' .. i .. 'RightClickMenuButton2']:SetID(playerIndex);
            _G['TalcVoteFrameContestantFrame' .. i .. 'RightClickMenuButton3']:SetID(playerIndex);

            _G['TalcVoteFrameContestantFrame' .. i .. 'Votes']:SetText(votes);

            if votes == TalcFrame.currentItemMaxVotes and TalcFrame.currentItemMaxVotes > 0 then
                _G['TalcVoteFrameContestantFrame' .. i .. 'Votes']:SetText('|cff1fba1f' .. votes);
            end

            if TalcFrame.VotedItemsFrames[TalcFrame.CurrentVotedItem].awardedTo ~= '' or --not awarded
                    TalcFrame.numPlayersThatWant == 1 or --only one player wants
                    TalcFrame.VotedItemsFrames[TalcFrame.CurrentVotedItem].rolled or --item being rolled
                    roll ~= 0 or --waiting rolls
                    TalcFrame.doneVoting[TalcFrame.CurrentVotedItem] == true then
                --doneVoting is pressed
                canVote = false
            end

            if not TalcFrame.VoteCountdown.votingOpen then
                canVote = false
            end

            _G['TalcVoteFrameContestantFrame' .. i .. 'VoteButton']:SetText('VOTE')
            _G['TalcVoteFrameContestantFrame' .. i .. 'VoteButtonCheck']:Hide()
            if TalcFrame.itemVotes[TalcFrame.CurrentVotedItem][name] then
                if TalcFrame.itemVotes[TalcFrame.CurrentVotedItem][name][core.me] then
                    if TalcFrame.itemVotes[TalcFrame.CurrentVotedItem][name][core.me] == '+' then
                        voted = true
                    end
                end
            end

            if canVote then
                _G['TalcVoteFrameContestantFrame' .. i .. 'VoteButton']:Enable()
            else
                _G['TalcVoteFrameContestantFrame' .. i .. 'VoteButton']:Disable()
            end
            if voted then
                _G['TalcVoteFrameContestantFrame' .. i .. 'VoteButtonCheck']:Show()
                _G['TalcVoteFrameContestantFrame' .. i .. 'VoteButton']:SetText('')
            else
                _G['TalcVoteFrameContestantFrame' .. i .. 'VoteButtonCheck']:Hide()
                _G['TalcVoteFrameContestantFrame' .. i .. 'VoteButton']:SetText('VOTE')
            end

            local lastItem = ''
            for lootTime, item in core.pairsByKeysReverse(db['VOTE_LOOT_HISTORY']) do
                if item['player'] == name then
                    lastItem = item['item'] .. '(' .. date("%d/%m", lootTime) .. ')'
                    break ;
                end
            end

            _G['TalcVoteFrameContestantFrame' .. i .. 'RollWinner']:Hide();
            if (TalcFrame.currentMaxRoll[TalcFrame.CurrentVotedItem] == roll and roll > 0) then
                _G['TalcVoteFrameContestantFrame' .. i .. 'RollWinner']:Show();
            end
            _G['TalcVoteFrameContestantFrame' .. i .. 'WinnerIcon']:Hide();
            if (TalcFrame.VotedItemsFrames[TalcFrame.CurrentVotedItem].awardedTo == name) then
                _G['TalcVoteFrameContestantFrame' .. i .. 'WinnerIcon']:Show();
            end

            --hide all CL icons / tooltip buttons
            for w = 1, 10 do
                _G['TalcVoteFrameContestantFrame' .. i .. 'CLVote' .. w]:Hide()
                _G['TalcVoteFrameContestantFrame' .. i .. 'CLVote' .. w .. 'Tooltip']:Hide()
            end
            if TalcFrame.itemVotes[TalcFrame.CurrentVotedItem][name] then
                local w = 0;
                for voter, vote in next, TalcFrame.itemVotes[TalcFrame.CurrentVotedItem][name] do
                    if vote == '+' then
                        w = w + 1
                        local voterClass = core.getPlayerClass(voter)
                        local texture = "Interface\\AddOns\\Talc\\images\\classes\\" .. voterClass

                        local frameW = 0

                        if not _G['TalcVoteFrameContestantFrame' .. i .. 'CLVote' .. w]:IsVisible() then
                            _G['TalcVoteFrameContestantFrame' .. i .. 'CLVote' .. w]:SetTexture(texture)
                            _G['TalcVoteFrameContestantFrame' .. i .. 'CLVote' .. w]:Show()
                            frameW = w
                        end

                        -- add tooltips
                        local tooltipNames = {}
                        if frameW ~= 0 then
                            tooltipNames[frameW] = voter;
                            _G['TalcVoteFrameContestantFrame' .. i .. 'CLVote' .. frameW .. 'Tooltip']:Show()
                            _G['TalcVoteFrameContestantFrame' .. i .. 'CLVote' .. frameW .. 'Tooltip']:SetID(frameW)
                            local CLIconButton = _G['TalcVoteFrameContestantFrame' .. i .. 'CLVote' .. frameW .. 'Tooltip']

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
            end

            _G['TalcVoteFrameContestantFrame' .. i .. 'VoteButton']:SetID(playerIndex);

            _G['TalcVoteFrameContestantFrame' .. i]:SetBackdropColor(color.r, color.g, color.b, 0.5);
            _G['TalcVoteFrameContestantFrame' .. i .. 'ClassIcon']:SetTexture('Interface\\AddOns\\Talc\\images\\classes\\' .. class);

            _G['TalcVoteFrameContestantFrame' .. i .. 'VoteButton']:Show();
            if need == 'pass' or need == 'autopass' or need == 'wait' then
                _G['TalcVoteFrameContestantFrame' .. i .. 'VoteButton']:Hide();
            end

            if ci1 ~= "0" then
                local _, _, itemLink = core.find(ci1, "(item:%d+:%d+:%d+:%d+)");
                local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)

                if not tex then
                    tex = 'Interface\\Icons\\INV_Misc_QuestionMark'
                end

                _G['TalcVoteFrameContestantFrame' .. i .. 'ReplacesItem1']:SetNormalTexture(tex)
                _G['TalcVoteFrameContestantFrame' .. i .. 'ReplacesItem1']:SetPushedTexture(tex)
                core.addButtonOnEnterTooltip(_G['TalcVoteFrameContestantFrame' .. i .. 'ReplacesItem1'], itemLink)
                _G['TalcVoteFrameContestantFrame' .. i .. 'ReplacesItem1']:Show()
            else
                _G['TalcVoteFrameContestantFrame' .. i .. 'ReplacesItem1']:Hide()
            end
            if ci2 ~= "0" then
                local _, _, itemLink = core.find(ci2, "(item:%d+:%d+:%d+:%d+)");
                local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)

                if not tex then
                    tex = 'Interface\\Icons\\INV_Misc_QuestionMark'
                end

                _G['TalcVoteFrameContestantFrame' .. i .. 'ReplacesItem2']:SetNormalTexture(tex)
                _G['TalcVoteFrameContestantFrame' .. i .. 'ReplacesItem2']:SetPushedTexture(tex)
                core.addButtonOnEnterTooltip(_G['TalcVoteFrameContestantFrame' .. i .. 'ReplacesItem2'], itemLink)
                _G['TalcVoteFrameContestantFrame' .. i .. 'ReplacesItem2']:Show()
            else
                _G['TalcVoteFrameContestantFrame' .. i .. 'ReplacesItem2']:Hide()
            end
            if ci3 ~= "0" then
                local _, _, itemLink = core.find(ci3, "(item:%d+:%d+:%d+:%d+)");
                local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)

                if not tex then
                    tex = 'Interface\\Icons\\INV_Misc_QuestionMark'
                end

                _G['TalcVoteFrameContestantFrame' .. i .. 'ReplacesItem3']:SetNormalTexture(tex)
                _G['TalcVoteFrameContestantFrame' .. i .. 'ReplacesItem3']:SetPushedTexture(tex)
                core.addButtonOnEnterTooltip(_G['TalcVoteFrameContestantFrame' .. i .. 'ReplacesItem3'], itemLink)
                _G['TalcVoteFrameContestantFrame' .. i .. 'ReplacesItem3']:Show()
            else
                _G['TalcVoteFrameContestantFrame' .. i .. 'ReplacesItem3']:Hide()
            end

            if playerIndex > #TalcFrame.currentPlayersList then
                _G['TalcVoteFrameContestantFrame' .. i]:Hide();
            else
                _G['TalcVoteFrameContestantFrame' .. i]:Show();
            end
        end
    end

    if TalcFrame.doneVoting[TalcFrame.CurrentVotedItem] then
        TalcVoteFrameDoneVoting:Disable()
        TalcVoteFrameDoneVotingCheck:Show()
    else
        if TalcFrame.pickResponses[TalcFrame.CurrentVotedItem] then
            if TalcFrame.pickResponses[TalcFrame.CurrentVotedItem] > 1 then
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

    TalcFrame:UpdateCLVotedButtons()

    -- ScrollFrame update
    FauxScrollFrame_Update(TalcVoteFrameContestantScrollListFrame, #TalcFrame.currentPlayersList, TalcFrame.playersPerPage, 20);
end

function TalcFrame:updateVotedItemsFrames()
    for index, _ in next, TalcFrame.VotedItemsFrames do
        _G['VotedItem' .. index .. 'VotedItemButtonCheck']:Hide()
        if TalcFrame.VotedItemsFrames[index].awardedTo ~= '' then
            _G['VotedItem' .. index .. 'VotedItemButtonCheck']:Show()
        end
    end

    TalcFrame_VoteFrameListScroll_Update()
end

function TalcFrame:ResetVars()

    TalcFrame.LootCountdown:Hide()
    TalcFrame.VoteCountdown:Hide()

    TalcFrame.CurrentVotedItem = nil
    TalcFrame.currentPlayersList = {}
    TalcFrame.playersWhoWantItems = {}

    TalcFrame.waitResponses = {}
    TalcFrame.pickResponses = {}
    TalcFrame.receivedResponses = 0

    TalcFrame.itemVotes = {}

    TalcFrame.myVotes = {}
    TalcFrame.LCVoters = 0

    TalcFrame.selectedPlayer = {}

    TalcVoteFrameTitle:SetText('Thunder Ale Brewing Co Loot Council v' .. core.addonVer)
    TalcVoteFrameVotesLabel:SetText('Votes');
    TalcVoteFrameContestantCount:SetText()

    TalcVoteFrameWinnerStatus:Hide()
    TalcVoteFrameMLToWinner:Hide()
    TalcVoteFrameMLToWinner:Disable()
    TalcVoteFrameMLToWinnerNrOfVotes:SetText()
    TalcVoteFrameWinnerStatusNrOfVotes:SetText()

    for index, _ in next, TalcFrame.VotedItemsFrames do
        _G['VotedItem' .. index]:Hide()
    end

    for i = 1, TalcFrame.playersPerPage, 1 do
        _G['TalcVoteFrameContestantFrame' .. i]:Hide()
    end

    TalcFrame.LootCountdown.currentTime = 1
    TalcFrame.VoteCountdown.currentTime = 1
    TalcFrame.VoteCountdown.votingOpen = false

    TalcVoteFrameTimeLeftBar:SetWidth(592)

    TalcVoteFrameCurrentVotedItemIcon:Hide()
    TalcVoteFrameVotedItemName:Hide()
    TalcVoteFrameVotedItemType:Hide()
    TalcVoteFrameCurrentVotedItemQuestReward1:Hide()
    TalcVoteFrameCurrentVotedItemQuestReward2:Hide()
    TalcVoteFrameCurrentVotedItemQuestReward3:Hide()
    TalcVoteFrameCurrentVotedItemQuestReward4:Hide()
    TalcVoteFrameCurrentVotedItemQuestReward5:Hide()
    TalcVoteFrameCurrentVotedItemQuestReward6:Hide()
    TalcVoteFrameCurrentVotedItemQuestReward7:Hide()
    TalcVoteFrameCurrentVotedItemQuestReward8:Hide()
    TalcVoteFrameCurrentVotedItemQuestReward9:Hide()
    TalcVoteFrameCurrentVotedItemQuestReward10:Hide()

    TalcVoteFrameVotedItemType:Hide()

    TalcFrame.doneVoting = {}
    TalcFrame.clDoneVotingItem = {}
    TalcVoteFrameDoneVoting:Disable();
    TalcVoteFrameDoneVotingCheck:Hide();
    TalcVoteFrameContestantScrollListFrame:Hide()

    TalcFrame.itemsToPreSend = {}

    TalcFrame.numItems = 0

    TalcVoteFrameMLToEnchanter:Hide()
end

function TalcFrame:handleSync(pre, t, ch, sender)
    --talc_debug(sender .. ' says: ' .. t)

    if core.find(t, 'NeedButtons=', 1, true) then
        if not core.canVote(core.me) then
            return false
        end
        if not core.isRL(sender) then
            return false
        end

        local buttons = core.split('=', t)
        if not buttons[2] then
            return false
        end

        db['VOTE_CONFIG']['NeedButtons']['BIS'] = core.find(buttons[2], 'b', 1, true) ~= nil
        db['VOTE_CONFIG']['NeedButtons']['MS'] = core.find(buttons[2], 'm', 1, true) ~= nil
        db['VOTE_CONFIG']['NeedButtons']['OS'] = core.find(buttons[2], 'o', 1, true) ~= nil
        db['VOTE_CONFIG']['NeedButtons']['XMOG'] = core.find(buttons[2], 'x', 1, true) ~= nil
    end
    if core.find(t, 'boss&', 1, true) then
        if not core.canVote(core.me) then
            return false
        end
        if not core.isRL(sender) then
            return false
        end

        local bossName = core.split('&', t)
        if not bossName[2] then
            return false
        end
        --
        TalcVoteFrameTitle:SetText('Thunder Ale Brewing Co Loot Council v' .. core.addonVer .. ' - ' .. bossName[2])
    end
    if core.find(t, 'giveml=', 1, true) then
        if not core.canVote(core.me) then
            return false
        end
        if not core.isRL(sender) then
            return false
        end

        if sender == core.me then
            return false
        end

        local ml = core.split('=', t)
        if not ml[2] or not ml[3] then
            talc_error('wrong giveml syntax')
            talc_error(t)
            return false
        end

        TalcFrame:AwardPlayer(ml[3], core.int(ml[2]))
    end
    if core.find(t, 'doneSending=', 1, true) and core.canVote(core.me) then
        if not core.isRL(sender) then
            return false
        end
        local nrItems = core.split('=', t)
        if not nrItems[2] or not nrItems[3] then
            talc_error('wrong doneSending syntax')
            talc_error(t)
            return false
        end
        TalcVoteFrameContestantCount:SetText('|cff1fba1fLoot sent. Waiting picks...')
        core.asend( "CLreceived=" .. TalcFrame.numItems .. "=items")
    end
    if core.sub(t, 1, 11) == 'CLreceived=' then
        if not core.isRL(core.me) then
            return
        end

        local nrItems = core.split('=', t)
        if not nrItems[2] or not nrItems[3] then
            talc_error('wrong CLreceived syntax')
            talc_error(t)
            return false
        end

        if core.int(nrItems[2]) ~= TalcFrame.numItems then
            talc_error('Officer ' .. sender .. ' got ' .. nrItems[2] .. '/' .. TalcFrame.numItems .. ' items.')
        end
    end
    if core.sub(t, 1, 9) == 'received=' then
        if not core.canVote(core.me) then
            return
        end

        local nrItems = core.split('=', t)
        if not nrItems[2] or not nrItems[3] then
            talc_error('wrong received syntax')
            talc_error(t)
            return false
        end

        if core.int(nrItems[2]) ~= TalcFrame.numItems then
            talc_error('Player ' .. sender .. ' got ' .. nrItems[2] .. '/' .. TalcFrame.numItems .. ' items.')
        else
            TalcFrame.receivedResponses = TalcFrame.receivedResponses + 1
        end
    end
    if core.find(t, 'playerRoll:', 1, true) then

        if not core.isRL(sender) or sender == core.me then
            return
        end
        if not core.canVote(core.me) then
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

        TalcFrame.playersWhoWantItems[core.int(indexEx[2])]['roll'] = core.int(indexEx[3])
        TalcFrame.VotedItemsFrames[core.int(indexEx[4])].rolled = true
        TalcFrame_VoteFrameListScroll_Update()
    end
    if core.find(t, 'changePickTo@', 1, true) then

        if not core.isRL(sender) or sender == core.me then
            return
        end
        if not core.canVote(core.me) then
            return
        end

        local pickEx = core.split('@', t)
        if not pickEx[2] or not pickEx[3] or not pickEx[4] then
            talc_error('bad changePick syntax')
            talc_error(t)
            return false
        end

        if not core.int(pickEx[4]) then
            talc_error('bad changePick itemIndex')
            talc_error(t)
            return false
        end

        TalcFrame:ChangePlayerPickTo(pickEx[2], pickEx[3], core.int(pickEx[4]))
    end

    if core.find(t, 'rollChoice=', 1, true) then

        if not core.canVote(core.me) then
            return
        end

        local r = core.split('=', t)
        --r[2] = voteditem id
        --r[3] = roll
        if not r[2] or not r[3] then
            talc_debug('bad rollChoice syntax')
            talc_debug(t)
            return false
        end

        if core.int(r[3]) == -1 then

            local name = sender
            local roll = core.int(r[3]) -- -1

            --check if name is in playersWhoWantItems with vote == -2
            for pwIndex, pwPlayer in next, TalcFrame.playersWhoWantItems do
                if (pwPlayer['name'] == name and pwPlayer['roll'] == -2) then
                    TalcFrame.playersWhoWantItems[pwIndex]['roll'] = roll
                    TalcVoteFrame_VoteFrameListScroll_Update()
                    break
                end
            end
        else
            talc_debug('ROLLCATCHER ' .. sender .. ' rolled for ' .. r[2])
        end
    end
    if core.find(t, 'itemVote:', 1, true) then

        if not core.canVote(sender) or sender == core.me then
            return
        end
        if not core.canVote(core.me) then
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
        if (not TalcFrame.itemVotes[votedItem][votedPlayer]) then
            TalcFrame.itemVotes[votedItem][votedPlayer] = {}
        end
        TalcFrame.itemVotes[votedItem][votedPlayer][sender] = vote
        TalcFrame_VoteFrameListScroll_Update()
    end
    if core.find(t, 'doneVoting;', 1, true) then
        if not core.canVote(sender) or not core.canVote(core.me) then
            return
        end

        local itemEx = core.split(';', t)
        if not itemEx[2] then
            talc_error('bad doneVoting syntax')
            talc_error(t)
            return false
        end

        if not core.int(itemEx[2]) then
        end

        if not TalcFrame.clDoneVotingItem[sender] then
            TalcFrame.clDoneVotingItem[sender] = {}
        end
        TalcFrame.clDoneVotingItem[sender][core.int(itemEx[2])] = true

        TalcFrame_VoteFrameListScroll_Update()
    end
    if core.find(t, 'voteframe=', 1, true) then
        local command = core.split('=', t)

        if not command[2] then
            talc_error('bad voteframe syntax')
            talc_error(t)
            return false
        end

        if command[2] == "whoVF" then
            core.bsend("NORMAL", "withAddonVF=" .. sender .. "=" .. core.me .. "=" .. core.addonVer)
            return
        end

        if not core.isRL(sender) then
            return
        end
        if not core.canVote(core.me) then
            return
        end

        if command[2] == "reset" then
            TalcFrame:ResetVars()
        end
        if command[2] == "close" then
            TalcFrame:CloseWindow()
        end
        if command[2] == "show" then
            TalcFrame:showWindow()
        end
    end
    if core.find(t, 'preloadInVoteFrame=', 1, true) then

        if not core.isRL(sender) then
            return
        end

        local item = core.split("=", t)

        if not item[2] or not item[3] or not item[4] or not item[5] then
            talc_error('bad loot syntax')
            talc_error(t)
            return false
        end

        if not core.int(item[2]) then
            talc_error('bad loot index')
            talc_error(t)
            return false
        end

        TalcFrame.numItems = TalcFrame.numItems + 1

        local index = core.int(item[2])
        local texture = item[3]
        local link = item[5]
        TalcFrame:addVotedItem(index, texture, link)

    end
    if core.find(t, 'countdownframe=', 1, true) then

        if not core.isRL(sender) then
            return
        end
        if not core.canVote(core.me) then
            return
        end

        local action = core.split("=", t)

        if not action[2] then
            talc_error('bad countdownframe syntax')
            talc_error(t)
            return false
        end

        if action[2] == 'show' then
            TalcFrame.LootCountdown:Show()
        end
    end
    if core.find(t, 'wait=', 1, true) then
        if true then
            return false
        end --ignore wait commands for now
        if not core.canVote(core.me) then
            return
        end

        local needEx = core.split('=', t)

        -- 3rd current item
        if not needEx[5] then
            needEx[5] = '0'
        end

        if not needEx[2] or not needEx[3] or not needEx[4] then
            --add or not needEx[5] after everyone updates
            talc_error('bad wait syntax')
            talc_error(t)
            return false
        end

        if not core.int(needEx[2]) then
            talc_error('bad wait itemIndex')
            talc_error(t)
            return false
        end

        if #TalcFrame.playersWhoWantItems > 0 then
            for i = 1, #TalcFrame.playersWhoWantItems do
                if TalcFrame.playersWhoWantItems[i]['itemIndex'] == core.int(needEx[2]) and
                        TalcFrame.playersWhoWantItems[i]['name'] == sender then
                    return false --exists already
                end
            end
        end

        if (TalcFrame.waitResponses[core.int(needEx[2])]) then
            TalcFrame.waitResponses[core.int(needEx[2])] = TalcFrame.waitResponses[core.int(needEx[2])] + 1
        else
            TalcFrame.waitResponses[core.int(needEx[2])] = 1
        end

        core.insert(TalcFrame.playersWhoWantItems, {
            ['itemIndex'] = core.int(needEx[2]),
            ['name'] = sender,
            ['need'] = 'wait',
            ['ci1'] = needEx[3],
            ['ci2'] = needEx[4],
            ['ci3'] = needEx[5],
            ['votes'] = 0,
            ['roll'] = 0
        })

        TalcFrame.itemVotes[core.int(needEx[2])] = {}
        TalcFrame.itemVotes[core.int(needEx[2])][sender] = {}

        TalcFrame_VoteFrameListScroll_Update()
    end
    --ms=1=item:123=item:323
    if core.sub(t, 1, 4) == 'bis='
            or core.sub(t, 1, 3) == 'ms='
            or core.sub(t, 1, 3) == 'os='
            or core.sub(t, 1, 5) == 'xmog='
            or core.sub(t, 1, 5) == 'pass='
            or core.sub(t, 1, 9) == 'autopass=' then

        if core.canVote(core.me) then

            local needEx = core.split('=', t)

            if not needEx[5] then
                needEx[5] = '0'
            end

            if not needEx[2] or not needEx[3] or not needEx[4] then
                --add or not needEx[5] in the future
                talc_error('bad need syntax')
                talc_error(t)
                return false
            end

            if core.sub(t, 1, 9) == 'autopass=' then
                return false
            end

            --stuff for without wait=
            if #TalcFrame.playersWhoWantItems > 0 then
                for i = 1, #TalcFrame.playersWhoWantItems do
                    if TalcFrame.playersWhoWantItems[i]['itemIndex'] == core.int(needEx[2]) and
                            TalcFrame.playersWhoWantItems[i]['name'] == sender then
                        return false --exists already
                    end
                end
            end

            if TalcFrame.waitResponses[core.int(needEx[2])] then
                TalcFrame.waitResponses[core.int(needEx[2])] = TalcFrame.waitResponses[core.int(needEx[2])] + 1
            else
                TalcFrame.waitResponses[core.int(needEx[2])] = 1
            end

            core.insert(TalcFrame.playersWhoWantItems, {
                ['itemIndex'] = core.int(needEx[2]),
                ['name'] = sender,
                ['need'] = 'wait',
                ['ci1'] = needEx[3],
                ['ci2'] = needEx[4],
                ['ci3'] = needEx[5],
                ['votes'] = 0,
                ['roll'] = 0
            })

            TalcFrame.itemVotes[core.int(needEx[2])] = {}
            TalcFrame.itemVotes[core.int(needEx[2])][sender] = {}
            --stuff for without wait= end

            if TalcFrame.pickResponses[core.int(needEx[2])] then
                if TalcFrame.pickResponses[core.int(needEx[2])] < TalcFrame.waitResponses[core.int(needEx[2])] then
                    TalcFrame.pickResponses[core.int(needEx[2])] = TalcFrame.pickResponses[core.int(needEx[2])] + 1
                end
            else
                TalcFrame.pickResponses[core.int(needEx[2])] = 1
            end

            for index, player in next, TalcFrame.playersWhoWantItems do
                if player['name'] == sender and player['itemIndex'] == core.int(needEx[2]) then
                    -- found the wait=
                    TalcFrame.playersWhoWantItems[index]['need'] = needEx[1]
                    TalcFrame.playersWhoWantItems[index]['ci1'] = needEx[3]
                    TalcFrame.playersWhoWantItems[index]['ci2'] = needEx[4]
                    TalcFrame.playersWhoWantItems[index]['ci3'] = needEx[5]
                    break
                end
            end

            TalcFrame_VoteFrameListScroll_Update()
        else
            TalcVoteFrame:Hide()
        end
    end
    -- roster sync
    if core.find(t, 'syncRoster=', 1, true) then
        if not core.isRL(sender) then
            return
        end
        if sender == core.me and t == 'syncRoster=end' then
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
            TalcFrame.NEW_ROSTER = {}
        elseif command == "end" then
            db['VOTE_ROSTER'] = TalcFrame.NEW_ROSTER
            talc_debug('Roster updated.')
        else
            TalcFrame.NEW_ROSTER[command[2]] = false
        end
    end
    --code still here, but disabled in TalcFrame:AwardPlayer
    if core.find(t, 'youWon=', 1, true) then
        if not core.isRL(sender) then
            return
        end
        local wonData = core.split("=", t)
        if wonData[2] and wonData[4] then
            TalcFrame.VotedItemsFrames[core.int(wonData[4])].awardedTo = wonData[2]
            TalcFrame:updateVotedItemsFrames()
        end
    end
    --using playerWon instead, to let other CL know who got loot
    if core.find(t, 'playerWon#', 1, true) then
        if not core.canVote(sender) then
            return
        end
        local wonData = core.split("#", t) --playerWon#unitName#link#votedItem

        if not wonData[2] or not wonData[3] or not wonData[4] then
            talc_error('bad playerWon syntax')
            talc_error(t)
            return false
        end

        TalcFrame.VotedItemsFrames[core.int(wonData[4])].awardedTo = wonData[2]
        TalcFrame:updateVotedItemsFrames()
        --save loot in history
        db['VOTE_LOOT_HISTORY'][time()] = {
            ['player'] = wonData[2],
            ['item'] = TalcFrame.VotedItemsFrames[core.int(wonData[4])].link
        }
    end
    if core.sub(t, 1, 4) == 'ttn=' then
        if not core.isRL(sender) then
            return
        end

        local ttn = core.split("=", t)

        if not ttn[2] then
            talc_error('bad ttn syntax')
            talc_error(t)
            return false
        end

        db['VOTE_TTN'] = core.int(ttn[2]) --might be useless ?
        TalcFrame.LootCountdown.countDownFrom = db['VOTE_TTN']
    end
    if core.sub(t, 1, 4) == 'ttv=' then
        if not core.isRL(sender) then
            return
        end

        local ttv = core.split("=", t)

        if not ttv[2] then
            talc_error('bad ttv syntax')
            talc_error(t)
            return false
        end

        db['VOTE_TTV'] = core.int(ttv[2])
        TalcFrame.VoteCountdown.countDownFrom = db['VOTE_TTV']
    end
    if core.sub(t, 1, 4) == 'ttr=' then
        if not core.isRL(sender) then
            return
        end

        local ttr = core.split("=", t)

        if not ttr[2] then
            talc_error('bat ttr syntax')
            talc_error(t)
            return false
        end

        db['VOTE_TTR'] = core.int(ttr[2])
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
            TalcFrame.peopleWithAddon = TalcFrame.peopleWithAddon .. star ..
                    core.classColors[core.getPlayerClass(sender)].colorStr ..
                    sender .. ' ' .. verColor .. n[4] .. '\n'
            VoteFrameWhoTitle:SetText('TALC With Addon')
            VoteFrameWhoText:SetText(TalcFrame.peopleWithAddon)
        end
    end
    if core.find(t, 'loot_history_sync;', 1, true) then

        if core.isRL(sender) and sender == core.me and t == 'loot_history_sync;end' then
            talc_print('History Sync complete.')
            TalcVoteFrameRLWindowFrameSyncLootHistory:Enable()
        end

        if not core.isRL(sender) or sender == core.me then
            return
        end
        local lh = core.split(";", t)

        if not lh[2] or not lh[3] or not lh[4] then
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
                ["player"] = lh[3],
                ["item"] = lh[4],
            }
        end
    end
end

function TalcFrame:RefreshContestantsList()
    --getto ordering
    local tempTable = TalcFrame.playersWhoWantItems
    TalcFrame.playersWhoWantItems = {}
    local j = 0
    for _, d in next, tempTable do
        if d['need'] == 'bis' then
            j = j + 1
            TalcFrame.playersWhoWantItems[j] = d
        end
    end
    for _, d in next, tempTable do
        if d['need'] == 'ms' then
            j = j + 1
            TalcFrame.playersWhoWantItems[j] = d
        end
    end
    for _, d in next, tempTable do
        if d['need'] == 'os' then
            j = j + 1
            TalcFrame.playersWhoWantItems[j] = d
        end
    end
    for _, d in next, tempTable do
        if d['need'] == 'xmog' then
            j = j + 1
            TalcFrame.playersWhoWantItems[j] = d
        end
    end
    for _, d in next, tempTable do
        if d['need'] == 'pass' then
            j = j + 1
            TalcFrame.playersWhoWantItems[j] = d
        end
    end
    for _, d in next, tempTable do
        if d['need'] == 'autopass' then
            j = j + 1
            TalcFrame.playersWhoWantItems[j] = d
        end
    end
    for _, d in next, tempTable do
        if d['need'] == 'wait' then
            j = j + 1
            TalcFrame.playersWhoWantItems[j] = d
        end
    end
    -- sort
    TalcFrame.currentPlayersList = {}
    for i = 1, TalcFrame.playersPerPage, 1 do
        _G['TalcVoteFrameContestantFrame' .. i]:Hide();
    end
    for pIndex, data in next, TalcFrame.playersWhoWantItems do
        if data['itemIndex'] == TalcFrame.CurrentVotedItem then
            core.insert(TalcFrame.currentPlayersList, TalcFrame.playersWhoWantItems[pIndex])
        end
    end
end

function TalcFrame:VoteButton(id)
    local _, name = TalcFrame:GetPlayerInfo(id)

    if not TalcFrame.itemVotes[TalcFrame.CurrentVotedItem][name] then
        TalcFrame.itemVotes[TalcFrame.CurrentVotedItem][name] = {
            [core.me] = '+'
        }
        core.asend( "itemVote:" .. TalcFrame.CurrentVotedItem .. ":" .. name .. ":+")
    else
        if TalcFrame.itemVotes[TalcFrame.CurrentVotedItem][name][core.me] == '+' then
            TalcFrame.itemVotes[TalcFrame.CurrentVotedItem][name][core.me] = '-'
            core.asend( "itemVote:" .. TalcFrame.CurrentVotedItem .. ":" .. name .. ":-")
        else
            TalcFrame.itemVotes[TalcFrame.CurrentVotedItem][name][core.me] = '+'
            core.asend( "itemVote:" .. TalcFrame.CurrentVotedItem .. ":" .. name .. ":+")
        end
    end

    TalcFrame_VoteFrameListScroll_Update()
end

function TalcFrame:CalculateVotes()

    --init votes to 0
    for pIndex in next, TalcFrame.currentPlayersList do
        TalcFrame.currentPlayersList[pIndex].votes = 0
    end

    if TalcFrame.CurrentVotedItem ~= nil then
        for n, _ in next, TalcFrame.itemVotes[TalcFrame.CurrentVotedItem] do

            if TalcFrame:GetPlayerInfo(n) then
                local _, _, _, _, _, _, _, _, pIndex = TalcFrame:GetPlayerInfo(n)
                for _, vote in next, TalcFrame.itemVotes[TalcFrame.CurrentVotedItem][n] do
                    if vote == '+' then
                        TalcFrame.currentPlayersList[pIndex].votes = TalcFrame.currentPlayersList[pIndex].votes + 1
                    end
                end
            else
                talc_error('TalcFrame:GetPlayerInfo(' .. n .. ') Not Found. Please report this.')
            end
        end
    end
end

function TalcFrame:CalculateWinner()

    if not TalcFrame.CurrentVotedItem then
        return false
    end

    -- calc roll winner(s)
    TalcFrame.currentRollWinner = ''
    TalcFrame.currentMaxRoll[TalcFrame.CurrentVotedItem] = 0
    --    talc_debug('calculare maxroll')
    for _, d in next, TalcFrame.currentPlayersList do
        if d['itemIndex'] == TalcFrame.CurrentVotedItem and d['roll'] > 0 and d['roll'] > TalcFrame.currentMaxRoll[TalcFrame.CurrentVotedItem] then
            TalcFrame.currentMaxRoll[TalcFrame.CurrentVotedItem] = d['roll']
            TalcFrame.currentRollWinner = d['name']
        end
    end
    --    talc_debug('maxroll = ' .. TalcFrame.currentMaxRoll[TalcFrame.CurrentVotedItem])

    if TalcFrame.VotedItemsFrames[TalcFrame.CurrentVotedItem].awardedTo ~= '' then
        TalcVoteFrameMLToWinner:Disable();
        local color = core.classColors[core.getPlayerClass(TalcFrame.VotedItemsFrames[TalcFrame.CurrentVotedItem].awardedTo)]
        TalcVoteFrameMLToWinner:SetText('Awarded to ' .. color.colorStr .. TalcFrame.VotedItemsFrames[TalcFrame.CurrentVotedItem].awardedTo);
        TalcVoteFrameWinnerStatus:SetText('Awarded to ' .. color.colorStr .. TalcFrame.VotedItemsFrames[TalcFrame.CurrentVotedItem].awardedTo);
        return
    end

    -- roll tie detection
    local rollTie = 0
    for _, d in next, TalcFrame.currentPlayersList do
        if d['itemIndex'] == TalcFrame.CurrentVotedItem and d['roll'] > 0 and d['roll'] == TalcFrame.currentMaxRoll[TalcFrame.CurrentVotedItem] then
            rollTie = rollTie + 1
        end
    end

    if rollTie ~= 0 then
        if (rollTie == 1) then
            TalcVoteFrameMLToWinner:Enable();
            local color = core.classColors[core.getPlayerClass(TalcFrame.currentRollWinner)]
            TalcVoteFrameMLToWinner:SetText('Award ' .. color.colorStr .. TalcFrame.currentRollWinner);
            TalcVoteFrameWinnerStatus:SetText('Winner: ' .. color.colorStr .. TalcFrame.currentRollWinner);

            TalcFrame.currentItemWinner = TalcFrame.currentRollWinner
            TalcFrame.voteTiePlayers = ''
        else
            TalcVoteFrameMLToWinner:Enable();
            TalcVoteFrameMLToWinner:SetText('ROLL VOTE TIE'); -- .. voteTies
            TalcVoteFrameWinnerStatus:SetText('VOTE TIE'); -- .. voteTies
        end
        return
    else

        -- calc vote winner
        TalcFrame.currentItemWinner = ''
        TalcFrame.currentItemMaxVotes = 0
        TalcFrame.voteTiePlayers = '';
        TalcFrame.numPlayersThatWant = 0
        TalcFrame.namePlayersThatWants = ''
        for _, d in next, TalcFrame.currentPlayersList do
            if d['itemIndex'] == TalcFrame.CurrentVotedItem then

                -- calc winner if only one exists with bis, ms, os, xmog
                if d['need'] == 'bis' or d['need'] == 'ms' or d['need'] == 'os' or d['need'] == 'xmog' then
                    TalcFrame.numPlayersThatWant = TalcFrame.numPlayersThatWant + 1
                    TalcFrame.namePlayersThatWants = d['name']
                end

                if (d['votes'] > 0 and d['votes'] > TalcFrame.currentItemMaxVotes) then
                    TalcFrame.currentItemMaxVotes = d['votes']
                    TalcFrame.currentItemWinner = d['name']
                end
            end
        end

        if TalcFrame.numPlayersThatWant == 1 then
            TalcFrame.currentItemWinner = TalcFrame.namePlayersThatWants
            TalcVoteFrameMLToWinner:Enable();
            local color = core.classColors[core.getPlayerClass(TalcFrame.currentItemWinner)]
            TalcVoteFrameMLToWinner:SetText('Award single picker ' .. color.colorStr .. TalcFrame.currentItemWinner);
            TalcVoteFrameWinnerStatus:SetText('Single picker ' .. color.colorStr .. TalcFrame.currentItemWinner);
            return
        end

        --    talc_debug('maxVotes = ' .. maxVotes)
        --tie check
        local ties = 0
        for _, d in next, TalcFrame.currentPlayersList do
            if d['itemIndex'] == TalcFrame.CurrentVotedItem then
                if (d['votes'] == TalcFrame.currentItemMaxVotes and TalcFrame.currentItemMaxVotes > 0) then
                    TalcFrame.voteTiePlayers = TalcFrame.voteTiePlayers .. d['name'] .. ' '
                    ties = ties + 1
                end
            end
        end
        TalcFrame.voteTiePlayers = core.trim(TalcFrame.voteTiePlayers)

        if ties > 1 then
            TalcVoteFrameMLToWinner:Enable()
            TalcVoteFrameMLToWinner:SetText('ROLL VOTE TIE') -- .. voteTies
            TalcVoteFrameWinnerStatus:SetText('VOTE TIE') -- .. voteTies
        else
            --no tie
            TalcFrame.voteTiePlayers = ''
            if TalcFrame.currentItemWinner ~= '' then
                TalcVoteFrameMLToWinner:Enable();
                local color = core.classColors[core.getPlayerClass(TalcFrame.currentItemWinner)]
                TalcVoteFrameMLToWinner:SetText('Award ' .. color.colorStr .. TalcFrame.currentItemWinner);
                TalcVoteFrameWinnerStatus:SetText('Winner: ' .. color.colorStr .. TalcFrame.currentItemWinner);
            else
                TalcVoteFrameMLToWinner:Disable()
                TalcVoteFrameMLToWinner:SetText('Waiting votes...')
                TalcVoteFrameWinnerStatus:SetText('Waiting votes...')
            end
        end
    end
end

function TalcFrame:UpdateLCVoters()

    if not TalcFrame.CurrentVotedItem then
        return false
    end

    local nr = 0
    -- reset OV
    for officer, _ in next, db['VOTE_ROSTER'] do
        db['VOTE_ROSTER'][officer] = false
    end
    for n, _ in next, TalcFrame.itemVotes[TalcFrame.CurrentVotedItem] do
        for voter, vote in next, TalcFrame.itemVotes[TalcFrame.CurrentVotedItem][n] do
            for officer, _ in next, db['VOTE_ROSTER'] do
                if voter == officer and vote == '+' then
                    db['VOTE_ROSTER'][officer] = true
                end
            end
        end
    end
    for _, v in next, db['VOTE_ROSTER'] do
        if v then
            nr = nr + 1
        end
    end

    for officer, voted in next, db['VOTE_ROSTER'] do
        if not voted then
            --check if he clicked done voting for this itme
            if TalcFrame.clDoneVotingItem[officer] then
                for itemIndex, doneVoting in next, TalcFrame.clDoneVotingItem[officer] do
                    if itemIndex == TalcFrame.CurrentVotedItem and doneVoting then
                        nr = nr + 1
                    end
                end
            end
        end
    end

    local numOfficersInRaid = 0
    for o, _ in next, db['VOTE_ROSTER'] do
        if core.onlineInRaid(o) then
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
    --    talc_debug(TalcFrame.voteTiePlayers)
    if TalcFrame.voteTiePlayers ~= '' then
        TalcFrame.VotedItemsFrames[TalcFrame.CurrentVotedItem].rolled = true
        local players = core.split(' ', TalcFrame.voteTiePlayers)
        for _, d in next, TalcFrame.currentPlayersList do
            for _, tieName in next, players do
                if d['itemIndex'] == TalcFrame.CurrentVotedItem and d['name'] == tieName then

                    local linkString = TalcFrame.VotedItemsFrames[TalcFrame.CurrentVotedItem].link
                    local _, _, itemLink = core.find(linkString, "(item:%d+:%d+:%d+:%d+)");
                    local name, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)

                    for pwIndex, pwPlayer in next, TalcFrame.playersWhoWantItems do
                        if (pwPlayer['name'] == tieName and pwPlayer['itemIndex'] == TalcFrame.CurrentVotedItem) then
                            -- found the wait=
                            TalcFrame.playersWhoWantItems[pwIndex]['roll'] = -2 --roll
                            --send to officers
                            core.asend( "playerRoll:" .. pwIndex .. ":-2:" .. TalcFrame.CurrentVotedItem)
                            --send to raiders
                            core.asend( 'rollFor=' .. TalcFrame.CurrentVotedItem .. '=' .. tex .. '=' .. name .. '=' .. linkString .. '=' .. db['VOTE_TTR'] .. '=' .. tieName)
                            break
                        end
                    end
                end
            end
        end
        TalcVoteFrameMLToWinner:Disable();
        TalcFrame_VoteFrameListScroll_Update()
    else
        TalcFrame:AwardPlayer(TalcFrame.currentItemWinner, TalcFrame.CurrentVotedItem)
    end
end

function TalcFrame:MLToEnchanter()
    if db['VOTE_DESENCHANTER'] == '' then
        talc_print('Disenchanter not set. Uset /talc set enchanter/disenchanter [name] to set it.')
        return false;
    end

    local foundInRaid = false

    for i = 0, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) then
            local n = GetRaidRosterInfo(i);
            if n == db['VOTE_DESENCHANTER'] then
                foundInRaid = true
            end
        end
    end
    if not foundInRaid then
        talc_print('Disenchanter ' .. db['VOTE_DESENCHANTER'] .. ' is not in raid. Use /talc set enchanter/disenchanter [name] to set a different one.')
        return false;
    end
    for i = 0, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) then
            local n, _, _, _, _, _, z = GetRaidRosterInfo(i);
            if n == db['VOTE_DESENCHANTER'] and z == 'Offline' then
                talc_print('Disenchanter ' .. db['VOTE_DESENCHANTER'] .. ' is offline. Use /talc set enchanter/disenchanter [name] to set a different one.')
                return false;
            end
        end
    end
    TalcFrame:AwardPlayer(db['VOTE_DESENCHANTER'], TalcFrame.CurrentVotedItem, true)
end

function TalcFrame:ContestantClick(id)

    local playerOffset = FauxScrollFrame_GetOffset(TalcVoteFrameContestantScrollListFrame);
    id = id - playerOffset

    if arg1 == 'RightButton' then
        TalcFrame:ShowContestantDropdownMenu(id)
        return true
    end

    if TalcVoteFrameRaiderDetailsFrame:IsVisible() and TalcFrame.selectedPlayer[TalcFrame.CurrentVotedItem] == _G['TalcVoteFrameContestantFrame' .. id].name then
        TalcFrame:RaiderDetailsClose()
    else
        TalcFrame.HistoryId = id
        local historyPlayerName = _G['TalcVoteFrameContestantFrame' .. id].name
        local totalItems = 0
        for _, item in next, db['VOTE_LOOT_HISTORY'] do
            if historyPlayerName == item['player'] then
                totalItems = totalItems + 1
            end
        end
        TalcVoteFrameRaiderDetailsFrameTitle:SetText(totalItems .. " items looted")
        TalcVoteFrameRaiderDetailsFrameLootHistoryTitle:SetText(core.classColors[core.getPlayerClass(historyPlayerName)].colorStr .. historyPlayerName .. "|r's Details")
        TalcFrame:RaiderDetailsChangeTab(1);
    end
end

function TalcFrame:ContestantOnEnter(id)
    local playerOffset = FauxScrollFrame_GetOffset(TalcVoteFrameContestantScrollListFrame);
    id = id - playerOffset
    local r, g, b = _G['TalcVoteFrameContestantFrame' .. id]:GetBackdropColor()
    _G['TalcVoteFrameContestantFrame' .. id]:SetBackdropColor(r, g, b, 1)
end

function TalcFrame:ContestantOnLeave()
    for i = 1, TalcFrame.playersPerPage do
        local r, g, b = _G['TalcVoteFrameContestantFrame' .. i]:GetBackdropColor()
        if TalcFrame.selectedPlayer[TalcFrame.CurrentVotedItem] ~= _G['TalcVoteFrameContestantFrame' .. i].name then
            _G['TalcVoteFrameContestantFrame' .. i]:SetBackdropColor(r, g, b, 0.5)
        end
    end
end

function TalcFrame:AwardPlayer(playerName, cvi, disenchant)

    if not playerName or playerName == '' then
        talc_error('TalcFrame:AwardPlayer: playerName is nil.')
        return false
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
        local link = TalcFrame.VotedItemsFrames[cvi].link
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

            core.asend( "playerWon#" .. GetMasterLootCandidate(unitIndex) .. "#" .. link .. "#" .. cvi .. "#" .. need)

            GiveMasterLoot(index, unitIndex);

            Screenshot()

            if disenchant then
                SendChatMessage(GetMasterLootCandidate(unitIndex) .. ' was awarded with ' .. link .. ' for Dissenchant!', "RAID")
            else
                SendChatMessage(GetMasterLootCandidate(unitIndex) .. ' was awarded with ' .. link .. ' for ' .. core.needs[need].text .. '!', "RAID")
            end

            TalcFrame.VotedItemsFrames[cvi].awardedTo = playerName
            TalcFrame:updateVotedItemsFrames()

        else
            talc_error('Item not found. Is the loot window opened ?')
        end
    end
end

function TalcFrame:UpdateCLVotedButtons()
    local index = 0
    --hide all
    for i = 0, 15 do
        if _G['CLVotedButton' .. i] then
            _G['CLVotedButton' .. i]:Hide()
        end
    end
    index = 0
    for name, voted in next, db['VOTE_ROSTER'] do
        index = index + 1
        local class = core.getPlayerClass(name)
        if not TalcFrame.CLVotedFrames[index] then
            TalcFrame.CLVotedFrames[index] = CreateFrame('Button', 'CLVotedButton' .. index, TalcVoteFrameCLThatVotedList, 'Talc_CLVotedButton')
        end
        TalcFrame.CLVotedFrames[index]:SetPoint("TOPLEFT", TalcVoteFrameCLThatVotedList, "TOPLEFT", index * 21 - 20, 0)
        TalcFrame.CLVotedFrames[index]:Show()
        TalcFrame.CLVotedFrames[index].name = name
        _G['CLVotedButton' .. index]:SetNormalTexture("Interface\\AddOns\\Talc\\images\\classes\\" .. class)
        _G['CLVotedButton' .. index]:SetPushedTexture("Interface\\AddOns\\Talc\\images\\classes\\" .. class)
        _G['CLVotedButton' .. index]:SetHighlightTexture("Interface\\AddOns\\Talc\\images\\classes\\" .. class)

        local CLButton = _G['CLVotedButton' .. index]

        CLButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -(this:GetWidth() / 4), -(this:GetHeight() / 4));
            GameTooltip:AddLine(this.name)
            GameTooltip:Show();
        end)

        CLButton:SetScript("OnLeave", function(self)
            GameTooltip:Hide();
        end)

        _G['CLVotedButton' .. index]:SetAlpha(0.3)

        --normal votes
        for n, _ in next, TalcFrame.itemVotes[TalcFrame.CurrentVotedItem] do
            for voter, vote in next, TalcFrame.itemVotes[TalcFrame.CurrentVotedItem][n] do
                if voter == name and vote == '+' then
                    _G['CLVotedButton' .. index]:SetAlpha(1)
                end
            end
        end

        --done voting
        if not voted then
            --check if he clicked done voting for this itme
            if TalcFrame.clDoneVotingItem[name] then
                for itemIndex, doneVoting in next, TalcFrame.clDoneVotingItem[name] do
                    if itemIndex == TalcFrame.CurrentVotedItem and doneVoting then
                        _G['CLVotedButton' .. index]:SetAlpha(1)
                    end
                end
            end
        end

    end
    TalcVoteFrameMLToWinnerNrOfVotes:Hide()
    TalcVoteFrameWinnerStatusNrOfVotes:Hide()
end

function closeWhoWindow()
    VoteFrameWho:Hide()
end

function TalcFrame:RaiderDetailsChangeTab(tab)

    if tab == 1 then
        TalcVoteFrameRaiderDetailsFrameTab1:SetText(FONT_COLOR_CODE_CLOSE .. 'Loot History')

        TalcVoteFrameRaiderDetailsFrameScrollFrame:Show()

        TalcVoteFrameRaiderDetailsFrameLootHistoryTitle:Show()

        if TalcVoteFrameRLWindowFrame:IsVisible() then
            TalcVoteFrameRLWindowFrame:Hide()
        end

        for index in next, TalcFrame.lootHistoryFrames do
            TalcFrame.lootHistoryFrames[index]:Hide()
        end

        Talc_LootHistory_Update()
    end

    TalcVoteFrameRaiderDetailsFrame:Show()
end

function TalcFrame:SetTokenRewardLink(reward, index)

    local _, _, itemLink = core.find(reward, "(item:%d+:%d+:%d+:%d+)");
    local _, link, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)
    if link then
        core.addButtonOnEnterTooltip(_G['TalcVoteFrameCurrentVotedItemQuestReward' .. index], link)
        _G['TalcVoteFrameCurrentVotedItemQuestReward' .. index]:SetNormalTexture(tex)
        _G['TalcVoteFrameCurrentVotedItemQuestReward' .. index]:SetPushedTexture(tex)
        _G['TalcVoteFrameCurrentVotedItemQuestReward' .. index]:Show()
    else
        GameTooltip:SetHyperlink(itemLink)
        GameTooltip:Hide()
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

    for i = 1, #TalcFrame.RLFrame.assistFrames, 1 do
        TalcFrame.RLFrame.assistFrames[i]:Hide()
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
        if not TalcFrame.RLFrame.assistFrames[i] then
            TalcFrame.RLFrame.assistFrames[i] = CreateFrame('Frame', 'AssistFrame' .. i, TalcVoteFrameRLWindowFrame, 'Talc_CLFrameTemplate')
        end

        TalcFrame.RLFrame.assistFrames[i]:SetPoint("TOPLEFT", TalcVoteFrameRLWindowFrame, "TOPLEFT", 4, d.y)
        TalcFrame.RLFrame.assistFrames[i]:Show()
        TalcFrame.RLFrame.assistFrames[i].name = d.name

        _G['AssistFrame' .. i .. 'AName']:SetText(d.color .. d.name)
        _G['AssistFrame' .. i .. 'CLCheck']:Enable()
        _G['AssistFrame' .. i .. 'AssistCheck']:Enable()

        _G['AssistFrame' .. i .. 'StatusIconOnline']:Hide()
        _G['AssistFrame' .. i .. 'StatusIconOffline']:Show()
        _G['AssistFrame' .. i .. 'AssistCheck']:Disable()
        if core.onlineInRaid(d.name) then
            _G['AssistFrame' .. i .. 'StatusIconOnline']:Show()
            _G['AssistFrame' .. i .. 'StatusIconOffline']:Hide()
            _G['AssistFrame' .. i .. 'AssistCheck']:Enable()
        end

        _G['AssistFrame' .. i .. 'CLCheck']:SetID(i)
        _G['AssistFrame' .. i .. 'AssistCheck']:SetID(i)

        _G['AssistFrame' .. i .. 'AssistCheck']:SetChecked(d.assist)
        _G['AssistFrame' .. i .. 'CLCheck']:SetChecked(d.cl)

        if d.name == core.me then
            if _G['AssistFrame' .. i .. 'CLCheck']:GetChecked() then
                _G['AssistFrame' .. i .. 'CLCheck']:Disable()
            end
            _G['AssistFrame' .. i .. 'AssistCheck']:Disable()
        end
    end

    TalcVoteFrameRLWindowFrameBISButton:SetChecked(db['VOTE_CONFIG']['NeedButtons']['BIS']);
    TalcVoteFrameRLWindowFrameMSButton:SetChecked(db['VOTE_CONFIG']['NeedButtons']['MS']);
    TalcVoteFrameRLWindowFrameOSButton:SetChecked(db['VOTE_CONFIG']['NeedButtons']['OS']);
    TalcVoteFrameRLWindowFrameXMOGButton:SetChecked(db['VOTE_CONFIG']['NeedButtons']['XMOG']);
end

function TalcFrame.RLFrame:SaveLootButton(button, value)
    db['VOTE_CONFIG']['NeedButtons'][button] = value;
end

function TalcFrame.RLFrame:ChangeTab(tab)

    if tab == 1 then
        TalcVoteFrameRLWindowFrameTab1:SetText(FONT_COLOR_CODE_CLOSE .. 'Officers')
        TalcVoteFrameRLWindowFrameTab2:SetText('|cff696969Loot Buttons')
        TalcVoteFrameRLWindowFrameTab3:SetText('|cff696969Loot History')

        TalcVoteFrameRLWindowFrameBISButton:Hide()
        TalcVoteFrameRLWindowFrameMSButton:Hide()
        TalcVoteFrameRLWindowFrameOSButton:Hide()
        TalcVoteFrameRLWindowFrameXMOGButton:Hide()
        TalcVoteFrameRaiderDetailsFrame:Hide()
        TalcVoteFrameRLWindowFrameSyncLootHistory:Hide()
        TalcVoteFrameRLWindowFrameNeedButtonsDesc:Hide()
        TalcVoteFrameRLWindowFrameNameTitle:Show()
        TalcVoteFrameRLWindowFrameAssist:Show()
        TalcVoteFrameRLWindowFrameOfficer:Show()
        for i = 1, #TalcFrame.RLFrame.assistFrames, 1 do
            TalcFrame.RLFrame.assistFrames[i]:Hide()
        end
        TalcFrame.RLFrame:CheckAssists()
    end
    if tab == 2 then
        TalcVoteFrameRLWindowFrameTab1:SetText('|cff696969Officers')
        TalcVoteFrameRLWindowFrameTab2:SetText(FONT_COLOR_CODE_CLOSE .. 'Loot Buttons')
        TalcVoteFrameRLWindowFrameTab3:SetText('|cff696969Loot History')

        TalcVoteFrameRLWindowFrameBISButton:Show()
        TalcVoteFrameRLWindowFrameMSButton:Show()
        TalcVoteFrameRLWindowFrameOSButton:Show()
        TalcVoteFrameRLWindowFrameXMOGButton:Show()

        TalcVoteFrameRaiderDetailsFrame:Hide()

        TalcVoteFrameRLWindowFrameSyncLootHistory:Hide()
        TalcVoteFrameRLWindowFrameNeedButtonsDesc:Show()
        TalcVoteFrameRLWindowFrameNameTitle:Hide()
        TalcVoteFrameRLWindowFrameAssist:Hide()
        TalcVoteFrameRLWindowFrameOfficer:Hide()
        for i = 1, #TalcFrame.RLFrame.assistFrames, 1 do
            TalcFrame.RLFrame.assistFrames[i]:Hide()
        end
    end
    if tab == 3 then
        TalcVoteFrameRLWindowFrameTab1:SetText('|cff696969Officers')
        TalcVoteFrameRLWindowFrameTab2:SetText('|cff696969Loot Buttons')
        TalcVoteFrameRLWindowFrameTab3:SetText(FONT_COLOR_CODE_CLOSE .. 'Loot History')

        TalcVoteFrameRLWindowFrameBISButton:Hide()
        TalcVoteFrameRLWindowFrameMSButton:Hide()
        TalcVoteFrameRLWindowFrameOSButton:Hide()
        TalcVoteFrameRLWindowFrameXMOGButton:Hide()

        TalcVoteFrameRaiderDetailsFrame:Hide()

        TalcVoteFrameRLWindowFrameSyncLootHistory:Show()
        TalcVoteFrameRLWindowFrameNeedButtonsDesc:Hide()
        TalcVoteFrameRLWindowFrameNameTitle:Hide()
        TalcVoteFrameRLWindowFrameAssist:Hide()
        TalcVoteFrameRLWindowFrameOfficer:Hide()
        for i = 1, #TalcFrame.RLFrame.assistFrames, 1 do
            TalcFrame.RLFrame.assistFrames[i]:Hide()
        end
    end
end


TalcFrame.VoteCountdown = CreateFrame("Frame")
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
        if TalcFrame.LootCountdown.currentTime ~= TalcFrame.LootCountdown.countDownFrom + plus then
            --tick

            if TalcFrame.VotedItemsFrames[TalcFrame.CurrentVotedItem] then
                if TalcFrame.VotedItemsFrames[TalcFrame.CurrentVotedItem].pickedByEveryone then
                    TalcVoteFrameTimeLeftBar:Hide()
                else
                    TalcVoteFrameTimeLeftBar:Show()
                end
            end

            local tlx = 15 + ((TalcFrame.LootCountdown.countDownFrom - TalcFrame.LootCountdown.currentTime + plus) * 500 / TalcFrame.LootCountdown.countDownFrom)
            if tlx > 470 then
                tlx = 470
            end
            if tlx <= 250 then
                tlx = 250
            end
            if core.floor(TalcFrame.LootCountdown.countDownFrom - TalcFrame.LootCountdown.currentTime) > 55 then
                TalcVoteFrameTimeLeft:Show()
            end
            if core.floor(TalcFrame.LootCountdown.countDownFrom - TalcFrame.LootCountdown.currentTime) <= 55 then
                TalcVoteFrameTimeLeft:Show()
            end
            if core.floor(TalcFrame.LootCountdown.countDownFrom - TalcFrame.LootCountdown.currentTime) < 1 then
                TalcVoteFrameTimeLeft:Hide()
            end

            local secondsLeft = core.floor(TalcFrame.LootCountdown.countDownFrom - TalcFrame.LootCountdown.currentTime) -- .. 's'

            TalcVoteFrameTimeLeft:SetText(core.SecondsToClock(secondsLeft))
            TalcVoteFrameTimeLeft:SetPoint("BOTTOMLEFT", 280, 10)

            TalcVoteFrameTimeLeftBar:SetWidth((TalcFrame.LootCountdown.countDownFrom - TalcFrame.LootCountdown.currentTime + plus) * 592 / TalcFrame.LootCountdown.countDownFrom)
        end
        TalcFrame.LootCountdown:Hide()
        if (TalcFrame.LootCountdown.currentTime < TalcFrame.LootCountdown.countDownFrom + plus) then
            --still tick
            TalcFrame.LootCountdown.currentTime = TalcFrame.LootCountdown.currentTime + plus
            TalcFrame.LootCountdown:Show()
        elseif (TalcFrame.LootCountdown.currentTime > TalcFrame.LootCountdown.countDownFrom + plus) then

            --end
            TalcFrame.LootCountdown:Hide()
            TalcFrame.LootCountdown.currentTime = 1

            TalcVoteFrameMLToWinner:Enable()

            --set all auto pass v2 (no wait=)
            local onlineRaiders = core.getNumOnlineRaidMembers()
            for raidi = 0, GetNumRaidMembers() do
                if GetRaidRosterInfo(raidi) then
                    local n, _, _, _, _, _, z = GetRaidRosterInfo(raidi);
                    if z ~= 'Offline' then

                        for index, _ in next, TalcFrame.VotedItemsFrames do
                            local picked = false
                            for i = 1, #TalcFrame.playersWhoWantItems do
                                if TalcFrame.playersWhoWantItems[i]['itemIndex'] == index and TalcFrame.playersWhoWantItems[i]['name'] == n then
                                    picked = true
                                    break
                                end
                            end
                            if not picked then
                                --add player to playersWhoWant with autopass
                                --can be disabled to hide autopasses
                                core.insert(TalcFrame.playersWhoWantItems, {
                                    ['itemIndex'] = index,
                                    ['name'] = n,
                                    ['need'] = 'autopass',
                                    ['ci1'] = '0',
                                    ['ci2'] = '0',
                                    ['ci3'] = '0',
                                    ['votes'] = 0,
                                    ['roll'] = 0
                                })

                                --increment pick responses, even for autopass
                                if TalcFrame.pickResponses[index] then
                                    if TalcFrame.pickResponses[index] < onlineRaiders then
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

            TalcFrame_VoteFrameListScroll_Update()

            TalcFrame.VoteCountdown:Show()

        end
    end
end)

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
        if (TalcFrame.VoteCountdown.currentTime ~= TalcFrame.VoteCountdown.countDownFrom + plus) then
            --tick
            if (TalcFrame.VoteCountdown.countDownFrom - TalcFrame.VoteCountdown.currentTime) >= 0 then
                TalcVoteFrameTimeLeft:Show()
                local secondsLeftToVote = core.floor((TalcFrame.VoteCountdown.countDownFrom - TalcFrame.VoteCountdown.currentTime)) --.. 's left ! '
                TalcVoteFrameTimeLeft:SetPoint("BOTTOMLEFT", 240, 10)
                if TalcFrame.doneVoting[TalcFrame.CurrentVotedItem] == true then
                    TalcVoteFrameTimeLeft:SetText('')
                else
                    TalcVoteFrameTimeLeft:SetText('Please VOTE ! ' .. core.SecondsToClock(secondsLeftToVote))
                end

                local w = core.floor(((TalcFrame.VoteCountdown.countDownFrom - TalcFrame.VoteCountdown.currentTime) / TalcFrame.VoteCountdown.countDownFrom) * 1000)
                w = w / 1000

                if w > 0 and w <= 1 then
                    TalcVoteFrameTimeLeftBar:Show()
                    TalcVoteFrameTimeLeftBar:SetWidth(592 * w)
                else
                    TalcVoteFrameTimeLeftBar:Hide()
                end
            end

            TalcFrame.VoteCountdown:Hide()
            if (TalcFrame.VoteCountdown.currentTime < TalcFrame.VoteCountdown.countDownFrom + plus) then
                --still tick
                TalcFrame.VoteCountdown.currentTime = TalcFrame.VoteCountdown.currentTime + plus
                TalcFrame.VoteCountdown:Show()
            elseif (TalcFrame.VoteCountdown.currentTime > TalcFrame.VoteCountdown.countDownFrom + plus) then
                TalcFrame.VoteCountdown:Hide()
                TalcFrame.VoteCountdown.currentTime = 1

                TalcVoteFrameTimeLeft:Show()
                TalcVoteFrameTimeLeft:SetText('')
                TalcVoteFrameMLToWinner:Enable()
            end
        end
    end
end)


function buildMinimapMenu()
    local separator = {};
    separator.text = ""
    separator.disabled = true

    local title = {};
    title.text = "TALC"
    title.disabled = false
    title.isTitle = true
    title.func = function()
        --
    end
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
    UIDropDownMenu_AddButton(separator);

    local close = {};
    close.text = "Close"
    close.disabled = false
    close.isTitle = false
    close.func = function()
        --
    end
    UIDropDownMenu_AddButton(close);
end

function TestNeedButton_OnClick()


    local testItem1 = "\124cffa335ee\124Hitem:47215:0:0:0:0:0:0:0:0\124h[FOR STRENGTH FOR STAM]\124h\124r";
    local testItem2 = "\124cffa335ee\124Hitem:40612:0:0:0:0:0:0:0:0\124h[LEATHER BELT LVL 18]\124h\124r"

    local _, _, itemLink1 = core.find(testItem1, "(item:%d+:%d+:%d+:%d+)");
    local lootName1, _, quality1, _, _, _, _, _, _, lootIcon1 = GetItemInfo(itemLink1)

    local _, _, itemLink2 = core.find(testItem2, "(item:%d+:%d+:%d+:%d+)");
    local lootName2, _, quality2, _, _, _, _, _, _, lootIcon2 = GetItemInfo(itemLink2)

    if quality1 and lootIcon1 and quality2 and lootIcon2 then

        --SendChatMessage('This is a test, click whatever you want!', "RAID_WARNING")
        TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()

        core.SetDynTTN(2)
        TalcFrame.LootCountdown.countDownFrom = db['VOTE_TTN']
        core.asend('ttn=' .. db['VOTE_TTN'])
        core.SetDynTTV(2)
        core.asend('ttv=' .. db['VOTE_TTV'])
        core.asend('ttr=' .. db['VOTE_TTR'])

        TalcFrame:SendReset()

        TalcFrame.LootCountdown:Show()
        core.asend('countdownframe=show')

        core.bsend("ALERT",  "preloadInVoteFrame=1=" .. lootIcon1 .. "=" .. lootName1 .. "=" .. testItem1)
        core.bsend("ALERT",  "preloadInVoteFrame=2=" .. lootIcon2 .. "=" .. lootName2 .. "=" .. testItem2)

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

        core.bsend("ALERT",  "loot=1=" .. lootIcon1 .. "=" .. lootName1 .. "=" .. testItem1 .. "=" .. TalcFrame.LootCountdown.countDownFrom .. "=" .. buttons)
        core.bsend("ALERT",  "loot=2=" .. lootIcon2 .. "=" .. lootName2 .. "=" .. testItem2 .. "=" .. TalcFrame.LootCountdown.countDownFrom .. "=" .. buttons)
        core.bsend("ALERT",  "doneSending=2=items")

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