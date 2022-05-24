local db, core, tokenRewards
local _G = _G

local ContestantDropdownMenu = CreateFrame('Frame', 'ContestantDropdownMenu', UIParent, 'UIDropDownMenuTemplate')
ContestantDropdownMenu.currentContestantId = 0

TalcFrame = CreateFrame("Frame")

----------------------------------------------------
--- Vars
----------------------------------------------------

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

TalcFrame.receivedResponses = 0
TalcFrame.pickResponses = {}

TalcFrame.lootHistoryMinRarity = 3
TalcFrame.selectedPlayer = {}

TalcFrame.lootHistoryFrames = {}
TalcFrame.peopleWithAddon = ''

TalcFrame.doneVoting = {} --self / item
TalcFrame.clDoneVotingItem = {}
TalcFrame.CLVoted = {}

TalcFrame.sentReset = false

TalcFrame.numItems = 0

TalcFrame.CLVotedFrames = {}
TalcFrame.RaidBuffs = {}

TalcFrame.assistTriggers = 0

TalcFrame.HistoryId = 0

TalcFrame.contestantsFrames = {}
TalcFrame.bagItems = {}
TalcFrame.inspectPlayerGear = {}

TalcFrame.durationNotification = 1000 * 60 -- 10 * 60 -- s

TalcFrame.welcomeItemsFrames = {}

TalcFrame.withAddon = {}
TalcFrame.withAddonFrames = {}

TalcFrame.closeVoteFrameFromSettings = false

TalcFrame.itemRewardsFrames = {}

TalcFrame.wishlistItemsFrames = {}

TalcFrame.itemHistoryIndex = 0
TalcFrame.itemHistoryFrames = {}
TalcFrame.playerHistoryFrames = {}

TalcFrame.screens = {
    'Voting',
    'Welcome', 'Settings', 'Wishlist' --, Attendance
}

TalcFrame.syncLootHistoryCount = 0

TalcFrame.wishlistSearchItemsFrames = {}

TalcFrame.attendanceFrames = {}
TalcFrame.expandedAttendanceFrames = {}

TalcFrame.assistFrames = {}
TalcFrame.currentTab = 1

----------------------------------------------------
--- Init
----------------------------------------------------

function TalcFrame:init()

    db = TALC_DB
    core = TALC
    tokenRewards = TALC_TOKENS

    -- start syncing item history with guild every x seconds
    -- 2x 10m = 30/week
    -- 4x 25m = 60/week
    -- 4680 / year naxx
    TalcFrame.periodicSync.plus = 30 -- core.floor(3600 / core.min(core.periodicSyncMaxItems, core.n(db['VOTE_LOOT_HISTORY'])))
    TalcFrame.periodicSync:Show()

    self:ResetVars()
end

function TalcFrame:ResetVars()

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
    self.LCVoters = 0
    self.CLVoted = {}

    self.selectedPlayer = {}
    self.inspectPlayerGear = {}

    self.doneVoting = {}
    self.clDoneVotingItem = {}

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

    TalcVoteFrameVotesLabel:SetText('Votes');
    TalcVoteFrameContestantCount:SetText()
    TalcVoteFrameWinnerStatus:Hide()

    TalcVoteFrameMLToWinner:Disable()
    TalcVoteFrameMLToWinnerNrOfVotes:SetText()
    TalcVoteFrameMLToEnchanter:Hide()
    TalcVoteFrameWinnerStatusNrOfVotes:SetText()

    TalcVoteFrameTimeLeftBar:SetWidth(TalcVoteFrame:GetWidth() - 8)
    TalcVoteFrameTimeLeftBarBG:SetWidth(TalcVoteFrame:GetWidth() - 8)

    TalcVoteFrameCurrentVotedItemButton:Hide()
    TalcVoteFrameVotedItemName:Hide()

    TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()

    TalcVoteFrameDoneVoting:Disable();
    TalcVoteFrameDoneVotingCheck:Hide();
    TalcVoteFrameContestantScrollListFrame:Hide()

    TalcVoteFrameTradableItemsFrame:Hide()

    TalcVoteFrameContestantScrollListFrame:SetPoint("TOPLEFT", TalcVoteFrame, "TOPLEFT", 5, -109)
    TalcVoteFrameContestantScrollListFrame:SetPoint("BOTTOMRIGHT", TalcVoteFrame, "BOTTOMRIGHT", -5, 28)

    TalcVoteFrameRLExtraFrameDragLoot:SetText("Drag Loot")
    TalcVoteFrameRLExtraFrameDragLoot:Enable()

    if core.isRaidLeader() then
        TalcVoteFrameRLExtraFrame:Show()

        TalcVoteFrameMLToEnchanter:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", -100, 0);
            if db['VOTE_ENCHANTER'] == '' then
                GameTooltip:AddLine("Enchanter not set. Type /talc set enchanter [name]")
            else
                GameTooltip:AddLine("ML to " .. db['VOTE_ENCHANTER'] .. " to disenchant.")
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

    core.clearScrollbarTexture(TalcVoteFrameContestantScrollListFrameScrollBar)
    core.clearScrollbarTexture(TalcVoteFrameWelcomeFrameItemsScrollFrameScrollBar)
    core.clearScrollbarTexture(TalcVoteFrameWelcomeFrameItemHistoryScrollFrameScrollBar)
    core.clearScrollbarTexture(TalcVoteFrameWelcomeFramePlayerHistoryScrollFrameScrollBar)
    core.clearScrollbarTexture(TalcVoteFrameRaiderDetailsFrameLootHistoryFrameScrollFrameScrollBar)
    core.clearScrollbarTexture(TalcVoteFrameRaiderDetailsFrameAttendanceFrameScrollFrameScrollBar)

end

----------------------------------------------------
--- Addon Messages
----------------------------------------------------

function TalcFrame:handleSync(pre, t, ch, sender)
    if not core.find(t, 'periodic', 1, true) then
        talc_debug(sender .. ' says: ' .. t)
    end

    if core.find(t, 'boss&', 1, true) then
        if not core.canVote() then
            return false
        end
        if not core.isRaidLeader(sender) then
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
        if not core.isRaidLeader(sender) then
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
        if not core.isRaidLeader() then
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
        if not core.isRaidLeader() then
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

        if not core.isRaidLeader(sender) or sender == core.me then
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

        if not core.isRaidLeader(sender) or sender == core.me then
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

        if not core.isRaidLeader(sender) then
            return
        end

        if not core.canVote() then
            return
        end

        if command[2] == "reset" then
            self:ResetVars()
        end
        if command[2] == "close" then
            self:CloseWindow()
        end
        return
    end

    if core.find(t, 'preloadInVoteFrame=', 1, true) then

        local item = core.split("=", t)

        local index = core.int(item[2])
        local texture = item[3]
        local link = item[5]

        local _, _, itemLink = core.find(link, "(item:%d+:%d+:%d+:%d+)");
        local itemID = core.split(':', itemLink)
        core.cacheItem(core.int(itemID[2]))

        if not core.isRaidLeader(sender) or not core.canVote() then
            return
        end

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

        self.numItems = self.numItems + 1

        self:addVotedItem(index, texture, link)

        self:ShowScreen("Voting")

        return
    end

    if core.find(t, 'countdownframe=', 1, true) then

        if not core.isRaidLeader(sender) or not core.canVote() then
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

        if not core.canVote() then
            return
        end

        local needEx = core.split('=', t)

        if not needEx[7] then
            talc_error('bad need syntax')
            talc_error(t)
            return false
        end

        if core.sub(t, 1, 9) == 'autopass=' then
            return false
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
            gearscore = core.int(needEx[7]),
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
    if core.find(t, 'syncRoster=', 1, true) then
        if not core.isRaidLeader(sender) then
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
            db['VOTE_ROSTER'] = {}
        elseif command[2] == "end" then
            talc_debug('Roster updated.')
        else
            core.insert(db['VOTE_ROSTER'], command[2])
        end
        return
    end

    if core.find(t, 'playerWon#', 1, true) then

        if not core.isRaidLeader(sender) then
            return
        end

        local wonData = core.split("#", t)

        if not wonData[7] then
            talc_error('bad playerWon syntax')
            talc_error(t)
            return false
        end

        local hash, player, item, index, pick, raid

        hash = core.int(wonData[2])
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
        db['VOTE_LOOT_HISTORY'][hash] = {
            timestamp = time(),
            player = player,
            class = core.getPlayerClass(player),
            item = item,
            pick = pick,
            raid = raid
        }

        -- update welcome items if visible
        if TalcVoteFrameWelcomeFrame:IsVisible() then
            TalcFrame:WelcomeFrame_OnShow()
        end
        return
    end

    if core.find(t, 'Timers:ttn', 1, true) then
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
            if core.isRaidLeaderOrAssistant(sender) then
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

    -- includes periodic_loot_history_sync too
    if core.find(t, 'loot_history_sync;', 1, true) then

        if not core.isRaidLeader(sender) then
            return
        end

        local totalItems = 0
        for _ in next, db['VOTE_LOOT_HISTORY'] do
            totalItems = totalItems + 1
        end

        local lh = core.split(";", t)

        if not lh[8] then
            if t ~= 'loot_history_sync;start' and t ~= 'loot_history_sync;end' then
                talc_error('bad loot_history_sync syntax')
                talc_error(t)
                return false
            end
        end

        if lh[2] == 'start' then
        elseif lh[2] == 'end' then
            if sender == core.me then
                talc_print('History Sync complete.')
                TalcVoteFrameRLWindowFrameTab2ContentsSyncLootHistory:Enable()
                TalcVoteFrameRLWindowFrameTab2ContentsSyncLootHistory:SetText('Sync Loot History (' .. totalItems .. ')')
            else
                -- update welcome items if visible
                if TalcVoteFrameWelcomeFrame:IsVisible() then
                    self:WelcomeFrame_OnShow()
                end
            end
            talc_debug('loot history synced.')
        else

            if sender == core.me then
                self.syncLootHistoryCount = self.syncLootHistoryCount + 1
                local percent = core.floor(self.syncLootHistoryCount * 100 / totalItems)
                TalcVoteFrameRLWindowFrameTab2ContentsSyncLootHistory:SetText('Syncing (' .. percent .. '%)')
            else
                local hash, timestamp, player, class, item, pick, raid

                hash = core.int(lh[2])
                timestamp = core.int(lh[3])
                player = lh[4]
                class = lh[5]
                item = lh[6]
                pick = lh[7]
                raid = lh[8]

                local _, _, itemLink = core.find(item, "(item:%d+:%d+:%d+:%d+)");
                local itemID = core.int(core.split(':', itemLink)[2])
                core.cacheItem(itemID)

                if not db['VOTE_LOOT_HISTORY'][hash] then
                    db['VOTE_LOOT_HISTORY'][hash] = {
                        timestamp = timestamp,
                        player = player,
                        class = class,
                        item = item,
                        pick = pick,
                        raid = raid
                    }
                end

                -- update welcome items if visible
                if TalcVoteFrameWelcomeFrame:IsVisible() then
                    self:WelcomeFrame_OnShow()
                end

            end
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

----------------------------------------------------
--- Minimap
----------------------------------------------------

function Talc_BuildMinimapMenu()
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
        TalcFrame:ShowScreen("Settings")
    end
    UIDropDownMenu_AddButton(menu_settings);
    UIDropDownMenu_AddButton(separator);

    local close = {};
    close.text = "Close"
    close.disabled = false
    close.isTitle = false
    UIDropDownMenu_AddButton(close);
end

function TalcFrame:ShowMinimapDropdown()
    local TALCMinimapMenuFrame = CreateFrame('Frame', 'TALCMinimapMenuFrame', UIParent, 'UIDropDownMenuTemplate')
    UIDropDownMenu_Initialize(TALCMinimapMenuFrame, Talc_BuildMinimapMenu, "MENU");
    ToggleDropDownMenu(1, nil, TALCMinimapMenuFrame, Talc_Minimap, 1, 1);
end

----------------------------------------------------
--- Main Window
----------------------------------------------------

function TalcFrame:ToggleMainWindow_OnClick()

    if TalcVoteFrame:IsVisible() then
        self:CloseWindow()
    else
        self:ShowWindow()
    end
end

function TalcFrame:ShowWindow()
    if not TalcVoteFrame:IsVisible() then
        TalcVoteFrame:Show()
        TalcVoteFrame.animIn:Play()
    end
end

function TalcFrame:CloseWindow()
    TalcVoteFrame.animOut:Play()
    TalcVoteFrameRaiderDetailsFrame:Hide()
    TalcVoteFrameRLWindowFrame:Hide()
end

function TalcFrame:ResetClose_OnClick()
    self:SendReset()
    self:SendCloseWindow()
    self.sentReset = false
    SetLootMethod("master", core.me)
end

function TalcFrame:SendReset()
    core.asend("voteframe=reset")
    core.asend("needframe=reset")
    core.asend("rollframe=reset")
end

function TalcFrame:SendCloseWindow()
    core.asend("voteframe=close")
end

----------------------------------------------------
--- Raider's Details
----------------------------------------------------

function TalcFrame:RaiderDetailsClose()
    if self.selectedPlayer[self.CurrentVotedItem] then
        self.selectedPlayer[self.CurrentVotedItem] = ''
    end
    TalcVoteFrameRaiderDetailsFrame:Hide()
end

function Talc_LootHistory_Update()
    TalcFrame:LootHistoryUpdate()
end

function TalcFrame:LootHistoryUpdate()

    local itemOffset = FauxScrollFrame_GetOffset(TalcVoteFrameRaiderDetailsFrameLootHistoryFrameScrollFrame);

    local id = self.HistoryId

    self.selectedPlayer[self.CurrentVotedItem] = _G['TalcVoteFrameContestantFrame' .. id].name

    local historyPlayerName = _G['TalcVoteFrameContestantFrame' .. id].name

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
        for _, item in core.sortedLootHistory() do
            if historyPlayerName == item.player then

                index = index + 1

                if index > itemOffset and index <= itemOffset + 7 then

                    if not self.lootHistoryFrames[index] then
                        self.lootHistoryFrames[index] = CreateFrame('Button', 'HistoryItem' .. index, TalcVoteFrameRaiderDetailsFrameLootHistoryFrameScrollFrame, 'Talc_WelcomeItemTemplate')
                    end

                    local frame = 'HistoryItem' .. index

                    _G[frame]:SetPoint("TOPLEFT", TalcVoteFrameRaiderDetailsFrameLootHistoryFrameScrollFrame, "TOPLEFT", 5, 37 - 39 * (index - itemOffset) - 30)
                    _G[frame]:Show()
                    _G[frame]:SetWidth(190)

                    local today = ''
                    if date("%d/%m") == date("%d/%m", item.timestamp) then
                        today = core.classColors['mage'].colorStr
                    end

                    _G[frame .. 'TopText']:SetWidth(165)
                    _G[frame .. 'TopText']:SetText(item.item)
                    _G[frame .. 'MiddleText']:SetText(core.needs[item.pick].colorStr .. core.needs[item.pick].text)
                    _G[frame .. 'BottomText']:SetText(core.classColors['rogue'].colorStr .. today .. date("%d/%m", item.timestamp) ..
                            " |r" .. item.raid)

                    local _, _, itemLink = core.find(item.item, "(item:%d+:%d+:%d+:%d+)");
                    local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)
                    if not tex then
                        core.cacheItem(core.int(core.split(':', itemLink)[2]))
                        break
                    end

                    print(tex)

                    _G[frame .. 'Icon']:SetTexture(tex)
                    core.addButtonOnEnterTooltip(_G[frame], item.item)

                end
            end
        end
    end

    -- ScrollFrame update
    FauxScrollFrame_Update(TalcVoteFrameRaiderDetailsFrameLootHistoryFrameScrollFrame, totalItems, 7, 38);
end

function TalcFrame:ExpandAttendanceFrame_OnClick()
    if this.playerName then
        self.expandedAttendanceFrames[this.code] = not self.expandedAttendanceFrames[this.code]
        self:RaiderDetailsTab_OnClick(3, this.playerName)
    end
end

function TalcFrame:RaiderDetailsTab_OnClick(tab, playerName)

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

        if core.n(self.inspectPlayerGear[playerName]) == 0 then
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

        local _, _, _, _, _, _, _, _, _, _, gearScore = self:GetPlayerInfo(playerName)

        TalcVoteFrameRaiderDetailsFrameInspectGearFrameNameClassGS:SetText(
                core.classColors[core.getPlayerClass(playerName)].colorStr .. playerName .. "\n" ..
                        core.classColors[core.getPlayerClass(playerName)].colorStr .. core.ucFirst(core.getPlayerClass(playerName)) .. "\n" ..
                        "|rGearscore: " .. gearScore
        )

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

        local att = db['ATTENDANCE_DATA'][playerName]

        TalcVoteFrameRaiderDetailsFrameAttendanceFrameTitleFrameIcon:Hide()
        TalcVoteFrameRaiderDetailsFrameAttendanceFrameTitleFrameLeft:SetText("|cffffffffTotal attendance points")
        TalcVoteFrameRaiderDetailsFrameAttendanceFrameTitleFrameRight:SetText("|cffffffff" .. att.points)

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
                            _G["TALCAttendanceFrame" .. code .. "Left"]:SetText("   " .. date("%d/%m %H:%M", timestamp))
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

----------------------------------------------------
--- Tradable Items
----------------------------------------------------

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

        TalcVoteFrameTradableItemsFrame:SetHeight(40 + core.n(this.items) * 21)

        if core.n(this.items) > 0 then
            TalcVoteFrameTradableItemsFrame:Show()
        else
            TalcVoteFrameTradableItemsFrame:Hide()
        end

        this.startTime = GetTime()
    end
end)

function TalcFrame.tradableItemsCheck:Item_OnClick(id)
    if TalcVoteFrame:IsVisible() and TalcVoteFrameRLExtraFrameDragLoot:IsEnabled() then

        local link = self.items[id].itemLink
        local _, _, itemLink = core.find(link, "(item:%d+:%d+:%d+:%d+)");
        local itemID = core.split(':', itemLink)[2]

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


----------------------------------------------------
--- Voting System
----------------------------------------------------

local TalcVoteFrameVotingFrame = CreateFrame("Frame", "TalcVoteFrameVotingFrame")
TalcVoteFrameVotingFrame:SetScript("OnHide", function()
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
end)
TalcVoteFrameVotingFrame:SetScript("OnShow", function()
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

    if core.isRaidLeader() then
        TalcVoteFrameMLToWinner:Show()
    else
        TalcVoteFrameWinnerStatus:Show()
    end

    TalcVoteFrameCLThatVotedList:Show()
end)

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

function TalcFrame:VoteButton_OnClick(id)
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
                local _, _, _, _, _, _, _, _, _, pIndex = TalcFrame:GetPlayerInfo(n)
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
    for _, name in next, db['VOTE_ROSTER'] do
        self.CLVoted[self.CurrentVotedItem][name] = false
    end
    for n, _ in next, self.itemVotes[self.CurrentVotedItem] do
        for voter, vote in next, self.itemVotes[self.CurrentVotedItem][n] do
            for _, name in next, db['VOTE_ROSTER'] do
                if voter == name and vote == '+' then
                    self.CLVoted[self.CurrentVotedItem][name] = true
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
    for _, name in next, db['VOTE_ROSTER'] do
        if core.onlineInRaid(name) then
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

function TalcFrame:MLToWinner_OnClick()

    -- check if its a tie
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
                            --send -2 to officers
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
        -- no tie, award player
        self:AwardPlayer(self.currentItemWinner, self.CurrentVotedItem)
    end
end

function TalcFrame:MLToEnchanter_OnClick()
    if db['VOTE_ENCHANTER'] == '' then
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

function TalcFrame:Contestant_OnClick(id)

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
        self:RaiderDetailsTab_OnClick(1, _G['TalcVoteFrameContestantFrame' .. id].name);
    end
end

function TalcFrame:Contestant_OnEnter()
    local frame = _G['TalcVoteFrameContestantFrame' .. this:GetID()]
    local r, g, b = frame:GetBackdropColor()
    frame:SetBackdropColor(r, g, b, 1)
end

function TalcFrame:Contestant_OnLeave()
    local frame = _G['TalcVoteFrameContestantFrame' .. this:GetID()]
    local r, g, b = frame:GetBackdropColor()
    frame:SetBackdropColor(r, g, b, 0.5)
end

function TalcFrame:AwardPlayer(playerName, cvi, disenchant)

    if not playerName or playerName == '' then
        talc_error('TalcFrame:AwardPlayer: playerName is nil.')
        return
    end

    local item = self.VotedItemsFrames[cvi].link

    local _, _, _, raid = core.instanceInfo()
    if not raid then
        if db['ITEM_LOCATION_CACHE'][self.VotedItemsFrames[cvi].itemID] then
            raid = db['ITEM_LOCATION_CACHE'][self.VotedItemsFrames[cvi].itemID]
        else
            raid = "Unknown"
        end
    end

    if core.n(self.bagItems) > 0 then
        local _, _, need = TalcFrame:GetPlayerInfo(playerName);

        if disenchant then
            need = "de"
        end

        local shash = core.shash(playerName .. need)

        core.asend("playerWon#"
                .. shash .. "#"
                .. playerName .. "#"
                .. item .. "#"
                .. cvi .. '#'
                .. need .. '#'
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

            local index, _, need = TalcFrame:GetPlayerInfo(GetMasterLootCandidate(unitIndex));

            if disenchant then
                need = "de"
            end

            local shash = core.shash(playerName .. need)

            core.asend("playerWon#"
                    .. shash .. "#"
                    .. GetMasterLootCandidate(unitIndex) .. "#"
                    .. item .. "#"
                    .. cvi .. "#"
                    .. need .. "#"
                    .. raid)

            GiveMasterLoot(index, unitIndex);

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

                if not _G[frame].officerVotedFrames then
                    _G[frame].officerVotedFrames = {}
                end
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
                _G[frame .. 'ReplacesItem3']:SetPoint("TOPLEFT", _G[frame], core.floor(225 * ratio) - 5 + 21 + 21, -2)
                _G[frame .. 'ReplacesItem4']:SetPoint("TOPLEFT", _G[frame], core.floor(225 * ratio) - 5 + 21 + 21 + 21, -2)
                _G[frame .. 'Roll']:SetPoint("LEFT", _G[frame], core.floor(285 * ratio) - 5, 0)
                _G[frame .. 'RollPass']:SetPoint("LEFT", _G[frame], core.floor(285 * ratio), 0)
                _G[frame .. 'RollWinner']:SetPoint("LEFT", _G[frame], core.floor(270 * ratio), -2)
                _G[frame .. 'Votes']:SetPoint("LEFT", _G[frame], core.floor(406 * ratio) - 5, 0)
                _G[frame .. 'VoteButton']:SetPoint("TOPLEFT", _G[frame], core.floor(380 * ratio) - 80, -2)

                _G[frame]:Show()

                local currentItem = {}
                local _, name, need, votes, ci1, ci2, ci3, ci4, roll, _, gearscore, inWishlist = self:GetPlayerInfo(index);
                currentItem[1] = ci1
                currentItem[2] = ci2
                currentItem[3] = ci3
                currentItem[4] = ci4

                _G[frame].name = name;
                _G[frame].need = need;
                _G[frame].gearscore = gearscore;

                local class = core.getPlayerClass(name)
                local color = core.classColors[class]
                _G[frame]:SetBackdropColor(color.r, color.g, color.b, 0.5)

                _G[frame .. 'Name']:SetText(color.colorStr .. name)
                _G[frame .. 'Need']:SetText(core.needs[need].colorStr .. core.needs[need].text)
                _G[frame .. 'Wishlist']:Hide()
                if inWishlist then
                    _G[frame .. 'Wishlist']:Show()
                end
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

                _G[frame .. 'RollWinner']:Hide()
                if self.currentMaxRoll[self.CurrentVotedItem] == roll and roll > 0 then
                    _G[frame .. 'RollWinner']:Show()
                end
                _G[frame .. 'WinnerIcon']:Hide();
                if self.VotedItemsFrames[self.CurrentVotedItem].awardedTo == name then
                    _G[frame .. 'WinnerIcon']:Show()
                end

                for _, f in next, _G[frame].officerVotedFrames do
                    f:Hide()
                end

                if self.itemVotes[self.CurrentVotedItem][name] then
                    local w = 0
                    for voter, vote in next, self.itemVotes[self.CurrentVotedItem][name] do
                        if vote == '+' then
                            w = w + 1

                            if not _G[frame].officerVotedFrames[w] then
                                _G[frame].officerVotedFrames[w] = CreateFrame("Button", "TalcOfficerVotedFrameI" .. self.CurrentVotedItem .. "P" .. index .. "W" .. w, _G[frame], 'Talc_CLVotedButton')
                            end

                            local oFrame = "TalcOfficerVotedFrameI" .. self.CurrentVotedItem .. "P" .. index .. "W" .. w

                            local voterClass = core.getPlayerClass(voter)
                            local locked = self.clDoneVotingItem[voter] and self.clDoneVotingItem[voter][self.CurrentVotedItem]

                            _G[oFrame]:ClearAllPoints()
                            _G[oFrame]:SetSize(20, 20)

                            if w == 1 then
                                _G[oFrame]:SetPoint("LEFT", _G[frame .. 'Votes'], "LEFT", 15, 0)
                            else
                                _G[oFrame]:SetPoint("LEFT", _G["TalcOfficerVotedFrameI" .. self.CurrentVotedItem .. "P" .. index .. "W" .. (w - 1)], "RIGHT", 1, 0)
                            end

                            _G[oFrame]:SetNormalTexture("Interface\\AddOns\\Talc\\images\\classes\\" .. voterClass)
                            _G[oFrame]:SetHighlightTexture("Interface\\AddOns\\Talc\\images\\classes\\" .. voterClass)
                            _G[oFrame]:SetPushedTexture("Interface\\AddOns\\Talc\\images\\classes\\" .. voterClass)
                            _G[oFrame]:Show()
                            _G[oFrame]:SetAlpha(locked and 1 or 0.5)

                            local voterText = voter .. (locked and " |rDONE" or "")

                            _G[oFrame]:SetScript("OnEnter", function(self)
                                GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -(this:GetWidth() / 4), -(this:GetHeight() / 4));
                                GameTooltip:AddLine(core.classColors[voterClass].colorStr .. voterText)
                                GameTooltip:Show();
                            end)

                            _G[oFrame]:SetScript("OnLeave", function(self)
                                GameTooltip:Hide();
                            end)
                        end
                    end
                end

                _G[frame .. 'VoteButton']:SetID(index);

                _G[frame .. 'ClassIcon']:SetTexture('Interface\\AddOns\\Talc\\images\\classes\\' .. class);

                _G[frame .. 'VoteButton']:Show();
                if need == 'pass' or need == 'autopass' then
                    _G[frame .. 'VoteButton']:Hide();
                end

                for i = 1, 4 do
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
        _G['VotedItem' .. index .. 'ButtonCheck']:Hide()
        if self.VotedItemsFrames[index].awardedTo ~= '' then
            _G['VotedItem' .. index .. 'ButtonCheck']:Show()
        end
    end

    self:VoteFrameListUpdate()
end

function TalcFrame:ShowContestantDropdownMenu(id)

    if not core.isRaidLeader() then
        return
    end

    ContestantDropdownMenu.currentContestantId = id

    UIDropDownMenu_Initialize(ContestantDropdownMenu, Talc_BuildContestantDropdownMenu, "MENU");
    ToggleDropDownMenu(1, nil, ContestantDropdownMenu, "cursor", 2, 3);
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
        if core.n(self.bagItems) > 0 then

            core.SetDynTTN(core.n(self.bagItems))
            core.SetDynTTV(core.n(self.bagItems))
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

    if core.n(self.bagItems) > 0 then
        TalcVoteFrameRLExtraFrameDragLoot:SetText("Send " .. core.n(self.bagItems) .. " Item(s)")
    end

    ClearCursor()

end

function TalcFrame:BroadcastLoot_OnClick()

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

    local _, _, itemLink = core.find(link, "(item:%d+:%d+:%d+:%d+)");
    local itemID = core.int(core.split(':', itemLink)[2])

    if not self.VotedItemsFrames[index] then
        self.VotedItemsFrames[index] = CreateFrame("Frame", "VotedItem" .. index,
                TalcVoteFrameVotedItemsFrame, "Talc_VotedItemTemplate")
    end

    local frame = 'VotedItem' .. index

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
        TalcFrame:VotedItemButton_OnClick(index)
    end
end

function TalcFrame:VotedItemButton_OnClick(id)

    TalcVoteFrameMLToWinner:Hide()
    if core.isRaidLeader() then
        TalcVoteFrameMLToWinner:Show()
    end
    if core.canVote() and not core.isRaidLeader() then
        TalcVoteFrameWinnerStatus:Show()
    end

    SetDesaturation(_G['VotedItem' .. id .. 'Button']:GetNormalTexture(), 0)
    for index, _ in next, self.VotedItemsFrames do
        if index ~= id then
            SetDesaturation(_G['VotedItem' .. index .. 'Button']:GetNormalTexture(), 1)
        end
    end
    self:SetCurrentVotedItem(id)
end

function TalcFrame:SetCurrentVotedItem(id)

    self.CurrentVotedItem = id

    TalcVoteFrameCurrentVotedItemButton:Show()
    TalcVoteFrameVotedItemName:Show()

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
    core.addButtonOnEnterTooltip(TalcVoteFrameCurrentVotedItemButton, link, 'playerHistory')

    local _, _, itemLink = core.find(link, "(item:%d+:%d+:%d+:%d+)");
    local itemID = core.split(':', itemLink)
    itemID = core.int(itemID[2])
    local _, _, q, iLevel, _, _, t2, _, equip_slot = GetItemInfo(itemLink)

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
            GameTooltip:SetOwner(TalcNeedFrame, "ANCHOR_NONE");
            GameTooltip:SetHyperlink(itemLink)
            for i = 1, 20 do
                if _G["GameTooltipTextLeft" .. i] and _G["GameTooltipTextLeft" .. i]:GetText() then
                    if core.find(_G["GameTooltipTextLeft" .. i]:GetText(), "Classes:", 1, true) then
                        local _, _, qq, level = GetItemInfo(tokenRewards[itemID].rewards[1])
                        iLevel = level
                        q = qq
                        break
                    end
                end
            end
            GameTooltip:Hide()
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
            self.itemRewardsFrames[1] = CreateFrame("Button", "TALCItemReward1", TalcVoteFrame, 'Talc_CLVotedButton')
        end

        _G["TALCItemReward1"]:SetPoint("TOPLEFT", TalcVoteFrameCurrentVotedItemButton, "BOTTOMRIGHT", 3, 25)

        for i, rewardID in next, tokenRewards[itemID].rewards do
            local _, il, _, _, _, _, _, _, _, tex = GetItemInfo(rewardID)
            if il then

                if not self.itemRewardsFrames[i] then
                    self.itemRewardsFrames[i] = CreateFrame("Button", "TALCItemReward" .. i, TalcVoteFrame, 'Talc_CLVotedButton')
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

                GameTooltip:SetOwner(TalcNeedFrame, "ANCHOR_NONE");
                GameTooltip:SetHyperlink(il)

                for j = 5, 15 do
                    local classFound = false
                    if _G["GameTooltipTextLeft" .. j] and _G["GameTooltipTextLeft" .. j]:GetText() then
                        local itemText = _G["GameTooltipTextLeft" .. j]:GetText()

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

                GameTooltip:Hide()

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

function TalcFrame:DoneVoting_OnClick()
    self.doneVoting[self.CurrentVotedItem] = true
    TalcVoteFrameDoneVoting:Disable();
    TalcVoteFrameDoneVotingCheck:Show();
    core.asend("doneVoting;" .. self.CurrentVotedItem)
    self:VoteFrameListUpdate()
end

function TalcFrame:ChangePlayerPickTo(playerName, newPick, itemIndex)
    for pIndex, data in next, self.playersWhoWantItems do
        if data['itemIndex'] == itemIndex and data['name'] == playerName then
            self.playersWhoWantItems[pIndex]['need'] = newPick
            break
        end
    end
    if core.isRaidLeader() then
        core.asend("changePickTo@" .. playerName .. "@" .. newPick .. "@" .. itemIndex)
    end

    self:VoteFrameListUpdate()
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

                        for index in next, TalcFrame.VotedItemsFrames do
                            local picked = false
                            for _, player in next, TalcFrame.playersWhoWantItems do
                                if player.itemIndex == index and player.name == n then
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
                                    ci4 = '0',
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
            TalcFrame:ShowWindow()
            TalcFrame:ShowScreen("Voting")

            TalcFrame:VoteFrameListUpdate()

            TalcFrame.VoteCountdown:Show()

        end
    end
end)

----------------------------------------------------
--- Raid Leader's Options
----------------------------------------------------

function TalcFrame:ToggleRLOptions_OnClick()

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

function TalcFrame:SetCL_OnClick(id, to)
    if to then
        core.addToRoster(self.assistFrames[id].name, this)
    else
        core.remFromRoster(self.assistFrames[id].name)
    end
end

function TalcFrame:SetAssist_OnClick(id, to)
    for i = 0, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) then
            local n = GetRaidRosterInfo(i);
            if n == self.assistFrames[id].name then
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

function TalcFrame:SyncLootHistory()
    local totalItems = 0
    for _ in next, db['VOTE_LOOT_HISTORY'] do
        totalItems = totalItems + 1
    end

    TalcVoteFrameRLWindowFrameTab2ContentsSyncLootHistory:Disable()
    TalcVoteFrameRLWindowFrameTab2ContentsSyncLootHistory:SetText("Syncing (0%)")

    talc_print('Starting History Sync, ' .. totalItems .. ' entries...')

    core.bsend("BULK", "loot_history_sync;start")

    self.syncLootHistoryCount = 0

    for shash, item in next, db['VOTE_LOOT_HISTORY'] do
        core.bsend("BULK", "loot_history_sync;" .. shash .. ";"
                .. item.timestamp .. ";"
                .. item.player .. ";"
                .. item.class .. ";"
                .. item.item .. ";"
                .. item.pick .. ";"
                .. item.raid)
    end
    core.bsend("BULK", "loot_history_sync;end")
end

TalcFrame.periodicSync = CreateFrame("Frame")
TalcFrame.periodicSync:Hide()
TalcFrame.periodicSync.plus = 0;
TalcFrame.periodicSync:SetScript("OnShow", function()
    this.startTime = GetTime();
    this.index = 1;
    talc_debug('periodic sync started at ' .. this.plus .. 's interval')
end)
TalcFrame.periodicSync:SetScript("OnHide", function()
    talc_debug('periodic sync stopped')
end)
TalcFrame.periodicSync:SetScript("OnUpdate", function()

    if this.plus == 0 then
        this:Hide()
        return
    end

    local gt = GetTime() * 1000
    local st = (this.startTime + this.plus) * 1000
    if gt >= st then

        this.startTime = GetTime();

        if core.n(db['VOTE_LOOT_HISTORY']) == 0 then
            return
        end

        local i = 0
        for shash, item in core.sortedLootHistory() do
            i = i + 1
            if i == this.index then
                core.bsendg("BULK", "periodic_loot_history_sync;" .. shash .. ";"
                        .. item.timestamp .. ";"
                        .. item.player .. ";"
                        .. item.class .. ";"
                        .. item.item .. ";"
                        .. item.pick .. ";"
                        .. item.raid)
            end
        end

        if this.index < core.n(db['VOTE_LOOT_HISTORY']) and this.index < core.periodicSyncMaxItems then
            this.index = this.index + 1
        else
            this.index = 1
        end
    end
end)

function TalcFrame:CheckAssists()

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
            local n, r = GetRaidRosterInfo(i);
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

    for _, frame in next, self.assistFrames do
        frame:Hide()
    end

    TalcVoteFrameRLWindowFrame:SetHeight(110 + core.n(assistsAndCLs) * 25)

    for index, names in next, assistsAndCLs do
        if not self.assistFrames[index] then
            self.assistFrames[index] = CreateFrame('Frame', 'TALCAssistFrame' .. index, TalcVoteFrameRLWindowFrame, 'Talc_CLFrameTemplate')
        end

        local frame = 'TALCAssistFrame' .. index

        _G[frame]:SetPoint("TOPLEFT", TalcVoteFrameRLWindowFrame, "TOPLEFT", 4, -60 - 25 * index - 10)
        _G[frame]:Show()
        _G[frame].name = names.name

        _G[frame .. 'AName']:SetText(core.classColors[core.getPlayerClass(names.name)].colorStr .. names.name)

        _G[frame .. 'StatusIconOnline']:Hide()
        _G[frame .. 'StatusIconOffline']:Hide()

        if core.onlineInRaid(names.name) then
            _G[frame .. 'StatusIconOnline']:Show()
        else
            _G[frame .. 'StatusIconOffline']:Show()
        end

        _G[frame .. 'CLCheck']:SetID(index)
        _G[frame .. 'CLCheck']:SetChecked(names.cl)

        _G[frame .. 'AssistCheck']:SetID(index)
        _G[frame .. 'AssistCheck']:SetChecked(names.assist)

        _G[frame .. 'CLCheck']:Enable()
        if names.name == core.me then
            if _G[frame .. 'CLCheck']:GetChecked() then
                _G[frame .. 'CLCheck']:Disable()
            end
            _G[frame .. 'AssistCheck']:Disable()
        end
    end

    TalcVoteFrameRLWindowFrameTab1ContentsOfficer:SetText('Officer(' .. core.n(db['VOTE_ROSTER']) .. ')')
end

function TalcFrame:SaveLootButton(button, value)
    db['VOTE_CONFIG']['NeedButtons'][button] = value;
end

function TalcFrame:RLFrameChangeTab_OnClick(tab)

    TalcVoteFrameRaiderDetailsFrame:Hide()
    _G['TalcVoteFrameRLWindowFrameTab1Contents']:Hide()
    _G['TalcVoteFrameRLWindowFrameTab2Contents']:Hide()
    --_G['TalcVoteFrameRLWindowFrameTab3Contents']:Hide()

    _G['TalcVoteFrameRLWindowFrameTab' .. tab .. 'Contents']:Show()

    for _, frame in next, self.assistFrames do
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
--- Settings Screen
----------------------------------------------------

function TalcFrame:SettingsFrame_OnShow()

    -- dev
    if not db then
        return
    end

    TalcVoteFrameSettingsFramePurgeLootHistory:SetText('Purge Loot History (' .. core.n(db['VOTE_LOOT_HISTORY']) .. ')');

    if core.n(db['VOTE_LOOT_HISTORY']) > 0 then
        TalcVoteFrameSettingsFramePurgeLootHistory:Enable()
    else
        TalcVoteFrameSettingsFramePurgeLootHistory:Disable()
    end
end

function TalcFrame:PurgeLootHistory_OnClick()
    for shash in next, db['VOTE_LOOT_HISTORY'] do
        db['VOTE_LOOT_HISTORY'][shash] = nil
    end
    talc_print('Loot History purged.')
    TalcVoteFrameSettingsFramePurgeLootHistory:Disable()
    TalcVoteFrameSettingsFramePurgeLootHistory:SetText('Purge Loot History');
end

----------------------------------------------------
--- Welcome Screen
----------------------------------------------------

function TalcFrame:WelcomeFrame_OnShow()
    if GetGuildInfo('player') then
        db['VOTE_ROSTER_GUILD_NAME'] = GetGuildInfo('player')
    end

    if core.canVote() then
        TalcVoteFrameWelcomeFrameLCStatus:SetText("You are part of the " .. ITEM_QUALITY_COLORS[5].hex .. db['VOTE_ROSTER_GUILD_NAME'] .. " |rLoot Council.")
    else
        if GetGuildInfo('player') then
            TalcVoteFrameWelcomeFrameLCStatus:SetText("You are not part of the " .. ITEM_QUALITY_COLORS[5].hex .. db['VOTE_ROSTER_GUILD_NAME'] .. " |rLoot Council.")
        else
            TalcVoteFrameWelcomeFrameLCStatus:SetText("You are not part of a guild.")
        end
    end

    self:ShowWelcomeItems()

    TalcVoteFrameWelcomeFrameOpenWishlist:SetText("Wishlist (" .. core.n(db['NEED_WISHLIST']) .. "/" .. core.numWishlistItems .. ")")

    TalcVoteFrameWelcomeFrameRecentItems:SetText('Recent Items')
    TalcVoteFrameWelcomeFrameBackButton:Hide()
    TalcVoteFrameWelcomeFrameItemsScrollFrame:Show()
    TalcVoteFrameWelcomeFrameItemHistoryScrollFrame:Hide()
    TalcVoteFrameWelcomeFramePlayerHistoryScrollFrame:Hide()

    if db['ATTENDANCE_TRACKING'].enabled then
        if db['ATTENDANCE_TRACKING'].started then
            TalcVoteFrameWelcomeFrameAttendanceStopButton:Show()
            TalcVoteFrameWelcomeFrameAttendanceStartButton:Hide()
        else
            TalcVoteFrameWelcomeFrameAttendanceStopButton:Hide()
            TalcVoteFrameWelcomeFrameAttendanceStartButton:Show()
        end
    else
        TalcVoteFrameWelcomeFrameAttendanceStopButton:Hide()
        TalcVoteFrameWelcomeFrameAttendanceStartButton:Hide()
    end
end

function TalcFrame:ShowWelcomeItems()

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

    for _, item in core.sortedLootHistory() do
        index = index + 1

        local title = false
        if raid ~= (item.raid .. ", " .. (date("%d/%m", item.timestamp) == date("%d/%m", time()) and core.classColors['hunter'].colorStr or '|r') .. date("%d/%m", item.timestamp)) then
            raid = item.raid .. ", " .. (date("%d/%m", item.timestamp) == date("%d/%m", time()) and core.classColors['hunter'].colorStr or '|r') .. date("%d/%m", item.timestamp)
            title = true
            offset = offset + 1
            if col ~= 1 then
                row = row + 1
            end
            col = 1
        end

        if not self.welcomeItemsFrames[index] then
            self.welcomeItemsFrames[index] = CreateFrame('Button', 'WelcomeFrameItem' .. index, TalcVoteFrameWelcomeFrameItemsScrollFrameChild, 'Talc_WelcomeItemTemplate')
        end

        self.welcomeItemsFrames[index]:SetID(index)
        self.welcomeItemsFrames[index].playerName = item.player
        self.welcomeItemsFrames[index].itemName = item.item

        local frame = 'WelcomeFrameItem' .. index
        _G[frame]:SetPoint('TOPLEFT', 'TalcVoteFrameWelcomeFrameItemsScrollFrameChild', 'TOPLEFT', -180 + 185 * col, 54 - 44 * row - (offset * 30))

        _G[frame .. 'RaidTitle']:Hide()
        if title then
            _G[frame .. 'RaidTitle']:SetText(raid)
            _G[frame .. 'RaidTitle']:Show()
        end

        _G[frame .. 'TopText']:SetText(item.item)
        _G[frame .. 'MiddleText']:SetText(core.needs[item.pick].colorStr .. core.needs[item.pick].text)
        _G[frame .. 'BottomText']:SetText(core.classColors[item.class].colorStr .. item.player)

        local _, _, q, _, _, _, _, _, _, tex = GetItemInfo(item.item)
        _G[frame .. 'Icon']:SetTexture(tex)

        _G[frame .. 'Border']:Hide()
        if item.player == core.me then
            local color = ITEM_QUALITY_COLORS[q]
            _G[frame .. 'Border']:SetVertexColor(color.r, color.g, color.b, 1)
            _G[frame .. 'Border']:Show()
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

function TalcFrame:WelcomeItem_OnClick(id)

    TalcFrame.itemHistoryIndex = id

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

    TalcVoteFrameWelcomeFrameRecentItems:SetText('  ' .. self.welcomeItemsFrames[id].itemName .. ' History (' .. core.n(itemHistory) .. ')')

    for _, frame in next, self.itemHistoryFrames do
        frame:Hide()
    end

    for index, item in core.sortTableBy(itemHistory, 'timestamp') do

        if not self.itemHistoryFrames[index] then
            self.itemHistoryFrames[index] = CreateFrame('Button', 'ItemHistoryPlayerFrame' .. index, TalcVoteFrameWelcomeFrameItemHistoryScrollFrameChild, 'Talc_WelcomePlayerTemplate')
        end
        local frame = 'ItemHistoryPlayerFrame' .. index

        _G[frame]:SetPoint('TOPLEFT', 'TalcVoteFrameWelcomeFrameItemHistoryScrollFrameChild', 'TOPLEFT', 0, 26 - 26 * index)
        _G[frame .. 'Name']:SetText(core.classColors[item.class].colorStr .. item.player)
        _G[frame .. 'Pick']:SetText(core.needs[item.pick].colorStr .. core.needs[item.pick].text)
        _G[frame .. 'Date']:SetText((date("%d/%m", item.timestamp) == date("%d/%m", time()) and core.classColors['hunter'].colorStr or '|r') .. date("%d/%m", item.timestamp))

        _G[frame .. 'Icon']:SetTexture("Interface\\AddOns\\Talc\\images\\classes\\" .. item.class)

        _G[frame].name = item.player

        _G[frame]:Show()

        if index == core.maxItemHistoryPlayers then
            break
        end
    end

    TalcVoteFrameWelcomeFrameItemsScrollFrame:SetVerticalScroll(0)
end

function TalcFrame:WelcomePlayer_OnClick(name)

    TalcVoteFrameWelcomeFrameBackButton:Show()
    TalcVoteFrameWelcomeFrameItemsScrollFrame:Hide()
    TalcVoteFrameWelcomeFrameItemHistoryScrollFrame:Hide()
    TalcVoteFrameWelcomeFramePlayerHistoryScrollFrame:Show()
    TalcVoteFrameWelcomeFramePlayerHistoryScrollFrame.name = name

    local playerHistory = {}
    for _, item in next, db['VOTE_LOOT_HISTORY'] do
        if item.player == name then
            core.insert(playerHistory, item)
        end
    end

    if core.sub(name, core.len(name), core.len(name)) == 's' then
        TalcVoteFrameWelcomeFrameRecentItems:SetText('  ' .. name .. '\' Loot History (' .. core.n(playerHistory) .. ')')
    else
        TalcVoteFrameWelcomeFrameRecentItems:SetText('  ' .. name .. '\'s Loot History (' .. core.n(playerHistory) .. ')')
    end

    for _, frame in next, self.playerHistoryFrames do
        frame:Hide()
    end

    local x = TalcVoteFrameWelcomeFrame:GetWidth()
    local numCols = core.floor(x / 185)
    local col, row = 1, 1
    local raid = ''
    local offset = 0

    for index, item in core.sortTableBy(playerHistory, 'timestamp') do

        local title = false
        if raid ~= (item.raid .. ", " .. (date("%d/%m", item.timestamp) == date("%d/%m", time()) and core.classColors['hunter'].colorStr or '|r') .. date("%d/%m", timestamp)) then
            raid = item.raid .. ", " .. (date("%d/%m", item.timestamp) == date("%d/%m", time()) and core.classColors['hunter'].colorStr or '|r') .. date("%d/%m", timestamp)
            title = true
            offset = offset + 1
            if col ~= 1 then
                row = row + 1
            end
            col = 1
        end

        if not self.playerHistoryFrames[index] then
            self.playerHistoryFrames[index] = CreateFrame('Button', 'PlayerHistoryFrame' .. index, TalcVoteFrameWelcomeFramePlayerHistoryScrollFrameChild, 'Talc_WelcomeItemTemplate')
        end

        local frame = 'PlayerHistoryFrame' .. index

        _G[frame]:SetPoint('TOPLEFT', 'TalcVoteFrameWelcomeFramePlayerHistoryScrollFrameChild', 'TOPLEFT', -180 + 185 * col, 54 - 44 * row - (offset * 30))
        _G[frame]:SetID(index)

        _G[frame .. 'RaidTitle']:Hide()
        if title then
            _G[frame .. 'RaidTitle']:SetText(raid)
            _G[frame .. 'RaidTitle']:Show()
        end

        _G[frame .. 'TopText']:SetText(item.item)
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

    TalcVoteFrameWelcomeFrameItemsScrollFrame:SetVerticalScroll(0)
end

function TalcFrame:WelcomeFrameBackButton_OnClick()
    if TalcVoteFrameWelcomeFrameItemHistoryScrollFrame:IsVisible() then
        TalcFrame:WelcomeFrame_OnShow()
    end
    if TalcVoteFrameWelcomeFramePlayerHistoryScrollFrame:IsVisible() then
        TalcFrame:WelcomeItem_OnClick(self.itemHistoryIndex)
    end
end

----------------------------------------------------
--- Wishlist Screen
----------------------------------------------------

function TalcFrame:WishlistFrame_OnShow()
    self:WishlistUpdate()
end

TalcFrame.delayAddToWishlist = CreateFrame("Frame")
TalcFrame.delayAddToWishlist:Hide()
TalcFrame.delayAddToWishlist.id = 0
TalcFrame.delayAddToWishlist:SetScript("OnShow", function()
    this.startTime = GetTime();
end)
TalcFrame.delayAddToWishlist:SetScript("OnUpdate", function()
    local plus = 1
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        TalcFrame:TryToAddToWishlist_OnClick(this.item)
        this:Hide()
    end
end)

function TalcFrame:TryToAddToWishlist_OnClick(nameOrID)

    nameOrID = core.trim(nameOrID)

    -- empty query or wishlist full
    if core.len(nameOrID) == 0 or nameOrId == 0 or core.n(db['NEED_WISHLIST']) == core.numWishlistItems then
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
            core.cacheItem(nameOrID)
            self.delayAddToWishlist.id = nameOrID
            self.delayAddToWishlist:Show()
            return
        end

        -- text, not url, go search in atlas, if available
        if IsAddOnLoaded("AtlasLoot") and AtlasLoot_Data then
            AtlasLoot_LoadAllModules();

            nameOrID = core.lower(nameOrID);
            local results = {};
            local maxCols = core.floor((TalcVoteFrame:GetWidth() - 10) / 345)
            local maxRows = core.floor((TalcVoteFrame:GetHeight() - 180) / 30)
            local maxResults = maxCols * maxRows
            local col, row = 1, 1

            for _, data in core.pairs(AtlasLoot_Data) do
                for _, v in core.ipairs(data) do
                    if core.type(v[2]) == "number" and v[2] > 0 then
                        local itemName = GetItemInfo(v[2]);
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
                                core.cacheItem(v[2])
                                core.insert(results, { id = v[2], name = itemName });
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
                        self.wishlistSearchItemsFrames[index] = CreateFrame("Frame", "TalcWishlistSearchItem" .. index, TalcVoteFrameWishlistFrame, "Talc_WishlistItemTemplate")
                    end

                    local frame = "TalcWishlistSearchItem" .. index

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

function TalcFrame:WishlistFrameResultsBackButton_OnClick()
    TalcVoteFrameWishlistFrameResultsBack:Hide()
    self:WishlistUpdate()
end

function TalcFrame:AddToWishlist(itemLink, direct)

    if direct then

        for _, item in next, db['NEED_WISHLIST'] do

            local found, _, link = core.find(itemLink, "(item:%d+:%d+:%d+:%d+)");
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

function TalcFrame:RemoveFromWishlist_OnClick(id)
    if id == core.n(db['NEED_WISHLIST']) then
        db['NEED_WISHLIST'][id] = nil
    else
        for i = id, core.n(db['NEED_WISHLIST']) - 1 do
            db['NEED_WISHLIST'][i] = db['NEED_WISHLIST'][i + 1]
        end
        db['NEED_WISHLIST'][core.n(db['NEED_WISHLIST'])] = nil
    end
    TalcFrame:WishlistUpdate()
end

function TalcFrame:WishlistUpdate()

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
            self.wishlistItemsFrames[index] = CreateFrame("Frame", "TalcWishlistItem" .. index, TalcVoteFrameWishlistFrame, "Talc_WishlistItemTemplate")
        end

        local frame = "TalcWishlistItem" .. index

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

        local _, _, q, iLevel, _, _, t2, _, equip_slot, tex = GetItemInfo(itemLink)
        if tex then
            _G[frame .. 'ItemButtonIcon']:SetTexture(tex)
            core.addButtonOnEnterTooltip(_G[frame .. 'ItemButton'], itemLink, nil, true)
        end

        _G[frame]:Show()

    end
end

----------------------------------------------------
--- Attendance
----------------------------------------------------

function Talc_AttendanceQueryWindow_OnUpdate()
    if GetTime() * 1000 >= (this.startTime + 1) * 1000 then
        if this.timeout > 0 then
            this.startTime = GetTime();
            this.timeout = this.timeout - 1
            _G[this:GetName() .. "No"]:SetText("No (" .. this.timeout .. ")")
        else
            this:Hide()
        end
    end
end

TalcFrame.AttendanceTracker = CreateFrame("Frame")
TalcFrame.AttendanceTracker:Hide()
TalcFrame.AttendanceTracker:SetScript("OnShow", function()
    this.startTime = GetTime();
    talc_print("Attendance tracker started.")
    db['ATTENDANCE_TRACKING'].started = true
end)
TalcFrame.AttendanceTracker:SetScript("OnHide", function()
    talc_print("Attendance tracker stopped.")
    db['ATTENDANCE_TRACKING'].started = false
end)
TalcFrame.AttendanceTracker:SetScript("OnUpdate", function()
    local plus = 3 --db['ATTENDANCE_TRACKING'].period
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime();
        core.saveAttendance()
    end
end)

function TalcFrame.AttendanceTracker:Start()
    if not TalcFrame.AttendanceTracker:IsVisible() then
        TalcFrame.AttendanceTracker:Show()
    end
    if TalcVoteFrameWelcomeFrame:IsVisible() then
        TalcFrame:WelcomeFrame_OnShow()
    end
end

function TalcFrame.AttendanceTracker:Stop()
    talc_debug("stop pressed")
    TalcFrame.AttendanceTracker:Hide()
    if TalcVoteFrameWelcomeFrame:IsVisible() then
        TalcFrame:WelcomeFrame_OnShow()
    end
end

----------------------------------------------------
--- Who Query
----------------------------------------------------

function TalcFrame:QueryWho_OnClick()

    if not UnitInRaid('player') then
        talc_print('You are not in a raid.')
        return
    end

    TalcVoteFrameWho:Show()

    core.asend("versionQuery=")

    self.withAddon = {}
    self.withAddonFrames = {}

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

function TalcFrame:AnnounceWithoutAddon_OnClick()
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

function TalcFrame:AnnounceOlderAddon_OnClick()
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

    self.withAddonFrames = {}

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

function TalcFrame:SaveSetting(key, value)

    if core.type(key) == 'table' then
        db[key[1]][key[2]] = value == 1
        if key[1] == 'ATTENDANCE_TRACKING' and key[2] == 'enabled' then
            if db[key[1]][key[2]] then
                TalcVoteFrameSettingsFrameAttendanceBossKills:Enable()
                TalcVoteFrameSettingsFrameAttendanceTime:Enable()
            else
                TalcVoteFrameSettingsFrameAttendanceBossKills:Disable()
                TalcVoteFrameSettingsFrameAttendanceTime:Disable()
            end
        end
        return
    end

    if key == 'WIN_ENABLE_SOUND' then
        if value then
            TalcVoteFrameSettingsFrameWinSoundHigh:Enable()
            PlaySoundFile("Interface\\AddOns\\Talc\\sound\\win_" .. db['WIN_VOLUME'] .. ".ogg");
        else
            TalcVoteFrameSettingsFrameWinSoundHigh:Disable()
        end
    elseif key == 'WIN_VOLUME' then
        if db['WIN_ENABLE_SOUND'] then
            PlaySoundFile("Interface\\AddOns\\Talc\\sound\\win_" .. value .. ".ogg");
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
            TalcVoteFrameSettingsFrameRollTrombone:Enable()
        else
            TalcVoteFrameSettingsFrameRollSoundHigh:Disable()
            TalcVoteFrameSettingsFrameRollTrombone:Disable()
        end
        if value then
            PlaySoundFile("Interface\\AddOns\\Talc\\sound\\please_roll_" .. db['ROLL_VOLUME'] .. ".ogg");
        end
    elseif key == 'ROLL_VOLUME' then
        if db['ROLL_ENABLE_SOUND'] then
            PlaySoundFile("Interface\\AddOns\\Talc\\sound\\please_roll_" .. value .. ".ogg");
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
    end

    db[key] = value == 1;
end

function TalcFrame:Resizing()
    --TalcVoteFrame:SetAlpha(0.8)
    TalcVoteFrameTimeLeftBarBG:ClearAllPoints()
    TalcVoteFrameTimeLeftBarBG:SetPoint('BOTTOMLEFT', TalcVoteFrame, "BOTTOMLEFT", 4, 4)
    TalcVoteFrameTimeLeftBarBG:SetPoint('BOTTOMRIGHT', TalcVoteFrame, "BOTTOMRIGHT", -4, 28)
end

function TalcFrame:Resized()

    TalcVoteFrameTimeLeftBarBG:ClearAllPoints()
    TalcVoteFrameTimeLeftBarBG:SetPoint('BOTTOMRIGHT', TalcVoteFrame, "BOTTOMRIGHT", -4, 4)

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
        TalcFrame:WelcomePlayer_OnClick(TalcVoteFrameWelcomeFramePlayerHistoryScrollFrame.name)
    end
end

function TalcFrame:ShowScreen(screen)
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

function TalcFrame:SetTitle(to)
    if not to then
        TalcVoteFrameTitle:SetText('|cfffff569T|rhunder |cfffff569A|rle Brewing Co |cfffff569L|root |cfffff569C|rouncil v' .. core.addonVer)
    else
        TalcVoteFrameTitle:SetText('|cfffff569T|rhunder |cfffff569A|rle Brewing Co |cfffff569L|root |cfffff569C|rouncil v' .. core.addonVer .. ' - ' .. to)
    end
end

function TalcFrame:GetPlayerInfo(playerIndexOrName)
    --returns itemIndex, name, need, votes, ci1, ci2, ci3, ci4, roll, k, gearscore, inWishlist
    if core.type(playerIndexOrName) == 'string' then
        for k, player in next, self.currentPlayersList do
            if player.name == playerIndexOrName then
                return player.itemIndex, player.name, player.need, player.votes, player.ci1, player.ci2, player.ci3, player.ci4, player.roll, k, player.gearscore, player.inWishlist
            end
        end
    end
    local player = self.currentPlayersList[playerIndexOrName]
    if player then
        return player.itemIndex, player.name, player.need, player.votes, player.ci1, player.ci2, player.ci3, player.ci4, player.roll, playerIndexOrName, player.gearscore, player.inWishlist
    else
        return false
    end
end

function TalcFrame:SaveItemLocation(lootText)

    local _, _, _, raidString = core.instanceInfo()
    if not raidString then
        return
    end

    local _, _, itemLink = core.find(lootText, "(item:%d+:%d+:%d+:%d+)");
    if itemLink then

        local _, _, q = GetItemInfo(itemLink)

        if q and q >= 3 then
            local itemID = core.int(core.split(':', itemLink)[2])
            db['ITEM_LOCATION_CACHE'][itemID] = raidString
            talc_debug("saved " .. itemID .. " to " .. raidString)
        end
    end

end

function TalcFrame:SendTestItems_OnClick()

    local testItem1 = "\124cffa335ee\124Hitem:40610:0:0:0:0:0:0:0:0\124h[Chestguard of the Lost Conqueror]\124h\124r";
    local testItem2 = "\124cffa335ee\124Hitem:46052:0:0:0:0:0:0:0:0\124h[Reply-Code Alpha]\124h\124r"
    local testItem3 = "\124cffa335ee\124Hitem:40614:0:0:0:0:0:0:0:0\124h[Gloves of the Lost Protector]\124h\124r"

    local _, _, itemLink1 = core.find(testItem1, "(item:%d+:%d+:%d+:%d+)");
    local lootName1, _, quality1, _, _, _, _, _, _, lootIcon1 = GetItemInfo(itemLink1)

    local _, _, itemLink2 = core.find(testItem2, "(item:%d+:%d+:%d+:%d+)");
    local lootName2, _, quality2, _, _, _, _, _, _, lootIcon2 = GetItemInfo(itemLink2)

    local _, _, itemLink3 = core.find(testItem3, "(item:%d+:%d+:%d+:%d+)");
    local lootName3, _, quality3, _, _, _, _, _, _, lootIcon3 = GetItemInfo(itemLink3)

    SendChatMessage('This is a test, click whatever you want!', "RAID_WARNING")
    TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()

    core.SetDynTTN(3)
    core.SetDynTTV(3)
    self.LootCountdown.countDownFrom = db['VOTE_TTN']

    self:SendTimersAndButtons()

    self:SendReset()

    self.LootCountdown:Show()
    core.asend('countdownframe=show')

    core.bsend("ALERT", "preloadInVoteFrame=1=" .. lootIcon1 .. "=" .. lootName1 .. "=" .. testItem1)
    core.bsend("ALERT", "preloadInVoteFrame=2=" .. lootIcon2 .. "=" .. lootName2 .. "=" .. testItem2)
    core.bsend("ALERT", "preloadInVoteFrame=3=" .. lootIcon3 .. "=" .. lootName3 .. "=" .. testItem3)

    core.bsend("ALERT", "loot=1=" .. lootIcon1 .. "=" .. lootName1 .. "=" .. testItem1)
    core.bsend("ALERT", "loot=2=" .. lootIcon2 .. "=" .. lootName2 .. "=" .. testItem2)
    core.bsend("ALERT", "loot=3=" .. lootIcon3 .. "=" .. lootName3 .. "=" .. testItem3)
    core.bsend("ALERT", "doneSending=3=items")

    TalcVoteFrameMLToWinner:Disable()
end

--[[
PlaySound("igQuestListOpen");
PlaySound("igQuestListClose");

PlaySound("igMainMenuOptionCheckBoxOn");
PlaySound("igMainMenuOptionCheckBoxOff");

PlaySound("igCharacterInfoTab");
PlaySound("igMainMenuClose");
]]--