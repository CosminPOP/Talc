TALC = CreateFrame("Frame")

TALC.channel = 'TALC'
TALC.addonVer = '3.0.0.0'
TALC.me = UnitName('player')
TALC.numWishlistItems = 8
TALC.maxRecentItems = 100
TALC.maxItemHistoryPlayers = 20
TALC.maxLC = 3

local core, db, tokenRewards
local init = false

TALC:SetScript("OnEvent", function(__, event, ...)
    if event then

        if event == "ADDON_LOADED" and arg1 == "Blizzard_TimeManager" then

            TALC:UnregisterEvent("ADDON_LOADED")

            Talc_Utils:init();

            core = TALC
            db = TALC_DB
            tokenRewards = TALC_TOKENS

            for id in next, tokenRewards do
                core.cacheItem(id)
            end

            if not db then
                db = {}
            end
            if db['_DEBUG'] == nil then
                db['_DEBUG'] = false
            end

            if db['PLAYER_CLASS_CACHE'] == nil then
                db['PLAYER_CLASS_CACHE'] = {}
            end

            if db['ITEM_LOCATION_CACHE'] == nil then
                db['ITEM_LOCATION_CACHE'] = {}
            end

            if db['ATTENDANCE_DATA'] == nil then
                db['ATTENDANCE_DATA'] = {}
            end

            if db['ATTENDANCE_TRACKING'] == nil then
                db['ATTENDANCE_TRACKING'] = {
                    enabled = false,
                    started = false,
                    bossKills = false,
                    periodic = false,
                    period = 1 * 60
                }
            end

            if db['WIN_THRESHOLD'] == nil then
                db['WIN_THRESHOLD'] = "00345"
            end
            if db['WIN_ENABLE_SOUND'] == nil then
                db['WIN_ENABLE_SOUND'] = true
            end
            if db['WIN_VOLUME'] == nil then
                db['WIN_VOLUME'] = 'low'
            end

            if db['ROLL_ENABLE_SOUND'] == nil then
                db['ROLL_ENABLE_SOUND'] = true
            end
            if db['ROLL_VOLUME'] == nil then
                db['ROLL_VOLUME'] = 'low'
            end
            if db['ROLL_TROMBONE'] == nil then
                db['ROLL_TROMBONE'] = true
            end

            if db['NEED_SCALE'] == nil then
                db['NEED_SCALE'] = 1
            end
            if db['NEED_WISHLIST'] == nil then
                db['NEED_WISHLIST'] = {}
            end
            if db['NEED_FRAME_COLLAPSE'] == nil then
                db['NEED_FRAME_COLLAPSE'] = false
            end

            if db['BOSS_FRAME_ENABLE'] == nil then
                db['BOSS_FRAME_ENABLE'] = true
            end

            if db['VOTE_ROSTER'] == nil then
                db['VOTE_ROSTER'] = {}
            end
            if db['VOTE_ROSTER_GUILD_NAME'] == nil then
                db['VOTE_ROSTER_GUILD_NAME'] = ''
            end
            if db['VOTE_LOOT_HISTORY'] == nil then
                db['VOTE_LOOT_HISTORY'] = {}
            end
            if db['VOTE_TTN'] == nil then
                db['VOTE_TTN'] = 30
            end
            if db['VOTE_TTV'] == nil then
                db['VOTE_TTV'] = 30
            end
            if db['VOTE_TTR'] == nil then
                db['VOTE_TTR'] = 30
            end
            if db['VOTE_ENABLED'] == nil then
                db['VOTE_ENABLED'] = true
            end
            if db['VOTE_SCALE'] == nil then
                db['VOTE_SCALE'] = 1
            end
            if db['VOTE_ALPHA'] == nil then
                db['VOTE_ALPHA'] = 1
            end
            if db['VOTE_AUTO_ASSIST'] == nil then
                db['VOTE_AUTO_ASSIST'] = false
            end
            if db['VOTE_ENCHANTER'] == nil then
                db['VOTE_ENCHANTER'] = ''
            end
            if db['VOTE_SCREENSHOT_LOOT'] == nil then
                db['VOTE_SCREENSHOT_LOOT'] = true
            end

            if db['VOTE_CONFIG'] == nil then
                db['VOTE_CONFIG'] = {
                    ['NeedButtons'] = {
                        ['BIS'] = false,
                        ['MS'] = true,
                        ['OS'] = true,
                        ['XMOG'] = false
                    }
                }
            end

            TalcNeedFrame:SetScale(db['NEED_SCALE'])

            TalcVoteFrameRLWindowFrameTab2ContentsBISButton:SetChecked(db['VOTE_CONFIG']['NeedButtons']['BIS']);
            TalcVoteFrameRLWindowFrameTab2ContentsMSButton:SetChecked(db['VOTE_CONFIG']['NeedButtons']['MS']);
            TalcVoteFrameRLWindowFrameTab2ContentsOSButton:SetChecked(db['VOTE_CONFIG']['NeedButtons']['OS']);
            TalcVoteFrameRLWindowFrameTab2ContentsXMOGButton:SetChecked(db['VOTE_CONFIG']['NeedButtons']['XMOG']);

            TalcVoteFrameRLWindowFrameTab1ContentsAutoAssist:SetChecked(db['VOTE_AUTO_ASSIST']);
            TalcVoteFrameRLWindowFrameTab2ContentsScreenShot:SetChecked(db['VOTE_SCREENSHOT_LOOT']);

            TalcVoteFrameSettingsFrameWinEnableSound:SetChecked(db['WIN_ENABLE_SOUND'])
            if db['WIN_ENABLE_SOUND'] then
                TalcVoteFrameSettingsFrameWinSoundHigh:Enable()
            else
                TalcVoteFrameSettingsFrameWinSoundHigh:Disable()
            end
            TalcVoteFrameSettingsFrameWinSoundHigh:SetChecked(db['WIN_VOLUME'] == 'high')

            TalcVoteFrameSettingsFrameWinCommon:SetChecked(core.find(db['WIN_THRESHOLD'], '1', 1, true))
            TalcVoteFrameSettingsFrameWinUncommon:SetChecked(core.find(db['WIN_THRESHOLD'], '2', 1, true))
            TalcVoteFrameSettingsFrameWinRare:SetChecked(core.find(db['WIN_THRESHOLD'], '3', 1, true))
            TalcVoteFrameSettingsFrameWinEpic:SetChecked(core.find(db['WIN_THRESHOLD'], '4', 1, true))
            TalcVoteFrameSettingsFrameWinLegendary:SetChecked(core.find(db['WIN_THRESHOLD'], '5', 1, true))

            TalcVoteFrameSettingsFrameRollEnableSound:SetChecked(db['ROLL_ENABLE_SOUND'])
            if db['ROLL_ENABLE_SOUND'] then
                TalcVoteFrameSettingsFrameRollSoundHigh:Enable()
                TalcVoteFrameSettingsFrameRollTrombone:Enable()
            else
                TalcVoteFrameSettingsFrameRollSoundHigh:Disable()
                TalcVoteFrameSettingsFrameRollTrombone:Disable()
            end
            TalcVoteFrameSettingsFrameRollSoundHigh:SetChecked(db['ROLL_VOLUME'] == 'high')

            TalcVoteFrameSettingsFrameRollTrombone:SetChecked(db['ROLL_TROMBONE'])

            TalcVoteFrameSettingsFrameBossEnable:SetChecked(db['BOSS_FRAME_ENABLE'])

            TalcVoteFrameSettingsFrameNeedFrameCollapse:SetChecked(db['NEED_FRAME_COLLAPSE'])


            TalcVoteFrameSettingsFrameAttendanceTrack:SetChecked(db['ATTENDANCE_TRACKING'].enabled)
            TalcVoteFrameSettingsFrameAttendanceBossKills:SetChecked(db['ATTENDANCE_TRACKING'].bossKills)
            TalcVoteFrameSettingsFrameAttendanceTime:SetChecked(db['ATTENDANCE_TRACKING'].periodic)
            if db['ATTENDANCE_TRACKING'].enabled then
                TalcVoteFrameSettingsFrameAttendanceBossKills:Enable()
                TalcVoteFrameSettingsFrameAttendanceTime:Enable()
            else
                TalcVoteFrameSettingsFrameAttendanceBossKills:Disable()
                TalcVoteFrameSettingsFrameAttendanceTime:Disable()
            end

            TalcVoteFrameSettingsFrameDebug:SetChecked(db['_DEBUG'])

            TalcFrame:init();

            NeedFrame:init();
            WinFrame:init();
            RollFrame:init();
            BossFrame:init();

            print("TALC INIt")

            init = true
            return
        end

        if event == "PLAYER_ENTERING_WORLD" and db['ATTENDANCE_TRACKING'].enabled then
            if core.instanceInfo() then
                if db['ATTENDANCE_TRACKING'].started then
                    TalcFrame.AttendanceTracker:Start()
                else
                    TalcVoteAttendanceQueryStart:Show()
                end
            else
                if db['ATTENDANCE_TRACKING'].started then
                    TalcVoteAttendanceQueryStop:Show()
                else
                    TalcFrame.AttendanceTracker:Stop()
                end
            end
            return
        end

        if init then

            if event == 'CHAT_MSG_ADDON' and arg1 == TALC.channel then
                --print(arg1, arg2, arg3, arg4)
                TalcFrame:handleSync(...)
                NeedFrame:handleSync(...)
                WinFrame:handleSync(...)
                RollFrame:handleSync(...)
                return
            end

            if event == "RAID_ROSTER_UPDATE" then
                if core.isRL() then

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

                    TalcFrame:CheckAssists()
                else
                    TalcVoteFrameRLExtraFrame:Hide()

                end
                if not core.canVote() then
                    TalcVoteFrame:Hide()
                end
            end

            if event == "CHAT_MSG_SYSTEM" then

                RollFrame:handleSystem(arg1)

                -- todo check how this looks for non cl/leader
                if (core.find(arg1, "The following players are AFK", 1, true) or
                        core.find(arg1, "No players are AFK", 1, true) or
                        core.find(arg1, "is not ready", 1, true)) and core.isRL() then
                    SendChatMessage(arg1, "RAID")
                end
                if core.find(arg1, "rolls", 1, true) and core.find(arg1, "(1-100)", 1, true) then
                    local r = core.split(" ", arg1)

                    if not r[3] then
                        talc_error('bad roll syntax')
                        talc_error(arg1)
                        return false
                    end

                    local name = r[1]
                    local roll = core.int(r[3])

                    -- todo revisit this logic
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
                if core.isRL() then

                    local lootMethod = GetLootMethod()
                    if lootMethod == 'master' then

                        db['VOTE_TTN'] = core.SetDynTTN(GetNumLootItems())

                        local blueOrEpic = false

                        for id = 0, GetNumLootItems() do
                            if GetLootSlotInfo(id) and GetLootSlotLink(id) then
                                local _, _, itemLink = core.find(GetLootSlotLink(id), "(item:%d+:%d+:%d+:%d+)");
                                local _, _, quality = GetItemInfo(itemLink)
                                local itemID = core.int(core.split(':', itemLink)[2])
                                if quality >= 3 then
                                    blueOrEpic = true
                                    core.asend("cacheItem=" .. itemID)
                                end
                            end
                        end

                        if blueOrEpic then
                            TalcVoteFrameRLExtraFrameBroadcastLoot:Enable()
                            TalcVoteFrameRLExtraFrameBroadcastLoot:SetText('Load Items')
                            TalcFrame.sentReset = false
                            if core.me ~= 'Er' then
                                -- dont show for me, ill show it from erui addon
                                TalcFrame:ShowWindow()
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

            if event == "COMBAT_LOG_EVENT" and arg2 == "UNIT_DIED" then
                local _, instanceType = GetInstanceInfo();
                if instanceType ~= 'none' then
                    for _, boss in next, BossFrame.Bosses do
                        if arg7 == boss then
                            if MiniMapInstanceDifficultyText:GetText() == '10' or MiniMapInstanceDifficultyText:GetText() == '25' then
                                core.saveAttendance(boss)
                            end
                            if db['BOSS_FRAME_ENABLE'] then
                                BossFrame:StartBossAnimation(boss)
                            end
                            return
                        end
                    end
                end
                return
            end

            --if event == 'PLAYER_TARGET_CHANGED' then
            --    local master = 'Er'
            --    if core.me == master then
            --        return
            --    end
            --    if not UnitExists('target') or UnitAffectingCombat('player') then
            --        return
            --    end
            --    if UnitName('target') == master and CheckInteractDistance("target", 3) then
            --        PlaySoundFile("Sound\\Character\\Dwarf\\DwarfVocalFemale\\DwarfFemaleHello0" .. math.random(1, 3) .. ".wav", "Dialog")
            --    end
            --    return
            --end

            if event == 'CHAT_MSG_LOOT' then
                WinFrame:handleLoot(arg1)
                TalcFrame:SaveItemLocation(arg1)
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
TALC:RegisterEvent("PLAYER_TARGET_CHANGED")
TALC:RegisterEvent("CHAT_MSG_ADDON")
TALC:RegisterEvent("CHAT_MSG_LOOT")
TALC:RegisterEvent("COMBAT_LOG_EVENT")
TALC:RegisterEvent("PLAYER_ENTERING_WORLD")

SLASH_TALC1 = "/talc"
SlashCmdList["TALC"] = function(cmd)
    if cmd then
        if core.sub(cmd, 1, 3) == 'set' then
            local setEx = core.split(' ', cmd)
            if setEx[2] and setEx[3] then
                if core.isRL() then
                    if setEx[2] == 'enchanter' then
                        if not setEx[3] then
                            talc_print('Incorrect syntax. Use /talc set enchanter [name]')
                            return
                        end
                        db['VOTE_ENCHANTER'] = setEx[3]
                        local deClassColor = core.classColors[core.getPlayerClass(db['VOTE_ENCHANTER'])].colorStr
                        talc_print('Enchanter set to ' .. deClassColor .. db['VOTE_ENCHANTER'])
                    end
                else
                    talc_print('You are not the raid leader.')
                end
            else
                talc_print('Options')
                talc_print('/talc set enchanter [name] (current value: ' .. db['VOTE_ENCHANTER'] .. ')')
            end
        end

        if core.sub(cmd, 1, 6) == 'search' then
            local cmdEx = core.split(' ', cmd)

            if cmdEx[2] then

                local numItems = 0
                for _, item in core.pairsByKeysReverse(db['VOTE_LOOT_HISTORY']) do
                    if core.lower(cmdEx[2]) == core.lower(item.player) then
                        numItems = numItems + 1
                    end
                end

                if numItems > 0 then
                    talc_print('Listing ' .. cmdEx[2] .. '\'s loot history:')
                    for _, item in core.pairsByKeysReverse(db['VOTE_LOOT_HISTORY']) do
                        if core.lower(cmdEx[2]) == core.lower(item.player) then
                            talc_print(item.item .. ' - ' .. date("%d/%m", item.timestamp))
                        end
                    end
                else
                    talc_print('- no recorded items -')
                end

                for _, item in core.pairsByKeysReverse(db['VOTE_LOOT_HISTORY']) do
                    if core.find(core.lower(item.item), core.lower(cmdEx[2])) then
                        talc_print(item.player .. " - " .. item.item .. " " .. date("%d/%m", item.timestamp))
                    end
                end

                if core.find(cmdEx[2], '/', 1, true) then
                    numItems = 0
                    for _, item in core.pairsByKeysReverse(db['VOTE_LOOT_HISTORY']) do
                        if date("%d/%m", lootTime) == cmdEx[2] then
                            talc_print(item.player .. " - " .. item.item .. " " .. date("%d/%m", item.timestamp))
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

        if cmd == 'who' then
            if not UnitInRaid('player') then
                talc_print('You are not in a raid.')
                return false
            end
            TalcFrame:queryWho()
            return
        end
    end
end
