local core, db, tokenRewards
local _G = _G

TALCUtils = CreateFrame("Frame")

function TALCUtils:Init()

    core = TALC
    db = TALC_DB
    tokenRewards = TALC_TOKENS

    core.type = type
    core.select = select
    core.floor = math.floor
    core.ceil = math.ceil
    core.max = math.max
    core.min = math.min
    core.rep = string.rep
    core.sub = string.sub
    core.int = tonumber
    core.lower = string.lower
    core.upper = string.upper
    core.find = string.find
    core.format = string.format
    core.byte = string.byte
    core.char = string.char
    core.len = string.len
    core.gsub = string.gsub
    core.rep = string.rep
    core.tostring = tostring
    core.pairs = pairs
    core.ipairs = ipairs
    core.sort = table.sort
    core.insert = table.insert
    core.wipe = table.wipe

    core.dow = {
        [0] = "Sunday",
        [1] = "Monday",
        [2] = "Tuesday",
        [3] = "Wednesday",
        [4] = "Thursday",
        [5] = "Friday",
        [6] = "Saturday"
    }

    core.classColors = {
        ["warrior"] = { r = 0.78, g = 0.61, b = 0.43, colorStr = "|cffc79c6e" },
        ["mage"] = { r = 0.41, g = 0.8, b = 0.94, colorStr = "|cff69ccf0" },
        ["rogue"] = { r = 1, g = 0.96, b = 0.41, colorStr = "|cfffff569" },
        ["druid"] = { r = 1, g = 0.49, b = 0.04, colorStr = "|cffff7d0a" },
        ["hunter"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = "|cffabd473" },
        ["shaman"] = { r = 0.14, g = 0.35, b = 1.0, colorStr = "|cff0070de" },
        ["priest"] = { r = 1, g = 1, b = 1, colorStr = "|cffffffff" },
        ["warlock"] = { r = 0.58, g = 0.51, b = 0.79, colorStr = "|cff9482c9" },
        ["paladin"] = { r = 0.96, g = 0.55, b = 0.73, colorStr = "|cfff58cba" },
        ["deathknight"] = { r = 0.77, g = 0.12, b = 0.23, colorStr = "|cffC41F3B" },
    }

    core.needs = {
        ["bis"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = ITEM_QUALITY_COLORS[4].hex, text = 'BIS' },
        ["ms"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = ITEM_QUALITY_COLORS[3].hex, text = 'Main Spec' },
        ["os"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = ITEM_QUALITY_COLORS[2].hex, text = 'Offspec' },
        ["xmog"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = ITEM_QUALITY_COLORS[6].hex, text = 'Transmog' },
        ["pass"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = ITEM_QUALITY_COLORS[1].hex, text = 'pass' },
        ["autopass"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = ITEM_QUALITY_COLORS[0].hex, text = 'auto pass' },
        ["wait"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = ITEM_QUALITY_COLORS[1].hex, text = 'Waiting pick...' },
        ["de"] = { r = 0.96, g = 0.55, b = 0.73, colorStr = "|cfff58cba", text = 'Disenchant' },
    }

    core.equipSlotsDetails = {
        ["INVTYPE_HEAD"] = { slot = "Head", id = 1, canHaveEnchant = true },
        ["INVTYPE_NECK"] = { slot = "Neck", id = 2, canHaveEnchant = false },
        ["INVTYPE_SHOULDER"] = { slot = "Shoulder", id = 3, canHaveEnchant = true },
        ["INVTYPE_BODY"] = { slot = "Shirt", id = 4, canHaveEnchant = false },
        ["INVTYPE_CHEST"] = { slot = "Chest", id = 5, canHaveEnchant = true },
        ["INVTYPE_ROBE"] = { slot = "Chest", id = 5, canHaveEnchant = true },
        ["INVTYPE_WAIST"] = { slot = "Waist", id = 6, canHaveEnchant = false },
        ["INVTYPE_LEGS"] = { slot = "Legs", id = 7, canHaveEnchant = true },
        ["INVTYPE_FEET"] = { slot = "Feet", id = 8, canHaveEnchant = true },
        ["INVTYPE_WRIST"] = { slot = "Wrist", id = 9, canHaveEnchant = true },
        ["INVTYPE_HAND"] = { slot = "Hands", id = 10, canHaveEnchant = true },

        ["INVTYPE_FINGER0"] = { slot = "Finger0", id = 11, canHaveEnchant = false },
        ["INVTYPE_FINGER1"] = { slot = "Finger1", id = 12, canHaveEnchant = false },

        ["INVTYPE_TRINKET0"] = { slot = "Trinket0", id = 13, canHaveEnchant = false },
        ["INVTYPE_TRINKET1"] = { slot = "Trinket1", id = 14, canHaveEnchant = false },

        ["INVTYPE_CLOAK"] = { slot = "Back", id = 15, canHaveEnchant = true },

        ["INVTYPE_2HWEAPON"] = { slot = "MainHand", id = 16, canHaveEnchant = true },
        ["INVTYPE_WEAPONMAINHAND"] = { slot = "MainHand", id = 16, canHaveEnchant = true },
        ["INVTYPE_WEAPON0"] = { slot = "MainHand", id = 16, canHaveEnchant = true },

        ["INVTYPE_WEAPON1"] = { slot = "SecondaryHand", id = 17, canHaveEnchant = false },
        ["INVTYPE_SHIELD"] = { slot = "SecondaryHand", id = 17, canHaveEnchant = false },
        ["INVTYPE_WEAPONOFFHAND"] = { slot = "SecondaryHand", id = 17, canHaveEnchant = false },
        ["INVTYPE_HOLDABLE"] = { slot = "SecondaryHand", id = 17, canHaveEnchant = false },

        ["INVTYPE_RANGED"] = { slot = "Ranged", id = 18, canHaveEnchant = false },
        ["INVTYPE_THROWN"] = { slot = "Ranged", id = 18, canHaveEnchant = false },
        ["INVTYPE_RANGEDRIGHT"] = { slot = "Ranged", id = 18, canHaveEnchant = false },
        ["INVTYPE_RELIC"] = { slot = "Ranged", id = 18, canHaveEnchant = false },
        ["INVTYPE_TABARD"] = { slot = "Tabard", id = 19, canHaveEnchant = false },
    }

    core.equipSlots = {
        ["INVTYPE_AMMO"] = 'Ammo', --	0', --
        ["INVTYPE_HEAD"] = 'Head', --	1',
        ["INVTYPE_NECK"] = 'Neck', --	2',
        ["INVTYPE_SHOULDER"] = 'Shoulder', --	3',
        ["INVTYPE_BODY"] = 'Shirt', --	4',
        ["INVTYPE_CHEST"] = 'Chest', --	5',
        ["INVTYPE_ROBE"] = 'Chest', --	5',
        ["INVTYPE_WAIST"] = 'Waist', --	6',
        ["INVTYPE_LEGS"] = 'Legs', --	7',
        ["INVTYPE_FEET"] = 'Feet', --	8',
        ["INVTYPE_WRIST"] = 'Wrist', --	9',
        ["INVTYPE_HAND"] = 'Hands', --	10',
        ["INVTYPE_FINGER"] = 'Ring', --	11,12',
        ["INVTYPE_TRINKET"] = 'Trinket', --	13,14',
        ["INVTYPE_CLOAK"] = 'Cloak', --	15',
        ["INVTYPE_WEAPON"] = 'One-Hand', --	16,17',
        ["INVTYPE_SHIELD"] = 'Shield', --	17',
        ["INVTYPE_2HWEAPON"] = 'Two-Handed', --	16',
        ["INVTYPE_WEAPONMAINHAND"] = 'Main-Hand Weapon', --	16',
        ["INVTYPE_WEAPONOFFHAND"] = 'Off-Hand Weapon', --	17',
        ["INVTYPE_HOLDABLE"] = 'Held In Off-Hand', --	17',
        ["INVTYPE_RANGED"] = 'Bow', --	18',
        ["INVTYPE_THROWN"] = 'Ranged', --	18',
        ["INVTYPE_RANGEDRIGHT"] = '', --	18', --Wands, Guns, and Crossbows
        ["INVTYPE_RELIC"] = 'Relic', --	18',
        ["INVTYPE_TABARD"] = 'Tabard', --	19',
        ["INVTYPE_BAG"] = 'Container', --	20,21,22,23',
        ["INVTYPE_QUIVER"] = 'Quiver', --	20,21,22,23',
    }

    core.subFind = function(source, code)
        return core.sub(source, 1, core.len(code)) == code
    end

    core.split = function(delimiter, str)
        local result = {}
        local from = 1
        local delim_from, delim_to = core.find(str, delimiter, from)
        while delim_from do
            core.insert(result, core.sub(str, from, delim_from - 1))
            from = delim_to + 1
            delim_from, delim_to = core.find(str, delimiter, from)
        end
        core.insert(result, core.sub(str, from))
        return result
    end

    core.asend = function(msg)
        SendAddonMessage(core.channel, msg, "RAID")
    end

    core.bsend = function(prio, msg)
        ChatThrottleLib:SendAddonMessage(prio, core.channel, msg, "RAID")
    end
    core.bsendg = function(prio, msg)
        ChatThrottleLib:SendAddonMessage(prio, core.channel, msg, "GUILD")
    end

    core.wsend = function(prio, msg, to)
        ChatThrottleLib:SendAddonMessage(prio, core.channel, msg, "WHISPER", to)
    end

    core.n = function(table)
        local n = 0
        for _ in next, table do
            n = n + 1
        end
        return n
    end
    core.ucFirst = function(str)
        return core.upper(core.sub(str, 1, 1)) .. core.sub(str, 2, core.len(str))
    end

    core.trim = function(s)
        return core.gsub(s, "^%s*(.-)%s*$", "%1")
    end

    core.pairsByKeysReverse = function(t)
        local a = {}
        for n in core.pairs(t) do
            core.insert(a, n)
        end
        core.sort(a, function(a, b)
            return a > b
        end)
        local i = 0 -- iterator variable
        local iter = function()
            -- iterator function
            i = i + 1
            if a[i] == nil then
                return nil
            else
                return a[i], t[a[i]]
            end
        end
        return iter
    end

    core.addButtonOnEnterTooltip = function(frame, itemLink, custom, defaultClickEvents)

        if core.find(itemLink, "|", 1, true) then
            local ex = core.split("|", itemLink)

            if not ex[2] or not ex[3] then
                talc_error('bad addButtonOnEnterTooltip itemLink syntax')
                talc_error(itemLink)
                return
            end

            frame:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT", 0, -(this:GetHeight() / 4));
                GameTooltip:SetHyperlink(core.sub(ex[3], 2, core.len(ex[3])));

                if custom and custom == 'playerHistory' then

                    local _, _, il = core.find(itemLink, "(item:%d+:%d+:%d+:%d+)");
                    local name = GetItemInfo(il)
                    local numItems = 0
                    for _, item in core.pairsByKeysReverse(db['VOTE_LOOT_HISTORY']) do
                        if core.find(core.lower(item['item']), core.lower(name)) then
                            numItems = numItems + 1
                        end
                    end

                    if numItems == 0 then
                        GameTooltip:AddLine('------- AWARD HISTORY -------')
                        GameTooltip:AddLine('No records.')
                    else
                        GameTooltip:AddLine('------- AWARD HISTORY ('.. numItems ..') -------')

                        for timestamp, item in core.pairsByKeysReverse(db['VOTE_LOOT_HISTORY']) do
                            if core.find(core.lower(item['item']), core.lower(name)) then
                                GameTooltip:AddLine('|r' .. date("%d/%m", core.localTimeFromServerTime(timestamp)) .. " " .. core.classColors[core.getPlayerClass(item.player)].colorStr .. item.player)
                            end
                        end
                    end
                end

                GameTooltip:Show();
            end)

            if defaultClickEvents then
                frame:SetScript("OnClick", function(self)
                    if IsControlKeyDown() then
                        DressUpItemLink(itemLink)
                    end
                    if IsShiftKeyDown() then
                        if ChatFrame1EditBox:IsVisible() then
                            ChatFrame1EditBox:Insert(itemLink);
                        end
                    end
                end)
            end
        else
            frame:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT", (this:GetWidth()), -(this:GetHeight() / 4));
                GameTooltip:SetHyperlink(itemLink);
                GameTooltip:Show();
            end)
            if defaultClickEvents then
                frame:SetScript("OnClick", function(self)
                    if IsControlKeyDown() then
                        DressUpItemLink(itemLink)
                    end
                    if IsShiftKeyDown() then
                        if ChatFrame1EditBox:IsVisible() then
                            ChatFrame1EditBox:Insert(itemLink);
                        end
                    end
                end)
            end
        end
        frame:SetScript("OnLeave", function(self)
            GameTooltip:Hide();
        end)
    end

    core.remButtonOnEnterTooltip = function(frame)
        frame:SetScript("OnEnter", nil)
        frame:SetScript("OnLeave", nil)
        frame:SetScript("OnClick", nil)
    end

    core.ver = function(ver)
        return core.int(core.sub(ver, 1, 1)) * 1000 +
                core.int(core.sub(ver, 3, 3)) * 100 +
                core.int(core.sub(ver, 5, 5)) * 10 +
                core.int(core.sub(ver, 7, 7)) * 1
    end

    core.SetDynTTN = function(numItems)
        local t = 20
        if numItems == 2 then
            t = 25
        end
        if numItems == 3 then
            t = 30
        end
        if numItems == 4 then
            t = 40
        end
        if numItems >= 5 then
            t = 50
        end
        db['VOTE_TTN'] = t
    end

    core.SetDynTTV = function(numItems)
        local t = 45
        if numItems == 2 then
            t = 60
        end
        if numItems == 3 then
            t = 80
        end
        if numItems == 4 then
            t = 100
        end
        if numItems >= 5 then
            t = 120
        end
        db['VOTE_TTV'] = t
    end

    core.isOfficer = function(name)
        if not name then
            name = core.me
        end
        for _, n in next, db['VOTE_ROSTER'] do
            if n == name then
                return true
            end
        end
        return false
    end

    core.isRaidLeader = function(name)
        if not name then
            name = core.me
        end
        if not UnitInRaid('player') then
            return false
        end
        for i = 0, GetNumRaidMembers() do
            if GetRaidRosterInfo(i) then
                local n, r = GetRaidRosterInfo(i);
                if n == name and r == 2 then
                    return true
                end
            end
        end
        return false
    end

    core.isAssistant = function(name)
        if not name then
            name = core.me
        end
        if not UnitInRaid('player') then
            return false
        end
        for i = 0, GetNumRaidMembers() do
            if GetRaidRosterInfo(i) then
                local n, r = GetRaidRosterInfo(i);
                if n == name and r == 1 then
                    return true
                end
            end
        end
        return false
    end

    core.isRaidLeaderOrAssistant = function(name)
        if not name then
            name = core.me
        end
        return core.isAssistant(name) or core.isRaidLeader(name)
    end

    core.canVote = function(name)
        if not name then
            name = core.me
        end
        return core.isRaidLeaderOrAssistant(name) and core.isOfficer(name)
    end

    core.onlineInRaid = function(name)
        if not name then
            name = core.me
        end
        for i = 0, GetNumRaidMembers() do
            if GetRaidRosterInfo(i) then
                local n, _, _, _, _, _, z = GetRaidRosterInfo(i);
                if n == name and z ~= 'Offline' then
                    return true
                end
            end
        end
        return false
    end

    core.getNumOnlineRaidMembers = function()
        local num = 0
        if not UnitInRaid('player') then
            return num
        end
        for i = 0, GetNumRaidMembers() do
            if GetRaidRosterInfo(i) then
                local _, _, _, _, _, _, z = GetRaidRosterInfo(i);
                if z ~= 'Offline' then
                    num = num + 1
                end
            end
        end
        return num
    end

    core.getPlayerClass = function(name)
        if not name then
            name = core.me
        end
        if db['PLAYER_CLASS_CACHE'][name] then
            return db['PLAYER_CLASS_CACHE'][name]
        end
        for i = 0, GetNumRaidMembers() do
            if GetRaidRosterInfo(i) then
                local n = GetRaidRosterInfo(i);
                if name == n then
                    local _, unitClass = UnitClass('raid' .. i) --standard
                    db['PLAYER_CLASS_CACHE'][name] = core.lower(unitClass)
                    return core.lower(unitClass)
                end
            end
        end
        return 'priest'
    end

    core.syncRoster = function(prio)
        if not core.isRaidLeader() then
            return
        end

        local officers = ''
        for _, name in next, db['VOTE_ROSTER'] do
            officers = officers .. '=' .. name
        end
        if officers == '' then
            --no officers to send
            return
        end

        core.bsend(prio or "ALERT", "SyncRoster" .. officers)

        TalcVoteFrameRLWindowFrameTab1ContentsOfficer:SetText('Officer(' .. core.n(db['VOTE_ROSTER']) .. ')')
    end

    core.addToRoster = function(newName, checkbox)
        if not core.isRaidLeader() then
            talc_print('You are not the raid leader.')
            return
        end

        if core.n(db['VOTE_ROSTER']) == core.maxOfficers then
            talc_print("You can have a maximum of " .. core.maxOfficers .. " Officers.")
            checkbox:SetChecked(false)
            return
        end

        for _, name in next, db['VOTE_ROSTER'] do
            if name == newName then
                talc_print(core.classColors[core.getPlayerClass(newName)].colorStr .. newName .. ' |ralready exists.')
                return
            end
        end
        core.insert(db['VOTE_ROSTER'], newName)
        talc_print(core.classColors[core.getPlayerClass(newName)].colorStr .. newName .. ' |radded to TALC Roster')
        core.syncRoster()
    end

    core.remFromRoster = function(newName)
        if not core.isRaidLeader() then
            talc_print('You are not the raid leader.')
            return
        end
        for index, name in next, db['VOTE_ROSTER'] do
            if name == newName then
                db['VOTE_ROSTER'][index] = nil
                talc_print(core.classColors[core.getPlayerClass(newName)].colorStr .. newName .. ' |rremoved from TALC Roster')
                core.syncRoster()
                return
            end
        end
        talc_print(core.classColors[core.getPlayerClass(newName)].colorStr .. newName .. ' |rdoes not exist in the roster.')
    end

    core.SecondsToClock = function(seconds)
        seconds = core.int(seconds)

        if seconds <= 0 then
            return "00:00";
        else
            local hours = core.int(core.format("%02.f", core.floor(seconds / 3600)))
            local mins = core.format("%02.f", core.floor(seconds / 60 - (hours * 60)))
            local secs = core.format("%02.f", core.floor(seconds - hours * 3600 - mins * 60))
            if hours > 0 then
                return hours .. "h"
            end
            if core.int(mins) > 0 and secs == '00' then
                return mins .. "m"
            end
            return mins .. ":" .. secs
        end
    end

    core.CacheItem = function(id)

        if not id then
            talc_debug("cache item call with null")
            return
        end

        if not core.int(id) then

            -- try to get id from itemLink
            local itemID = core.split(':', id)
            if itemID[2] and core.int(itemID[2]) then
                core.CacheItem(core.int(itemID[2]))
                return
            end

            talc_debug("cache item call with not int " .. id .. " " .. core.type(id))
            return
        end

        if GetItemInfo(id) then
            -- cache rewards
            if tokenRewards[id] and tokenRewards[id].rewards then
                for _, rewardID in next, tokenRewards[id].rewards do
                    core.CacheItem(rewardID)
                end
            end
        else
            talc_debug(" + " .. id .. " needs cache")
            local item = "item:" .. id .. ":0:0:0"
            local _, _, itemLink = core.find(item, "(item:%d+:%d+:%d+:%d+)");
            GameTooltip:SetHyperlink(itemLink)
        end

    end

    core.clearScrollbarTexture = function(frame)
        _G[frame:GetName() .. 'ScrollUpButton']:SetNormalTexture(nil)
        _G[frame:GetName() .. 'ScrollUpButton']:SetDisabledTexture(nil)
        _G[frame:GetName() .. 'ScrollUpButton']:SetPushedTexture(nil)
        _G[frame:GetName() .. 'ScrollUpButton']:SetHighlightTexture(nil)

        _G[frame:GetName() .. 'ScrollDownButton']:SetNormalTexture(nil)
        _G[frame:GetName() .. 'ScrollDownButton']:SetDisabledTexture(nil)
        _G[frame:GetName() .. 'ScrollDownButton']:SetPushedTexture(nil)
        _G[frame:GetName() .. 'ScrollDownButton']:SetHighlightTexture(nil)

        _G[frame:GetName() .. 'ThumbTexture']:SetTexture(nil)
    end

    core.instanceInfo = function()
        local name, instanceType, difficulty, difficultyName, maxPlayers, playerDifficulty, isDynamicInstance = GetInstanceInfo();

        if instanceType == "party" then
            return false
        end
        local isHeroic = false;
        if instanceType == "raid" and not (difficulty == 1 and maxPlayers == 5) then
            if instanceType == "raid" then
                if isDynamicInstance then
                    isHeroic = playerDifficulty == 1
                elseif difficulty > 2 then
                    isHeroic = true
                end
            end
        else
            return false
        end
        return name, maxPlayers, isHeroic, name .. " " .. maxPlayers .. (isHeroic and '+' or '')
    end

    core.saveAttendance = function(boss)

        if not core.instanceInfo() then
            talc_debug("cant save attendance outside")
            return
        end
        if not boss then
            talc_debug("save attendance not boss")
            return
        end

        local _, _, _, raidString = core.instanceInfo()

        local att = db['ATTENDANCE_DATA']

        for i = 0, GetNumRaidMembers() do
            if GetRaidRosterInfo(i) then
                local n, _, _, _, _, _, z = GetRaidRosterInfo(i);
                if z ~= 'Offline' then

                    if not att[n] then
                        att[n] = {
                            raids = {}
                        }
                    end
                    if not att[n].raids[raidString] then
                        att[n].raids[raidString] = {
                            bosses = {}
                        }
                    end
                    if not att[n].raids[raidString].bosses[boss] then
                        att[n].raids[raidString].bosses[boss] = {
                            dates = {}
                        }
                    end

                    core.insert(att[n].raids[raidString].bosses[boss].dates, core.timeUTC())
                end
            end
        end
    end

    core.getAttendance = function(player)
        local att = db['ATTENDANCE_DATA']
        if not att[player] then
            return {
                points = 0,
                raids = {}
            }
        end

        att[player].points = 0
        for _, raidData in next, att[player].raids do
            raidData.points = 0
            for _, bossData in next, raidData.bosses do
                bossData.kills = #bossData.dates
                raidData.points = raidData.points + bossData.kills
            end
            att[player].points = att[player].points + raidData.points
        end

        return att[player]
    end

    core.byteSum = function(str)
        local sum = 0
        for i = 1, #str do
            sum = sum + core.byte(core.sub(str, i, i))
        end
        return sum
    end

    core.timeUTC = function()
        return time(date("!*t"))
    end

    core.localTimeFromServerTime = function(st)
        -- inspired from ElvUI
        local srvHours, srvMinutes = date("%H", st), date("%M", st)
        local timeLocal = date("!*t", st)
        local timeUTC = date("*t")
        local tzDiffHours = (timeLocal.hour - timeUTC.hour) + (timeUTC.isdst and 1 or 0)
        local tzDiffMinutes = (timeLocal.min - timeUTC.min)
        local tzDiffTotalSeconds = tzDiffHours * 3600 + tzDiffMinutes * 60
        local srvOffsetHours = srvHours - timeUTC.hour
        local srvOffsetMinutes = srvMinutes - timeUTC.min
        local srvDiffSecondsUTC = (srvOffsetHours * 3600) + (srvOffsetMinutes * 60)

        return st + srvDiffSecondsUTC - tzDiffTotalSeconds
    end

    core.sortTableBy = function(t, by, dir)
        local a = {}
        if not dir then
            dir = 1
        end
        -- collect timestamps
        for _, d in core.pairs(t) do
            core.insert(a, d[by])
        end
        -- sort timestamps
        core.sort(a, function(a, b)
            if dir == 1 then
                return a > b
            else
                return a < b
            end
        end)
        local i = 0 -- iterator variable
        local iter = function()
            -- iterator function
            i = i + 1
            if a[i] == nil then
                return nil
            else
                -- return record where timestamp is a[i]
                for n, d in core.pairs(t) do
                    if d[by] == a[i] then
                        return n, d
                    end
                end
                return nil
            end
        end
        return iter
    end

    core.sortedLootHistory = function()
        return core.sortTableBy(db['VOTE_LOOT_HISTORY'], 'timestamp')
    end

    core.SaveItemLocation = function(lootText)

        local _, _, _, raidString = core.instanceInfo()
        if not raidString then
            return
        end

        local _, _, itemLink = core.find(lootText, "(item:%d+:%d+:%d+:%d+)");
        if itemLink then

            local _, _, q = GetItemInfo(itemLink)

            if q and q >= 3 then
                local itemID = core.int(core.split(':', itemLink)[2])
                if not db['ITEM_LOCATION_CACHE'][itemID] then
                    db['ITEM_LOCATION_CACHE'][itemID] = raidString
                    talc_debug("saved " .. itemID .. " to " .. raidString)
                end
            end
        end
    end

    core.GetItemLocation = function(itemLinkOrID)
        if db['ITEM_LOCATION_CACHE'][itemLinkOrID] then
            return db['ITEM_LOCATION_CACHE'][itemLinkOrID]
        end

        if not core.int(itemLinkOrID) then
            local _, _, itemLink = core.find(itemLinkOrID, "(item:%d+:%d+:%d+:%d+)");
            local itemID = core.int(core.split(':', itemLink)[2])
            return core.GetItemLocation(itemID)
        end

        return GetZoneText()
    end

    core.SendVersion = function ()
        core.asend("TALCVersion=" .. core.addonVer, "PARTY")
        core.asend("TALCVersion=" .. core.addonVer, "GUILD")
        core.asend("TALCVersion=" .. core.addonVer, "RAID")
        core.asend("TALCVersion=" .. core.addonVer, "BATTLEGROUND")
    end

end

function talc_print(a)
    if a == nil then
        talc_error(time() .. '|r attempt to print a nil value.')
        return
    end
    print("|cff69ccf0[TALC] |r" .. a)
end

function talc_error(a)
    print('|cff69ccf0[TALC Error]|cff0070de:' .. time() .. '|r[' .. a .. ']')
end

function talc_debug(a)
    if not db then
        return
    end
    if not db['_DEBUG'] then
        return
    end
    if core.type(a) == 'boolean' then
        if a then
            talc_print('|cff0070de[DEBUG:' .. core.sub(time(), 5, 20) .. ']|cffffffff[true]')
        else
            talc_print('|cff0070de[DEBUG:' .. core.sub(time(), 5, 20) .. ']|cffffffff[false]')
        end
        return true
    end
    if core.type(a) == 'table' then
        talc_dump(a)
        return
    end
    talc_print('|cff0070de[DEBUG:' .. core.sub(time(), 7, 20) .. ']|cffffffff[' .. a .. ']')
end

function talc_dump(tbl, indent)
    if not indent then
        indent = 0
    end
    for k, v in core.pairs(tbl) do
        local formatting = core.rep("  ", indent) .. k .. ": "
        if core.type(v) == "table" then
            print(formatting)
            talc_dump(v, indent + 1)
        elseif core.type(v) == 'boolean' then
            print(formatting .. core.tostring(v))
        else
            print(formatting .. v)
        end
    end
end