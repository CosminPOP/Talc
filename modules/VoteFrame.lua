local db, core, tokenRewards
local _G = _G

local ContestantDropdownMenu = CreateFrame('Frame', 'ContestantDropdownMenu', UIParent, 'UIDropDownMenuTemplate')
ContestantDropdownMenu.currentContestantId = 0

VoteFrame = CreateFrame("Frame")

----------------------------------------------------
--- Vars
----------------------------------------------------

VoteFrame.VotedItemsFrames = {}
VoteFrame.CurrentVotedItem = nil --slotIndex
VoteFrame.currentPlayersList = {} --all
VoteFrame.itemVotes = {}
VoteFrame.playersWhoWantItems = {}
VoteFrame.voteTiePlayers = ''
VoteFrame.currentItemWinner = ''
VoteFrame.currentItemMaxVotes = 0
VoteFrame.currentRollWinner = ''
VoteFrame.currentMaxRoll = {}

VoteFrame.numPlayersThatWant = 0
VoteFrame.namePlayersThatWants = 0

VoteFrame.receivedResponses = 0
VoteFrame.pickResponses = {}

VoteFrame.selectedPlayer = {}

VoteFrame.lootHistoryFrames = {}

VoteFrame.doneVoting = {} --self / item
VoteFrame.OfficerDoneVotingItem = {}
VoteFrame.OfficerVoted = {}

VoteFrame.sentReset = false

VoteFrame.numItems = 0

VoteFrame.OfficerVotedFrames = {}

VoteFrame.HistoryId = 0

VoteFrame.contestantsFrames = {}
VoteFrame.bagItems = {}
VoteFrame.inspectPlayerGear = {}

VoteFrame.welcomeItemsFrames = {}

VoteFrame.withAddon = {}
VoteFrame.withAddonFrames = {}

VoteFrame.closeVoteFrameFromSettings = false

VoteFrame.itemRewardsFrames = {}

VoteFrame.wishlistItemsFrames = {}

VoteFrame.itemHistoryIndex = 0
VoteFrame.itemHistoryFrames = {}
VoteFrame.playerHistoryFrames = {}

VoteFrame.screens = {
    'Voting',
    'Welcome', 'Settings', 'Wishlist' --, Attendance
}

VoteFrame.syncLootHistoryCount = 0

VoteFrame.wishlistSearchItemsFrames = {}

VoteFrame.attendanceFrames = {}
VoteFrame.expandedAttendanceFrames = {}

VoteFrame.officerFrames = {}

VoteFrame.manualLootSync = false

----------------------------------------------------
--- Init
----------------------------------------------------

function VoteFrame:Init()

    db = TALC_DB
    core = TALC
    tokenRewards = TALC_TOKENS

    VoteFrame.periodicSync.plus = 30 -- core.floor(3600 / core.min(core.periodicSyncMaxItems, core.n(db['VOTE_LOOT_HISTORY'])))
    VoteFrame.periodicSync:Show()

    OpenCalendar()

    self:ResetVars()
end

function VoteFrame:ResetVars()

    self:ShowScreen('Welcome')

    self.LootCountdown:Hide()
    self.VoteCountdown:Hide()

    self.CurrentVotedItem = nil
    self.currentPlayersList = {}
    self.playersWhoWantItems = {}

    self.pickResponses = {}
    self.receivedResponses = 0

    self.itemVotes = {}

    self.myVotes = {}
    self.OfficerVoted = {}

    self.selectedPlayer = {}
    self.inspectPlayerGear = {}

    self.doneVoting = {}
    self.OfficerDoneVotingItem = {}

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

    for _, frame in next, self.VotedItemsFrames do
        frame:Hide()
    end
    for _, frame in next, self.contestantsFrames do
        frame:Hide()
    end
    for _, frame in next, self.itemRewardsFrames do
        frame:Hide()
    end

    TalcVoteFrame:SetScale(db['VOTE_SCALE'])

    TalcVoteFrameVotesLabel:SetText('Votes')
    TalcVoteFrameWinnerStatus:Hide()

    TalcVoteFrameMLToWinner:Disable()
    TalcVoteFrameMLToEnchanter:Hide()

    TalcVoteFrameCurrentVotedItemButton:Hide()
    TalcVoteFrameVotedItemName:Hide()
    TalcVoteFrameVotedItemType:Hide()

    TalcVoteFrameRLExtraFrameBroadcastLoot:SetText('Load Items')
    TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()

    TalcVoteFrameDoneVoting:Disable()
    TalcVoteFrameDoneVotingCheck:Hide()
    TalcVoteFrameContestantScrollListFrame:Hide()

    TalcVoteFrameTradableItemsFrame:Hide()

    --TalcVoteFrameContestantScrollListFrame:SetPoint("TOPLEFT", TalcVoteFrame, "TOPLEFT", 5, -109)
    --TalcVoteFrameContestantScrollListFrame:SetPoint("BOTTOMRIGHT", TalcVoteFrame, "BOTTOMRIGHT", -5, 28)

    TalcVoteFrameRLExtraFrameDragLoot:SetText("Drag Loot")
    TalcVoteFrameRLExtraFrameDragLoot:Enable()

    if core.isRaidLeader() then
        TalcVoteFrameRLExtraFrame:Show()

        TalcVoteFrameMLToEnchanter:SetScript("OnEnter", function(self)
            TALCTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", -100, 0)
            if db['VOTE_ENCHANTER'] == '' then
                TALCTooltip:AddLine("Enchanter not set. Type /talc set enchanter [name]")
            else
                TALCTooltip:AddLine("ML to " .. db['VOTE_ENCHANTER'] .. " to disenchant.")
            end
            TALCTooltip:Show()
        end)

        TalcVoteFrameMLToEnchanter:SetScript("OnLeave", function(self)
            TALCTooltip:Hide()
        end)
    else
        TalcVoteFrameRLExtraFrame:Hide()
    end

    core.clearScrollbarTexture(TalcVoteFrameContestantScrollListFrameScrollBar)
    core.clearScrollbarTexture(TalcVoteFrameWelcomeFrameItemsScrollFrameScrollBar)
    core.clearScrollbarTexture(TalcVoteFrameWelcomeFrameItemHistoryScrollFrameScrollBar)
    core.clearScrollbarTexture(TalcVoteFrameWelcomeFramePlayerHistoryScrollFrameScrollBar)
    core.clearScrollbarTexture(TalcVoteFrameRaiderDetailsFrameLootHistoryFrameScrollFrameScrollBar)
    core.clearScrollbarTexture(TalcVoteFrameRaiderDetailsFrameAttendanceFrameScrollFrameScrollBar)

end

----------------------------------------------------
--- Event Handler
----------------------------------------------------

function VoteFrame:HandleSync(_, t, _, sender)
    if not core.find(t, 'Periodic', 1, true) then
        talc_debug(sender .. ' says: ' .. t)
    end

    if core.subFind(t, 'SendAverageItemLevel=') then
        core.wsend("ALERT", "MyAverageItemLevel=" .. core.getAverageItemLevel(), sender)
        return
    end

    if core.subFind(t, 'MyAverageItemLevel=') then
        local ilEx = core.split('=', t)
        local ilColor = ITEM_QUALITY_COLORS[4].hex

        if core.int(ilEx[2]) < 140 then
            ilColor = ITEM_QUALITY_COLORS[2].hex
        elseif core.int(ilEx[2]) < 200 then
            ilColor = ITEM_QUALITY_COLORS[3].hex
        end
        talc_print(sender .. "'s average item level is " .. ilColor .. ilEx[2])
        return
    end

    if core.subFind(t, 'CurrentBoss=') then
        if not core.canVote() then
            return
        end
        if not core.isRaidLeader(sender) then
            return
        end

        local bossName = core.split('=', t)
        if not bossName[2] then
            return
        end

        self:SetTitle(bossName[2])
        return
    end

    if core.subFind(t, 'DoneSending=') then
        if not core.canVote() then
            return
        end
        if not core.isRaidLeader(sender) then
            return
        end
        local nrItems = core.split('=', t)
        if not nrItems[2] then
            talc_error('wrong doneSending syntax')
            talc_error(t)
            return
        end
        TalcVoteFrameTimeLeftBarTextLeft:SetText('Loot sent. Waiting picks...')
        core.asend("OfficerReceived=" .. self.numItems)
        return
    end

    if core.subFind(t, 'OfficerReceived=') then
        if not core.isRaidLeader() then
            return
        end

        local nrItems = core.split('=', t)
        if not nrItems[2] then
            talc_error('wrong OfficerReceived syntax')
            talc_error(t)
            return
        end

        if core.int(nrItems[2]) ~= self.numItems then
            talc_error('Officer ' .. sender .. ' got ' .. nrItems[2] .. '/' .. self.numItems .. ' items.')
        end
        return
    end

    if core.subFind(t, 'Received=') then
        if not core.isRaidLeader() then
            return
        end

        local nrItems = core.split('=', t)
        if not nrItems[2] then
            talc_error('wrong received syntax')
            talc_error(t)
            return
        end

        if core.int(nrItems[2]) ~= self.numItems then
            talc_error('Player ' .. sender .. ' got ' .. nrItems[2] .. '/' .. self.numItems .. ' items.')
        else
            self.receivedResponses = self.receivedResponses + 1
        end
        return
    end

    if core.subFind(t, 'PlayerRoll=') then

        if not core.isRaidLeader(sender) or sender == core.me then
            return
        end
        if not core.canVote() then
            return
        end

        local indexEx = core.split('=', t)

        if not indexEx[4] then
            talc_error('bad playerRoll syntax 4')
            talc_error(t)
            return
        end
        if not core.int(indexEx[3]) then
            talc_error('bad playerRoll syntax 3')
            talc_error(t)
            return
        end

        self.playersWhoWantItems[core.int(indexEx[2])]['roll'] = core.int(indexEx[3])
        self.VotedItemsFrames[core.int(indexEx[4])].rolled = true
        self:VoteFrameListUpdate()
        return
    end

    if core.subFind(t, 'ChangePickTo=') then

        if not core.isRaidLeader(sender) or sender == core.me then
            return
        end
        if not core.canVote() then
            return
        end

        local pickEx = core.split('=', t)
        if not pickEx[4] then
            talc_error('bad changePick syntax 4')
            talc_error(t)
            return
        end

        if not core.int(pickEx[4]) then
            talc_error('bad changePick itemIndex 42')
            talc_error(t)
            return
        end

        self:ChangePlayerPickTo(pickEx[2], pickEx[3], core.int(pickEx[4]))
        return
    end

    if core.subFind(t, 'RollChoice=') then

        if not core.canVote() then
            return
        end

        local r = core.split('=', t)
        if not r[3] then
            talc_debug('bad rollChoice syntax')
            talc_debug(t)
            return
        end

        if core.int(r[3]) == -1 then
            --pass
            for pwIndex, pwPlayer in next, self.playersWhoWantItems do
                if pwPlayer.name == sender and pwPlayer.roll == -2 then
                    self.playersWhoWantItems[pwIndex].roll = core.int(r[3])
                    self:updateVotedItemsFrames()
                    break
                end
            end
        else
            talc_debug('ROLLCATCHER ' .. sender .. ' rolled for ' .. r[2])
        end
        return
    end

    if core.subFind(t, 'ItemVote=') then

        if not core.canVote(sender) or sender == core.me then
            return
        end
        if not core.canVote() then
            return
        end

        local itemVoteEx = core.split('=', t)

        if not itemVoteEx[4] then
            talc_error('bad itemVote syntax')
            talc_error(t)
            return
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

    if core.subFind(t, 'DoneVoting=', 1, true) then
        if not core.canVote(sender) or not core.canVote() then
            return
        end

        local itemEx = core.split('=', t)
        if not itemEx[2] then
            talc_error('bad doneVoting syntax')
            talc_error(t)
            return
        end

        if not self.OfficerDoneVotingItem[sender] then
            self.OfficerDoneVotingItem[sender] = {}
        end
        self.OfficerDoneVotingItem[sender][core.int(itemEx[2])] = true

        self:VoteFrameListUpdate()
        return
    end

    if core.subFind(t, 'VersionQuery=') then
        core.asend("VersionReply=" .. sender .. "=" .. core.addonVer)
        return
    end

    if core.subFind(t, 'VersionQueryGuild=') then
        core.bsendg(nil, "VersionReplyGuild=" .. sender .. "=" .. core.addonVer)
        return
    end

    if core.subFind(t, 'VersionReply=') or core.subFind(t, 'VersionReplyGuild=') then
        local vEx = core.split("=", t)
        if vEx[2] == core.me then
            if vEx[3] then
                local verColor = ''
                local ver = vEx[3]
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

    if core.subFind(t, 'VoteFrame=') then

        if not core.isRaidLeader(sender) then
            return
        end

        if not core.canVote() then
            return
        end

        local command = core.split('=', t)

        if not command[2] then
            talc_error('bad voteframe= syntax')
            talc_error(t)
            return
        end

        if command[2] == "Reset" then
            self:ResetVars()
        end
        if command[2] == "Close" then
            self:CloseWindow()
        end
        return
    end

    if core.subFind(t, 'PreloadItem=') then

        if not core.isRaidLeader(sender) then
            return
        end

        local item = core.split("=", t)

        if not item[5] then
            talc_error('5bad loot syntax')
            talc_error(t)
            return
        end

        if not core.int(item[2]) then
            talc_error('2bad loot index')
            talc_error(t)
            return
        end

        local index = core.int(item[2])
        local texture = item[3]
        local link = item[5]

        local _, _, itemLink = core.find(link, "(item:%d+:%d+:%d+:%d+)")
        local itemID = core.split(':', itemLink)
        core.CacheItem(core.int(itemID[2]))

        if not core.canVote() then
            return
        end

        self.numItems = self.numItems + 1

        self:AddVotedItem(index, texture, link)

        self:ShowScreen("Voting")

        if core.n(self.bagItems) > 0 then
            TalcVoteFrameRLExtraFrameDragLoot:Enable()
            TalcVoteFrameRLExtraFrameDragLoot:SetText("Send " .. core.n(self.bagItems) .. " Item(s)")
            TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()
        else
            TalcVoteFrameRLExtraFrameDragLoot:Disable()
            TalcVoteFrameRLExtraFrameBroadcastLoot:SetText('Send Loot (' .. db['VOTE_TTN'] .. 's)')
            TalcVoteFrameRLExtraFrameBroadcastLoot:Enable()
        end

        return
    end

    if core.subFind(t, 'CountDownFrame=') then

        if not core.isRaidLeader(sender) or not core.canVote() then
            return
        end

        local action = core.split("=", t)

        if not action[2] then
            talc_error('bad countdownframe syntax')
            talc_error(t)
            return
        end

        if action[2] == 'Show' then
            self.LootCountdown:Show()
        end
        return
    end
    --ms=1=item:123=item:323
    if core.subFind(t, 'bis=')
            or core.subFind(t, 'ms=')
            or core.subFind(t, 'os=')
            or core.subFind(t, 'xmog=')
            or core.subFind(t, 'pass=')
            or core.subFind(t, 'autopass=') then

        if not core.canVote() then
            return
        end

        local needEx = core.split('=', t)

        if not needEx[7] then
            talc_error('bad need syntax')
            talc_error(t)
            return
        end

        if core.subFind(t, 'autopass=') then
            return
        end

        -- double need protection
        if core.n(self.playersWhoWantItems) > 0 then
            for i = 1, core.n(self.playersWhoWantItems) do
                if self.playersWhoWantItems[i].itemIndex == core.int(needEx[2]) and
                        self.playersWhoWantItems[i].name == sender then
                    return
                end
            end
        end

        core.insert(self.playersWhoWantItems, {
            itemIndex = core.int(needEx[2]),
            name = sender,
            need = needEx[1],
            ci1 = needEx[3],
            ci2 = needEx[4],
            ci3 = needEx[5],
            ci4 = needEx[6],
            votes = 0,
            roll = 0,
            itemLevel = core.int(needEx[7]),
            inWishlist = needEx[8] == '1'
        })

        self.itemVotes[core.int(needEx[2])] = {}
        self.itemVotes[core.int(needEx[2])][sender] = {}

        if self.pickResponses[core.int(needEx[2])] then
            self.pickResponses[core.int(needEx[2])] = self.pickResponses[core.int(needEx[2])] + 1
        else
            self.pickResponses[core.int(needEx[2])] = 1
        end

        self:VoteFrameListUpdate()
        return
    end

    -- roster sync
    if core.subFind(t, 'SyncRoster=') then
        if not core.isRaidLeader(sender) or sender == core.me then
            return
        end

        db['VOTE_ROSTER'] = {}

        for index, officer in next, core.split('=', t) do
            if index > 1 then
                core.insert(db['VOTE_ROSTER'], officer)
            end
        end

        if TalcVoteFrameWelcomeFrame:IsVisible() and not TalcVoteFrameWelcomeFrameBackButton:IsVisible() then
            self:WelcomeFrame_OnShow()
        end
        talc_debug('Roster updated.')
        return
    end

    if core.subFind(t, 'PlayerWon=') then

        if not core.isRaidLeader(sender) then
            return
        end

        local wonData = core.split("=", t)

        if not wonData[7] then
            talc_error('bad playerWon syntax')
            talc_error(t)
            return
        end

        local timestamp, player, item, index, pick, raid

        timestamp = core.int(wonData[2])
        player = wonData[3]
        item = wonData[4]
        index = core.int(wonData[5])
        pick = wonData[6]
        raid = wonData[7]

        if core.canVote() then
            self.VotedItemsFrames[index].awardedTo = player
            self:updateVotedItemsFrames()
        end

        --save loot in history
        db['VOTE_LOOT_HISTORY'][timestamp] = {
            player = player,
            class = core.getPlayerClass(player),
            item = item,
            pick = pick,
            raid = raid
        }

        -- update welcome items if visible
        if TalcVoteFrameWelcomeFrame:IsVisible() and not TalcVoteFrameWelcomeFrameBackButton:IsVisible() then
            self:WelcomeFrame_OnShow()
        end
        return
    end

    if core.subFind(t, 'Timers:ttn') then
        if not core.isRaidLeader(sender) then
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

    if core.subFind(t, 'PeriodicLootHistorySync=') then
        if sender ~= core.me then
            local lh = core.split("=", t)
            if not lh[7] then
                if t ~= 'LootHistorySync=Start' and t ~= 'LootHistorySync=End' then
                    talc_error('bad PeriodicLootHistorySync syntax')
                    talc_error(t)
                    return
                end
            end

            local timestamp, player, class, item, pick, raid

            timestamp = core.int(lh[2])
            player = lh[3]
            class = lh[4]
            item = lh[5]
            pick = lh[6]
            raid = lh[7]

            -- ignore old loot
            if timestamp < 1654672311 then
                return
            end

            local _, _, itemLink = core.find(item, "(item:%d+:%d+:%d+:%d+)")
            local itemID = core.int(core.split(':', itemLink)[2])
            core.CacheItem(itemID)

            if not db['VOTE_LOOT_HISTORY'][timestamp] then
                db['VOTE_LOOT_HISTORY'][timestamp] = {
                    player = player,
                    class = class,
                    item = item,
                    pick = pick,
                    raid = raid
                }
            end

            -- update welcome items if visible
            if TalcVoteFrameWelcomeFrame:IsVisible() and not TalcVoteFrameWelcomeFrameBackButton:IsVisible() then
                --self:WelcomeFrame_OnShow()
            end
        end
        return
    end

    if core.subFind(t, 'LootHistorySync=') then

        if not core.isRaidLeader(sender) then
            return
        end

        local totalItems = 0
        for _ in next, db['VOTE_LOOT_HISTORY'] do
            totalItems = totalItems + 1
        end

        local lh = core.split("=", t)

        if not lh[7] then
            if t ~= 'LootHistorySync=Start' and t ~= 'LootHistorySync=End' then
                talc_error('bad loothistorysync syntax')
                talc_error(t)
                return
            end
        end

        if lh[2] == 'Start' then
        elseif lh[2] == 'End' then
            if sender == core.me then
                VoteFrame.manualLootSync = false
                talc_print('History Sync complete.')
                TalcVoteFrameRLWindowFrameTab2ContentsSyncLootHistory:Enable()
                TalcVoteFrameRLWindowFrameTab2ContentsSyncLootHistory:SetText('Sync Loot History (' .. totalItems .. ')')
                return
            end
        else

            if sender == core.me then
                if VoteFrame.manualLootSync then
                    self.syncLootHistoryCount = self.syncLootHistoryCount + 1
                    local percent = core.floor(self.syncLootHistoryCount * 100 / totalItems)
                    TalcVoteFrameRLWindowFrameTab2ContentsSyncLootHistory:SetText('Syncing (' .. percent .. '%)')
                    return
                end
            else
                local timestamp, player, class, item, pick, raid

                timestamp = core.int(lh[2])
                player = lh[3]
                class = lh[4]
                item = lh[5]
                pick = lh[6]
                raid = lh[7]

                local _, _, itemLink = core.find(item, "(item:%d+:%d+:%d+:%d+)")
                local itemID = core.int(core.split(':', itemLink)[2])
                core.CacheItem(itemID)

                if not db['VOTE_LOOT_HISTORY'][timestamp] then
                    db['VOTE_LOOT_HISTORY'][timestamp] = {
                        player = player,
                        class = class,
                        item = item,
                        pick = pick,
                        raid = raid
                    }
                end
            end
        end

        -- update welcome items if visible
        if TalcVoteFrameWelcomeFrame:IsVisible() then
            self:WelcomeFrame_OnShow()
        end

        return
    end

    if core.subFind(t, 'SendingGear=', 1, true) then

        if t == 'SendingGear=Start' then
            self.inspectPlayerGear[sender] = {}
            return
        end

        if t == 'SendingGear=End' then
            self:RaiderDetailsShowGear()
            return
        end

        local tEx = core.split('=', t)
        local gearEx = core.split(':', tEx[2])

        core.CacheItem(core.int(gearEx[2]))

        self.inspectPlayerGear[sender][core.int(gearEx[6])] = {
            item = gearEx[1] .. ":" .. gearEx[2] .. ":" .. gearEx[3] .. ":" .. gearEx[4] .. ":" .. gearEx[5],
            enchant = core.int(gearEx[3]),
            slot = gearEx[7]
        }

        return
    end
end

----------------------------------------------------
--- Minimap
----------------------------------------------------

function VoteFrame:HideMinimapButton()
    Talc_Minimap:Hide()
    TALC_DB['MINIMAP_BUTTON'] = 'hidden'
    talc_print("Minimap Button hidden. Type /talc minimap to restore it.")
end

function Talc_BuildMinimapMenu()
    local separator = {}
    separator.text = ""
    separator.disabled = true

    local title = {}
    title.text = "TALC"
    title.disabled = false
    title.isTitle = true
    UIDropDownMenu_AddButton(title)
    UIDropDownMenu_AddButton(separator)

    local menu_enabled = {}
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
            VoteFrame:CloseWindow()
            talc_print('Addon disabled.')
        end
    end
    UIDropDownMenu_AddButton(menu_enabled)
    local menu_settings = {}
    menu_settings.text = "Settings"
    menu_settings.isTitle = false
    menu_settings.justifyH = 'LEFT'
    menu_settings.func = function()
        VoteFrame:ShowWindow()
        VoteFrame:ShowScreen("Settings")
    end
    UIDropDownMenu_AddButton(menu_settings)

    local menu_hide = {}
    menu_hide.text = "Hide Minimap Button"
    menu_hide.isTitle = false
    menu_hide.justifyH = 'LEFT'
    menu_hide.func = function()
        VoteFrame:HideMinimapButton()
    end
    UIDropDownMenu_AddButton(menu_hide)
    UIDropDownMenu_AddButton(separator)

    local close = {}
    close.text = "Close"
    close.disabled = false
    close.isTitle = false
    UIDropDownMenu_AddButton(close)
end

function VoteFrame:ShowMinimapDropdown()
    local TALCMinimapMenuFrame = CreateFrame('Frame', 'TALCMinimapMenuFrame', UIParent, 'UIDropDownMenuTemplate')
    UIDropDownMenu_Initialize(TALCMinimapMenuFrame, Talc_BuildMinimapMenu, "MENU")
    ToggleDropDownMenu(1, nil, TALCMinimapMenuFrame, Talc_Minimap, 1, 1)
end

----------------------------------------------------
--- Main Window
----------------------------------------------------

function VoteFrame:ToggleMainWindow_OnClick()

    if TalcVoteFrame:IsVisible() then
        self:CloseWindow()
    else
        if db['VOTE_ENABLED'] then
            self:ShowWindow()
        else
            talc_print("TALC is disabled.")
        end
    end
end

function VoteFrame:ShowWindow()
    if not TalcVoteFrame:IsVisible() then
        TalcVoteFrame:Show()
        TalcVoteFrame.animIn:Play()
    end
end

function VoteFrame:CloseWindow()
    TalcVoteFrame.animOut:Play()
    TalcVoteFrameRaiderDetailsFrame:Hide()
    TalcVoteFrameRLWindowFrame:Hide()
end

function VoteFrame:ResetClose_OnClick()
    self:SendReset()
    self:SendCloseWindow()
    self.sentReset = false
    SetLootMethod("master", core.me)
end

function VoteFrame:SendReset()
    core.asend("VoteFrame=Reset")
    core.asend("NeedFrame=Reset")
    core.asend("RollFrame=Reset")
    core.asend("BossLootFrame=Reset")
end

function VoteFrame:SendCloseWindow()
    core.asend("VoteFrame=Close")
end

----------------------------------------------------
--- Raider's Details
----------------------------------------------------

function VoteFrame:RaiderDetailsClose()
    if self.selectedPlayer[self.CurrentVotedItem] then
        self.selectedPlayer[self.CurrentVotedItem] = ''
    end
    TalcVoteFrameRaiderDetailsFrame:Hide()
end

function Talc_LootHistory_Update()
    VoteFrame:LootHistoryUpdate()
end

function VoteFrame:LootHistoryUpdate()

    local itemOffset = FauxScrollFrame_GetOffset(TalcVoteFrameRaiderDetailsFrameLootHistoryFrameScrollFrame)

    local id = self.HistoryId

    self.selectedPlayer[self.CurrentVotedItem] = _G['TALCContestantFrame' .. id].name

    local historyPlayerName = _G['TALCContestantFrame' .. id].name

    local totalItems = 0
    for _, item in next, db['VOTE_LOOT_HISTORY'] do
        if historyPlayerName == item.player then
            totalItems = totalItems + 1
        end
    end

    for index in next, self.lootHistoryFrames do
        self.lootHistoryFrames[index]:Hide()
    end

    if totalItems > 0 then

        local index = 0
        for timestamp, item in core.pairsByKeysReverse(db['VOTE_LOOT_HISTORY']) do
            if historyPlayerName == item.player then

                index = index + 1

                if index > itemOffset and index <= itemOffset + 7 then

                    if not self.lootHistoryFrames[index] then
                        self.lootHistoryFrames[index] = CreateFrame('Button', 'TALCHistoryItem' .. index, TalcVoteFrameRaiderDetailsFrameLootHistoryFrameScrollFrame, 'Talc_WelcomeItemTemplate')
                    end

                    local frame = 'TALCHistoryItem' .. index

                    _G[frame]:SetPoint("TOPLEFT", TalcVoteFrameRaiderDetailsFrameLootHistoryFrameScrollFrame, "TOPLEFT", 5, 37 - 39 * (index - itemOffset))
                    _G[frame]:Show()
                    _G[frame]:SetWidth(190)

                    local today = ''
                    if date("%d/%m") == date("%d/%m", core.localTimeFromServerTime(timestamp)) then
                        today = core.classColors['mage'].colorStr
                    end

                    _G[frame .. 'TopText']:SetWidth(165)
                    _G[frame .. 'TopText']:SetText(item.item)
                    _G[frame .. 'MiddleText']:SetText(core.needs[item.pick].colorStr .. core.needs[item.pick].text)
                    _G[frame .. 'BottomText']:SetText(core.classColors['rogue'].colorStr .. today .. date("%d/%m", core.localTimeFromServerTime(timestamp)) ..
                            " |r" .. item.raid)

                    local _, _, itemLink = core.find(item.item, "(item:%d+:%d+:%d+:%d+)")
                    local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)
                    if not tex then
                        core.CacheItem(core.int(core.split(':', itemLink)[2]))
                        break
                    end

                    _G[frame .. 'Icon']:SetTexture(tex)
                    core.addButtonOnEnterTooltip(_G[frame], item.item)

                end
            end
        end
    end

    -- ScrollFrame update
    FauxScrollFrame_Update(TalcVoteFrameRaiderDetailsFrameLootHistoryFrameScrollFrame, totalItems, 7, 38)
end

function VoteFrame:ExpandAttendanceFrame_OnClick()
    if this.playerName then
        self.expandedAttendanceFrames[this.code] = not self.expandedAttendanceFrames[this.code]
        self:RaiderDetailsTab_OnClick(3, this.playerName)
    end
end

function VoteFrame:RaiderDetailsTab_OnClick(tab, playerName)

    TalcVoteFrameRLWindowFrame:Hide()

    if not playerName then
        if self.selectedPlayer[self.CurrentVotedItem] then
            playerName = self.selectedPlayer[self.CurrentVotedItem]
        else
            talc_debug("no player name")
            return
        end
    end

    if tab == 1 then

        TalcVoteFrameRaiderDetailsFrameTab1:SetText('|rGear')
        TalcVoteFrameRaiderDetailsFrameTab2:SetText('|cff696969Loot History')
        TalcVoteFrameRaiderDetailsFrameTab3:SetText('|cff696969Attendance')

        TalcVoteFrameRaiderDetailsFrameInspectGearFrame:Show()
        TalcVoteFrameRaiderDetailsFrameLootHistoryFrame:Hide()
        TalcVoteFrameRaiderDetailsFrameAttendanceFrame:Hide()

        for _, d in next, core.equipSlotsDetails do
            local frame = _G['Character' .. d.slot .. 'SlotIconTexture']
            if frame then
                local tex = frame:GetTexture()
                _G['TalcVoteFrameRaiderDetailsFrameInspectGearFrame' .. d.slot .. 'Slot']:SetNormalTexture(tex)
            else
                talc_debug('no frame Character' .. d.slot .. 'SlotIconTexture')
            end
        end

        -- dont send gear from me to me
        if playerName == core.me then
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
                    local enchantEx = core.split(':', shortLink)
                    self.inspectPlayerGear[playerName][i] = {
                        item = shortLink,
                        enchant = core.int(enchantEx[3]),
                        slot = slotString
                    }
                end
            end
        end

        if core.n(self.inspectPlayerGear[playerName]) == 0 then
            core.wsend("ALERT", "SendGear=", playerName)
        else
            self:RaiderDetailsShowGear()
        end

        for i = 0, GetNumRaidMembers() do
            if GetRaidRosterInfo(i) then
                local n = GetRaidRosterInfo(i)
                if n == playerName then
                    TalcVoteFrameRaiderDetailsFrameInspectGearFrameModelFrame:SetUnit('raid' .. i)
                    TalcVoteFrameRaiderDetailsFrameInspectGearFrameModelFrame:SetPosition(-0.5, 0, 0)
                    break
                end
            end
        end

        local _, _, _, _, _, _, _, _, _, _, itemLevel = self:GetPlayerInfo(playerName)

        TalcVoteFrameRaiderDetailsFrameInspectGearFrameNameClassGS:SetText(
                core.classColors[core.getPlayerClass(playerName)].colorStr .. playerName .. "\n" ..
                        core.classColors[core.getPlayerClass(playerName)].colorStr .. core.ucFirst(core.getPlayerClass(playerName)) .. "\n" ..
                        ((itemLevel >= 0) and "|rItem Level: " .. itemLevel or ""))

        for index in next, self.lootHistoryFrames do
            self.lootHistoryFrames[index]:Hide()
        end
    end

    if tab == 2 then
        TalcVoteFrameRaiderDetailsFrameTab1:SetText('|cff696969Gear')
        TalcVoteFrameRaiderDetailsFrameTab2:SetText('|rLoot History')
        TalcVoteFrameRaiderDetailsFrameTab3:SetText('|cff696969Attendance')

        TalcVoteFrameRaiderDetailsFrameInspectGearFrame:Hide()
        TalcVoteFrameRaiderDetailsFrameLootHistoryFrame:Show()
        TalcVoteFrameRaiderDetailsFrameAttendanceFrame:Hide()

        for _, frame in next, self.lootHistoryFrames do
            frame:Hide()
        end

        self:LootHistoryUpdate()

        TalcVoteFrameRaiderDetailsFrameLootHistoryFrameScrollFrame:Show()
    end

    if tab == 3 then
        TalcVoteFrameRaiderDetailsFrameTab1:SetText('|cff696969Gear')
        TalcVoteFrameRaiderDetailsFrameTab2:SetText('|cff696969Loot History')
        TalcVoteFrameRaiderDetailsFrameTab3:SetText('|rAttendance')

        TalcVoteFrameRaiderDetailsFrameInspectGearFrame:Hide()
        TalcVoteFrameRaiderDetailsFrameLootHistoryFrame:Hide()
        TalcVoteFrameRaiderDetailsFrameAttendanceFrame:Show()

        for _, frame in next, self.attendanceFrames do
            frame:Hide()
        end

        local att = core.getAttendance(playerName)

        TalcVoteFrameRaiderDetailsFrameAttendanceFrameTitleFrameIcon:Hide()
        TalcVoteFrameRaiderDetailsFrameAttendanceFrameTitleFrameLeft:SetText("|cffffffffTotal attendance points: " .. att.points)
        TalcVoteFrameRaiderDetailsFrameAttendanceFrameTitleFrameRight:Hide()

        local index = 0
        for raidString, raidData in next, att.raids do
            index = index + 1

            local code = raidString:gsub("%W", "")

            if not self.attendanceFrames[code] then
                self.attendanceFrames[code] = CreateFrame("Button", "TALCAttendanceFrame" .. code, TalcVoteFrameRaiderDetailsFrameAttendanceFrameScrollFrameChild, 'Talc_AttendanceLineTemplate')
                self.attendanceFrames[code].code = code
                self.expandedAttendanceFrames[code] = false
            end

            _G["TALCAttendanceFrame" .. code]:SetPoint("TOPLEFT", TalcVoteFrameRaiderDetailsFrameAttendanceFrameScrollFrameChild, 0, 24 - 24 * index)
            _G["TALCAttendanceFrame" .. code].playerName = playerName

            _G["TALCAttendanceFrame" .. code]:Show()
            local tex = ''
            if core.find(raidString, 'Naxx', 1, true) then
                if core.find(raidString, '10', 1, true) then
                    tex = 'interface\\icons\\Achievement_Dungeon_Naxxramas_10man'
                end
                if core.find(raidString, '25', 1, true) then
                    tex = 'interface\\icons\\Achievement_Dungeon_Naxxramas_heroic'
                end
            end
            if core.find(raidString, 'Obsidian', 1, true) then
                tex = 'interface\\icons\\Achievement_Boss_Sartharion_01'
            end
            if core.find(raidString, 'Eternity', 1, true) then
                if core.find(raidString, '10', 1, true) then
                    tex = 'interface\\icons\\Achievement_Dungeon_NexusRaid_10man'
                end
                if core.find(raidString, '25', 1, true) then
                    tex = 'interface\\icons\\Achievement_Dungeon_NexusRaid_25man'
                end
            end

            _G["TALCAttendanceFrame" .. code .. "Icon"]:SetTexture(tex)
            _G["TALCAttendanceFrame" .. code .. "Icon"]:Show()
            _G["TALCAttendanceFrame" .. code .. "Left"]:SetText(raidString)
            _G["TALCAttendanceFrame" .. code .. "Right"]:SetText(raidData.points)

            if self.expandedAttendanceFrames[code] then
                for boss, bossData in next, raidData.bosses do
                    code = raidString:gsub("%W", "") .. boss:gsub("%W", "")
                    index = index + 1
                    if not self.attendanceFrames[code] then
                        self.attendanceFrames[code] = CreateFrame("Button", "TALCAttendanceFrame" .. code, TalcVoteFrameRaiderDetailsFrameAttendanceFrameScrollFrameChild, 'Talc_AttendanceLineTemplate')
                        self.attendanceFrames[code].code = code
                        self.expandedAttendanceFrames[code] = false
                    end

                    _G["TALCAttendanceFrame" .. code]:SetPoint("TOPLEFT", TalcVoteFrameRaiderDetailsFrameAttendanceFrameScrollFrameChild, 0, 24 - 24 * index)
                    _G["TALCAttendanceFrame" .. code].playerName = playerName
                    _G["TALCAttendanceFrame" .. code]:Show()
                    _G["TALCAttendanceFrame" .. code .. "Icon"]:Show()
                    _G["TALCAttendanceFrame" .. code .. "Icon"]:SetPoint("LEFT", 24, 0)
                    _G["TALCAttendanceFrame" .. code .. "Icon"]:SetSize(16, 16)
                    _G["TALCAttendanceFrame" .. code .. "Icon"]:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")

                    _G["TALCAttendanceFrame" .. code .. "Left"]:SetPoint("LEFT", 40, 0) --26
                    _G["TALCAttendanceFrame" .. code .. "Left"]:SetText(boss)
                    _G["TALCAttendanceFrame" .. code .. "Right"]:SetText(bossData.kills)

                    if self.expandedAttendanceFrames[code] then
                        for _, timestamp in next, bossData.dates do
                            code = raidString:gsub("%W", "") .. boss:gsub("%W", "") .. timestamp
                            index = index + 1
                            if not self.attendanceFrames[code] then
                                self.attendanceFrames[code] = CreateFrame("Button", "TALCAttendanceFrame" .. code, TalcVoteFrameRaiderDetailsFrameAttendanceFrameScrollFrameChild, 'Talc_AttendanceLineTemplate')
                                self.attendanceFrames[code].code = code
                                self.expandedAttendanceFrames[code] = false
                            end

                            _G["TALCAttendanceFrame" .. code]:SetPoint("TOPLEFT", TalcVoteFrameRaiderDetailsFrameAttendanceFrameScrollFrameChild, 0, 24 - 24 * index)
                            _G["TALCAttendanceFrame" .. code]:Show()
                            _G["TALCAttendanceFrame" .. code .. "Icon"]:Hide()
                            _G["TALCAttendanceFrame" .. code .. "Left"]:SetPoint("LEFT", 40, 0) --26
                            _G["TALCAttendanceFrame" .. code .. "Left"]:SetText("   " .. date("%d/%m/%y %H:%M", core.localTimeFromServerTime(timestamp)))
                            _G["TALCAttendanceFrame" .. code .. "Right"]:SetText("")

                            core.remButtonOnEnterTooltip(_G["TALCAttendanceFrame" .. code])
                        end
                    end
                end
            end
        end
    end

    TalcVoteFrameRaiderDetailsFrame:Show()
end

function VoteFrame:RaiderDetailsShowGear()

    -- clear frames from prev player
    for _, d in next, core.equipSlotsDetails do
        if _G['TalcVoteFrameRaiderDetailsFrameInspectGearFrame' .. d.slot .. 'Slot'] then

            local frame = _G['Character' .. d.slot .. 'SlotIconTexture']
            if frame then
                local tex = frame:GetTexture()
                _G['TalcVoteFrameRaiderDetailsFrameInspectGearFrame' .. d.slot .. 'Slot']:SetNormalTexture(tex)
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

        if q and frame then

            _G['TalcVoteFrameRaiderDetailsFrameInspectGearFrame' .. d.slot .. 'SlotNotEnchanted']:Hide()

            for _, es in next, core.equipSlotsDetails do
                if d.slot == es.slot and es.canHaveEnchant and d.enchant == 0 then
                    _G['TalcVoteFrameRaiderDetailsFrameInspectGearFrame' .. d.slot .. 'SlotNotEnchanted']:Show()
                end
            end

            _G['TalcVoteFrameRaiderDetailsFrameInspectGearFrame' .. d.slot .. 'SlotItemLevel']:SetText(ITEM_QUALITY_COLORS[q].hex .. il)

            frame:SetNormalTexture(tex)

            core.addButtonOnEnterTooltip(frame, link)
        end
    end
end

----------------------------------------------------
--- Tradable Items
----------------------------------------------------

VoteFrame.tradableItemsCheck = CreateFrame("Frame")
VoteFrame.tradableItemsCheck:Hide()
VoteFrame.tradableItemsCheck.n = 0
VoteFrame.tradableItemsCheck.items = {}
VoteFrame.tradableItemsCheck.frames = {}
VoteFrame.tradableItemsCheck:SetScript("OnShow", function()
    this.startTime = GetTime()
    this.n = 0
end)
VoteFrame.tradableItemsCheck:SetScript("OnUpdate", function()
    local plus = 30
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then

        this.startTime = GetTime()

        -- hax
        if this.n == 0 then
            this.n = this.n + 1
            this:GetTradableItems()
            return
        end
        this.n = 0

        if not core.isRaidLeader() then
            return
        end

        local items = this:GetTradableItems()

        if core.n(this.items) > 0 then
            if core.n(this.items) > core.n(items) then
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

        for i, item in next, this.items do


            if not this.frames[i] then
                this.frames[i] = CreateFrame('Frame', 'TALCTradableItem' .. i, TalcVoteFrameTradableItemsFrame, 'Talc_TradableItemTemplate')
            end

            local frame = 'TALCTradableItem' .. i

            _G[frame]:SetPoint("TOP", TalcVoteFrameTradableItemsFrame, "TOP", 0, -4 - 22 * i)
            _G[frame]:Show()
            _G[frame]:SetID(i)

            _G[frame .. 'Name']:SetText(item.itemLink)
            _G[frame .. 'Duration']:SetText(core.SecondsToClock(item.duration))

            _G[frame .. 'DurationBar']:SetWidth(240 * (item.duration / (2 * 60 * 60)))

            if item.duration <= 11 * 60 - 1 then
                talc_print(item.itemLink .. " will expire in " .. SecondsToTime(item.duration) .. ".")
            end

        end

        TalcVoteFrameTradableItemsFrame:SetHeight(40 + core.n(this.items) * 21)

        if core.n(this.items) > 0 and UnitInRaid('player') then
            TalcVoteFrameTradableItemsFrame:Show()
        else
            TalcVoteFrameTradableItemsFrame:Hide()
        end
    end
end)

function VoteFrame.tradableItemsCheck:Item_OnClick(id)
    if TalcVoteFrame:IsVisible() and TalcVoteFrameRLExtraFrameDragLoot:IsEnabled() then

        local link = self.items[id].itemLink
        local _, _, itemLink = core.find(link, "(item:%d+:%d+:%d+:%d+)")
        local itemID = core.split(':', itemLink)[2]

        core.insert(VoteFrame.bagItems, {
            preloaded = false,
            id = itemID,
            itemLink = link
        })

        for i, d in next, VoteFrame.bagItems do
            local name, l, quality, _, _, _, _, _, _, tex = GetItemInfo(d.itemLink)
            if quality >= 0 and not d.preloaded then
                core.bsend("BULK", "PreloadItem=" .. i .. "=" .. tex .. "=" .. name .. "=" .. l)
                d.preloaded = true
            end
        end
    end
end

function VoteFrame.tradableItemsCheck:GetTradableItems()
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
                        duration = duration
                    })
                end
            end
        end
    end
    return items
end

function VoteFrame.tradableItemsCheck:IsTradable(bag, slot)

    TradableItemsTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    TradableItemsTooltip:SetBagItem(bag, slot)

    local format = BIND_TRADE_TIME_REMAINING --REFUND_TIME_REMAINING

    for i = 1, TradableItemsTooltip:NumLines() do
        if core.find(_G["TradableItemsTooltipTextLeft" .. i]:GetText(), core.format(format, ".*")) then
            local _, _, hour = core.find(_G["TradableItemsTooltipTextLeft" .. i]:GetText(), "(%d+ hour)")
            local _, _, min = core.find(_G["TradableItemsTooltipTextLeft" .. i]:GetText(), "(%d+ min)")
            local _, _, sec = core.find(_G["TradableItemsTooltipTextLeft" .. i]:GetText(), "(%d+ sec)")

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
            TradableItemsTooltip:Hide()
            return true, duration
        end
    end
    TradableItemsTooltip:Hide()
    return false, nil
end


----------------------------------------------------
--- Voting System
----------------------------------------------------

local TalcVoteFrameVotingFrame = CreateFrame("Frame", "TalcVoteFrameVotingFrame")
TalcVoteFrameVotingFrame:SetScript("OnHide", function()
    TalcVoteFrameTimeLeftBar:Hide()
    TalcVoteFrameLabelsBackground:Hide()
    TalcVoteFrameNameLabel:Hide()
    TalcVoteFrameItemLevelLabel:Hide()
    TalcVoteFramePickLabel:Hide()
    TalcVoteFrameReplacesLabel:Hide()
    TalcVoteFrameRollLabel:Hide()
    TalcVoteFrameVotesLabel:Hide()
    TalcVoteFrameRecentItemsLabel:Hide()
    TalcVoteFrameDoneVoting:Hide()

    TalcVoteFrameWinnerStatus:Hide()
    TalcVoteFrameMLToWinner:Hide()
    TalcVoteFrameOfficersThatVotedList:Hide()

    VoteFrame:RaiderDetailsClose()
end)
TalcVoteFrameVotingFrame:SetScript("OnShow", function()
    TalcVoteFrameTimeLeftBar:Show()
    TalcVoteFrameLabelsBackground:Show()
    TalcVoteFrameNameLabel:Show()
    TalcVoteFrameItemLevelLabel:Show()
    TalcVoteFramePickLabel:Show()
    TalcVoteFrameReplacesLabel:Show()
    TalcVoteFrameRollLabel:Show()
    TalcVoteFrameVotesLabel:Show()
    TalcVoteFrameRecentItemsLabel:Show()
    TalcVoteFrameDoneVoting:Show()

    VoteFrame:RaiderDetailsClose()

    if core.isRaidLeader() then
        TalcVoteFrameMLToWinner:Show()
    else
        TalcVoteFrameWinnerStatus:Show()
    end

    TalcVoteFrameOfficersThatVotedList:Show()
end)

function Talc_BuildContestantDropdownMenu()
    local id = ContestantDropdownMenu.currentContestantId
    local separator = {}
    separator.text = ""
    separator.disabled = true

    local title = {}
    title.text = _G['TALCContestantFrame' .. id].name .. ' ' .. _G['TALCContestantFrame' .. id .. 'Need']:GetText()
    title.disabled = false
    title.notCheckable = true
    title.isTitle = true
    UIDropDownMenu_AddButton(title)
    UIDropDownMenu_AddButton(separator)

    local award = {}
    if VoteFrame.VotedItemsFrames[VoteFrame.CurrentVotedItem].awardedTo ~= '' then
        award.text = "Awarded " .. TalcVoteFrameVotedItemName:GetText()
    else
        award.text = "Award " .. TalcVoteFrameVotedItemName:GetText()
    end
    award.disabled = VoteFrame.VotedItemsFrames[VoteFrame.CurrentVotedItem].awardedTo ~= ''
    award.isTitle = false
    award.notCheckable = true
    award.tooltipTitle = 'Award'
    award.tooltipText = 'Send item to player'
    award.justifyH = 'LEFT'
    award.func = function()
        VoteFrame:AwardPlayer(_G['TALCContestantFrame' .. id].name, VoteFrame.CurrentVotedItem)
    end
    UIDropDownMenu_AddButton(award)
    UIDropDownMenu_AddButton(separator)

    local changeToBIS = {}
    changeToBIS.text = "Change to " .. core.needs['bis'].colorStr .. core.needs['bis'].text
    changeToBIS.disabled = _G['TALCContestantFrame' .. id].need == 'bis' or VoteFrame.VotedItemsFrames[VoteFrame.CurrentVotedItem].awardedTo ~= ''
    changeToBIS.isTitle = false
    changeToBIS.notCheckable = true
    changeToBIS.tooltipTitle = 'Change choice'
    changeToBIS.tooltipText = 'Change contestant\'s choice to ' .. core.needs['bis'].colorStr .. core.needs['bis'].text
    changeToBIS.justifyH = 'LEFT'
    changeToBIS.func = function()
        VoteFrame:ChangePlayerPickTo(_G['TALCContestantFrame' .. id].name, 'bis', VoteFrame.CurrentVotedItem)
    end
    UIDropDownMenu_AddButton(changeToBIS)

    local changeToMS = {}
    changeToMS.text = "Change to " .. core.needs['ms'].colorStr .. core.needs['ms'].text
    changeToMS.disabled = _G['TALCContestantFrame' .. id].need == 'ms' or VoteFrame.VotedItemsFrames[VoteFrame.CurrentVotedItem].awardedTo ~= ''
    changeToMS.isTitle = false
    changeToMS.notCheckable = true
    changeToMS.tooltipTitle = 'Change choice'
    changeToMS.tooltipText = 'Change contestant\'s choice to ' .. core.needs['ms'].colorStr .. core.needs['ms'].text
    changeToMS.justifyH = 'LEFT'
    changeToMS.func = function()
        VoteFrame:ChangePlayerPickTo(_G['TALCContestantFrame' .. id].name, 'ms', VoteFrame.CurrentVotedItem)
    end
    UIDropDownMenu_AddButton(changeToMS)

    local changeToOS = {}
    changeToOS.text = "Change to " .. core.needs['os'].colorStr .. core.needs['os'].text
    changeToOS.disabled = _G['TALCContestantFrame' .. id].need == 'os' or VoteFrame.VotedItemsFrames[VoteFrame.CurrentVotedItem].awardedTo ~= ''
    changeToOS.isTitle = false
    changeToOS.notCheckable = true
    changeToOS.tooltipTitle = 'Change choice'
    changeToOS.tooltipText = 'Change contestant\'s choice to ' .. core.needs['os'].colorStr .. core.needs['os'].text
    changeToOS.justifyH = 'LEFT'
    changeToOS.func = function()
        VoteFrame:ChangePlayerPickTo(_G['TALCContestantFrame' .. id].name, 'os', VoteFrame.CurrentVotedItem)
    end
    UIDropDownMenu_AddButton(changeToOS)

    local changeToXMOG = {}
    changeToXMOG.text = "Change to " .. core.needs['xmog'].colorStr .. core.needs['xmog'].text
    changeToXMOG.disabled = _G['TALCContestantFrame' .. id].need == 'xmog' or VoteFrame.VotedItemsFrames[VoteFrame.CurrentVotedItem].awardedTo ~= ''
    changeToXMOG.isTitle = false
    changeToXMOG.notCheckable = true
    changeToXMOG.tooltipTitle = 'Change choice'
    changeToXMOG.tooltipText = 'Change contestant\'s choice to ' .. core.needs['xmog'].colorStr .. core.needs['xmog'].text
    changeToXMOG.justifyH = 'LEFT'
    changeToXMOG.func = function()
        VoteFrame:ChangePlayerPickTo(_G['TALCContestantFrame' .. id].name, 'xmog', VoteFrame.CurrentVotedItem)
    end
    UIDropDownMenu_AddButton(changeToXMOG)

    UIDropDownMenu_AddButton(separator)

    local close = {}
    close.text = "Close"
    close.disabled = false
    close.notCheckable = true
    close.isTitle = false
    UIDropDownMenu_AddButton(close)
end

function VoteFrame:RefreshContestantsList()
    --ghetto ordering
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
    -- sort
    self.currentPlayersList = {}
    for _, frame in next, self.contestantsFrames do
        frame:Hide()
    end
    for pIndex, data in next, self.playersWhoWantItems do
        if data.itemIndex == self.CurrentVotedItem then
            core.insert(self.currentPlayersList, self.playersWhoWantItems[pIndex])
        end
    end
end

function VoteFrame:VoteButton_OnClick(id)
    local _, name = self:GetPlayerInfo(id)

    if not self.itemVotes[self.CurrentVotedItem][name] then
        self.itemVotes[self.CurrentVotedItem][name] = { [core.me] = '+' }
        core.asend("ItemVote=" .. self.CurrentVotedItem .. "=" .. name .. "=+")
    else
        if self.itemVotes[self.CurrentVotedItem][name][core.me] == '+' then
            self.itemVotes[self.CurrentVotedItem][name][core.me] = '-'
            core.asend("ItemVote=" .. self.CurrentVotedItem .. "=" .. name .. "=-")
        else
            self.itemVotes[self.CurrentVotedItem][name][core.me] = '+'
            core.asend("ItemVote=" .. self.CurrentVotedItem .. "=" .. name .. "=+")
        end
    end

    self:VoteFrameListUpdate()
end

function VoteFrame:CalculateVotes()

    --init votes to 0
    for _, list in next, self.currentPlayersList do
        list.votes = 0
    end

    if self.CurrentVotedItem ~= nil then
        for n, _ in next, self.itemVotes[self.CurrentVotedItem] do
            if self:GetPlayerInfo(n) then
                local _, _, _, _, _, _, _, _, _, pIndex = self:GetPlayerInfo(n)
                for _, vote in next, self.itemVotes[self.CurrentVotedItem][n] do
                    if vote == '+' then
                        self.currentPlayersList[pIndex].votes = self.currentPlayersList[pIndex].votes + 1
                    end
                end
            else
                talc_error('VoteFrame:GetPlayerInfo(' .. n .. ') Not Found. Please report this.')
            end
        end
    end
end

function VoteFrame:CalculateWinner()

    if not self.CurrentVotedItem then
        return
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
        TalcVoteFrameMLToWinner:Disable()
        local color = core.classColors[core.getPlayerClass(self.VotedItemsFrames[self.CurrentVotedItem].awardedTo)]
        TalcVoteFrameMLToWinner:SetText('Awarded to ' .. color.colorStr .. self.VotedItemsFrames[self.CurrentVotedItem].awardedTo)
        TalcVoteFrameWinnerStatus:SetText('Awarded to ' .. color.colorStr .. self.VotedItemsFrames[self.CurrentVotedItem].awardedTo)
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
            TalcVoteFrameMLToWinner:Enable()
            local color = core.classColors[core.getPlayerClass(self.currentRollWinner)]
            TalcVoteFrameMLToWinner:SetText('Award ' .. color.colorStr .. self.currentRollWinner)
            TalcVoteFrameWinnerStatus:SetText('Winner: ' .. color.colorStr .. self.currentRollWinner)

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
        self.voteTiePlayers = ''
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
            TalcVoteFrameMLToWinner:Enable()
            local color = core.classColors[core.getPlayerClass(self.currentItemWinner)]
            TalcVoteFrameMLToWinner:SetText('Award single picker ' .. color.colorStr .. self.currentItemWinner)
            TalcVoteFrameWinnerStatus:SetText('Single picker ' .. color.colorStr .. self.currentItemWinner)
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
                TalcVoteFrameMLToWinner:Enable()
                local color = core.classColors[core.getPlayerClass(self.currentItemWinner)]
                TalcVoteFrameMLToWinner:SetText('Award ' .. color.colorStr .. self.currentItemWinner)
                TalcVoteFrameWinnerStatus:SetText('Winner: ' .. color.colorStr .. self.currentItemWinner)
            else
                TalcVoteFrameMLToWinner:Disable()
                TalcVoteFrameMLToWinner:SetText('Waiting votes...')
                TalcVoteFrameWinnerStatus:SetText('Waiting votes...')
            end
        end
    end
end

function VoteFrame:UpdateOfficerVotesNum()

    if not self.CurrentVotedItem then
        return
    end

    if not self.OfficerVoted[self.CurrentVotedItem] then
        self.OfficerVoted[self.CurrentVotedItem] = {}
    end

    -- reset
    local nr = 0
    for _, name in next, db['VOTE_ROSTER'] do
        self.OfficerVoted[self.CurrentVotedItem][name] = false
    end
    for n, _ in next, self.itemVotes[self.CurrentVotedItem] do
        for voter, vote in next, self.itemVotes[self.CurrentVotedItem][n] do
            for _, name in next, db['VOTE_ROSTER'] do
                if voter == name and vote == '+' then
                    self.OfficerVoted[self.CurrentVotedItem][name] = true
                end
            end
        end
    end

    for officer, voted in next, self.OfficerVoted[self.CurrentVotedItem] do
        if voted then
            nr = nr + 1
        else
            --check if he clicked done voting for this item
            if self.OfficerDoneVotingItem[officer] and self.OfficerDoneVotingItem[officer][self.CurrentVotedItem] then
                nr = nr + 1
            end
        end
    end

    local numOfficersInRaid = 0
    for _, name in next, db['VOTE_ROSTER'] do
        if core.onlineInRaid(name) then
            numOfficersInRaid = numOfficersInRaid + 1
        end
    end

    if nr == numOfficersInRaid then
        TalcVoteFrameMLToWinner:Enable()
        TalcVoteFrameVotesLabel:SetText('Votes |cff1fba1f' .. nr .. '/' .. numOfficersInRaid)
    elseif nr >= core.floor(numOfficersInRaid / 2) then
        TalcVoteFrameVotesLabel:SetText('Votes |cfffff569' .. nr .. '/' .. numOfficersInRaid)
    else
        TalcVoteFrameVotesLabel:SetText('Votes |cffa53737' .. nr .. '/' .. numOfficersInRaid)
    end
end

function VoteFrame:MLToWinner_OnClick()

    -- check if its a tie
    if self.voteTiePlayers ~= '' then
        self.VotedItemsFrames[self.CurrentVotedItem].rolled = true
        local players = core.split(' ', self.voteTiePlayers)
        for _, d in next, self.currentPlayersList do
            for _, tieName in next, players do
                if d.itemIndex == self.CurrentVotedItem and d.name == tieName then

                    local linkString = self.VotedItemsFrames[self.CurrentVotedItem].link
                    local _, _, itemLink = core.find(linkString, "(item:%d+:%d+:%d+:%d+)")
                    local name, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)

                    for pwIndex, pwPlayer in next, self.playersWhoWantItems do
                        if pwPlayer.name == tieName and pwPlayer.itemIndex == self.CurrentVotedItem then
                            self.playersWhoWantItems[pwIndex].roll = -2
                            --send -2 to officers
                            core.asend("PlayerRoll=" .. pwIndex .. "=" .. self.playersWhoWantItems[pwIndex].roll .. "=" .. self.CurrentVotedItem)
                            --send to raiders
                            core.asend('RollFor=' .. self.CurrentVotedItem .. '=' .. tex .. '=' .. name .. '=' .. linkString .. '=' .. tieName)
                            break
                        end
                    end
                end
            end
        end
        TalcVoteFrameMLToWinner:Disable()
        self:VoteFrameListUpdate()
    else
        -- no tie, award player
        self:AwardPlayer(self.currentItemWinner, self.CurrentVotedItem)
    end
end

function VoteFrame:MLToEnchanter_OnClick()
    if db['VOTE_ENCHANTER'] == '' then
        talc_print('Enchanter not set. Use /talc set enchanter [name] to set it.')
        return
    end

    local foundInRaid = false

    for i = 0, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) then
            local n = GetRaidRosterInfo(i)
            if n == db['VOTE_ENCHANTER'] then
                foundInRaid = true
            end
        end
    end
    if not foundInRaid then
        talc_print('Enchanter ' .. db['VOTE_ENCHANTER'] .. ' is not in raid. Use /talc set enchanter [name] to set a new one.')
        return
    end
    for i = 0, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) then
            local n, _, _, _, _, _, z = GetRaidRosterInfo(i)
            if n == db['VOTE_ENCHANTER'] and z == 'Offline' then
                talc_print('Enchanter ' .. db['VOTE_ENCHANTER'] .. ' is offline. Use /talc set enchanter [name] to set a new one.')
                return
            end
        end
    end
    self:AwardPlayer(db['VOTE_ENCHANTER'], self.CurrentVotedItem, true)
end

function VoteFrame:Contestant_OnClick(id)

    local playerOffset = FauxScrollFrame_GetOffset(TalcVoteFrameRaiderDetailsFrameLootHistoryFrameScrollFrame)
    id = id - playerOffset

    if arg1 == 'RightButton' then
        self:ShowContestantDropdownMenu(id)
        return
    end

    if TalcVoteFrameRaiderDetailsFrame:IsVisible() and self.selectedPlayer[self.CurrentVotedItem] == _G['TALCContestantFrame' .. id].name then
        self:RaiderDetailsClose()
    else
        self.selectedPlayer[self.CurrentVotedItem] = this.name
        if not self.inspectPlayerGear[self.selectedPlayer[self.CurrentVotedItem]] then
            self.inspectPlayerGear[self.selectedPlayer[self.CurrentVotedItem]] = {}
        end
        self.HistoryId = id
        self:RaiderDetailsTab_OnClick(1, _G['TALCContestantFrame' .. id].name)
    end
end

function VoteFrame:Contestant_OnEnter()
    local r, g, b = this:GetBackdropColor()
    this:SetBackdropColor(r, g, b, 1)
end

function VoteFrame:Contestant_OnLeave()
    local r, g, b = this:GetBackdropColor()
    this:SetBackdropColor(r, g, b, 0.5)
end

function VoteFrame:AwardPlayer(playerName, cvi, disenchant)

    if not playerName or playerName == '' then
        talc_error('VoteFrame:AwardPlayer: playerName is nil.')
        return
    end

    local item = self.VotedItemsFrames[cvi].link

    local _, _, _, raid = core.instanceInfo()
    if not raid then
        raid = core.GetItemLocation(self.VotedItemsFrames[cvi].itemID)
    end

    if core.n(self.bagItems) > 0 then
        local _, _, need = self:GetPlayerInfo(playerName)

        if disenchant then
            need = "de"
        end

        core.asend("PlayerWon="
                .. core.timeUTC() .. "="
                .. playerName .. "="
                .. item .. "="
                .. cvi .. '='
                .. need .. '='
                .. raid)

        if db['VOTE_SCREENSHOT_LOOT'] then
            Screenshot()
        end

        if disenchant then
            SendChatMessage(playerName .. ' was awarded with ' .. item .. ' for Disenchant!', "RAID")
        else
            SendChatMessage(playerName .. ' was awarded with ' .. item .. ' for ' .. core.needs[need].text .. '!', "RAID")
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

        local itemIndex = cvi

        talc_debug('ML item should be ' .. item)
        local foundItemIndexInLootFrame = false
        for id = 0, GetNumLootItems() do
            if GetLootSlotInfo(id) and GetLootSlotLink(id) then
                if item == GetLootSlotLink(id) then
                    foundItemIndexInLootFrame = true
                    itemIndex = id
                end
            end
        end

        if foundItemIndexInLootFrame then

            local index, _, need = self:GetPlayerInfo(GetMasterLootCandidate(unitIndex))

            if disenchant then
                need = "de"
            end

            core.asend("PlayerWon="
                    .. core.timeUTC() .. "="
                    .. GetMasterLootCandidate(unitIndex) .. "="
                    .. item .. "="
                    .. cvi .. "="
                    .. need .. "="
                    .. raid)

            GiveMasterLoot(index, unitIndex)

            if db['VOTE_SCREENSHOT_LOOT'] then
                Screenshot()
            end

            if disenchant then
                SendChatMessage(GetMasterLootCandidate(unitIndex) .. ' was awarded with ' .. item .. ' for Disenchant!', "RAID")
            else
                SendChatMessage(GetMasterLootCandidate(unitIndex) .. ' was awarded with ' .. item .. ' for ' .. core.needs[need].text .. '!', "RAID")
            end

            self.VotedItemsFrames[cvi].awardedTo = playerName
            self:updateVotedItemsFrames()

        else
            talc_error('Item not found. Is the loot window opened ?')
        end
    end
end

function VoteFrame:UpdateOfficerVotedIcons()

    for _, frame in next, self.OfficerVotedFrames do
        frame:Hide()
    end

    local index = 0
    for officer, voted in next, self.OfficerVoted[self.CurrentVotedItem] do
        index = index + 1
        local class = core.getPlayerClass(officer)
        if not self.OfficerVotedFrames[index] then
            self.OfficerVotedFrames[index] = CreateFrame('Button', 'TALCOfficerVotedButton' .. index, TalcVoteFrameOfficersThatVotedList, 'Talc_SmallIconButtonTemplate')
        end

        local frame = self.OfficerVotedFrames[index]

        frame:SetPoint("TOPLEFT", TalcVoteFrameOfficersThatVotedList, "TOPLEFT", index * 21 - 20, 0)
        frame:Show()
        frame.name = officer

        frame:SetNormalTexture("Interface\\AddOns\\Talc\\images\\classes\\" .. class)
        frame:SetPushedTexture("Interface\\AddOns\\Talc\\images\\classes\\" .. class)
        frame:SetHighlightTexture("Interface\\AddOns\\Talc\\images\\classes\\" .. class)

        frame:SetScript("OnEnter", function(self)
            TALCTooltip:SetOwner(this, "ANCHOR_RIGHT", -(this:GetWidth() / 4), -(this:GetHeight() / 4))
            TALCTooltip:AddLine(this.name)
            TALCTooltip:Show()
        end)

        frame:SetScript("OnLeave", function(self)
            TALCTooltip:Hide()
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
            if self.OfficerDoneVotingItem[officer] then
                for itemIndex, doneVoting in next, self.OfficerDoneVotingItem[officer] do
                    if itemIndex == self.CurrentVotedItem and doneVoting then
                        frame:SetAlpha(1)
                    end
                end
            end
        end

    end
end

function VoteFrame:VoteFrameListUpdate()

    if not self.CurrentVotedItem then
        return
    end

    self:RefreshContestantsList()
    self:CalculateVotes()
    self:UpdateOfficerVotesNum()
    self:CalculateWinner()

    if not self.pickResponses[self.CurrentVotedItem] then
        self.pickResponses[self.CurrentVotedItem] = 0
    end

    if self.pickResponses[self.CurrentVotedItem] == core.getNumOnlineRaidMembers() then

        local bis, ms, os, pass, xmog = 0, 0, 0, 0, 0
        for _, data in next, self.playersWhoWantItems do
            if data.itemIndex == self.CurrentVotedItem then
                if data.need == 'bis' then
                    bis = bis + 1
                elseif data.need == 'ms' then
                    ms = ms + 1
                elseif data.need == 'os' then
                    os = os + 1
                elseif data.need == 'xmog' then
                    xmog = xmog + 1
                elseif data.need == 'pass' or data.need == 'autopass' then
                    pass = pass + 1
                end
            end
        end

        TalcVoteFrameTimeLeftBarTextLeft:SetText(core.getNumOnlineRaidMembers() .. '/' .. self.pickResponses[self.CurrentVotedItem]
                .. ' pick(s), ' .. pass .. ' pass(es)')
        self.VotedItemsFrames[self.CurrentVotedItem].pickedByEveryone = true
    else
        TalcVoteFrameTimeLeftBarTextLeft:SetText('Waiting picks ' ..
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
    FauxScrollFrame_Update(TalcVoteFrameContestantScrollListFrame, maxFrames, framesPerPage, frameHeight)
    local offset = FauxScrollFrame_GetOffset(TalcVoteFrameContestantScrollListFrame)

    local index = 0

    -- calc max gs
    local maxIL = 0
    for i in next, self.currentPlayersList do
        if self:GetPlayerInfo(i) then
            local _, _, _, _, _, _, _, _, _, _, itemLevel = self:GetPlayerInfo(i)
            if itemLevel > maxIL then
                maxIL = itemLevel
            end
        end
    end

    for _ in next, self.currentPlayersList do

        index = index + 1

        if index > offset and index <= offset + framesPerPage then

            if self:GetPlayerInfo(index) then

                if not self.contestantsFrames[index] then
                    self.contestantsFrames[index] = CreateFrame('Frame', 'TALCContestantFrame' .. index, TalcVoteFrameContestantScrollListFrame, 'Talc_ContestantFrameTemplate')
                end

                local frame = 'TALCContestantFrame' .. index

                if not _G[frame].officerVotedFrames then
                    _G[frame].officerVotedFrames = {}
                end
                _G[frame]:ClearAllPoints()
                _G[frame]:SetPoint("TOPLEFT", TalcVoteFrameContestantScrollListFrame, 0, 23 - 24 * (index - offset))
                _G[frame]:SetPoint("TOPRIGHT", TalcVoteFrameContestantScrollListFrame, 0, 23 - 24 * (index - offset))
                _G[frame]:SetID(index)

                local ratio = TalcVoteFrame:GetWidth() / 600
                _G[frame .. 'Name']:SetPoint("LEFT", _G[frame], core.floor(8 * ratio) + 20, 0)
                _G[frame .. 'ItemLevel']:SetPoint("LEFT", _G[frame], core.floor(100 * ratio) - 5, 0)
                _G[frame .. 'Need']:SetPoint("LEFT", _G[frame], core.floor(165 * ratio) - 5, 0)
                _G[frame .. 'ReplacesItem1']:SetPoint("TOPLEFT", _G[frame], core.floor(225 * ratio) - 5, -2)
                _G[frame .. 'ReplacesItem2']:SetPoint("TOPLEFT", _G[frame], core.floor(225 * ratio) - 5 + 21, -2)
                _G[frame .. 'ReplacesItem3']:SetPoint("TOPLEFT", _G[frame], core.floor(225 * ratio) - 5 + 21 + 21, -2)
                _G[frame .. 'ReplacesItem4']:SetPoint("TOPLEFT", _G[frame], core.floor(225 * ratio) - 5 + 21 + 21 + 21, -2)
                _G[frame .. 'Roll']:SetPoint("LEFT", _G[frame], core.floor(285 * ratio) - 5, 0)
                _G[frame .. 'RollPass']:SetPoint("LEFT", _G[frame], core.floor(285 * ratio) - 5, 0)
                _G[frame .. 'RollWinner']:SetPoint("LEFT", _G[frame], core.floor(270 * ratio), -2)
                _G[frame .. 'Votes']:SetPoint("LEFT", _G[frame], core.floor(406 * ratio) - 5, 0)
                _G[frame .. 'VoteButton']:SetPoint("TOPLEFT", _G[frame], core.floor(380 * ratio) - 80, -2)

                _G[frame]:Show()

                local currentItem = {}
                local _, name, need, votes, ci1, ci2, ci3, ci4, roll, _, itemLevel, inWishlist = self:GetPlayerInfo(index)
                currentItem[1] = ci1
                currentItem[2] = ci2
                currentItem[3] = ci3
                currentItem[4] = ci4

                _G[frame].name = name
                _G[frame].need = need
                _G[frame].itemLevel = itemLevel

                local class = core.getPlayerClass(name)
                local color = core.classColors[class]
                _G[frame]:SetBackdropColor(color.r, color.g, color.b, 0.5)

                _G[frame .. 'Name']:SetText(color.colorStr .. name)
                _G[frame .. 'Need']:SetText(core.needs[need].colorStr .. core.needs[need].text)
                _G[frame .. 'Wishlist']:Hide()
                if inWishlist then
                    _G[frame .. 'Wishlist']:Show()
                end

                -- color item level
                local ILColor = '|cff0be700'
                local ILPerc = core.floor(itemLevel * 100 / maxIL)
                if ILPerc < 75 and ILPerc >= 50 then
                    ILColor = '|cffffb400'
                elseif ILPerc < 50 then
                    ILColor = '|cffc80500'
                end

                _G[frame .. 'ItemLevel']:SetText(ILColor .. itemLevel)
                if itemLevel >= 0 then
                    _G[frame .. 'ItemLevel']:Show()
                else
                    _G[frame .. 'ItemLevel']:Hide()
                end
                _G[frame .. 'RollPass']:Hide()

                _G[frame .. 'Votes']:SetText(votes)
                _G[frame .. 'VoteButton']:SetText('VOTE')
                _G[frame .. 'VoteButtonCheck']:Hide()
                _G[frame .. 'Roll']:SetText()

                if roll == -1 then
                    _G[frame .. 'RollPass']:Show()
                    _G[frame .. 'Roll']:SetText('')
                elseif roll == -2 then
                    _G[frame .. 'Roll']:SetText('...')
                elseif roll > 0 then
                    _G[frame .. 'Roll']:SetText(roll)
                end

                if votes == self.currentItemMaxVotes and self.currentItemMaxVotes > 0 then
                    _G[frame .. 'Votes']:SetText('|cff1fba1f' .. votes)
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

                _G[frame .. 'RollWinner']:Hide()
                if self.currentMaxRoll[self.CurrentVotedItem] == roll and roll > 0 then
                    _G[frame .. 'RollWinner']:Show()
                end
                _G[frame .. 'WinnerIcon']:Hide()
                if self.VotedItemsFrames[self.CurrentVotedItem].awardedTo == name then
                    _G[frame .. 'WinnerIcon']:Show()
                end

                for _, f in next, _G[frame].officerVotedFrames do
                    f:Hide()
                end

                if not _G[frame].recentItemsFrames then
                    _G[frame].recentItemsFrames = {}
                end

                for _, f in next, _G[frame].recentItemsFrames do
                    f:Hide()
                end

                local rIndex = 0
                for timestamp, item in core.pairsByKeysReverse(core.getRecentItems(name)) do
                    rIndex = rIndex + 1
                    if not _G[frame].recentItemsFrames[rIndex] then
                        _G[frame].recentItemsFrames[rIndex] = CreateFrame("Button", "TALCRecentItemsFrameF" .. index .. "I" .. rIndex, _G[frame], 'Talc_SmallIconButtonTemplate')
                    end
                    local rFrame = "TALCRecentItemsFrameF" .. index .. "I" .. rIndex
                    _G[rFrame]:ClearAllPoints()
                    _G[rFrame]:SetSize(18, 18)

                    if rIndex == 1 then
                        _G[rFrame]:SetPoint("LEFT", _G[frame], "LEFT", core.floor(486 * ratio) - 5, 0)
                    else
                        _G[rFrame]:SetPoint("LEFT", _G["TALCRecentItemsFrameF" .. index .. "I" .. (rIndex - 1)], "RIGHT", 1, 0)
                    end

                    local _, _, itemLink = core.find(item.item, "(item:%d+:%d+:%d+:%d+)")
                    local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)
                    if not tex then
                        core.CacheItem(core.int(core.split(':', itemLink)[2]))
                        break
                    end

                    core.addButtonOnEnterTooltip(_G[rFrame], item.item, 'recentItems', false, {
                        [timestamp] = item
                    })

                    _G[rFrame]:SetNormalTexture(tex)
                    _G[rFrame]:SetHighlightTexture(tex)
                    _G[rFrame]:SetPushedTexture(tex)

                    _G[rFrame .. "Border"]:Hide()
                    _G[rFrame]:SetAlpha(1)
                    if item.pick == 'os' or item.pick == 'xmog' or true then
                        _G[rFrame]:SetAlpha(0.5)
                    end

                    _G[rFrame]:Show()

                end

                if self.itemVotes[self.CurrentVotedItem][name] then
                    local officer = 0
                    for voter, vote in next, self.itemVotes[self.CurrentVotedItem][name] do
                        if vote == '+' then
                            officer = officer + 1

                            if not _G[frame].officerVotedFrames[officer] then
                                _G[frame].officerVotedFrames[officer] = CreateFrame("Button", "TALCOfficerVotedFrameP" .. index .. "O" .. officer, _G[frame], 'Talc_SmallIconButtonTemplate')
                            end

                            local oFrame = "TALCOfficerVotedFrameP" .. index .. "O" .. officer

                            local voterClass = core.getPlayerClass(voter)
                            local locked = self.OfficerDoneVotingItem[voter] and self.OfficerDoneVotingItem[voter][self.CurrentVotedItem]

                            _G[oFrame]:ClearAllPoints()
                            _G[oFrame]:SetSize(20, 20)

                            if officer == 1 then
                                _G[oFrame]:SetPoint("LEFT", _G[frame .. 'Votes'], "LEFT", 15, 0)
                            else
                                _G[oFrame]:SetPoint("LEFT", _G["TALCOfficerVotedFrameP" .. index .. "O" .. (officer - 1)], "RIGHT", 1, 0)
                            end

                            _G[oFrame]:SetNormalTexture("Interface\\AddOns\\Talc\\images\\classes\\" .. voterClass)
                            _G[oFrame]:SetHighlightTexture("Interface\\AddOns\\Talc\\images\\classes\\" .. voterClass)
                            _G[oFrame]:SetPushedTexture("Interface\\AddOns\\Talc\\images\\classes\\" .. voterClass)
                            _G[oFrame]:Show()
                            _G[oFrame]:SetAlpha(locked and 1 or 0.5)

                            local voterText = voter .. (locked and core.classColors['hunter'].colorStr .. "\nFinal" or core.classColors['rogue'].colorStr .. "\nNot Final")

                            _G[oFrame]:SetScript("OnEnter", function(self)
                                TALCTooltip:SetOwner(this, "ANCHOR_RIGHT", -(this:GetWidth() / 4), -(this:GetHeight() / 4))
                                TALCTooltip:AddLine(core.classColors[voterClass].colorStr .. voterText)
                                TALCTooltip:Show()
                            end)

                            _G[oFrame]:SetScript("OnLeave", function(self)
                                TALCTooltip:Hide()
                            end)
                        end
                    end
                end

                _G[frame .. 'VoteButton']:SetID(index)

                _G[frame .. 'ClassIcon']:SetTexture('Interface\\AddOns\\Talc\\images\\classes\\' .. class)

                _G[frame .. 'VoteButton']:Show()
                if need == 'pass' or need == 'autopass' then
                    _G[frame .. 'VoteButton']:Hide()
                end

                for i = 1, 4 do
                    if currentItem[i] ~= "0" then
                        local _, _, itemLink = core.find(currentItem[i], "(item:%d+:%d+:%d+:%d+)")
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

    self:UpdateOfficerVotedIcons()

end

function VoteFrame:updateVotedItemsFrames()
    for index, _ in next, self.VotedItemsFrames do
        _G['TALCVotedItem' .. index .. 'ButtonCheck']:Hide()
        if self.VotedItemsFrames[index].awardedTo ~= '' then
            _G['TALCVotedItem' .. index .. 'ButtonCheck']:Show()
        end
    end

    self:VoteFrameListUpdate()
end

function VoteFrame:ShowContestantDropdownMenu(id)

    if not core.isRaidLeader() then
        return
    end

    ContestantDropdownMenu.currentContestantId = id

    UIDropDownMenu_Initialize(ContestantDropdownMenu, Talc_BuildContestantDropdownMenu, "MENU")
    ToggleDropDownMenu(1, nil, ContestantDropdownMenu, "cursor", 2, 3)
end

function VoteFrame:SendTimersAndButtons()

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

function VoteFrame:ReceiveDrag()

    if CursorHasItem() then

        local infoType, id, itemLink = GetCursorInfo()
        if infoType == "item" then

            self.tradableItemsCheck:GetTradableItems()

            TalcVoteFrameRLExtraFrameDragLoot:Disable()
            TalcVoteFrameRLExtraFrameDragLoot:SetText('Waiting sync...')

            core.insert(self.bagItems, {
                preloaded = false,
                id = id,
                itemLink = itemLink
            })

            for i, d in next, self.bagItems do
                local name, l, quality, _, _, _, _, _, _, tex = GetItemInfo(d.itemLink)
                if quality >= 0 and not d.preloaded then
                    core.bsend("BULK", "PreloadItem=" .. i .. "=" .. tex .. "=" .. name .. "=" .. l)
                    d.preloaded = true
                end
            end

        end

    else
        -- load and broadcast logic
        if core.n(self.bagItems) > 0 then

            core.SetDynTTN(core.n(self.bagItems))
            core.SetDynTTV(core.n(self.bagItems))
            self.LootCountdown.countDownFrom = db['VOTE_TTN']

            core.syncRoster()

            self:SendTimersAndButtons()

            self.LootCountdown:Show()
            core.asend('CountDownFrame=Show')

            local numLootItems = 0
            for i, d in next, self.bagItems do

                local name, l, quality, _, _, _, _, _, _, tex = GetItemInfo(d.itemLink)

                if quality >= 0 then
                    --send to c
                    core.bsend("ALERT", "Loot=" .. i .. "=" .. tex .. "=" .. name .. "=" .. l)
                    numLootItems = numLootItems + 1
                end
            end
            core.bsend("ALERT", "DoneSending=" .. numLootItems)
            TalcVoteFrameMLToWinner:Disable()

            TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()

            TalcVoteFrameRLExtraFrameDragLoot:Disable()
            TalcVoteFrameRLExtraFrameDragLoot:SetText(numLootItems .. " Item(s) sent")

            return
        end
    end

    ClearCursor()

end

function VoteFrame:BroadcastLoot_OnClick()

    local lootMethod = GetLootMethod()
    if lootMethod ~= 'master' then
        talc_print('Looting method is not master looter. (' .. lootMethod .. ')')
        return
    end

    local target = UnitName('target')
    if UnitIsPlayer('target') or not UnitExists('target') then
        target = 'Chest'
    end
    core.asend('CurrentBoss=' .. target)

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

        self:SendReset()

        for id = 0, GetNumLootItems() do
            if GetLootSlotInfo(id) and GetLootSlotLink(id) then
                local lootIcon, lootName = GetLootSlotInfo(id)

                local _, _, itemLink = core.find(GetLootSlotLink(id), "(item:%d+:%d+:%d+:%d+)")
                local _, _, quality = GetItemInfo(itemLink)
                if quality >= 0 then
                    --send to officers
                    core.bsend("BULK", "PreloadItem=" .. id .. "=" .. lootIcon .. "=" .. lootName .. "=" .. GetLootSlotLink(id))
                end
            end
        end

        core.syncRoster()
        self.sentReset = true

        TalcVoteFrameRLExtraFrameBroadcastLoot:SetText('Waiting sync...')

        return
    end

    TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()

    self.LootCountdown:Show()
    core.asend('CountDownFrame=Show')

    local numLootItems = 0
    for id = 0, GetNumLootItems() do
        if GetLootSlotInfo(id) and GetLootSlotLink(id) then
            local lootIcon, lootName = GetLootSlotInfo(id)

            local _, _, itemLink = core.find(GetLootSlotLink(id), "(item:%d+:%d+:%d+:%d+)")
            local _, _, quality = GetItemInfo(itemLink)
            if quality >= 0 then
                --send to c
                core.bsend("ALERT", "Loot=" .. id .. "=" .. lootIcon .. "=" .. lootName .. "=" .. GetLootSlotLink(id))
                numLootItems = numLootItems + 1
            end
        end
    end
    core.bsend("ALERT", "DoneSending=" .. numLootItems)
    TalcVoteFrameMLToWinner:Disable()

    TalcVoteFrameRLExtraFrameBroadcastLoot:SetText(numLootItems .. " items sent")
end

function VoteFrame:AddVotedItem(index, texture, link)

    self.itemVotes[index] = {}
    self.doneVoting[index] = false
    self.selectedPlayer[index] = ''

    local _, _, itemLink = core.find(link, "(item:%d+:%d+:%d+:%d+)")
    local itemID = core.int(core.split(':', itemLink)[2])

    if not self.VotedItemsFrames[index] then
        self.VotedItemsFrames[index] = CreateFrame("Frame", "TALCVotedItem" .. index, TalcVoteFrameVotedItemsFrame, "Talc_VotedItemTemplate")
    end

    local frame = 'TALCVotedItem' .. index

    TalcVoteFrameVotedItemsFrame:SetHeight(40 * index + 35)

    _G[frame]:SetPoint("TOPLEFT", TalcVoteFrameVotedItemsFrame, "TOPLEFT", 5, 35 - (45 * index))

    _G[frame]:Show()
    _G[frame].link = link
    _G[frame].itemID = itemID
    _G[frame].texture = texture
    _G[frame].awardedTo = ''
    _G[frame].rolled = false
    _G[frame].pickedByEveryone = false

    core.addButtonOnEnterTooltip(_G[frame .. 'Button'], link)

    _G[frame .. 'Button']:SetID(index)
    _G[frame .. 'Button']:SetNormalTexture(texture)
    _G[frame .. 'Button']:SetPushedTexture(texture)
    _G[frame .. 'Button']:SetHighlightTexture(texture)

    _G[frame .. 'ButtonCheck']:Hide()
    _G[frame .. 'Button']:SetHighlightTexture(texture)

    if index ~= 1 then
        SetDesaturation(_G[frame .. 'Button']:GetNormalTexture(), 1)
    end

    if not self.CurrentVotedItem then
        self:VotedItemButton_OnClick(index)
    end
end

function VoteFrame:VotedItemButton_OnClick(id)

    TalcVoteFrameMLToWinner:Hide()
    if core.isRaidLeader() then
        TalcVoteFrameMLToWinner:Show()
    end
    if core.canVote() and not core.isRaidLeader() then
        TalcVoteFrameWinnerStatus:Show()
    end

    SetDesaturation(_G['TALCVotedItem' .. id .. 'Button']:GetNormalTexture(), 0)
    for index, _ in next, self.VotedItemsFrames do
        if index ~= id then
            SetDesaturation(_G['TALCVotedItem' .. index .. 'Button']:GetNormalTexture(), 1)
        end
    end
    self:SetCurrentVotedItem(id)
end

function VoteFrame:SetCurrentVotedItem(id)

    self.CurrentVotedItem = id

    TalcVoteFrameCurrentVotedItemButton:Show()

    for index, frame in next, self.VotedItemsFrames do
        if index == id then
            _G[frame:GetName() .. 'Button']:SetSize(44, 44)
            _G[frame:GetName() .. 'Backdrop']:Show()
        else
            _G[frame:GetName() .. 'Button']:SetSize(38, 38)
            _G[frame:GetName() .. 'Backdrop']:Hide()
        end
    end

    TalcVoteFrameCurrentVotedItemButton:SetNormalTexture(self.VotedItemsFrames[id].texture)
    TalcVoteFrameCurrentVotedItemButton:SetPushedTexture(self.VotedItemsFrames[id].texture)

    local link = self.VotedItemsFrames[id].link

    TalcVoteFrameVotedItemName:SetText(link)
    TalcVoteFrameVotedItemName:Show()

    core.addButtonOnEnterTooltip(TalcVoteFrameCurrentVotedItemButton, link, 'playerHistory')

    local _, _, itemLink = core.find(link, "(item:%d+:%d+:%d+:%d+)")
    local itemID = core.split(':', itemLink)
    itemID = core.int(itemID[2])
    local _, _, q, iLevel, _, _, t2, _, equip_slot = GetItemInfo(itemLink)

    TalcVoteFrameVotedItemType:Hide()

    local itemType = ''
    if core.equipSlotsDetails[equip_slot] then
        itemType = core.equipSlotsDetails[equip_slot].name .. ", " .. t2
        TalcVoteFrameVotedItemType:SetText(itemType)
        TalcVoteFrameVotedItemType:Show()
    end

    if core.find(t2, 'Quest', 1, true) then
        if tokenRewards[itemID] and tokenRewards[itemID].rewards then
            local _, _, qq, level = GetItemInfo(tokenRewards[itemID].rewards[1])
            iLevel = level
            q = qq
        end
    end

    if core.find(t2, 'Junk', 1, true) then
        -- Token

        if tokenRewards[itemID] and tokenRewards[itemID].rewards then
            TALCTooltip:SetOwner(TalcNeedFrame, "ANCHOR_NONE")
            TALCTooltip:SetHyperlink(itemLink)
            for i = 1, 20 do
                if _G["TALCTooltipTextLeft" .. i] and _G["TALCTooltipTextLeft" .. i]:GetText() then
                    if core.find(_G["TALCTooltipTextLeft" .. i]:GetText(), "Classes:", 1, true) then
                        local _, _, qq, level = GetItemInfo(tokenRewards[itemID].rewards[1])
                        iLevel = level
                        q = qq
                        break
                    end
                end
            end
            TALCTooltip:Hide()
        end
    end

    TalcVoteFrameCurrentVotedItemButtonItemLevel:SetText(ITEM_QUALITY_COLORS[q].hex .. iLevel)

    for _, frame in next, self.itemRewardsFrames do
        frame:Hide()
    end

    local showDe = true

    if tokenRewards[itemID] and tokenRewards[itemID].rewards then
        showDe = false
        if not self.itemRewardsFrames[1] then
            self.itemRewardsFrames[1] = CreateFrame("Button", "TALCItemReward1", TalcVoteFrame, 'Talc_SmallIconButtonTemplate')
        end

        if tokenRewards[itemID].count then
            _G['TALCItemReward1Count']:SetText(tokenRewards[itemID].count)
            _G['TALCItemReward1Count']:Show()
        else
            _G['TALCItemReward1Count']:Hide()
        end

        _G["TALCItemReward1"]:SetPoint("TOPLEFT", TalcVoteFrameCurrentVotedItemButton, "BOTTOMRIGHT", 3, 25)

        for i, rewardID in next, tokenRewards[itemID].rewards do
            local _, il, _, _, _, _, _, _, _, tex = GetItemInfo(rewardID)
            if il then

                if not self.itemRewardsFrames[i] then
                    self.itemRewardsFrames[i] = CreateFrame("Button", "TALCItemReward" .. i, TalcVoteFrame, 'Talc_SmallIconButtonTemplate')
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

                TALCTooltip:SetOwner(TalcNeedFrame, "ANCHOR_NONE")
                TALCTooltip:SetHyperlink(il)

                for j = 5, 15 do
                    local classFound = false
                    if _G["TALCTooltipTextLeft" .. j] and _G["TALCTooltipTextLeft" .. j]:GetText() then
                        local itemText = _G["TALCTooltipTextLeft" .. j]:GetText()

                        _G[frame .. "Border"]:Hide()

                        for class, data in next, core.classColors do
                            if itemText == "Classes: " .. core.ucFirst(class) then
                                _G[frame .. "Border"]:Show()
                                _G[frame .. "Border"]:SetVertexColor(data.r, data.g, data.b)
                                classFound = true
                                break
                            end
                        end
                    end
                    if classFound then
                        break
                    end
                end

                TALCTooltip:Hide()

                core.addButtonOnEnterTooltip(_G[frame], il)

            end
        end
    end

    if showDe then
        TalcVoteFrameMLToEnchanter:Show()
    else
        TalcVoteFrameMLToEnchanter:Hide()
    end

    self:VoteFrameListUpdate()
end

function VoteFrame:DoneVoting_OnClick()
    self.doneVoting[self.CurrentVotedItem] = true
    TalcVoteFrameDoneVoting:Disable()
    TalcVoteFrameDoneVotingCheck:Show()
    core.asend("DoneVoting=" .. self.CurrentVotedItem)
    self:VoteFrameListUpdate()
end

function VoteFrame:ChangePlayerPickTo(playerName, newPick, itemIndex)
    for pIndex, data in next, self.playersWhoWantItems do
        if data.itemIndex == itemIndex and data.name == playerName then
            self.playersWhoWantItems[pIndex].need = newPick
            break
        end
    end
    if core.isRaidLeader() then
        core.asend("ChangePickTo=" .. playerName .. "=" .. newPick .. "=" .. itemIndex)
    end

    self:VoteFrameListUpdate()
end

function VoteFrame:TimeLeftBar_OnUpdate()
    if this:GetValue() <= 0 then
        _G[this:GetName() .. 'Spark']:Hide()
        TalcVoteFrameTimeLeftBarTextCenter:Hide()
    else
        _G[this:GetName() .. 'Spark']:Show()
        TalcVoteFrameTimeLeftBarTextCenter:Show()
    end

    if this.pleaseVote then
        TalcVoteFrameTimeLeftBarTextCenter:SetText('Please VOTE ! ' .. core.SecondsToClock(this:GetValue()))
    else
        TalcVoteFrameTimeLeftBarTextCenter:SetText(core.SecondsToClock(this:GetValue()))
    end

    _G[this:GetName() .. 'Spark']:SetPoint("CENTER", this, "LEFT",
            this.currentTime * this:GetWidth() / this.countDownFrom, 0)
end

VoteFrame.VoteCountdown = CreateFrame("Frame")
VoteFrame.VoteCountdown:Hide()
VoteFrame.VoteCountdown.currentTime = 0
VoteFrame.VoteCountdown.votingOpen = false
VoteFrame.VoteCountdown:SetScript("OnShow", function()
    this.startTime = GetTime()
    TalcVoteFrameTimeLeftBar:SetMinMaxValues(0, this.countDownFrom)
    this.currentTime = this.countDownFrom

    TalcVoteFrameTimeLeftBar.currentTime = this.currentTime
    TalcVoteFrameTimeLeftBar.countDownFrom = this.countDownFrom
    TalcVoteFrameTimeLeftBar.pleaseVote = true
end)
VoteFrame.VoteCountdown:SetScript("OnUpdate", function()
    local plus = 0.03
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then

        this.currentTime = this.currentTime - plus

        TalcVoteFrameTimeLeftBar.currentTime = this.currentTime
        TalcVoteFrameTimeLeftBar:SetValue(this.currentTime)

        if this.currentTime <= 0 then
            TalcVoteFrameMLToWinner:Enable()
            this:Hide()
        end

        this.startTime = GetTime()
    end
end)

VoteFrame.LootCountdown = CreateFrame("Frame")
VoteFrame.LootCountdown:Hide()
VoteFrame.LootCountdown.currentTime = 0
VoteFrame.LootCountdown:SetScript("OnShow", function()
    this.startTime = GetTime()
    TalcVoteFrameTimeLeftBar:SetMinMaxValues(0, this.countDownFrom)
    this.currentTime = this.countDownFrom

    TalcVoteFrameTimeLeftBar.currentTime = this.currentTime
    TalcVoteFrameTimeLeftBar.countDownFrom = this.countDownFrom
    TalcVoteFrameTimeLeftBar.pleaseVote = false
end)
VoteFrame.LootCountdown:SetScript("OnUpdate", function()
    local plus = 0.03
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then

        this.currentTime = this.currentTime - plus

        TalcVoteFrameTimeLeftBar.currentTime = this.currentTime
        TalcVoteFrameTimeLeftBar:SetValue(this.currentTime)

        if this.currentTime <= 0 then
            this:Hide()

            TalcVoteFrameMLToWinner:Enable()

            VoteFrame.VoteCountdown.votingOpen = true

            for raidi = 0, GetNumRaidMembers() do
                if GetRaidRosterInfo(raidi) then
                    local n, _, _, _, _, _, z = GetRaidRosterInfo(raidi)
                    if z ~= 'Offline' then

                        for index in next, VoteFrame.VotedItemsFrames do
                            local picked = false
                            for _, player in next, VoteFrame.playersWhoWantItems do
                                if player.itemIndex == index and player.name == n then
                                    picked = true
                                    break
                                end
                            end
                            if not picked then
                                --add players without addon to playersWhoWant with autopass
                                --can be disabled to hide autopasses
                                core.insert(VoteFrame.playersWhoWantItems, {
                                    itemIndex = index,
                                    name = n,
                                    need = 'autopass',
                                    ci1 = '0', ci2 = '0', ci3 = '0', ci4 = '0',
                                    votes = 0,
                                    roll = 0,
                                    itemLevel = -1,
                                    inWishlist = false
                                })

                                --increment pick responses, even for autopass
                                if VoteFrame.pickResponses[index] then
                                    if VoteFrame.pickResponses[index] < core.getNumOnlineRaidMembers() then
                                        VoteFrame.pickResponses[index] = VoteFrame.pickResponses[index] + 1
                                    end
                                else
                                    VoteFrame.pickResponses[index] = 1
                                end
                            end
                        end
                    end
                end
            end

            VoteFrame:ShowWindow()
            VoteFrame:ShowScreen("Voting")
            VoteFrame:VoteFrameListUpdate()
            VoteFrame.VoteCountdown:Show()

        end

        this.startTime = GetTime()

    end
end)

----------------------------------------------------
--- Raid Leader's Options
----------------------------------------------------

function VoteFrame:ToggleRLOptions_OnClick()

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
        self:RLFrameChangeTab_OnClick(1)
    end
end

function VoteFrame:SetOfficer_OnClick(id, to)
    if to then
        core.addToRoster(self.officerFrames[id].name, this)
    else
        core.remFromRoster(self.officerFrames[id].name)
    end
end

function VoteFrame:SetAssist_OnClick(id, to)
    for i = 0, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) then
            local n = GetRaidRosterInfo(i)
            if n == self.officerFrames[id].name then
                if to then
                    talc_debug('promote ')
                    PromoteToAssistant(n)
                else
                    talc_debug('demote ')
                    DemoteAssistant(n)
                end
                return
            end
        end
    end
end

function VoteFrame:SyncLootHistory()
    VoteFrame.manualLootSync = true
    local totalItems = 0
    for _ in next, db['VOTE_LOOT_HISTORY'] do
        totalItems = totalItems + 1
    end

    TalcVoteFrameRLWindowFrameTab2ContentsSyncLootHistory:Disable()
    TalcVoteFrameRLWindowFrameTab2ContentsSyncLootHistory:SetText("Syncing (0%)")

    talc_print('Starting History Sync, ' .. totalItems .. ' entries...')

    core.bsend("BULK", "LootHistorySync=Start")

    self.syncLootHistoryCount = 0

    for timestamp, item in next, db['VOTE_LOOT_HISTORY'] do
        core.bsend("BULK", "LootHistorySync="
                .. timestamp .. "="
                .. item.player .. "="
                .. item.class .. "="
                .. item.item .. "="
                .. item.pick .. "="
                .. item.raid)
    end
    core.bsend("BULK", "LootHistorySync=End")
end

function VoteFrame:CheckAssists()

    local assistsAndCLs = {}

    -- add me
    core.insert(assistsAndCLs, {
        name = core.me,
        assist = true,
        cl = core.canVote()
    })
    -- get assists
    for i = 0, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) then
            local n, r = GetRaidRosterInfo(i)
            if r == 1 then
                core.insert(assistsAndCLs, {
                    name = n,
                    assist = true,
                    cl = core.canVote(n)
                })
            end
        end
    end
    --getcls
    for _, name in next, db['VOTE_ROSTER'] do
        local add = true
        for _, aac in next, assistsAndCLs do
            if aac.name == name then
                add = false
            end
        end
        if add then
            core.insert(assistsAndCLs, {
                name = name,
                assist = core.isAssistant(name),
                cl = true
            })
        end
    end

    for _, frame in next, self.officerFrames do
        frame:Hide()
    end

    for index, names in next, assistsAndCLs do
        if not self.officerFrames[index] then
            self.officerFrames[index] = CreateFrame('Frame', 'TALCOfficerFrame' .. index, TalcVoteFrameRLWindowFrame, 'Talc_OfficerFrameTemplate')
        end

        local frame = 'TALCOfficerFrame' .. index

        _G[frame]:SetPoint("TOPLEFT", TalcVoteFrameRLWindowFrame, "TOPLEFT", 7, -60 - 25 * index - 10)
        _G[frame]:Show()
        _G[frame].name = names.name

        _G[frame .. 'Name']:SetText(core.classColors[core.getPlayerClass(names.name)].colorStr .. names.name)

        _G[frame .. 'StatusIconOnline']:Hide()
        _G[frame .. 'StatusIconOffline']:Hide()

        if core.onlineInRaid(names.name) then
            _G[frame .. 'StatusIconOnline']:Show()
        else
            _G[frame .. 'StatusIconOffline']:Show()
        end

        _G[frame .. 'OfficerCheck']:SetID(index)
        _G[frame .. 'OfficerCheck']:SetChecked(names.cl)

        _G[frame .. 'AssistCheck']:SetID(index)
        _G[frame .. 'AssistCheck']:SetChecked(names.assist)

        _G[frame .. 'OfficerCheck']:Enable()
        if names.name == core.me then
            if _G[frame .. 'OfficerCheck']:GetChecked() then
                _G[frame .. 'OfficerCheck']:Disable()
            end
            _G[frame .. 'AssistCheck']:Disable()
        end
    end

    TalcVoteFrameRLWindowFrameTab1ContentsOfficer:SetText('Officer(' .. core.n(db['VOTE_ROSTER']) .. ')')
end

function VoteFrame:SaveLootButton(button, value)
    db['VOTE_CONFIG']['NeedButtons'][button] = value
end

function VoteFrame:RLFrameChangeTab_OnClick(tab)

    TalcVoteFrameRaiderDetailsFrame:Hide()
    _G['TalcVoteFrameRLWindowFrameTab1Contents']:Hide()
    _G['TalcVoteFrameRLWindowFrameTab2Contents']:Hide()
    --_G['TalcVoteFrameRLWindowFrameTab3Contents']:Hide()

    _G['TalcVoteFrameRLWindowFrameTab' .. tab .. 'Contents']:Show()

    for _, frame in next, self.officerFrames do
        frame:Hide()
    end

    if tab == 1 then
        TalcVoteFrameRLWindowFrameTab1:SetText(FONT_COLOR_CODE_CLOSE .. 'Officers')
        TalcVoteFrameRLWindowFrameTab2:SetText('|cff696969Loot')
        --TalcVoteFrameRLWindowFrameTab3:SetText('|cff696969Unused')

        self:CheckAssists()
    end
    if tab == 2 then
        TalcVoteFrameRLWindowFrameTab1:SetText('|cff696969Officers')
        TalcVoteFrameRLWindowFrameTab2:SetText(FONT_COLOR_CODE_CLOSE .. 'Loot')
        --TalcVoteFrameRLWindowFrameTab3:SetText('|cff696969Unused')
    end
    --if tab == 3 then
    --    TalcVoteFrameRLWindowFrameTab1:SetText('|cff696969Officers')
    --    TalcVoteFrameRLWindowFrameTab2:SetText('|cff696969Loot')
    --    TalcVoteFrameRLWindowFrameTab3:SetText(FONT_COLOR_CODE_CLOSE .. 'Unused')
    --end
end

----------------------------------------------------
--- Periodic Loot History Sync
----------------------------------------------------

VoteFrame.periodicSync = CreateFrame("Frame")
VoteFrame.periodicSync:Hide()
VoteFrame.periodicSync.plus = 0
VoteFrame.periodicSync:SetScript("OnShow", function()
    this.startTime = GetTime()
    talc_debug('periodic sync started at ' .. this.plus .. 's interval, current index = ' .. db['PERIODIC_SYNC_INDEX'])
end)
VoteFrame.periodicSync:SetScript("OnHide", function()
    talc_debug('periodic sync stopped')
end)
VoteFrame.periodicSync:SetScript("OnUpdate", function()

    if this.plus == 0 then
        this:Hide()
        return
    end

    local gt = GetTime() * 1000
    local st = (this.startTime + this.plus) * 1000
    if gt >= st then

        this.startTime = GetTime()

        if core.n(db['VOTE_LOOT_HISTORY']) == 0 then
            return
        end

        local i = 0
        for timestamp, item in core.pairsByKeysReverse(db['VOTE_LOOT_HISTORY']) do

            -- dont send old testing items
            if timestamp < 1654672311 then
                -- delete old testing items
                db['VOTE_LOOT_HISTORY'] = nil
            else
                i = i + 1
                if i == db['PERIODIC_SYNC_INDEX'] then
                    talc_debug('periodic sync send index ' .. db['PERIODIC_SYNC_INDEX'])
                    core.bsendg("BULK", "PeriodicLootHistorySync="
                            .. timestamp .. "="
                            .. item.player .. "="
                            .. item.class .. "="
                            .. item.item .. "="
                            .. item.pick .. "="
                            .. item.raid)
                end
            end
        end

        if db['PERIODIC_SYNC_INDEX'] < core.n(db['VOTE_LOOT_HISTORY']) and db['PERIODIC_SYNC_INDEX'] < core.periodicSyncMaxItems then
            db['PERIODIC_SYNC_INDEX'] = db['PERIODIC_SYNC_INDEX'] + 1
        else
            db['PERIODIC_SYNC_INDEX'] = 1
        end
    end
end)

----------------------------------------------------
--- Settings Screen
----------------------------------------------------

function VoteFrame:SettingsFrame_OnShow()

    if not db then
        return
    end

    TalcVoteFrameSettingsFramePurgeLootHistory:SetText('Purge Loot History (' .. core.n(db['VOTE_LOOT_HISTORY']) .. ')')

    if core.n(db['VOTE_LOOT_HISTORY']) > 0 then
        TalcVoteFrameSettingsFramePurgeLootHistory:Enable()
    else
        TalcVoteFrameSettingsFramePurgeLootHistory:Disable()
    end
end

function VoteFrame:PurgeLootHistory_OnClick()
    core.wipe(db['VOTE_LOOT_HISTORY'])
    talc_print('Loot History purged.')
    TalcVoteFrameSettingsFramePurgeLootHistory:Disable()
    TalcVoteFrameSettingsFramePurgeLootHistory:SetText('Purge Loot History')
end

----------------------------------------------------
--- Welcome Screen
----------------------------------------------------

function VoteFrame:WelcomeFrame_OnShow()

    --eventType
    --CALENDAR_EVENTTYPE_RAID    = 1
    --CALENDAR_EVENTTYPE_DUNGEON = 2
    --CALENDAR_EVENTTYPE_PVP     = 3
    --CALENDAR_EVENTTYPE_MEETING = 4
    --CALENDAR_EVENTTYPE_OTHER   = 5

    local title, description, creator, eventType, repeatOption, maxSize, textureIndex,
    weekday, month, day, year, hour, minute,
    lockoutWeekday, lockoutMonth, lockoutDay, lockoutYear, lockoutHour, lockoutMinute,
    locked, autoApprove, pendingInvite, inviteStatus, inviteType, calendarType = CalendarGetEventInfo()

    -- skip check past events
    if title and month == core.int(date('%m')) and day < core.int(date('%d')) then
        title = nil
    end
    if title and month == core.int(date('%m')) and day == core.int(date('%d')) then
        if hour < core.int(date('%H')) then
            title = nil
        end
    end

    if not title then
        -- try to trigger calendar stuff
        for i = core.int(date('%d')), 31 do
            if CalendarGetDayEvent(0, i, 1) then
                title, hour, minute, calendarType, _, eventType, _, _, inviteStatus = CalendarGetDayEvent(0, i, 1)
                if calendarType ~= 'RAID_LOCKOUT' and calendarType ~= 'HOLIDAY' then
                    day = i
                    month = core.int(date('%m'))
                    local today = date("*t")
                    today.day = day
                    weekday = date('%w', time(today)) + 1
                    break
                else
                    title = nil
                end
            end
        end
        if not title then
            for i = 1, 31 do
                if CalendarGetDayEvent(1, i, 1) then
                    title, hour, minute, calendarType, _, eventType, _, _, inviteStatus = CalendarGetDayEvent(1, i, 1)
                    if calendarType ~= 'RAID_LOCKOUT' and calendarType ~= 'HOLIDAY' then
                        day = i
                        month = core.int(date('%m'))
                        local today = date("*t")
                        today.day = day
                        weekday = date('%w', time(today)) + 1
                        break
                    else
                        title = nil
                    end
                end
            end
        end
    end

    local eventColor = core.RGBToHex(NORMAL_FONT_COLOR)

    if inviteStatus == CALENDAR_INVITESTATUS_ACCEPTED or inviteStatus == CALENDAR_INVITESTATUS_CONFIRMED or
            inviteStatus == CALENDAR_INVITESTATUS_SIGNEDUP then
        eventColor = core.RGBToHex(GREEN_FONT_COLOR)
    elseif inviteStatus == CALENDAR_INVITESTATUS_STANDBY or inviteStatus == CALENDAR_INVITESTATUS_TENTATIVE then
        eventColor = core.RGBToHex(ORANGE_FONT_COLOR)
    end

    local nextEventText = ''

    if title then
        if minute < 10 then
            minute = '0' .. minute
        end
        if hour < 10 then
            hour = '0' .. hour
        end

        local eventTypeText = ''
        if eventType == CALENDAR_EVENTTYPE_RAID then
            eventTypeText = ' (RAID)'
        end
        if eventType == CALENDAR_EVENTTYPE_DUNGEON then
            eventTypeText = ' (DUNGEON)'
        end
        if eventType == CALENDAR_EVENTTYPE_PVP then
            eventTypeText = ' (PVP)'
        end
        if eventType == CALENDAR_EVENTTYPE_MEETING then
            eventTypeText = ' (MEETING)'
        end
        if eventType == CALENDAR_EVENTTYPE_OTHER then
            eventTypeText = ' (OTHER)'
        end

        nextEventText = 'Your next event is ' .. eventColor .. title .. '|r' .. eventTypeText .. ', '
        if month == core.int(date('%m')) and
                year == 2000 + core.int(date('%y')) and
                day == core.int(date('%d')) then
            nextEventText = nextEventText .. "today at " .. hour .. ":" .. minute
        else
            if day == 1 or day == 21 or day == 31 then
                day = day .. "st"
            elseif day == 2 or day == 22 then
                day = day .. "nd"
            else
                day = day .. "th"
            end
            month = core.months[month]
            nextEventText = nextEventText .. core.dow[weekday - 1] .. " " .. day .. " of " .. month .. " at " .. hour .. ":" .. minute .. "ST"
        end
    else
        nextEventText = 'You have no upcoming events.'
    end

    TalcVoteFrameWelcomeFrameEventInfo:SetText(nextEventText)

    self:ShowWelcomeItems()

    TalcVoteFrameWelcomeFrameOpenWishlist:SetText("Wishlist (" .. core.n(db['NEED_WISHLIST']) .. "/" .. core.numWishlistItems .. ")")

    TalcVoteFrameWelcomeFrameRecentItems:SetText('Recent Items')
    TalcVoteFrameWelcomeFrameBackButton:Hide()
    TalcVoteFrameWelcomeFrameItemsScrollFrame:Show()
    TalcVoteFrameWelcomeFrameItemHistoryScrollFrame:Hide()
    TalcVoteFrameWelcomeFramePlayerHistoryScrollFrame:Hide()

    TalcVoteFrameWelcomeFrameTitle:SetText("Welcome (Average Item Level: " .. core.getAverageItemLevel() .. ")")

    --if db['ATTENDANCE_TRACKING'].enabled then
    --    if db['ATTENDANCE_TRACKING'].started then
    --        TalcVoteFrameWelcomeFrameAttendanceStopButton:Show()
    --        TalcVoteFrameWelcomeFrameAttendanceStartButton:Hide()
    --    else
    --        TalcVoteFrameWelcomeFrameAttendanceStopButton:Hide()
    --        TalcVoteFrameWelcomeFrameAttendanceStartButton:Show()
    --    end
    --else
    --    TalcVoteFrameWelcomeFrameAttendanceStopButton:Hide()
    --    TalcVoteFrameWelcomeFrameAttendanceStartButton:Hide()
    --end
end

function VoteFrame:ShowWelcomeItems()

    local totalItems = 0
    for _ in next, db['VOTE_LOOT_HISTORY'] do
        totalItems = totalItems + 1
    end

    if totalItems == 0 then
        TalcVoteFrameWelcomeFrameNoRecentItems:Show()
    else
        TalcVoteFrameWelcomeFrameNoRecentItems:Hide()
    end

    for _, frame in next, self.welcomeItemsFrames do
        frame:Hide()
    end

    local index = 0
    local x = TalcVoteFrameWelcomeFrame:GetWidth()
    local numCols = core.floor(x / 185)
    local col, row = 1, 1
    local raid = ''
    local offset = 0

    for timestamp, item in core.pairsByKeysReverse(db['VOTE_LOOT_HISTORY']) do
        index = index + 1

        local title = false

        local raidStringFormatted = item.raid .. ", Today"

        if date("%d%m", core.localTimeFromServerTime(timestamp)) ~= date("%d%m", time()) then
            local dow = core.dow[core.int(date("%w", core.localTimeFromServerTime(timestamp)))]
            local day = core.int(date("%d", core.localTimeFromServerTime(timestamp)))
            if day == 1 or day == 21 or day == 31 then
                day = day .. "st"
            elseif day == 2 or day == 22 then
                day = day .. "nd"
            else
                day = day .. "th"
            end
            local month = date("%B", core.localTimeFromServerTime(timestamp))
            raidStringFormatted = item.raid .. ", " .. dow .. ", " .. day .. " of " .. month
        end

        if raid ~= raidStringFormatted then
            raid = raidStringFormatted
            title = true
            offset = offset + 1
            if col ~= 1 then
                row = row + 1
            end
            col = 1
        end

        if not self.welcomeItemsFrames[index] then
            self.welcomeItemsFrames[index] = CreateFrame('Button', 'TALCWelcomeFrameItem' .. index, TalcVoteFrameWelcomeFrameItemsScrollFrameChild, 'Talc_WelcomeItemTemplate')
        end

        self.welcomeItemsFrames[index]:SetID(index)
        self.welcomeItemsFrames[index].playerName = item.player
        self.welcomeItemsFrames[index].itemName = item.item

        local frame = 'TALCWelcomeFrameItem' .. index
        _G[frame]:SetPoint('TOPLEFT', 'TalcVoteFrameWelcomeFrameItemsScrollFrameChild', 'TOPLEFT', -180 + 185 * col, 54 - 44 * row - (offset * 30))

        _G[frame .. 'RaidTitle']:Hide()
        if title then
            _G[frame .. 'RaidTitle']:SetText(raid)
            _G[frame .. 'RaidTitle']:Show()
        end

        _G[frame].itemLink = item.item
        _G[frame .. 'TopText']:SetText(item.item)
        _G[frame .. 'MiddleText']:SetText(core.needs[item.pick].colorStr .. core.needs[item.pick].text)
        _G[frame .. 'BottomText']:SetText(core.classColors[item.class].colorStr .. item.player)

        local _, _, q, _, _, _, _, _, _, tex = GetItemInfo(item.item)
        _G[frame .. 'Icon']:SetTexture(tex)

        _G[frame .. 'Border']:Hide()
        if item.player == core.me then
            local color = ITEM_QUALITY_COLORS[q]
            if color then
                _G[frame .. 'Border']:SetVertexColor(color.r, color.g, color.b, 1)
                _G[frame .. 'Border']:Show()
            end
        end

        core.addButtonOnEnterTooltip(_G[frame], item.item)

        _G[frame]:Show()

        col = col + 1

        if col > numCols then
            col = 1
            row = row + 1
        end

        if index == core.maxRecentItems then
            break
        end
    end

    TalcVoteFrameWelcomeFrameItemsScrollFrame:SetVerticalScroll(0)
end

function VoteFrame:WelcomeItem_OnClick(id)

    if this.itemLink then
        if IsControlKeyDown() then
            DressUpItemLink(this.itemLink)
            return
        end
        if IsShiftKeyDown() then
            if ChatFrame1EditBox:IsVisible() then
                ChatFrame1EditBox:Insert(this.itemLink);
                return
            end
        end
    end

    VoteFrame.itemHistoryIndex = id

    TalcVoteFrameWelcomeFrameBackButton:Show()

    TalcVoteFrameWelcomeFrameItemsScrollFrame:Hide()
    TalcVoteFrameWelcomeFramePlayerHistoryScrollFrame:Hide()

    TalcVoteFrameWelcomeFrameItemHistoryScrollFrame:Show()

    local itemHistory = {}
    for _, item in next, db['VOTE_LOOT_HISTORY'] do
        if item.item == self.welcomeItemsFrames[id].itemName then
            core.insert(itemHistory, item)
        end
    end

    TalcVoteFrameWelcomeFrameRecentItems:SetText('  ' .. self.welcomeItemsFrames[id].itemName
            .. ' History (' .. core.n(itemHistory) .. ') '
            .. core.GetItemLocation(self.welcomeItemsFrames[id].itemName))

    for _, frame in next, self.itemHistoryFrames do
        frame:Hide()
    end

    local index = 0
    for timestamp, item in core.pairsByKeysReverse(db['VOTE_LOOT_HISTORY']) do

        if item.item == self.welcomeItemsFrames[id].itemName then

            index = index + 1
            if not self.itemHistoryFrames[index] then
                self.itemHistoryFrames[index] = CreateFrame('Button', 'TALCItemHistoryPlayerFrame' .. index, TalcVoteFrameWelcomeFrameItemHistoryScrollFrameChild, 'Talc_WelcomePlayerTemplate')
            end
            local frame = 'TALCItemHistoryPlayerFrame' .. index

            _G[frame]:SetPoint('TOPLEFT', 'TalcVoteFrameWelcomeFrameItemHistoryScrollFrameChild', 'TOPLEFT', 0, 26 - 26 * index)
            _G[frame .. 'Name']:SetText(core.classColors[item.class].colorStr .. item.player)
            _G[frame .. 'Pick']:SetText(core.needs[item.pick].colorStr .. core.needs[item.pick].text)
            _G[frame .. 'Date']:SetText((date("%d/%m", timestamp) == date("%d/%m", time()) and core.classColors['hunter'].colorStr or '|r') .. date("%d/%m", timestamp))

            _G[frame .. 'Icon']:SetTexture("Interface\\AddOns\\Talc\\images\\classes\\" .. item.class)

            _G[frame].name = item.player

            _G[frame]:Show()

            if index == core.maxItemHistoryPlayers then
                break
            end

        end
    end

    TalcVoteFrameWelcomeFrameItemsScrollFrame:SetVerticalScroll(0)
end

function VoteFrame:WelcomePlayer_OnClick(name)

    TalcVoteFrameWelcomeFrameBackButton:Show()
    TalcVoteFrameWelcomeFrameItemsScrollFrame:Hide()
    TalcVoteFrameWelcomeFrameItemHistoryScrollFrame:Hide()
    TalcVoteFrameWelcomeFramePlayerHistoryScrollFrame:Show()
    TalcVoteFrameWelcomeFramePlayerHistoryScrollFrame.name = name

    local playerHistory = {}
    local forDE = 0
    for _, item in next, db['VOTE_LOOT_HISTORY'] do
        if item.player == name then
            core.insert(playerHistory, item)
            if item.pick == 'de' then
                forDE = forDE + 1
            end
        end
    end

    if core.sub(name, core.len(name), core.len(name)) == 's' then
        TalcVoteFrameWelcomeFrameRecentItems:SetText('  ' .. name .. '\' Loot History (' .. (core.n(playerHistory) - forDE) .. ')')
    else
        TalcVoteFrameWelcomeFrameRecentItems:SetText('  ' .. name .. '\'s Loot History (' .. (core.n(playerHistory) - forDE) .. ')')
    end

    for _, frame in next, self.playerHistoryFrames do
        frame:Hide()
    end

    local x = TalcVoteFrameWelcomeFrame:GetWidth()
    local numCols = core.floor(x / 185)
    local col, row = 1, 1
    local raid = ''
    local offset = 0

    local index = 0
    for timestamp, item in core.pairsByKeysReverse(db['VOTE_LOOT_HISTORY']) do
        if item.player == name then

            index = index + 1

            local title = false

            local raidStringFormatted = item.raid .. ", Today"

            if date("%d%m", core.localTimeFromServerTime(timestamp)) ~= date("%d%m", time()) then
                local dow = core.dow[core.int(date("%w", core.localTimeFromServerTime(timestamp)))]
                local day = core.int(date("%d", core.localTimeFromServerTime(timestamp)))
                if day == 1 or day == 21 or day == 31 then
                    day = day .. "st"
                elseif day == 2 or day == 22 then
                    day = day .. "nd"
                else
                    day = day .. "th"
                end
                local month = date("%B", core.localTimeFromServerTime(timestamp))
                raidStringFormatted = item.raid .. ", " .. dow .. ", " .. day .. " of " .. month
            end

            if raid ~= raidStringFormatted then
                raid = raidStringFormatted
                title = true
                offset = offset + 1
                if col ~= 1 then
                    row = row + 1
                end
                col = 1
            end

            if not self.playerHistoryFrames[index] then
                self.playerHistoryFrames[index] = CreateFrame('Button', 'TALCPlayerHistoryFrame' .. index, TalcVoteFrameWelcomeFramePlayerHistoryScrollFrameChild, 'Talc_WelcomeItemTemplate')
            end

            local frame = 'TALCPlayerHistoryFrame' .. index

            _G[frame]:SetPoint('TOPLEFT', 'TalcVoteFrameWelcomeFramePlayerHistoryScrollFrameChild', 'TOPLEFT', -180 + 185 * col, 54 - 44 * row - (offset * 30))
            _G[frame]:SetID(index)

            _G[frame .. 'RaidTitle']:Hide()
            if title then
                _G[frame .. 'RaidTitle']:SetText(raid)
                _G[frame .. 'RaidTitle']:Show()
            end

            _G[frame .. 'TopText']:SetText(item.item)
            _G[frame].itemLink = item.item
            _G[frame .. 'MiddleText']:SetText(core.needs[item.pick].colorStr .. core.needs[item.pick].text)
            _G[frame .. 'BottomText']:SetText("")

            _G[frame].name = item.player

            local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(item.item)
            _G[frame .. 'Icon']:SetTexture(tex)
            core.addButtonOnEnterTooltip(_G[frame], item.item)

            _G[frame]:Show()

            col = col + 1

            if col > numCols then
                col = 1
                row = row + 1
            end

            if index == core.maxRecentItems then
                break
            end
        end
    end

    TalcVoteFrameWelcomeFrameItemsScrollFrame:SetVerticalScroll(0)
end

function VoteFrame:WelcomeFrameBackButton_OnClick()
    if TalcVoteFrameWelcomeFrameItemHistoryScrollFrame:IsVisible() then
        self:WelcomeFrame_OnShow()
    end
    if TalcVoteFrameWelcomeFramePlayerHistoryScrollFrame:IsVisible() then
        self:WelcomeItem_OnClick(self.itemHistoryIndex)
    end
end

----------------------------------------------------
--- Wishlist Screen
----------------------------------------------------

function VoteFrame:WishlistFrame_OnShow()
    self:WishlistUpdate()
end

VoteFrame.delayAddToWishlist = CreateFrame("Frame")
VoteFrame.delayAddToWishlist:Hide()
VoteFrame.delayAddToWishlist.id = 0
VoteFrame.delayAddToWishlist:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
VoteFrame.delayAddToWishlist:SetScript("OnUpdate", function()
    local plus = 1
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        VoteFrame:TryToAddToWishlist_OnClick(this.id)
        this:Hide()
    end
end)

function VoteFrame:TryToAddToWishlist_OnClick(nameOrID)

    nameOrID = core.trim(nameOrID)

    -- empty query or wishlist full
    if core.len(nameOrID) == 0 or
            (core.int(nameOrID) and core.int(nameOrID) == 0) or
            nameOrID == 'Item ID or URL' or
            core.n(db['NEED_WISHLIST']) == core.numWishlistItems then
        self:WishlistUpdate()
        return
    end

    TalcVoteFrameWishlistFrameAdd:Disable()
    TalcVoteFrameWishlistFrameItemEditBox:ClearFocus()

    -- text query, get id from link
    if not core.int(nameOrID) then
        local fromURL, _, urlID = core.find(nameOrID, "(%d+)")
        if fromURL then
            nameOrID = core.int(urlID)
        end
    end

    -- name, id or id from link, cached
    if GetItemInfo(nameOrID) then
        local _, itemLink = GetItemInfo(nameOrID)
        self:AddToWishlist(itemLink, true)
        return
    else

        -- id or id from link, not cached
        if core.int(nameOrID) then
            -- cache and add
            core.CacheItem(nameOrID)
            self.delayAddToWishlist.id = nameOrID
            self.delayAddToWishlist:Show()
            return
        end

        -- text, not url, go search in atlas, if available
        if IsAddOnLoaded("AtlasLoot") and AtlasLoot_Data then
            AtlasLoot_LoadAllModules()

            nameOrID = core.lower(nameOrID)
            local results = {}
            local maxCols = core.floor((TalcVoteFrame:GetWidth() - 10) / 345)
            local maxRows = core.floor((TalcVoteFrame:GetHeight() - 180) / 30)
            local maxResults = maxCols * maxRows
            local col, row = 1, 1

            for _, data in core.pairs(AtlasLoot_Data) do
                for _, v in core.ipairs(data) do
                    if core.type(v[2]) == "number" and v[2] > 0 then
                        local itemName = GetItemInfo(v[2])
                        if not itemName then
                            itemName = core.gsub(v[4], "=q%d=", "")
                        end
                        if core.find(core.lower(itemName), nameOrID) then
                            -- check if it already exists
                            local found = false
                            for _, item in next, results do
                                if item.id == v[2] then
                                    found = true
                                    break
                                end
                            end
                            if not found then
                                core.CacheItem(v[2])
                                core.insert(results, { id = v[2], name = itemName })
                            end
                        end
                    end
                    if core.n(results) == maxResults then
                        break
                    end
                end
                if core.n(results) == maxResults then
                    break
                end
            end

            if core.n(results) == 0 then
                -- no results, do nothing
                talc_print("Nothing found.")
                self:WishlistUpdate()
                return
            elseif core.n(results) == 1 then
                -- one result, add the id
                nameOrID = results[1].id
                self:TryToAddToWishlist_OnClick(nameOrID)
                return
            else
                -- multiple results, display them

                TalcVoteFrameWishlistFrameCloseWindow:Hide()
                TalcVoteFrameWishlistFrameResultsBack:Show()

                for _, frame in next, self.wishlistItemsFrames do
                    frame:Hide()
                end
                for _, frame in next, self.wishlistSearchItemsFrames do
                    frame:Hide()
                end

                for index, item in next, results do
                    if not self.wishlistSearchItemsFrames[index] then
                        self.wishlistSearchItemsFrames[index] = CreateFrame("Frame", "TALCWishlistSearchItem" .. index, TalcVoteFrameWishlistFrame, "Talc_WishlistItemTemplate")
                    end

                    local frame = "TALCWishlistSearchItem" .. index

                    _G[frame]:SetPoint('TOPLEFT', TalcVoteFrameWishlistFrame, 5 + 340 * (col - 1), -70 - 30 * row)
                    _G[frame .. 'ItemButtonName']:SetText(item.name)

                    _G[frame .. 'ItemButtonIcon']:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                    core.remButtonOnEnterTooltip(_G[frame .. 'ItemButton'])

                    _G[frame .. 'RemoveButton']:Hide()
                    _G[frame .. 'AddButton']:SetID(item.id)
                    _G[frame .. 'AddButton']:Show()

                    local _, link, _, _, _, _, _, _, _, tex = GetItemInfo(item.id)
                    if tex then
                        _G[frame .. 'ItemButtonName']:SetText(link)
                        _G[frame .. 'ItemButtonIcon']:SetTexture(tex)
                        core.addButtonOnEnterTooltip(_G[frame .. 'ItemButton'], link, nil, true)
                    end

                    _G[frame]:Show()

                    col = col + 1
                    if col > maxCols then
                        col = 1
                        row = row + 1
                    end
                end

                TalcVoteFrameWishlistFrameAdd:Enable()

                return
            end
        else
            talc_print("Nothing found. Please install Atlas Loot to allow TALC to search for items.")
            self:WishlistUpdate()
        end
    end
end

function VoteFrame:WishlistFrameResultsBackButton_OnClick()
    TalcVoteFrameWishlistFrameResultsBack:Hide()
    self:WishlistUpdate()
end

function VoteFrame:AddToWishlist(itemLink, direct)

    if direct then

        for _, item in next, db['NEED_WISHLIST'] do

            local found, _, link = core.find(itemLink, "(item:%d+:%d+:%d+:%d+)")
            local name = found and GetItemInfo(link) or itemLink

            if item == itemLink or item == name then
                talc_print(itemLink .. " is already in your Wishlist.")
                self:WishlistUpdate()
                return
            end
        end

        for i = 1, core.numWishlistItems do
            if db['NEED_WISHLIST'][i] == nil then
                db['NEED_WISHLIST'][i] = itemLink
                break
            end
        end

        self:WishlistUpdate()
        return
    end

    if not GetItemInfo(itemLink) then
        talc_print(core.classColors['hunter'].colorStr .. "[" .. itemLink .. "] |rItem was not found. Try using Item ID instead.")
    end
    self:WishlistUpdate()
end

function VoteFrame:RemoveFromWishlist_OnClick(id)
    if id == core.n(db['NEED_WISHLIST']) then
        db['NEED_WISHLIST'][id] = nil
    else
        for i = id, core.n(db['NEED_WISHLIST']) - 1 do
            db['NEED_WISHLIST'][i] = db['NEED_WISHLIST'][i + 1]
        end
        db['NEED_WISHLIST'][core.n(db['NEED_WISHLIST'])] = nil
    end
    self:WishlistUpdate()
end

function VoteFrame:WishlistUpdate()

    for _, frame in next, self.wishlistSearchItemsFrames do
        frame:Hide()
    end

    for _, frame in next, self.wishlistItemsFrames do
        frame:Hide()
    end

    TalcVoteFrameWishlistFrameCloseWindow:Show()
    TalcVoteFrameWishlistFrameResultsBack:Hide()

    TalcVoteFrameWishlistFrameItemEditBox:SetText("Item ID or URL")
    TalcVoteFrameWishlistFrameDescription:SetText("You can add up to " .. core.numWishlistItems .. " items to your Wishlist.")
    TalcVoteFrameWishlistFrameAdd:Enable()

    TalcVoteFrameWishlistFrameCloseWindow:Show()

    if core.n(db['NEED_WISHLIST']) > 0 then
        TalcVoteFrameWishlistFrameDescription:SetText(TalcVoteFrameWishlistFrameDescription:GetText() .. "Your list has " .. core.n(db['NEED_WISHLIST']) .. " item(s).")
        if core.n(db['NEED_WISHLIST']) == core.numWishlistItems then
            TalcVoteFrameWishlistFrameAdd:Disable()
        end
    else
        TalcVoteFrameWishlistFrameDescription:SetText(TalcVoteFrameWishlistFrameDescription:GetText() .. "Your current list is empty.")
        return
    end

    for index, itemLink in next, db['NEED_WISHLIST'] do
        if not self.wishlistItemsFrames[index] then
            self.wishlistItemsFrames[index] = CreateFrame("Frame", "TALCWishlistItem" .. index, TalcVoteFrameWishlistFrame, "Talc_WishlistItemTemplate")
        end

        local frame = "TALCWishlistItem" .. index

        local x = 5
        local y = index
        if index >= 5 then
            x = 5 + _G[frame]:GetWidth() + 40
            y = y - 5 + 1
        end

        _G[frame]:SetPoint('TOPLEFT', TalcVoteFrameWishlistFrame, x, -70 - 30 * y)
        _G[frame .. 'ItemButtonName']:SetText(itemLink)

        _G[frame .. 'ItemButtonIcon']:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        core.remButtonOnEnterTooltip(_G[frame .. 'ItemButton'])

        _G[frame .. 'RemoveButton']:SetID(index)

        local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)
        if tex then
            _G[frame .. 'ItemButtonIcon']:SetTexture(tex)
            core.addButtonOnEnterTooltip(_G[frame .. 'ItemButton'], itemLink, nil, true)
        else
            core.CacheItem(itemLink)
        end

        _G[frame]:Show()

    end
end

----------------------------------------------------
--- Attendance
----------------------------------------------------

--function Talc_AttendanceQueryWindow_OnUpdate()
--    if GetTime() * 1000 >= (this.startTime + 1) * 1000 then
--        if this.timeout > 0 then
--            this.startTime = GetTime()
--            this.timeout = this.timeout - 1
--            _G[this:GetName() .. "No"]:SetText("No (" .. this.timeout .. ")")
--        else
--            this:Hide()
--        end
--    end
--end
--
--VoteFrame.AttendanceTracker = CreateFrame("Frame")
--VoteFrame.AttendanceTracker:Hide()
--VoteFrame.AttendanceTracker:SetScript("OnShow", function()
--    this.startTime = GetTime()
--    talc_print("Attendance tracker started.")
--    db['ATTENDANCE_TRACKING'].started = true
--end)
--VoteFrame.AttendanceTracker:SetScript("OnHide", function()
--    talc_print("Attendance tracker stopped.")
--    db['ATTENDANCE_TRACKING'].started = false
--end)
--VoteFrame.AttendanceTracker:SetScript("OnUpdate", function()
--    local plus = 3 --db['ATTENDANCE_TRACKING'].period
--    local gt = GetTime() * 1000
--    local st = (this.startTime + plus) * 1000
--    if gt >= st then
--        this.startTime = GetTime()
--        core.saveAttendance()
--    end
--end)
--
--function VoteFrame.AttendanceTracker:Start()
--    if not VoteFrame.AttendanceTracker:IsVisible() then
--        VoteFrame.AttendanceTracker:Show()
--    end
--if TalcVoteFrameWelcomeFrame:IsVisible() and not TalcVoteFrameWelcomeFrameBackButton:IsVisible() then
--    self:WelcomeFrame_OnShow()
--end
--end
--
--function VoteFrame.AttendanceTracker:Stop()
--    talc_debug("stop pressed")
--    VoteFrame.AttendanceTracker:Hide()
--if TalcVoteFrameWelcomeFrame:IsVisible() and not TalcVoteFrameWelcomeFrameBackButton:IsVisible() then
--    self:WelcomeFrame_OnShow()
--end
--end

----------------------------------------------------
--- Who Query
----------------------------------------------------

function VoteFrame:QueryWho_OnClick()

    GuildRoster()

    TalcVoteFrameWho:Show()

    if UnitInRaid('player') then
        core.asend("VersionQuery=")
    else
        core.bsendg(nil, "VersionQueryGuild=")
    end

    self.withAddon = {}
    self.withAddonFrames = {}

    TalcVoteFrameWhoTitle:SetText('TALC v' .. core.addonVer)

    if UnitInRaid('player') then
        for i = 0, GetNumRaidMembers() do
            if GetRaidRosterInfo(i) then
                local n, _, _, _, _, _, z = GetRaidRosterInfo(i)
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
    else
        local numOnlineMembers = GetNumGuildMembers();
        for i = 0, numOnlineMembers do
            if GetGuildRosterInfo(i) then
                local n, _, _, _, class = GetGuildRosterInfo(i)
                class = core.lower(class)

                self.withAddon[n] = {
                    class = core.lower(class),
                    v = '-'
                }
            end
        end
    end

    self:updateWithAddon()
end

function VoteFrame:AnnounceWithoutAddon_OnClick()
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

function VoteFrame:AnnounceOlderAddon_OnClick()
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

function VoteFrame:updateWithAddon()

    self.withAddonFrames = {}

    local row, col = 1, 1

    local index = 0

    for name, data in next, self.withAddon do

        index = index + 1

        if not self.withAddonFrames[index] then
            self.withAddonFrames[index] = CreateFrame("Button", "TALCAddonStatus" .. index, TalcVoteFrameWho, "Talc_WhoButtonTemplate")
        end

        local frame = "TALCAddonStatus" .. index

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

    TalcVoteFrameWho:SetHeight(500)

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
        TalcVoteFrameWhoAnnounceWithoutAddon:SetText('Without Addon (' .. without .. ')')
        TalcVoteFrameWhoAnnounceWithoutAddon:Enable()
    else
        TalcVoteFrameWhoAnnounceWithoutAddon:SetText('Without Addon')
        TalcVoteFrameWhoAnnounceWithoutAddon:Disable()
    end
    if older > 0 then
        TalcVoteFrameWhoAnnounceOlderAddon:SetText('Older Versions (' .. older .. ')')
        TalcVoteFrameWhoAnnounceOlderAddon:Enable()
    else
        TalcVoteFrameWhoAnnounceOlderAddon:SetText('Older Versions')
        TalcVoteFrameWhoAnnounceOlderAddon:Disable()
    end
end

----------------------------------------------------
--- Utils
----------------------------------------------------

function VoteFrame:SaveSetting(key, value)

    if core.type(key) == 'table' then
        db[key[1]][key[2]] = value == 1
        --if key[1] == 'ATTENDANCE_TRACKING' and key[2] == 'enabled' then
        --if db[key[1]][key[2]] then
        --    TalcVoteFrameSettingsFrameAttendanceBossKills:Enable()
        --    TalcVoteFrameSettingsFrameAttendanceTime:Enable()
        --else
        --    TalcVoteFrameSettingsFrameAttendanceBossKills:Disable()
        --    TalcVoteFrameSettingsFrameAttendanceTime:Disable()
        --end
        --end
        return
    end

    if key == 'WIN_ENABLE_SOUND' then
        if value then
            TalcVoteFrameSettingsFrameWinSoundHigh:Enable()
            PlaySoundFile("Interface\\AddOns\\Talc\\sound\\win_" .. db['WIN_VOLUME'] .. ".ogg")
        else
            TalcVoteFrameSettingsFrameWinSoundHigh:Disable()
        end
    elseif key == 'WIN_VOLUME' then
        if db['WIN_ENABLE_SOUND'] then
            PlaySoundFile("Interface\\AddOns\\Talc\\sound\\win_" .. value .. ".ogg")
        end
        db[key] = value
        return
    elseif key == 'WIN_THRESHOLD' then
        local t = ''
        t = t .. (TalcVoteFrameSettingsFrameWinUncommon:GetChecked() and '2' or '0')
        t = t .. (TalcVoteFrameSettingsFrameWinRare:GetChecked() and '3' or '0')
        t = t .. (TalcVoteFrameSettingsFrameWinEpic:GetChecked() and '4' or '0')
        t = t .. (TalcVoteFrameSettingsFrameWinLegendary:GetChecked() and '5' or '0')
        db[key] = t
        return
    elseif key == 'ROLL_ENABLE_SOUND' then
        if value then
            TalcVoteFrameSettingsFrameRollSoundHigh:Enable()
            TalcVoteFrameSettingsFrameRollTrombone:Enable()
        else
            TalcVoteFrameSettingsFrameRollSoundHigh:Disable()
            TalcVoteFrameSettingsFrameRollTrombone:Disable()
        end
        if value then
            PlaySoundFile("Interface\\AddOns\\Talc\\sound\\please_roll_" .. db['ROLL_VOLUME'] .. ".ogg")
        end
    elseif key == 'ROLL_VOLUME' then
        if db['ROLL_ENABLE_SOUND'] then
            PlaySoundFile("Interface\\AddOns\\Talc\\sound\\please_roll_" .. value .. ".ogg")
        end
        db[key] = value
        return
    elseif key == 'ROLL_TROMBONE' then
        if value then
            PlaySoundFile("Interface\\AddOns\\Talc\\sound\\sadtrombone.ogg")
        end
    elseif key == 'BOSS_FRAME_ENABLE' then
        if value then
            BossFrame:StartBossAnimation("Raid Boss")
        end
    elseif key == 'BOSS_LOOT_FRAME_ENABLE' then
        if value then
            BossLootFrame:StartTestAnimation()
        end
    end

    db[key] = value == 1
end

function VoteFrame:Resizing()
    --TalcVoteFrame:SetAlpha(0.8)
end

function VoteFrame:Resized()

    local ratio = TalcVoteFrame:GetWidth() / 600
    TalcVoteFrameNameLabel:SetPoint("TOPLEFT", TalcVoteFrame, core.floor(8 * ratio), -92)
    TalcVoteFrameItemLevelLabel:SetPoint("TOPLEFT", TalcVoteFrame, core.floor(100 * ratio), -92)
    TalcVoteFramePickLabel:SetPoint("TOPLEFT", TalcVoteFrame, core.floor(165 * ratio), -92)
    TalcVoteFrameReplacesLabel:SetPoint("TOPLEFT", TalcVoteFrame, core.floor(225 * ratio), -92)
    TalcVoteFrameRollLabel:SetPoint("TOPLEFT", TalcVoteFrame, core.floor(285 * ratio), -92)
    TalcVoteFrameVotesLabel:SetPoint("TOPLEFT", TalcVoteFrame, core.floor(406 * ratio), -92)
    TalcVoteFrameRecentItemsLabel:SetPoint("TOPLEFT", TalcVoteFrame, core.floor(486 * ratio), -92)

    TalcVoteFrame:SetAlpha(db['VOTE_ALPHA'])

    if TalcVoteFrameWelcomeFrame:IsVisible() then
        self:ShowWelcomeItems()
    end

    self:VoteFrameListUpdate()

    -- resize wishlist results
    if TalcVoteFrameWishlistFrameResultsBack:IsVisible() then
        TalcVoteFrameWishlistFrameAdd:Click()
    end

    -- resize player item history results
    if TalcVoteFrameWelcomeFramePlayerHistoryScrollFrame:IsVisible() then
        self:WelcomePlayer_OnClick(TalcVoteFrameWelcomeFramePlayerHistoryScrollFrame.name)
    end
end

function VoteFrame:ShowScreen(screen)
    for _, frame in next, self.screens do
        if frame ~= screen then
            if _G["TalcVoteFrame" .. frame .. "Frame"]:IsVisible() then
                _G["TalcVoteFrame" .. frame .. "Frame"]:Hide()
            end
        else
            if not _G["TalcVoteFrame" .. screen .. "Frame"]:IsVisible() then
                _G["TalcVoteFrame" .. screen .. "Frame"]:Show()
            end
        end
    end
end

function VoteFrame:SetTitle(to)
    if not to then
        TalcVoteFrameTitle:SetText('|cfffff569T|rhunder |cfffff569A|rle Brewing Co |cfffff569L|root |cfffff569C|rompanion v' .. core.addonVer)
    else
        TalcVoteFrameTitle:SetText('|cfffff569T|rhunder |cfffff569A|rle Brewing Co |cfffff569L|root |cfffff569C|rompanion v' .. core.addonVer .. ' - ' .. to)
    end
end

function VoteFrame:GetPlayerInfo(playerIndexOrName)
    --returns itemIndex, name, need, votes, ci1, ci2, ci3, ci4, roll, k, itemLevel, inWishlist
    if core.type(playerIndexOrName) == 'string' then
        for k, player in next, self.currentPlayersList do
            if player.name == playerIndexOrName then
                return player.itemIndex, player.name, player.need, player.votes, player.ci1, player.ci2, player.ci3, player.ci4, player.roll, k, player.itemLevel, player.inWishlist
            end
        end
    end
    local player = self.currentPlayersList[playerIndexOrName]
    if player then
        return player.itemIndex, player.name, player.need, player.votes, player.ci1, player.ci2, player.ci3, player.ci4, player.roll, playerIndexOrName, player.itemLevel, player.inWishlist
    else
        return false
    end
end

function VoteFrame:SendTestItems_OnClick()

    local testItem1 = "\124cffa335ee\124Hitem:40610:0:0:0:0:0:0:0:0\124h[Chestguard of the Lost Conqueror]\124h\124r"
    local testItem2 = "\124cffa335ee\124Hitem:46052:0:0:0:0:0:0:0:0\124h[Reply-Code Alpha]\124h\124r"
    --local testItem3 = "\124cffa335ee\124Hitem:40614:0:0:0:0:0:0:0:0\124h[Gloves of the Lost Protector]\124h\124r"
    local testItem3 = "\124cffa335ee\124Hitem:40256:0:0:0:0:0:0:0:0\124h[Grim Toll]\124h\124r"

    local _, _, itemLink1 = core.find(testItem1, "(item:%d+:%d+:%d+:%d+)")
    local lootName1, _, quality1, _, _, _, _, _, _, lootIcon1 = GetItemInfo(itemLink1)

    local _, _, itemLink2 = core.find(testItem2, "(item:%d+:%d+:%d+:%d+)")
    local lootName2, _, quality2, _, _, _, _, _, _, lootIcon2 = GetItemInfo(itemLink2)

    local _, _, itemLink3 = core.find(testItem3, "(item:%d+:%d+:%d+:%d+)")
    local lootName3, _, quality3, _, _, _, _, _, _, lootIcon3 = GetItemInfo(itemLink3)

    if lootName1 and lootName2 and lootName3 then

        SendChatMessage('This is a test, click whatever you want!', "RAID_WARNING")
        TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()

        core.SetDynTTN(3)
        core.SetDynTTV(3)
        self.LootCountdown.countDownFrom = db['VOTE_TTN']

        self:SendTimersAndButtons()

        self:SendReset()

        self.LootCountdown:Show()
        core.asend('CountDownFrame=Show')

        core.bsend("ALERT", "PreloadItem=1=" .. lootIcon1 .. "=" .. lootName1 .. "=" .. testItem1)
        core.bsend("ALERT", "PreloadItem=2=" .. lootIcon2 .. "=" .. lootName2 .. "=" .. testItem2)
        core.bsend("ALERT", "PreloadItem=3=" .. lootIcon3 .. "=" .. lootName3 .. "=" .. testItem3)

        core.bsend("ALERT", "Loot=1=" .. lootIcon1 .. "=" .. lootName1 .. "=" .. testItem1)
        core.bsend("ALERT", "Loot=2=" .. lootIcon2 .. "=" .. lootName2 .. "=" .. testItem2)
        core.bsend("ALERT", "Loot=3=" .. lootIcon3 .. "=" .. lootName3 .. "=" .. testItem3)
        core.bsend("ALERT", "DoneSending=3")

        TalcVoteFrameMLToWinner:Disable()
    else
        talc_print("Items are caching, try again in a couple moments.")
    end
end

--[[
PlaySound("igQuestListOpen")
PlaySound("igQuestListClose")

PlaySound("igMainMenuOptionCheckBoxOn")
PlaySound("igMainMenuOptionCheckBoxOff")

PlaySound("igCharacterInfoTab")
PlaySound("igMainMenuClose")
]]--
