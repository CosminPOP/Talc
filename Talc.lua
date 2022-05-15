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
            if TALC_DB['_DEBUG'] == nil then
                TALC_DB['_DEBUG'] = false
            end

            if TALC_DB['WIN_THRESHOLD'] == nil then
                TALC_DB['WIN_THRESHOLD'] = 3
            end
            if TALC_DB['WIN_ENABLE_SOUND']  == nil then
                TALC_DB['WIN_ENABLE_SOUND'] = true
            end
            if TALC_DB['WIN_VOLUME']  == nil then
                TALC_DB['WIN_VOLUME'] = 'high'
            end

            if TALC_DB['ROLL_ENABLE_SOUND'] == nil then
                TALC_DB['ROLL_ENABLE_SOUND'] = true
            end
            if TALC_DB['ROLL_VOLUME'] == nil then
                TALC_DB['ROLL_VOLUME'] = 'high'
            end
            if TALC_DB['ROLL_TROMBONE'] == nil then
                TALC_DB['ROLL_TROMBONE'] = 'true'
            end

            if TALC_DB['NEED_SCALE'] == nil then
                TALC_DB['NEED_SCALE'] = 1
            end

            if TALC_DB['PULL'] == nil then
                TALC_DB['PULL'] = true
            end
            if TALC_DB['PULL_SOUND'] == nil then
                TALC_DB['PULL_SOUND'] = true
            end

            if TALC_DB['BOSS_FRAME'] == nil then
                TALC_DB['BOSS_FRAME'] = true
            end

            if TALC_DB['VOTE_ROSTER'] == nil then
                TALC_DB['VOTE_ROSTER'] = {}
            end
            if TALC_DB['VOTE_ROSTER_GUILD_NAME'] == nil then
                TALC_DB['VOTE_ROSTER_GUILD_NAME'] = ''
            end
            if TALC_DB['VOTE_LOOT_HISTORY'] == nil then
                TALC_DB['VOTE_LOOT_HISTORY'] = {}
            end
            if TALC_DB['VOTE_TTN'] == nil then
                TALC_DB['VOTE_TTN'] = 30
            end
            if TALC_DB['VOTE_TTV'] == nil then
                TALC_DB['VOTE_TTV'] = 30
            end
            if TALC_DB['VOTE_TTR'] == nil then
                TALC_DB['VOTE_TTR'] = 30
            end
            if TALC_DB['VOTE_ENABLED'] == nil then
                TALC_DB['VOTE_ENABLED'] = true
            end
            if TALC_DB['VOTE_SCALE'] == nil then
                TALC_DB['VOTE_SCALE'] = 1
            end
            if TALC_DB['VOTE_ALPHA'] == nil then
                TALC_DB['VOTE_ALPHA'] = 1
            end
            if TALC_DB['VOTE_AUTO_ASSIST'] == nil then
                TALC_DB['VOTE_AUTO_ASSIST'] = false
            end
            if TALC_DB['VOTE_ENCHANTER'] == nil then
                TALC_DB['VOTE_ENCHANTER'] = ''
            end
            if TALC_DB['VOTE_SCREENSHOT_LOOT'] == nil then
                TALC_DB['VOTE_SCREENSHOT_LOOT'] = true
            end

            if TALC_DB['VOTE_CONFIG'] == nil then
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

            TalcVoteFrameRLWindowFrameTab2ContentsBISButton:SetChecked(TALC_DB['VOTE_CONFIG']['NeedButtons']['BIS']);
            TalcVoteFrameRLWindowFrameTab2ContentsMSButton:SetChecked(TALC_DB['VOTE_CONFIG']['NeedButtons']['MS']);
            TalcVoteFrameRLWindowFrameTab2ContentsOSButton:SetChecked(TALC_DB['VOTE_CONFIG']['NeedButtons']['OS']);
            TalcVoteFrameRLWindowFrameTab2ContentsXMOGButton:SetChecked(TALC_DB['VOTE_CONFIG']['NeedButtons']['XMOG']);

            TalcVoteFrameRLWindowFrameTab1ContentsAutoAssist:SetChecked(TALC_DB['VOTE_AUTO_ASSIST']);
            TalcVoteFrameRLWindowFrameTab2ContentsScreenShot:SetChecked(TALC_DB['VOTE_SCREENSHOT_LOOT']);

            Talc_Utils:init();
            TalcFrame:init();

            NeedFrame:init();
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
                --print(arg1, arg2, arg3, arg4)
                TalcFrame:handleSync(...)
                NeedFrame:handleSync(...)
                WinFrame:handleSync(...)
                RollFrame:handleSync(...)
            end

            if event == "RAID_ROSTER_UPDATE" then
                if core.isRL(core.me) then

                    if db['VOTE_AUTO_ASSIST'] then
                        for i = 0, GetNumRaidMembers() do
                            if GetRaidRosterInfo(i) then
                                local n, r = GetRaidRosterInfo(i);
                                if core.isCL(n) and r == 0 and n ~= core.me then
                                    TalcFrame.assistTriggers = TalcFrame.assistTriggers + 1
                                    PromoteToAssistant(n)
                                    talc_print(core.classColors[core.getPlayerClass(n)].colorStr .. n .. ' |rauto promoted.')

                                    if TalcFrame.assistTriggers > 100 then
                                        talc_error('Autoassist trigger error (>100). Autoassist disabled.')
                                        db['VOTE_AUTO_ASSIST'] = false
                                    end

                                    return false
                                end
                            end
                        end
                    end
                    TalcVoteFrameRLExtraFrame:Show()

                    TalcFrame.RLFrame:CheckAssists()
                else
                    TalcVoteFrameRLExtraFrame:Hide()

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
                    local r = core.split(" ", arg1)

                    if not r[2] or not r[3] then
                        talc_error('bad roll syntax')
                        talc_error(arg1)
                        return false
                    end

                    local name = r[1]
                    local roll = core.int(r[3])

                    --check if name is in playersWhoWantItems with vote == -2
                    for pwIndex, pwPlayer in next, TalcFrame.playersWhoWantItems do
                        if pwPlayer['name'] == name and pwPlayer['roll'] == -2 then
                            TalcFrame.playersWhoWantItems[pwIndex]['roll'] = roll
                            core.asend("playerRoll:" .. pwIndex .. ":" .. roll .. ":" .. TalcFrame.CurrentVotedItem)
                            TalcFrame:VoteFrameListUpdate()
                            break
                        end
                    end
                end
            end
            if event == "LOOT_OPENED" then
                TalcVoteFrameRLExtraFrameBroadcastLoot:Enable()
                TalcVoteFrameRLExtraFrameDragLoot:Disable()
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
                        TalcVoteFrameRLExtraFrameBroadcastLoot:SetText('Load Items')
                        TalcFrame.sentReset = false
                        if core.me ~= 'Er' then
                            -- dont show for me, ill show it from erui addon
                            TalcFrame:showWindow()
                        end

                        --pre send items for never seen
                        for id = 0, GetNumLootItems() do
                            if GetLootSlotInfo(id) and GetLootSlotLink(id) then
                                local lootIcon, lootName = GetLootSlotInfo(id)

                                local _, _, itemLink = core.find(GetLootSlotLink(id), "(item:%d+:%d+:%d+:%d+)");
                                local itemID, _, quality = GetItemInfo(itemLink)
                                if quality >= 3 then

                                    if not TalcFrame.itemsToPreSend[itemID] then
                                        TalcFrame.itemsToPreSend[itemID] = true

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
                TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()
                TalcVoteFrameRLExtraFrameDragLoot:Enable()
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
                return
            end

            if event == 'CHAT_MSG_LOOT' then
                WinFrame:handleLoot(arg1)
                return
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
        if core.sub(cmd, 1, 3) == 'set' then
            local setEx = core.split(' ', cmd)
            if setEx[2] and setEx[3] then
                if core.isRL(core.me) then
                    if setEx[2] == 'enchanter' then
                        if not setEx[3] then
                            talc_print('Incorrect syntax. Use /talc set enchanter [name]')
                            return
                        end
                        db['VOTE_ENCHANTER'] = setEx[3]
                        local deClassColor = core.classColors[core.getPlayerClass(db['VOTE_DESENCHANTER'])].colorStr
                        talc_print('Enchanter set to ' .. deClassColor .. db['VOTE_DESENCHANTER'])
                        TalcVoteFrameMLToEnchanter:Show()
                    end
                else
                    talc_print('You are not the raid leader.')
                end
            else
                talc_print('Options')
                talc_print('/talc set enchanter [name] (current value: ' .. db['VOTE_ENCHANTER'] .. ')')
            end
        end
        if cmd == 'debug' then
            db['_DEBUG'] = not db['_DEBUG']
            if db['_DEBUG'] then
                talc_print('Debug ENABLED')
            else
                talc_print('Debug DISABLED')
            end
            return
        end
        if cmd == 'who' then
            TalcFrame:RefreshWho()
            return
        end
        if cmd == 'clearhistory' then
            db['VOTE_LOOT_HISTORY'] = {}
            talc_print('Loot History cleared.')
            return
        end
        if core.sub(cmd, 1, 6) == 'search' then
            local cmdEx = core.split(' ', cmd)

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
            local scaleEx = core.split(' ', cmd)
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
            local alphaEx = core.split(' ', msg)
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
            return
        end

        if cmd == 'boss' then
            db['BOSS_FRAME'] = not db['BOSS_FRAME']
            if db['BOSS_FRAME'] then
                talc_print('BossFrame Enabled. Type |cfffff569/talc |cff69ccf0boss |rto toggle boss frame.')
            else
                talc_print('BossFrame Disabled. Type |cfffff569/talc |cff69ccf0boss |rto toggle boss frame.')
            end
            return
        end

    end
end
