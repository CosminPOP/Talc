TALC = CreateFrame("Frame")

----------------------------------------------------
--- Constants
----------------------------------------------------

TALC.channel = 'TALC'
TALC.addonVer = '3.0.0.0'
TALC.me = UnitName('player')
TALC.numWishlistItems = 8
TALC.maxRecentItems = 100
TALC.maxItemHistoryPlayers = 20
TALC.maxOfficers = 10
TALC.periodicSyncMaxItems = 200
TALC.updateNotificationShown = false

local core, tokenRewards
local assistTriggers = 0
local init = false

----------------------------------------------------
--- Event Handler
----------------------------------------------------

TALC:SetScript("OnEvent", function(__, event, ...)
    if event then

        if event == "ADDON_LOADED" and arg1 == "Talc" then

            TALC:UnregisterEvent("ADDON_LOADED")

            core = TALC
            tokenRewards = TALC_TOKENS

            --- init saved vars
            if not TALC_DB then
                TALC_DB = {}
            end
            if TALC_DB['_DEBUG'] == nil then
                TALC_DB['_DEBUG'] = false
            end

            if TALC_DB['PERIODIC_SYNC_INDEX'] == nil then
                TALC_DB['PERIODIC_SYNC_INDEX'] = 1
            end

            if TALC_DB['PLAYER_CLASS_CACHE'] == nil then
                TALC_DB['PLAYER_CLASS_CACHE'] = {}
            end

            if TALC_DB['ITEM_LOCATION_CACHE'] == nil then
                TALC_DB['ITEM_LOCATION_CACHE'] = {}
            end

            if TALC_DB['ATTENDANCE_DATA'] == nil then
                TALC_DB['ATTENDANCE_DATA'] = {}
            end

            if TALC_DB['ATTENDANCE_TRACKING'] == nil then
                TALC_DB['ATTENDANCE_TRACKING'] = {
                    enabled = true,
                }
            end

            if TALC_DB['WIN_THRESHOLD'] == nil then
                TALC_DB['WIN_THRESHOLD'] = "0345"
            end
            if TALC_DB['WIN_ENABLE_SOUND'] == nil then
                TALC_DB['WIN_ENABLE_SOUND'] = true
            end
            if TALC_DB['WIN_VOLUME'] == nil then
                TALC_DB['WIN_VOLUME'] = 'low'
            end
            if TALC_DB['WIN_BLACKLIST'] == nil then
                TALC_DB['WIN_BLACKLIST'] = {}
            end

            if TALC_DB['ROLL_ENABLE_SOUND'] == nil then
                TALC_DB['ROLL_ENABLE_SOUND'] = true
            end
            if TALC_DB['ROLL_VOLUME'] == nil then
                TALC_DB['ROLL_VOLUME'] = 'low'
            end
            if TALC_DB['ROLL_TROMBONE'] == nil then
                TALC_DB['ROLL_TROMBONE'] = true
            end

            if TALC_DB['NEED_SCALE'] == nil then
                TALC_DB['NEED_SCALE'] = 1
            end
            if TALC_DB['NEED_WISHLIST'] == nil then
                TALC_DB['NEED_WISHLIST'] = {}
            end
            if TALC_DB['NEED_BLACKLIST'] == nil then
                TALC_DB['NEED_BLACKLIST'] = {}
            end
            if TALC_DB['NEED_PASSES'] == nil then
                TALC_DB['NEED_PASSES'] = {}
            end


            if TALC_DB['NEED_FRAME_COLLAPSE'] == nil then
                TALC_DB['NEED_FRAME_COLLAPSE'] = false
            end

            if TALC_DB['BOSS_FRAME_ENABLE'] == nil then
                TALC_DB['BOSS_FRAME_ENABLE'] = true
            end
            if TALC_DB['BOSS_LOOT_FRAME_ENABLE'] == nil then
                TALC_DB['BOSS_LOOT_FRAME_ENABLE'] = true
            end

            if TALC_DB['VOTE_ROSTER'] == nil then
                TALC_DB['VOTE_ROSTER'] = {}
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
                    ['NeedButtons'] = {
                        ['BIS'] = false,
                        ['MS'] = true,
                        ['OS'] = true,
                        ['XMOG'] = false
                    }
                }
            end

            TALCUtils:Init();

            --- pre cache
            --- wishlist
            for _, id in next, TALC_DB['NEED_WISHLIST'] do
                core.CacheItem(id)
            end
            --- tokenRewards
            for id in next, tokenRewards do
                core.CacheItem(id)
            end

            --- update UI
            TalcNeedFrame:SetScale(TALC_DB['NEED_SCALE'])

            TalcVoteFrameRLWindowFrameTab2ContentsBISButton:SetChecked(TALC_DB['VOTE_CONFIG']['NeedButtons']['BIS']);
            TalcVoteFrameRLWindowFrameTab2ContentsMSButton:SetChecked(TALC_DB['VOTE_CONFIG']['NeedButtons']['MS']);
            TalcVoteFrameRLWindowFrameTab2ContentsOSButton:SetChecked(TALC_DB['VOTE_CONFIG']['NeedButtons']['OS']);
            TalcVoteFrameRLWindowFrameTab2ContentsXMOGButton:SetChecked(TALC_DB['VOTE_CONFIG']['NeedButtons']['XMOG']);

            TalcVoteFrameRLWindowFrameTab1ContentsAutoAssist:SetChecked(TALC_DB['VOTE_AUTO_ASSIST']);
            TalcVoteFrameRLWindowFrameTab2ContentsScreenShot:SetChecked(TALC_DB['VOTE_SCREENSHOT_LOOT']);

            TalcVoteFrameSettingsFrameWinEnableSound:SetChecked(TALC_DB['WIN_ENABLE_SOUND'])
            if TALC_DB['WIN_ENABLE_SOUND'] then
                TalcVoteFrameSettingsFrameWinSoundHigh:Enable()
            else
                TalcVoteFrameSettingsFrameWinSoundHigh:Disable()
            end
            TalcVoteFrameSettingsFrameWinSoundHigh:SetChecked(TALC_DB['WIN_VOLUME'] == 'high')

            TalcVoteFrameSettingsFrameWinUncommon:SetChecked(core.find(TALC_DB['WIN_THRESHOLD'], '2', 1, true))
            TalcVoteFrameSettingsFrameWinRare:SetChecked(core.find(TALC_DB['WIN_THRESHOLD'], '3', 1, true))
            TalcVoteFrameSettingsFrameWinEpic:SetChecked(core.find(TALC_DB['WIN_THRESHOLD'], '4', 1, true))
            TalcVoteFrameSettingsFrameWinLegendary:SetChecked(core.find(TALC_DB['WIN_THRESHOLD'], '5', 1, true))

            TalcVoteFrameSettingsFrameRollEnableSound:SetChecked(TALC_DB['ROLL_ENABLE_SOUND'])
            if TALC_DB['ROLL_ENABLE_SOUND'] then
                TalcVoteFrameSettingsFrameRollSoundHigh:Enable()
                TalcVoteFrameSettingsFrameRollTrombone:Enable()
            else
                TalcVoteFrameSettingsFrameRollSoundHigh:Disable()
                TalcVoteFrameSettingsFrameRollTrombone:Disable()
            end
            TalcVoteFrameSettingsFrameRollSoundHigh:SetChecked(TALC_DB['ROLL_VOLUME'] == 'high')

            TalcVoteFrameSettingsFrameRollTrombone:SetChecked(TALC_DB['ROLL_TROMBONE'])

            TalcVoteFrameSettingsFrameBossEnable:SetChecked(TALC_DB['BOSS_FRAME_ENABLE'])
            TalcVoteFrameSettingsFrameBossLootEnable:SetChecked(TALC_DB['BOSS_LOOT_FRAME_ENABLE'])

            TalcVoteFrameSettingsFrameNeedFrameCollapse:SetChecked(TALC_DB['NEED_FRAME_COLLAPSE'])

            --TalcVoteFrameSettingsFrameAttendanceTrack:SetChecked(TALC_DB['ATTENDANCE_TRACKING'].enabled)
            --TalcVoteFrameSettingsFrameAttendanceBossKills:SetChecked(TALC_DB['ATTENDANCE_TRACKING'].bossKills)
            --TalcVoteFrameSettingsFrameAttendanceTime:SetChecked(TALC_DB['ATTENDANCE_TRACKING'].periodic)
            --if TALC_DB['ATTENDANCE_TRACKING'].enabled then
            --    TalcVoteFrameSettingsFrameAttendanceBossKills:Enable()
            --    TalcVoteFrameSettingsFrameAttendanceTime:Enable()
            --else
            --    TalcVoteFrameSettingsFrameAttendanceBossKills:Disable()
            --    TalcVoteFrameSettingsFrameAttendanceTime:Disable()
            --end

            --TalcVoteFrameSettingsFrameDebug:SetChecked(TALC_DB['_DEBUG'])

            --- init modules
            VoteFrame:Init();
            NeedFrame:Init();
            WinFrame:Init();
            RollFrame:Init();
            BossFrame:Init();
            BossLootFrame:Init();

            print("TALC INIt")

            init = true
            return
        end

        --if event == "PLAYER_ENTERING_WORLD" and TALC_DB['ATTENDANCE_TRACKING'].enabled then
        --    if core.instanceInfo() then
        --        if TALC_DB['ATTENDANCE_TRACKING'].started then
        --            VoteFrame.AttendanceTracker:Start()
        --        else
        --            TalcVoteAttendanceQueryStart:Show()
        --        end
        --    else
        --        if TALC_DB['ATTENDANCE_TRACKING'].started then
        --            if not VoteFrame.AttendanceTracker:IsVisible() then
        --                VoteFrame.AttendanceTracker:Show()
        --            end
        --            TalcVoteAttendanceQueryStop:Show()
        --        else
        --            VoteFrame.AttendanceTracker:Stop()
        --        end
        --    end
        --    return
        --end

        if init then

            if event == 'CHAT_MSG_ADDON' and arg1 == TALC.channel then
                --print(arg1, arg2, arg3, arg4)
                VoteFrame:HandleSync(...)
                NeedFrame:HandleSync(...)
                WinFrame:HandleSync(...)
                RollFrame:HandleSync(...)
                BossLootFrame:HandleSync(...)

                --- version
                if core.subFind(arg2, "TALCVersion=") and arg4 ~= core.me and not core.updateNotificationShown then
                    local verEx = core.split('=', arg2)
                    if core.ver(verEx[2]) > core.ver(core.addonVer) then
                        talc_print('New version available |cff69ccf0v' .. verEx[2] ..
                                '|r (your version |cffff8000v' .. core.addonVer .. '|r)')
                        talc_print('Update yours at |cff69ccf0https://github.com/CosminPOP/Talc')
                        core.updateNotificationShown = true
                    end
                end
                return
            end

            if event == "PLAYER_ENTERING_WORLD" then
                --- restart tradableItemsCheck on loading screen
                VoteFrame.tradableItemsCheck:Hide()
                VoteFrame.tradableItemsCheck:Show()

                core.SendVersion()
            end

            if event == "RAID_ROSTER_UPDATE" then
                if core.isRaidLeader() then

                    --- auto assist officers on raid update
                    if TALC_DB['VOTE_AUTO_ASSIST'] then
                        for i = 0, GetNumRaidMembers() do
                            if GetRaidRosterInfo(i) then
                                local n, r = GetRaidRosterInfo(i);
                                if core.isOfficer(n) and r == 0 and n ~= core.me then
                                    assistTriggers = assistTriggers + 1
                                    PromoteToAssistant(n)
                                    talc_print(core.classColors[core.getPlayerClass(n)].colorStr .. n .. ' |rauto promoted.')

                                    if assistTriggers > 100 then
                                        talc_error('Autoassist trigger error (>100). Autoassist disabled.')
                                        TALC_DB['VOTE_AUTO_ASSIST'] = false
                                        TalcVoteFrameRLWindowFrameTab1ContentsAutoAssist:SetChecked(TALC_DB['VOTE_AUTO_ASSIST']);
                                    end

                                    return
                                end
                            end
                        end
                    end

                    --- show raid leader's frame
                    TalcVoteFrameRLExtraFrame:Show()

                    VoteFrame:CheckAssists()
                    core.syncRoster("BULK")
                else
                    --- hide raid leader's frame
                    TalcVoteFrameRLExtraFrame:Hide()
                end
            end

            if event == "CHAT_MSG_SYSTEM" then

                if not core.isRaidLeader() then
                    return
                end

                --- ready check stuff
                if core.find(arg1, "The following players are Away:", 1, true) or
                        core.find(arg1, "No players are Away", 1, true) or
                        core.find(arg1, "is not ready", 1, true) then
                    SendChatMessage(arg1, "RAID")
                end

                --- player roll stuff
                if core.find(arg1, "rolls", 1, true) and core.find(arg1, "(1-100)", 1, true) then
                    local r = core.split(" ", arg1)

                    if not r[3] then
                        talc_error('bad roll syntax')
                        talc_error(arg1)
                        return
                    end

                    local name = r[1]
                    local roll = core.int(r[3])

                    for pwIndex, pwPlayer in next, VoteFrame.playersWhoWantItems do
                        --- check if name is in playersWhoWantItems with vote == -2
                        if pwPlayer.name == name and pwPlayer.roll == -2 then
                            --- set roll details
                            VoteFrame.playersWhoWantItems[pwIndex].roll = roll
                            VoteFrame.VotedItemsFrames[VoteFrame.CurrentVotedItem].rolled = true
                            --- send it to officers
                            core.asend("PlayerRoll=" .. pwIndex .. "=" .. roll .. "=" .. VoteFrame.CurrentVotedItem)
                            VoteFrame:VoteFrameListUpdate()
                            break
                        end
                    end
                end
                return
            end

            if event == "LOOT_OPENED" then

                local bossItems = {}
                -- save item location if item is epic or better
                if GetNumLootItems() > 0 then
                    for i = 0, GetNumLootItems() do
                        if GetLootSlotInfo(i) and GetLootSlotLink(i) then
                            local _, _, itemLink = core.find(GetLootSlotLink(i), "(item:%d+:%d+:%d+:%d+)");
                            local _, _, quality = GetItemInfo(itemLink)
                            if quality >= 4 then
                                core.SaveItemLocation(itemLink)
                                local _, name = GetLootSlotInfo(i)
                                if not core.find(name, "Emblem of", 1, true) then
                                    core.insert(bossItems, itemLink)
                                end
                            end
                        end
                    end
                end
                if BossLootFrame.sendItems and #bossItems > 0 then
                    core.asend("BossLootFrame=Start")
                    for i, item in next, bossItems do
                        core.asend("BossLootFrame=" .. i .. "=" .. item)
                    end
                    core.asend("BossLootFrame=End")
                    BossLootFrame.sendItems = false
                end

                if not TALC_DB['VOTE_ENABLED'] then
                    return
                end

                TalcVoteFrameRLExtraFrameBroadcastLoot:Enable()
                TalcVoteFrameRLExtraFrameDragLoot:Disable()

                if not core.isRaidLeader() then
                    return
                end

                local lootMethod = GetLootMethod()
                if lootMethod == 'master' then

                    TALC_DB['VOTE_TTN'] = core.SetDynTTN(GetNumLootItems())

                    local blueOrEpic = false

                    for id = 0, GetNumLootItems() do
                        if GetLootSlotInfo(id) and GetLootSlotLink(id) then
                            local _, _, itemLink = core.find(GetLootSlotLink(id), "(item:%d+:%d+:%d+:%d+)");
                            local _, _, quality = GetItemInfo(itemLink)
                            local itemID = core.int(core.split(':', itemLink)[2])
                            if quality >= 3 then
                                blueOrEpic = true
                                core.asend("CacheItem=" .. itemID)
                            end
                        end
                    end

                    if blueOrEpic then
                        TalcVoteFrameRLExtraFrameBroadcastLoot:Enable()
                        TalcVoteFrameRLExtraFrameBroadcastLoot:SetText('Load Items')
                        VoteFrame.sentReset = false
                        if core.me ~= 'Er' then
                            --- dont show for me, ill show it from erui addon
                            VoteFrame:ShowWindow()
                        end
                    end

                else
                    TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()
                end
                return
            end

            if event == "LOOT_SLOT_CLEARED" then
            end

            if event == "LOOT_CLOSED" then
                TalcVoteFrameRLExtraFrameBroadcastLoot:Disable()
                TalcVoteFrameRLExtraFrameDragLoot:Enable()
            end

            if event == "COMBAT_LOG_EVENT" and arg2 == "UNIT_DIED" then
                --- attendance save and boss dead animation
                local _, instanceType = GetInstanceInfo();
                if instanceType ~= 'none' then
                    for _, boss in next, BossFrame.Bosses do
                        if arg7 == boss then
                            if MiniMapInstanceDifficultyText:GetText() == '10' or MiniMapInstanceDifficultyText:GetText() == '25' then
                                core.saveAttendance(boss)
                            end
                            if TALC_DB['BOSS_FRAME_ENABLE'] then
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
                WinFrame:HandleLoot(arg1)
                core.SaveItemLocation(arg1)
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


----------------------------------------------------
--- Slashcommands
----------------------------------------------------

SLASH_TALC1 = "/talc"
SlashCmdList["TALC"] = function(cmd)
    if cmd then
        if core.sub(cmd, 1, 3) == 'set' then
            local setEx = core.split(' ', cmd)
            if setEx[2] and setEx[3] then
                if core.isRaidLeader() then
                    if setEx[2] == 'enchanter' then
                        if not setEx[3] then
                            talc_print('Incorrect syntax. Use /talc set enchanter [name]')
                            return
                        end
                        TALC_DB['VOTE_ENCHANTER'] = setEx[3]
                        talc_print('Enchanter set to ' ..
                                core.classColors[core.getPlayerClass(TALC_DB['VOTE_ENCHANTER'])].colorStr ..
                                TALC_DB['VOTE_ENCHANTER'])
                    end
                else
                    talc_print('You are not the raid leader.')
                end
            else
                talc_print('Set Options:')
                talc_print('/talc set enchanter [name] (current: ' .. TALC_DB['VOTE_ENCHANTER'] .. ')')
            end
        end

        if core.sub(cmd, 1, 6) == 'search' then
            local cmdEx = core.split(' ', cmd)

            if cmdEx[2] then

                local numItems = 0
                for _, item in core.pairsByKeysReverse(TALC_DB['VOTE_LOOT_HISTORY']) do
                    if core.lower(cmdEx[2]) == core.lower(item.player) then
                        numItems = numItems + 1
                    end
                end

                if numItems > 0 then
                    talc_print('Listing ' .. cmdEx[2] .. '\'s loot history(' .. numItems .. '):')
                    for timestamp, item in core.pairsByKeysReverse(TALC_DB['VOTE_LOOT_HISTORY']) do
                        if core.lower(cmdEx[2]) == core.lower(item.player) then
                            talc_print(item.item .. ' - ' .. date("%x", core.localTimeFromServerTime(timestamp)))
                        end
                    end
                else
                    talc_print('No items found for player ' .. cmdEx[2] .. '.')
                end

                for timestamp, item in core.pairsByKeysReverse(TALC_DB['VOTE_LOOT_HISTORY']) do
                    if core.find(core.lower(item.item), core.lower(cmdEx[2])) then
                        talc_print(core.classColors[item.class].colorStr .. item.player .. "|r - " ..
                                item.item .. " - " .. date("%x", core.localTimeFromServerTime(timestamp)))
                    end
                end

                if core.find(cmdEx[2], '/', 1, true) then
                    numItems = 0
                    for timestamp, item in core.pairsByKeysReverse(TALC_DB['VOTE_LOOT_HISTORY']) do
                        if date("%m/%d", core.localTimeFromServerTime(timestamp)) == cmdEx[2] then
                            talc_print(core.classColors[item.class].colorStr .. item.player .. "|r - " ..
                                    item.item .. " - " .. date("%x", core.localTimeFromServerTime(timestamp)))
                            numItems = numItems + 1
                        end
                    end
                    talc_print(numItems .. ' recorded for ' .. cmdEx[2])
                end

            else
                talc_print('Search syntax: /talc search [name/item/date(m/d)]')
            end
            return
        end

        if core.sub(cmd, 1, 5) == 'scale' then
            local scaleEx = core.split(' ', cmd)
            if not scaleEx[1] or not scaleEx[2] or not core.int(scaleEx[2]) then
                talc_print('Set scale syntax: /talc scale [scale from 0.5 to 2]')
                return
            end

            if core.int(scaleEx[2]) >= 0.5 and core.int(scaleEx[2]) <= 2 then
                TalcVoteFrame:SetScale(core.int(scaleEx[2]))
                TalcVoteFrame:ClearAllPoints();
                TalcVoteFrame:SetPoint("CENTER", UIParent);
                TALC_DB['VOTE_SCALE'] = core.int(scaleEx[2])
                talc_print('Scale set to: x' .. core['VOTE_SCALE'])
            else
                talc_print('Set scale syntax: /talc scale [scale from 0.5 to 2]')
            end
        end

        if core.sub(cmd, 1, 5) == 'alpha' then
            local alphaEx = core.split(' ', msg)
            if not alphaEx[1] or not alphaEx[2] or not core.int(alphaEx[2]) then
                talc_print('Set alpha syntax: /talc alpha [0.2-1]')
                return false
            end

            if core.int(alphaEx[2]) >= 0.2 and core.int(alphaEx[2]) <= 1 then
                TALC_DB['VOTE_ALPHA'] = core.int(alphaEx[2])
                TalcVoteFrame:SetAlpha(TALC_DB['VOTE_ALPHA'])
                talc_print('Alpha set to: ' .. TALC_DB['VOTE_ALPHA'])
            else
                talc_print('Set alpha syntax: /talc alpha [0.2-1]')
            end
        end

        if core.find(cmd, 'need resetscale') then
            TalcNeedFrame:ClearAllPoints()
            TalcNeedFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
            talc_print('Frame scale reset to 1x.')
            TALC_DB['NEED_SCALE'] = 1
            TalcNeedFrame:SetScale(TALC_DB['NEED_SCALE'])
            return
        end

        if core.find(cmd, 'win blacklist') then
            if core.find(cmd, 'win blacklist add') then
                local cmdEx = core.split(" add ", cmd)
                for _, item in next, TALC_DB['WIN_BLACKLIST'] do
                    if core.lower(item) == core.lower(cmdEx[2]) then
                        talc_print(item .. " is already in your Win Blacklist.")
                        return
                    end
                end
                core.insert(TALC_DB['WIN_BLACKLIST'], cmdEx[2])
                talc_print(cmdEx[2] .. " was added to your Win Blacklist and it will not show when looted.")
                return
            end
            if core.find(cmd, 'win blacklist remove') then
                local cmdEx = core.split(" remove ", cmd)
                for index, item in next, TALC_DB['WIN_BLACKLIST'] do
                    if core.lower(item) == core.lower(cmdEx[2]) then
                        talc_print(item .. " was remove from your Win Blacklist and it will show when looted.")
                        TALC_DB['WIN_BLACKLIST'][index] = nil
                        return
                    end
                end

                talc_print(cmdEx[2] .. " was not found in your Win Blacklist.")
                return
            end
            if core.find(cmd, 'win blacklist list') then
                if #TALC_DB['WIN_BLACKLIST'] == 0 then
                    talc_print("Your Win Blacklist is empty.")
                    talc_print("Type /talc win blacklist add [name] to add items to the list.")
                    return
                end
                talc_print("Listing your Win Blacklist, " .. #TALC_DB['WIN_BLACKLIST'] .. " item(s).")
                for index, item in next, TALC_DB['WIN_BLACKLIST'] do
                    talc_print(index .. ". " .. item)
                end
                talc_print("Type /talc win blacklist remove [name] to remove items from the list.")
                return
            end
            if core.find(cmd, 'win blacklist clear') then
                TALC_DB['WIN_BLACKLIST'] = {}
                talc_print("Win Blacklist cleared.")
                return
            end
        end

        if core.find(cmd, 'need blacklist') then
            if core.find(cmd, 'need blacklist add') then
                local cmdEx = core.split(" add ", cmd)
                for _, item in next, TALC_DB['NEED_BLACKLIST'] do
                    if core.lower(item) == core.lower(cmdEx[2]) then
                        talc_print(item .. " is already in your Need Blacklist.")
                        return
                    end
                end
                core.insert(TALC_DB['NEED_BLACKLIST'], cmdEx[2])
                talc_print(cmdEx[2] .. " was added to your Need Blacklist and it will not show when it drops.")
                return
            end
            if core.find(cmd, 'need blacklist remove') then
                local cmdEx = core.split(" remove ", cmd)
                for index, item in next, TALC_DB['NEED_BLACKLIST'] do
                    if core.lower(item) == core.lower(cmdEx[2]) then
                        talc_print(item .. " was remove from your Need Blacklist and it will show when it drops.")
                        TALC_DB['NEED_BLACKLIST'][index] = nil
                        return
                    end
                end

                talc_print(cmdEx[2] .. " was not found in your Need Blacklist.")
                return
            end
            if core.find(cmd, 'need blacklist list') then
                if #TALC_DB['NEED_BLACKLIST'] == 0 then
                    talc_print("Your Need Blacklist is empty.")
                    talc_print("Type /talc need blacklist add [name] to add items to the list.")
                    return
                end
                talc_print("Listing your Need Blacklist, " .. #TALC_DB['NEED_BLACKLIST'] .. " item(s).")
                for index, item in next, TALC_DB['NEED_BLACKLIST'] do
                    talc_print(index .. ". " .. item)
                end
                talc_print("Type /talc need blacklist remove [name] to remove items from the list.")
                return
            end
            if core.find(cmd, 'need blacklist clear') then
                TALC_DB['NEED_BLACKLIST'] = {}
                talc_print("Need Blacklist cleared.")
                return
            end
        end

        if cmd == 'who' then
            if not UnitInRaid('player') then
                talc_print('You are not in a raid.')
                return
            end
            VoteFrame:queryWho()
            return
        end
    end
end
