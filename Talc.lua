TALC = CreateFrame("Frame")

TALC.channel = 'TALC'
TALC.addonVer = '3.0.0.0'
TALC.me = UnitName('player')

local core, db
local init = false

TALC:SetScript("OnEvent", function(__, event, ...)
    if event then

        if event == "ADDON_LOADED" and arg1 == "Blizzard_TimeManager" then

            TALC:UnregisterEvent("ADDON_LOADED")

            if not TALC_DB then
                TALC_DB = {}
            end
            if not TALC_DB['_DEBUG'] then
                TALC_DB['_DEBUG'] = false
            end

            if not TALC_DB['WIN_THRESHOLD'] then
                TALC_DB['WIN_THRESHOLD'] = 3
            end
            if not TALC_DB['WIN_ENABLE_SOUND'] then
                TALC_DB['WIN_ENABLE_SOUND'] = true
            end
            if not TALC_DB['WIN_VOLUME'] then
                TALC_DB['WIN_VOLUME'] = 'high'
            end

            if not TALC_DB['ROLL_ENABLE_SOUND'] then
                TALC_DB['ROLL_ENABLE_SOUND'] = true
            end
            if not TALC_DB['ROLL_VOLUME'] then
                TALC_DB['ROLL_VOLUME'] = 'high'
            end
            if not TALC_DB['ROLL_TROMBONE'] then
                TALC_DB['ROLL_TROMBONE'] = 'true'
            end

            if not TALC_DB['NEED_SCALE'] then
                TALC_DB['NEED_SCALE'] = 1
            end

            if not TALC_DB['PULL'] then
                TALC_DB['PULL'] = true
            end
            if not TALC_DB['PULL_SOUND'] then
                TALC_DB['PULL_SOUND'] = true
            end

            if not TALC_DB['BOSS_FRAME'] then
                TALC_DB['BOSS_FRAME'] = true
            end

            if not TALC_DB['VOTE_ROSTER'] then
                TALC_DB['VOTE_ROSTER'] = {}
            end
            if not TALC_DB['VOTE_LOOT_HISTORY'] then
                TALC_DB['VOTE_LOOT_HISTORY'] = {}
            end
            if not TALC_DB['VOTE_TTN'] then
                TALC_DB['VOTE_TTN'] = 30
            end
            if not TALC_DB['VOTE_TTV'] then
                TALC_DB['VOTE_TTV'] = 30
            end
            if not TALC_DB['VOTE_TTR'] then
                TALC_DB['VOTE_TTR'] = 30
            end
            if not TALC_DB['VOTE_ENABLED'] then
                TALC_DB['VOTE_ENABLED'] = true
            end
            if not TALC_DB['VOTE_SCALE'] then
                TALC_DB['VOTE_SCALE'] = 1
            end
            if not TALC_DB['VOTE_ALPHA'] then
                TALC_DB['VOTE_ALPHA'] = 1
            end
            if not TALC_DB['VOTE_AUTO_ASSIST'] then
                TALC_DB['VOTE_AUTO_ASSIST'] = false
            end
            if not TALC_DB['VOTE_DESENCHANTER'] then
                TALC_DB['VOTE_DESENCHANTER'] = ''
            end

            if not TALC_DB['VOTE_CONFIG'] then
                TALC_DB['VOTE_CONFIG'] = {
                    ['AutoML'] = false,
                    ['AutoMLItems'] = {},
                    ['NeedButtons'] = {
                        ['BIS'] = false,
                        ['MS'] = true,
                        ['OS'] = true,
                        ['XMOG'] = false
                    }
                }
            end

            Talc_Utils.init();
            TalcFrame:init();

            NeedFrame.init();
            WinFrame:init();
            RollFrame:init();
            BossFrame:init();

            core = TALC
            db = TALC_DB

            print("TALC INIt")

            init = true
        end

        if init then

            if event == 'CHAT_MSG_ADDON' and arg1 == TALC.channel then
                TalcFrame:handleSync(arg1, arg2, arg3, arg4)
                NeedFrameComs:handleSync(arg1, arg2, arg3, arg4)
                WinFrame:handleSync(arg1, arg2, arg3, arg4)
            end

            if event == "RAID_ROSTER_UPDATE" then
                if core.isRL(core.me) then

                    if db['VOTE_AUTO_ASSIST'] then
                        for i = 0, GetNumRaidMembers() do
                            if GetRaidRosterInfo(i) then
                                local n, r = GetRaidRosterInfo(i);
                                if core.isCL(n) and r == 0 and n ~= core.me then
                                    LCVoteFrame.assistTriggers = LCVoteFrame.assistTriggers + 1
                                    PromoteToAssistant(n)
                                    talc_print(n .. ' |cff69ccf0autopromoted|cffffffff(' .. LCVoteFrame.assistTriggers .. '/100). Type |cff69ccf0/talc autoassist |cffffffffto disable this feature.')

                                    if LCVoteFrame.assistTriggers > 100 then
                                        talc_error('Autoassist trigger error (>100). Autoassist disabled.')
                                        db['VOTE_AUTO_ASSIST'] = false
                                    end

                                    return false
                                end
                            end
                        end
                    end
                    TalcVoteFrameRLExtraFrameRLOptionsButton:Show()
                    TalcVoteFrameRLExtraFrame:Show()
                    TalcVoteFrameMLToWinner:Show()
                    TalcVoteFrameRLExtraFrameResetClose:Show()
                    TalcFrame.RLFrame:CheckAssists()
                else
                    TalcVoteFrameMLToWinner:Hide()
                    TalcVoteFrameRLExtraFrame:Hide()
                    TalcVoteFrameRLOptionsButton:Hide()
                    TalcVoteFrameRLWindowFrame:Hide()
                    TalcVoteFrameRLExtraFrameResetClose:Hide()
                end
                if not core.canVote(core.me) then
                    TalcVoteFrame:Hide()
                end
            end

            if event == "CHAT_MSG_SYSTEM" then

                RollFrame:handleSystem(arg1)

                if (core.find(arg1, "The following players are AFK", 1, true) or
                        core.find(arg1, "No players are AFK", 1, true) or
                        core.find(arg1, "is not ready", 1, true)) and core.isRL(core.me) then
                    SendChatMessage(arg1, "RAID")
                end
                if core.find(arg1, "rolls", 1, true) and core.find(arg1, "(1-100)", 1, true) then
                    local r = core.explode(arg1, " ")

                    if not r[2] or not r[3] then
                        talc_error('bad roll syntax')
                        talc_error(arg1)
                        return false
                    end

                    local name = r[1]
                    local roll = core.int(r[3])

                    --check if name is in playersWhoWantItems with vote == -2
                    for pwIndex, pwPlayer in next, LCVoteFrame.playersWhoWantItems do
                        if (pwPlayer['name'] == name and pwPlayer['roll'] == -2) then
                            LCVoteFrame.playersWhoWantItems[pwIndex]['roll'] = roll
                            core.asend("playerRoll:" .. pwIndex .. ":" .. roll .. ":" .. LCVoteFrame.CurrentVotedItem)
                            VoteFrameListScroll_Update()
                            break
                        end
                    end
                end
            end
            if event == "LOOT_OPENED" then
                LCVoteFrame.LOOT_OPENED = true
                if not db['VOTE_ENABLED'] then
                    return
                end
                if core.isRL(core.me) then

                    local lootMethod = GetLootMethod()
                    if lootMethod == 'master' then

                        local blueOrEpic = false

                        db['VOTE_TTN'] = core.SetDynTTN(GetNumLootItems())

                        for id = 0, GetNumLootItems() do
                            if GetLootSlotInfo(id) and GetLootSlotLink(id) then
                                local _, lootName = GetLootSlotInfo(id)

                                local _, _, itemLink = core.find(GetLootSlotLink(id), "(item:%d+:%d+:%d+:%d+)");
                                local _, _, quality = GetItemInfo(itemLink)
                                if quality >= 3 and lootName ~= 'Elementium Ore' and lootName ~= 'Nexus Crystal' then

                                    if lootName ~= 'Alabaster Idol' and
                                            lootName ~= 'Jasper Idol' and
                                            lootName ~= 'Word of Thawing' then

                                        blueOrEpic = true

                                    end
                                end
                                --auto ML sand
                                --if lootName == 'Hourglass Sand' then
                                --    local collectorIndex = -1
                                --    for j = 1, 40 do
                                --        if GetMasterLootCandidate(j) == TWLC_SAND_COLLECTOR then
                                --            talc_debug('found: sand candidate' .. GetMasterLootCandidate(j) .. ' ==  ' .. TWLC_SAND_COLLECTOR)
                                --            collectorIndex = j
                                --            break
                                --        end
                                --    end
                                --    if collectorIndex ~= -1 then
                                --        GiveMasterLoot(id, collectorIndex)
                                --    else
                                --        twprint('Sand collector ' .. TWLC_SAND_COLLECTOR .. ' not in raid and auto ml sand is ON. Ignoring.')
                                --    end
                                --end
                            end
                        end

                        if not blueOrEpic then
                            return false
                        end

                        TalcVoteFrameRLExtraFrameBroadcastLoot:Enable()
                        TalcVoteFrameRLExtraFrameBroadcastLoot:SetText('Prepare Broadcast')
                        LCVoteFrame.sentReset = false
                        if core.me ~= 'Er' then
                            -- dont show for me, ill show it from erui addon
                            LootLCVoteFrameWindow:Show()
                        end

                        --pre send items for never seen
                        for id = 0, GetNumLootItems() do
                            if GetLootSlotInfo(id) and GetLootSlotLink(id) then
                                local lootIcon, lootName = GetLootSlotInfo(id)

                                local _, _, itemLink = core.find(GetLootSlotLink(id), "(item:%d+:%d+:%d+:%d+)");
                                local itemID, _, quality = GetItemInfo(itemLink)
                                if quality >= 3 then

                                    if not LCVoteFrame.itemsToPreSend[itemID] then
                                        LCVoteFrame.itemsToPreSend[itemID] = true

                                        --send to all
                                        core.asend("preSend=" .. id .. "=" .. lootIcon .. "=" .. lootName .. "=" .. GetLootSlotLink(id))
                                    end
                                end
                            end
                        end

                    else
                        TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()
                    end
                end
            end
            if event == "LOOT_SLOT_CLEARED" then
            end
            if event == "LOOT_CLOSED" then
                LCVoteFrame.LOOT_OPENED = false
                TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()
            end

            if event == "COMBAT_LOG_EVENT" then
                if arg2 == 'UNIT_DIED' then
                    for _, boss in next, BossFrame.Bosses do
                        if arg7 == boss and db['BOSS_FRAME'] then
                            BossFrame:StartBossAnimation(boss)
                            return true
                        end
                    end

                end
            end

            if event == 'PLAYER_TARGET_CHANGED' then
                local master = 'Er'
                if core.me == master then
                    return false
                end
                if not UnitExists('target') or UnitAffectingCombat('player') then
                    return
                end
                if UnitName('target') == master and CheckInteractDistance("target", 3) then
                    PlaySoundFile("Sound\\Character\\Dwarf\\DwarfVocalFemale\\DwarfFemaleHello0" .. math.random(1, 3) .. ".wav", "Dialog")
                end
            end

            if event == 'CHAT_MSG_LOOT' then
                WinFrame:handleLoot(arg1)
            end
        end


    end
end)

TALC:RegisterEvent("ADDON_LOADED")
TALC:RegisterEvent("LOOT_OPENED")
TALC:RegisterEvent("LOOT_SLOT_CLEARED")
TALC:RegisterEvent("LOOT_CLOSED")
TALC:RegisterEvent("RAID_ROSTER_UPDATE")
TALC:RegisterEvent("CHAT_MSG_SYSTEM")
TALC:RegisterEvent("PLAYER_TARGET_CHANGED") --for bosses
TALC:RegisterEvent("CHAT_MSG_ADDON")
TALC:RegisterEvent("CHAT_MSG_LOOT")
TALC:RegisterEvent("COMBAT_LOG_EVENT")

SLASH_TALC1 = "/talc"
SlashCmdList["TALC"] = function(cmd)
    if cmd then
        if core.sub(cmd, 1, 3) == 'add' then
            local setEx = core.explode(cmd, ' ')
            if setEx[2] then
                addToRoster(setEx[2])
            else
                talc_print('Adds LC member')
                talc_print('syntax: /talc add <name>')
            end
        end
        if core.sub(cmd, 1, 3) == 'rem' then
            local setEx = core.explode(cmd, ' ')
            if setEx[2] then
                remFromRoster(setEx[2])
            else
                talc_print('Removes LC member')
                talc_print('syntax: /talc rem <name>')
            end
        end
        if core.sub(cmd, 1, 3) == 'set' then
            local setEx = core.explode(cmd, ' ')
            if setEx[2] and setEx[3] then
                if core.isRL(core.me) then
                    if setEx[2] == 'disenchanter' or setEx[2] == 'enchanter' then
                        if setEx[3] == '' or core.int(setEx[3]) then
                            talc_print('Incorrect syntax. Use /talc set disenchanter/enchanter [name]')
                            return false
                        end
                        db['VOTE_DESENCHANTER'] = setEx[3]
                        local deClassColor = core.classColors[getPlayerClass(db['VOTE_DESENCHANTER'])].colorStr
                        talc_print('VOTE_DESENCHANTER - set to ' .. deClassColor .. db['VOTE_DESENCHANTER'])
                        TalcVoteFrameMLToEnchanter:Show()

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
                    end
                    if setEx[2] == 'ttr' then
                        if setEx[3] == '' or not core.int(setEx[3]) then
                            talc_print('Incorrect syntax. Use /talc set ttr [time in seconds]')
                            return false
                        end
                        db['VOTE_TTR'] = core.int(setEx[3])
                        talc_print('VOTE_TTR - set to ' .. db['VOTE_TTR'] .. 's')
                        core.asend('ttr=' .. db['VOTE_TTR'])
                    end
                else
                    talc_print('You are not the raid leader.')
                end
            else
                talc_print('SET Options')
                talc_print('/talc set ttr <time> - sets VOTE_TTR (current value: ' .. db['VOTE_TTR'] .. 's)')
                talc_print('/talc set enchanter/disenchanter <name> - sets VOTE_DESENCHANTER (current value: ' .. db['VOTE_DESENCHANTER'] .. ')')
            end
        end
        if cmd == 'debug' then
            db['_DEBUG'] = not db['_DEBUG']
            if db['_DEBUG'] then
                talc_print('Debug ENABLED')
            else
                talc_print('Debug DISABLED')
            end
        end
        if cmd == 'autoassist' then
            db['VOTE_AUTO_ASSIST'] = not db['VOTE_AUTO_ASSIST']
            if db['VOTE_AUTO_ASSIST'] then
                talc_print('AutoAssist ENABLED')
                LCVoteFrame.assistTriggers = 0
            else
                talc_print('AutoAssist DISABLED')
            end
        end
        if cmd == 'who' then
            RefreshWho_OnClick()
        end
        if cmd == 'synchistory' then
            if not core.isRL(core.me) then
                return
            end
            Talc_SyncLootHistory()
        end
        if cmd == 'clearhistory' then
            db['VOTE_LOOT_HISTORY'] = {}
            talc_print('Loot History cleared.')
        end
        if core.sub(cmd, 1, 6) == 'search' then
            local cmdEx = core.explode(cmd, ' ')

            if cmdEx[2] then

                local numItems = 0
                for _, item in core.pairsByKeysReverse(db['VOTE_LOOT_HISTORY']) do
                    if core.lower(cmdEx[2]) == core.lower(item['player']) then
                        numItems = numItems + 1
                    end
                end

                if numItems > 0 then
                    talc_print('Listing ' .. cmdEx[2] .. '\'s loot history:')
                    for lootTime, item in core.pairsByKeysReverse(db['VOTE_LOOT_HISTORY']) do
                        if core.lower(cmdEx[2]) == core.lower(item['player']) then
                            talc_print(item['item'] .. ' - ' .. date("%d/%m", lootTime))
                        end
                    end
                else
                    talc_print('- no recorded items -')
                end

                for lootTime, item in core.pairsByKeysReverse(db['VOTE_LOOT_HISTORY']) do
                    if core.find(core.lower(item['item']), core.lower(cmdEx[2])) then
                        talc_print(item['player'] .. " - " .. item['item'] .. " " .. date("%d/%m", lootTime))
                    end
                end

                if core.find(cmdEx[2], '/', 1, true) then
                    numItems = 0
                    for lootTime, item in core.pairsByKeysReverse(db['VOTE_LOOT_HISTORY']) do
                        if date("%d/%m", lootTime) == cmdEx[2] then
                            talc_print(item['player'] .. " - " .. item['item'] .. " " .. date("%d/%m", lootTime))
                            numItems = numItems + 1
                        end
                    end
                    talc_print(numItems .. ' recorded for ' .. cmdEx[2])
                end

            else
                talc_print('Search syntax: /talc search [Playername/Item]')
            end
        end
        if core.sub(cmd, 1, 5) == 'scale' then
            local scaleEx = core.explode(cmd, ' ')
            if not scaleEx[1] or not scaleEx[2] or not core.int(scaleEx[2]) then
                talc_print('Set scale syntax: |cfffff569/talc scale [scale from 0.5 to 2]')
                return false
            end

            if core.int(scaleEx[2]) >= 0.5 and core.int(scaleEx[2]) <= 2 then
                TalcVoteFrame:SetScale(core.int(scaleEx[2]))
                TalcVoteFrame:ClearAllPoints();
                TalcVoteFrame:SetPoint("CENTER", UIParent);
                db['VOTE_SCALE'] = core.int(scaleEx[2])
                talc_print('Scale set to |cfffff569x' .. core['VOTE_SCALE'])
            else
                talc_print('Set scale syntax: |cfffff569/talc scale [scale from 0.5 to 2]')
            end
        end
        if core.sub(cmd, 1, 5) == 'alpha' then
            local alphaEx = core.explode(cmd, ' ')
            if not alphaEx[1] or not alphaEx[2] or not core.int(alphaEx[2]) then
                talc_print('Set alpha syntax: |cfffff569/talc alpha [0.2-1]')
                return false
            end

            if core.int(alphaEx[2]) >= 0.2 and core.int(alphaEx[2]) <= 1 then
                db['VOTE_ALPHA'] = core.int(alphaEx[2])
                TalcVoteFrame:SetAlpha(db['VOTE_ALPHA'])
                talc_print('Alpha set to |cfffff569' .. db['VOTE_ALPHA'])
            else
                talc_print('Set alpha syntax: |cfffff569/talc alpha [0.2-1]')
            end
        end

        if core.find(cmd, 'need resetscale') then

            TalcNeedFrame:SetScale(1)
            TalcNeedFrame:ClearAllPoints()
            TalcNeedFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
            talc_print('Frame scale reset to 1x.')
            db['NEED_SCALE'] = 1
            return
        end
        if core.find(cmd, 'need who') then

            if not UnitInRaid('player') then
                talc_print('You are not in a raid.')
                return false
            end

            queryWho()
            return
        end
        if core.find(cmd, 'need') then
            NeedFrame:ShowAnchor()
            return
        end

        if core.find(cmd, 'winsound') then
            local soundSplit = core.split(' ', cmd)
            if soundSplit[2] and (soundSplit[2] == 'high' or soundSplit[2] == 'low') then
                db['WIN_VOLUME'] = soundSplit[2]
                talc_print('Win Sound Volume set to |cfffff569' .. db['WIN_VOLUME'])
                return true
            end

            db['WIN_ENABLE_SOUND'] = not db['WIN_ENABLE_SOUND']

            if db['WIN_ENABLE_SOUND'] then
                talc_print('Win Sound Enabled')
            else
                talc_print('Win Sound Disabled')
            end
        end

        if core.find(cmd, 'win') then
            local winSplit = core.split(' ', cmd)
            if winSplit[2] and core.int(winSplit[2]) then
                local newT = core.int(winSplit[2])
                if newT >= 0 and newT <= 5 then
                    db['WIN_THRESHOLD'] = newT
                    local text = ''
                    local qualities = {
                        [0] = 'Poor',
                        [1] = 'Common',
                        [2] = 'Uncommon',
                        [3] = 'Rare',
                        [4] = 'Epic',
                        [5] = 'Legendary'
                    }
                    for i = newT, 5 do
                        local _, _, _, color = GetItemQualityColor(i)
                        text = text .. color .. qualities[i] .. ' '
                    end
                    talc_print('[WIN] Loot threshold changed to ' .. db['WIN_THRESHOLD'] .. ', ' .. text)
                else
                    talc_print('[WIN] Accepted range is |cfffff5690-5')
                end
            else
                WinFrame.animFrame:showAnchor()
            end
            return
        end

        if core.find(cmd, 'trombone') then
            db['ROLL_TROMBONE'] = not db['ROLL_TROMBONE']
            if db['ROLL_TROMBONE'] then
                talc_print('Sad Trombone Sound is Enabled. Type |cfffff569/talc |cff69ccf0trombone |cffffffffto toggle sad trombone sound on or off.')
            else
                talc_print('Sad Trombone Sound is Disabled. Type |cfffff569/talc |cff69ccf0trombone |cffffffffto toggle sad trombone sound on or off.')
            end
        end

        if core.find(cmd, 'rollsound') then
            local cmdEx = core.split(' ', cmd)
            if cmdEx[2] == 'high' or cmdEx[2] == 'low' then
                db['ROLL_VOLUME'] = cmdEx[2]
                talc_print('Roll Sound Volume set to |cfffff569' .. db['ROLL_VOLUME'])
                return true
            end
            db['ROLL_ENABLE_SOUND'] = not db['ROLL_ENABLE_SOUND']
            if db['ROLL_ENABLE_SOUND'] then
                talc_print('Roll Sound Enabled')
            else
                talc_print('Roll Sound Disabled')
            end
            return
        end

        if cmd == 'roll' then
            RollFrame:showAnchor()
        end

        if cmd == 'boss' then
            db['BOSS_FRAME'] = not db['BOSS_FRAME']
            if db['BOSS_FRAME'] then
                talc_print('BossFrame Enabled. Type |cfffff569/talc |cff69ccf0boss |rto toggle boss frame.')
            else
                talc_print('BossFrame Disabled. Type |cfffff569/talc |cff69ccf0boss |rto toggle boss frame.')
            end
        end

    end
end
