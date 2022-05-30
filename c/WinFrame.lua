local db, core
local _G = _G

WinFrame = CreateFrame("Frame")

----------------------------------------------------
--- Vars
----------------------------------------------------

WinFrame.items = {}
WinFrame.xmog = false

----------------------------------------------------
--- Event Handler
----------------------------------------------------

function WinFrame:HandleSync(_, msg, _, sender)
    if core.find(msg, 'PlayerWon=') and core.isRaidLeader(sender) then
        local wonData = core.split('=', msg)
        if wonData[7] and wonData[3] == core.me then

            local _, _, itemLink = core.find(wonData[4], "(item:%d+:%d+:%d+:%d+)");
            local name = GetItemInfo(itemLink)

            for index, item in next, db['NEED_WISHLIST'] do
                if item == wonData[4] or item == name then
                    VoteFrame:RemoveFromWishlist(index)
                    break
                end
            end
            self.xmog = wonData[6] == 'xmog'
        end
    end
end

function WinFrame:HandleLoot(arg1)
    if core.find(arg1, 'You receive loot', 1, true) then
        local recEx = core.split(' loot:', arg1)
        if recEx[1] then
            self:AddWonItem(recEx[2], recEx[1])
        end
        return
    end
    if core.find(arg1, 'You create', 1, true) then
        local recEx = core.split(' create:', arg1)
        if recEx[1] then
            self:AddWonItem(recEx[2], recEx[1])
        end
        return
    end
end

----------------------------------------------------
--- Init
----------------------------------------------------

function WinFrame:Init()
    core = TALC
    db = TALC_DB
    self:HideAnchor()
end

function WinFrame:AddWonItem(linkString, winText)

    local _, _, itemLink = core.find(linkString, "(item:%d+:%d+:%d+:%d+)");

    GameTooltip:SetHyperlink(itemLink)
    GameTooltip:Hide()

    local name, _, quality, _, _, _, _, _, _, tex = GetItemInfo(itemLink)

    if not name or not quality then
        self.delayAddWonItem.data[linkString] = winText
        self.delayAddWonItem:Show()
        return false
    end

    if quality < 2 or quality > 5 then
        return
    end

    if  not core.find(db['WIN_THRESHOLD'], quality, 1, true) then
        return false
    end

    local index = 0
    for i, frame in next, self.items do
        if not frame.active then
            index = i
            break
        end
    end

    if index == 0 then
        index = core.n(self.items) + 1
    end

    if not self.items[index] then
        self.items[index] = CreateFrame("Frame", "TALCWinFrame" .. index, TalcWinFrame, "Talc_WinFrameItemTemplate")
    end

    local frame = "TALCWinFrame" .. index

    _G[frame]:SetPoint("TOP", TalcWinFrame, "TOP", 0, (20 + 100 * index))
    _G[frame]:SetID(index)
    _G[frame].active = true
    _G[frame].xmog = self.xmog
    self.xmog = false

    _G[frame .. 'BackgroundLow']:Hide()
    _G[frame .. 'BackgroundHigh']:Hide()
    _G[frame .. 'BackgroundXmog']:Hide()

    if _G[frame].xmog then
        _G[frame .. 'BackgroundXmog']:Show()
    else
        if quality <= 3 then
            _G[frame .. 'BackgroundLow']:Show()
        else
            _G[frame .. 'BackgroundHigh']:Show()
        end
    end

    _G[frame .. 'ItemQuality2']:Hide()
    _G[frame .. 'ItemQuality3']:Hide()
    _G[frame .. 'ItemQuality4']:Hide()
    _G[frame .. 'ItemQuality5']:Hide()

    _G[frame .. 'ItemQuality' .. quality]:Show()

    _G[frame .. 'Item']:SetNormalTexture(tex)
    _G[frame .. 'Item']:SetPushedTexture(tex)
    _G[frame .. 'ItemWay']:SetText(winText)
    _G[frame .. 'ItemName']:SetText(ITEM_QUALITY_COLORS[quality].hex .. name)


    local ex = core.split("|", linkString)

    if ex[3] then
        core.addButtonOnEnterTooltip(_G[frame .. 'Item'], core.sub(ex[3], 2, core.len(ex[3])), nil, true)
    else
        talc_debug('wrong itemlink ?')
    end

    WinFrame:FadeInFrame(_G[frame])
end

function WinFrame:ShowAnchor()
    TalcWinFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        tile = true,
    })
    TalcWinFrame:EnableMouse(true)
    TalcWinFrameTitle:Show()
    TalcWinFrameTestButton:Show()
    TalcWinFrameCloseButton:Show()
end

function WinFrame:HideAnchor()
    TalcWinFrame:SetBackdrop({
        bgFile = "",
        tile = true,
    })
    TalcWinFrame:EnableMouse(false)
    TalcWinFrameTitle:Hide()
    TalcWinFrameTestButton:Hide()
    TalcWinFrameCloseButton:Hide()
end

function NeedFrame:AnimInFinished()
    local frame = this:GetRegionParent()
    frame.animOut:Stop();
    frame.animOut.animOut:SetStartDelay(7);
    frame.animOut:Play();

end

function WinFrame:AnimOutFinished()
    this:GetRegionParent():Hide()
    this:GetRegionParent().active = false
end

function WinFrame:FadeInFrame(frame)

    local button = _G[frame:GetName() .. 'Item']

    frame:Show();
    frame.animIn:Stop();
    frame.animIn.animIn:SetStartDelay(frame:GetID() * 0.2);
    frame.animIn:Play();

    button.glow.animIn:Stop();
    button.glow.animIn.animIn:SetStartDelay(frame:GetID() * 0.2);
    button.glow.animIn:Play();

    frame.glow.animIn:Stop();
    frame.glow.animIn.animIn:SetStartDelay(frame:GetID() * 0.2);
    frame.glow.animIn:Play();

    frame.shine.animIn:Stop();
    frame.shine.animIn.animIn:SetStartDelay(frame:GetID() * 0.2);
    frame.shine.animIn:Play();

    if db['WIN_ENABLE_SOUND'] then
        PlaySoundFile("Interface\\AddOns\\Talc\\sound\\win_" .. db['WIN_VOLUME'] .. ".ogg");
    end
end

function WinFrame:AddTestItems()
    WinFrame:AddWonItem('\124cff0070dd\124Hitem:37220:0:0:0:0:0:0:0:0\124h[Essence of Gossamer]\124h\124r', 'You receive')
    WinFrame:AddWonItem('\124cffa335ee\124Hitem:45074:0:0:0:0:0:0:0:0\124h[Claymore of the Prophet]\124h\124r', 'You receive')
    WinFrame:AddWonItem('|cffff8000|Hitem:46017:0:0:0:0:0:0:0:0|h[Val\'anyr, Hammer of Ancient Kings]|h|4r"', 'You create')
end

----------------------------------------------------
--- Delay/Cache Add
----------------------------------------------------

WinFrame.delayAddWonItem = CreateFrame("Frame")
WinFrame.delayAddWonItem:Hide()
WinFrame.delayAddWonItem.data = {}
WinFrame.delayAddWonItem:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
WinFrame.delayAddWonItem:SetScript("OnUpdate", function()
    local plus = 0.3
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then

        local atLeastOne = false
        for id, data in next, this.data do
            if this.data[id] then
                atLeastOne = true
                WinFrame:addWonItem(id, data)
                this.data[id] = nil
            end
        end

        if not atLeastOne then
            this:Hide()
        end
    end
end)
