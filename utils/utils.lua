local core, db, tokenRewards
local _G = _G

Talc_Utils = CreateFrame("Frame")

function Talc_Utils:init()
    core = TALC
    db = TALC_DB
    tokenRewards = TALC_TOKENS

    core.type = type
    core.floor = math.floor
    core.ceil = math.ceil
    core.max = math.max
    core.rep = string.rep
    core.sub = string.sub
    core.int = tonumber
    core.lower = string.lower
    core.upper = string.upper
    core.find = string.find
    core.format = string.format
    core.string = tostring
    core.len = string.len
    core.gsub = string.gsub
    core.pairs = pairs
    core.sort = table.sort
    core.insert = table.insert

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

    core.wsend = function(prio, msg, to)
        ChatThrottleLib:SendAddonMessage(prio, core.channel, msg, "WHISPER", to)
    end

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

    core.ucFirst = function(str)
        return core.upper(core.sub(str, 1, 1)) .. core.sub(str, 2, core.len(str))
    end

    core.fixClassColorsInStr = function(str)
        for class, data in next, core.classColors do
            if core.find(str, class, 1, true) then
                local cEx = core.split(class, str)
                str = cEx[1] .. data.colorStr .. class .. '|r' .. cEx[2]
            end

            if core.find(str, core.ucFirst(class), 1, true) then
                local cEx = core.split(core.ucFirst(class), str)
                str = cEx[1] .. data.colorStr .. core.ucFirst(class) .. '|r' .. cEx[2]
            end
        end
        return str
    end

    core.needs = {
        ["bis"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = ITEM_QUALITY_COLORS[4].hex, text = 'BIS' },
        ["ms"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = ITEM_QUALITY_COLORS[3].hex, text = 'Main Spec' },
        ["os"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = ITEM_QUALITY_COLORS[2].hex, text = 'Offspec' },
        ["xmog"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = ITEM_QUALITY_COLORS[6].hex, text = 'Transmog' },
        ["pass"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = ITEM_QUALITY_COLORS[1].hex, text = 'pass' },
        ["autopass"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = ITEM_QUALITY_COLORS[0].hex, text = 'auto pass' },
        ["wait"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = ITEM_QUALITY_COLORS[1].hex, text = 'Waiting pick...' },
    }

    core.equipSlotsDetails = {
        ["INVTYPE_HEAD"] = { slot = "Head", id = 1 },
        ["INVTYPE_NECK"] = { slot = "Neck", id = 2 },
        ["INVTYPE_SHOULDER"] = { slot = "Shoulder", id = 3 },
        ["INVTYPE_BODY"] = { slot = "Shirt", id = 4 },
        ["INVTYPE_CHEST"] = { slot = "Chest", id = 5 },
        ["INVTYPE_ROBE"] = { slot = "Chest", id = 5 },
        ["INVTYPE_WAIST"] = { slot = "Waist", id = 6 },
        ["INVTYPE_LEGS"] = { slot = "Legs", id = 7 },
        ["INVTYPE_FEET"] = { slot = "Feet", id = 8 },
        ["INVTYPE_WRIST"] = { slot = "Wrist", id = 9 },
        ["INVTYPE_HAND"] = { slot = "Hands", id = 10 },

        ["INVTYPE_FINGER0"] = { slot = "Finger0", id = 11 },
        ["INVTYPE_FINGER1"] = { slot = "Finger1", id = 12 },

        ["INVTYPE_TRINKET0"] = { slot = "Trinket0", id = 13 },
        ["INVTYPE_TRINKET1"] = { slot = "Trinket1", id = 14 },

        ["INVTYPE_CLOAK"] = { slot = "Back", id = 15 },

        ["INVTYPE_2HWEAPON"] = { slot = "MainHand", id = 16 },
        ["INVTYPE_WEAPONMAINHAND"] = { slot = "MainHand", id = 16 },
        ["INVTYPE_WEAPON0"] = { slot = "MainHand", id = 16 },

        ["INVTYPE_WEAPON1"] = { slot = "SecondaryHand", id = 17 },
        ["INVTYPE_SHIELD"] = { slot = "SecondaryHand", id = 17 },
        ["INVTYPE_WEAPONOFFHAND"] = { slot = "SecondaryHand", id = 17 },
        ["INVTYPE_HOLDABLE"] = { slot = "SecondaryHand", id = 17 },

        ["INVTYPE_RANGED"] = { slot = "Ranged", id = 18 },
        ["INVTYPE_THROWN"] = { slot = "Ranged", id = 18 },
        ["INVTYPE_RANGEDRIGHT"] = { slot = "Ranged", id = 18 },
        ["INVTYPE_RELIC"] = { slot = "Ranged", id = 18 },
        ["INVTYPE_TABARD"] = { slot = "Tabard", id = 19 },
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

    core.getEquipSlot = function(j)
        for k, v in next, core.equipSlots do
            if k == core.string(j) then
                return v
            end
        end
        return ''
    end

    core.trim = function(s)
        return core.gsub(s, "^%s*(.-)%s*$", "%1")
    end

    core.pairsByKeys = function(t)
        local a = {}
        for n in core.pairs(t) do
            core.insert(a, n)
        end
        core.sort(a, function(a, b)
            return a < b
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
                    GameTooltip:AddLine('-------AWARD HISTORY --------')
                    local _, _, il = core.find(itemLink, "(item:%d+:%d+:%d+:%d+)");
                    local name = GetItemInfo(il)
                    for lootTime, item in core.pairsByKeysReverse(db['VOTE_LOOT_HISTORY']) do
                        if core.find(core.lower(item['item']), core.lower(name)) then
                            GameTooltip:AddLine('|r' .. date("%d/%m", lootTime) .. " " .. core.classColors[core.getPlayerClass(item['player'])].colorStr .. item['player'])
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
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT", (this:GetWidth() ), -(this:GetHeight() / 4));
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

    core.isCL = function(name)
        if not name then
            name = core.me
        end
        return db['VOTE_ROSTER'][name] ~= nil
    end

    core.isRL = function(name)
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

    core.isAssist = function(name)
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

    core.isRLorAssist = function(name)
        if not name then
            name = core.me
        end
        return core.isAssist(name) or core.isRL(name)
    end

    core.canVote = function(name)
        if not name then
            name = core.me
        end
        if not core.isRLorAssist(name) then
            return false
        end
        if not core.isCL(name) then
            return false
        end
        return true
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

    core.syncRoster = function()
        local index = 0
        core.bsend("BULK", "syncRoster=start")
        for name, _ in next, db['VOTE_ROSTER'] do
            index = index + 1
            core.bsend("BULK", "syncRoster=" .. name)
        end
        core.bsend("BULK", "syncRoster=end")

        TalcVoteFrameRLWindowFrameTab1ContentsOfficer:SetText('Officer(' .. index .. ')')

        if core.isRL(core.me) then
            TalcFrame.RLFrame:CheckAssists()
        end
    end

    core.addToRoster = function(newName)
        if not core.isRL(core.me) then
            talc_print('You are not the raid leader.')
            return
        end
        for name, _ in next, db['VOTE_ROSTER'] do
            if name == newName then
                talc_print(core.classColors[core.getPlayerClass(newName)].colorStr .. newName .. ' |ralready exists.')
                return false
            end
        end
        db['VOTE_ROSTER'][newName] = false
        talc_print(core.classColors[core.getPlayerClass(newName)].colorStr .. newName .. ' |radded to TALC Roster')
        PromoteToAssistant(newName)
        core.syncRoster()
    end

    core.remFromRoster = function(newName)
        if not core.isRL(core.me) then
            talc_print('You are not the raid leader.')
            return
        end
        for name, _ in next, db['VOTE_ROSTER'] do
            if name == newName then
                db['VOTE_ROSTER'][newName] = nil
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

    core.cacheItem = function(id)
        if not id or not core.int(id) then
            talc_debug("cache item call with null or not int " .. id .. " " .. core.type(id))
            return
        end

        if GetItemInfo(id) then
            -- cache rewards
            if tokenRewards[id] and tokenRewards[id].rewards then
                for _, rewardID in next, tokenRewards[id].rewards do
                    core.cacheItem(rewardID)
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

end

function talc_print(a)
    if a == nil then
        talc_error(time() .. '|r attempt to print a nil value.')
        return false
    end
    print("|cff69ccf0[TALC] |r" .. a)
end

function talc_error(a)
    print('|cff69ccf0[TALC Error]|cff0070de:' .. time() .. '|r[' .. a .. ']')
end

function talc_debug(a)
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
        talc_debug("Dumping table:")
        for i, d in next, a do
            talc_debug(i .. ":" ..d)
        end
        return
    end
    talc_print('|cff0070de[DEBUG:' .. core.sub(time(), 7, 20) .. ']|cffffffff[' .. a .. ']')
end
