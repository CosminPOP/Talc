local db, core
local _G = _G

WinFrame = CreateFrame("Frame")

WinFrame.xmog = false

function WinFrame:handleSync(pre, msg, ch, sender)
    if core.find(msg, 'playerWon#') then
        local wonData = core.split('#', msg)
        if wonData[5] then
            if wonData[5] == 'xmog' and wonData[2] == core.me then
                self.xmog = true
            else
                self.xmog = false
            end
        end
    end
end

function WinFrame:handleLoot(arg1)
    --receive
    if core.find(arg1, 'You receive loot', 1, true) then
        local recEx = core.split('loot', arg1)
        if recEx[1] then
            self:addWonItem(recEx[2], recEx[1] .. 'loot:')
        end
    end
    --create
    if core.find(arg1, 'You create', 1, true) then
        local recEx = core.split('create:', arg1)
        if recEx[1] then
            self:addWonItem(recEx[2], recEx[1] .. 'create:')
        end
    end
end

function WinFrame:init()
    core = TALC
    db = TALC_DB

    self.animFrame:hideAnchor()

    local text = ''
    local qualities = {
        [0] = 'Poor',
        [1] = 'Common',
        [2] = 'Uncommon',
        [3] = 'Rare',
        [4] = 'Epic',
        [5] = 'Legendary'
    }
    for i = db['WIN_THRESHOLD'], 5 do
        local _, _, _, color = GetItemQualityColor(i)
        text = text .. color .. qualities[i] .. ' '
    end
    talc_print('TALC WinFrame (v' .. core.addonVer .. ') Loaded. Type |cfffff569/talc |cff69ccf0win |rto show the Anchor window.')
    talc_print('Type |cfffff569/talc |cff69ccf0win <0-5> |ro change loot window threshold '
            .. '( current threshhold set at ' .. db['WIN_THRESHOLD'] .. ' : ' .. text .. '|r).')
    if db['WIN_ENABLE_SOUND'] then
        talc_print('Win Sound is Enabled(' .. db['WIN_VOLUME'] .. '). Type |cfffff569/talc |cff69ccf0win|cfffff569sound |rto toggle win sound on or off.')
    else
        talc_print('Win Sound is Disabled. Type |cfffff569/alc |cff69ccf0win|cfffff569sound |rto toggle win sound on or off.')
    end
end

function WinFrame:startItemAnimation()
    if db['WIN_ENABLE_SOUND'] then
        PlaySoundFile("Interface\\AddOns\\Talc\\sound\\win_" .. db['WIN_VOLUME'] .. ".ogg");
    end
    if #self.animFrame.wonItems > 0 then
        self.animFrame.showLootWindow = true
    end
    if not self.animFrame:IsVisible() then
        self.animFrame:Show()
    end
end

function WinFrame:addWonItem(linkString, winText)

    local _, _, itemLink = core.find(linkString, "(item:%d+:%d+:%d+:%d+)");

    GameTooltip:SetHyperlink(itemLink)
    GameTooltip:Hide()

    local name, _, quality, _, _, _, _, _, _, tex = GetItemInfo(itemLink)

    if not name or not quality then
        self.delayAddWonItem.data[linkString] = winText
        self.delayAddWonItem:Show()
        return false
    end

    if quality < db['WIN_THRESHOLD'] then
        return false
    end

    local _, _, _, color = GetItemQualityColor(quality)

    local wonIndex = 0
    for i = 1, #self.animFrame.wonItems, 1 do
        if not self.animFrame.wonItems[i].active then
            wonIndex = i
            break
        end
    end

    if wonIndex == 0 then
        wonIndex = #self.animFrame.wonItems + 1
    end

    if not self.animFrame.wonItems[wonIndex] then
        self.animFrame.wonItems[wonIndex] = CreateFrame("Frame", "WinFrame" .. wonIndex, TalcWinFrame, "TalcWonItemTemplate")
    end

    self.animFrame.wonItems[wonIndex]:SetPoint("TOP", TalcWinFrame, "TOP", 0, (20 + 100 * wonIndex))
    self.animFrame.wonItems[wonIndex].active = true
    self.animFrame.wonItems[wonIndex].quality = quality
    self.animFrame.wonItems[wonIndex].frameIndex = 0
    self.animFrame.wonItems[wonIndex].doAnim = true
    self.animFrame.wonItems[wonIndex].xmog = self.xmog
    self.xmog = false

    self.animFrame.wonItems[wonIndex]:SetAlpha(0)
    self.animFrame.wonItems[wonIndex]:Show()


    _G['WinFrame' .. wonIndex .. 'Icon']:SetNormalTexture(tex)
    _G['WinFrame' .. wonIndex .. 'Icon']:SetPushedTexture(tex)
    _G['WinFrame' .. wonIndex .. 'ItemName']:SetText(color .. name)
    _G['WinFrame' .. wonIndex .. 'Title']:SetText(winText)

    local ex = core.split("|", linkString)

    if ex[3] then
        core.addButtonOnEnterTooltip(_G['WinFrame' .. wonIndex .. 'Icon'], core.sub(ex[3], 2, core.len(ex[3])), nil, true)
    else
        talc_Debug('wrong itemlink ?')
    end

    self:startItemAnimation()
end



WinFrame.delayAddWonItem = CreateFrame("Frame")

WinFrame.delayAddWonItem:Hide()
WinFrame.delayAddWonItem.data = {}

WinFrame.delayAddWonItem:SetScript("OnShow", function()
    this.startTime = GetTime()
end)

WinFrame.delayAddWonItem:SetScript("OnUpdate", function()
    local plus = 0.2
    local gt = GetTime() * 1000 --22.123 -> 22123
    local st = (this.startTime + plus) * 1000 -- (22.123 + 0.1) * 1000 =  22.223 * 1000 = 22223
    if gt >= st then

        local atLeastOne = false
        for id, data in next, self.delayAddWonItem.data do
            if self.delayAddWonItem.data[id] then
                atLeastOne = true
                self.addWonItem(id, data)
                self.delayAddWonItem.data[id] = nil
            end
        end

        if not atLeastOne then
            self.delayAddWonItem:Hide()
        end
    end
end)



WinFrame.animFrame = CreateFrame("Frame")

WinFrame.animFrame:Hide()

WinFrame.animFrame.wonItems = {}
WinFrame.animFrame.showLootWindow = false

function WinFrame.animFrame:showAnchor()
    TalcWinFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        tile = true,
    })
    TalcWinFrame:EnableMouse(true)
    TalcWinFrameTitle:Show()
    TalcWinFrameTestPlacement:Show()
    TalcWinFrameClosePlacement:Show()
end

function WinFrame.animFrame:hideAnchor()
    TalcWinFrame:SetBackdrop({
        bgFile = "",
        tile = true,
    })
    TalcWinFrame:EnableMouse(false)
    TalcWinFrameTitle:Hide()
    TalcWinFrameTestPlacement:Hide()
    TalcWinFrameClosePlacement:Hide()
end

WinFrame.animFrame:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
WinFrame.animFrame:SetScript("OnUpdate", function()
    if WinFrame.animFrame.showLootWindow then
        if ((GetTime()) >= (this.startTime) + 0.03) then

            this.startTime = GetTime()

            for i, d in next, WinFrame.animFrame.wonItems do

                if WinFrame.animFrame.wonItems[i].active then

                    local frame = _G['WinFrame' .. i]

                    local quality = WinFrame.animFrame.wonItems[i].quality

                    local image = 'loot_frame_' .. quality .. '_'

                    if quality < 3 then
                        image = 'loot_frame_012_'
                    else
                        image = 'loot_frame_345_'
                    end

                    if WinFrame.animFrame.wonItems[i].xmog then
                        image = 'loot_frame_xmog_'
                        _G['WinFrame' .. i .. 'Title']:Hide()
                        _G['WinFrame' .. i .. 'QualityBorder']:Hide()
                        _G['WinFrame' .. i .. 'Icon']:SetPoint('LEFT', 160, -9)
                        _G['WinFrame' .. i .. 'Icon']:SetWidth(36)
                        _G['WinFrame' .. i .. 'IconNormalTexture']:SetWidth(36)
                        _G['WinFrame' .. i .. 'Icon']:SetHeight(36)
                        _G['WinFrame' .. i .. 'IconNormalTexture']:SetHeight(36)

                    else
                        _G['WinFrame' .. i .. 'Title']:Show()
                        _G['WinFrame' .. i .. 'QualityBorder']:Show()
                        _G['WinFrame' .. i .. 'Icon']:SetPoint('LEFT', 148, 0)
                        _G['WinFrame' .. i .. 'Icon']:SetWidth(46)
                        _G['WinFrame' .. i .. 'IconNormalTexture']:SetWidth(46)
                        _G['WinFrame' .. i .. 'Icon']:SetHeight(46)
                        _G['WinFrame' .. i .. 'IconNormalTexture']:SetHeight(46)
                    end

                    if WinFrame.animFrame.wonItems[i].frameIndex < 10 then
                        image = image .. '0' .. WinFrame.animFrame.wonItems[i].frameIndex
                    else
                        image = image .. WinFrame.animFrame.wonItems[i].frameIndex;
                    end

                    WinFrame.animFrame.wonItems[i].frameIndex = WinFrame.animFrame.wonItems[i].frameIndex + 1

                    _G['WinFrame' .. i .. 'QualityBorder']:SetTexture('Interface\\addons\\Talc\\images\\loot\\' .. quality .. '_large')

                    if WinFrame.animFrame.wonItems[i].doAnim then

                        local backdrop = {
                            bgFile = 'Interface\\AddOns\\Talc\\images\\loot\\' .. image,
                            tile = false
                        }
                        if WinFrame.animFrame.wonItems[i].frameIndex <= 30 then
                            frame:SetBackdrop(backdrop)
                        end
                        frame:SetAlpha(frame:GetAlpha() + 0.03)
                        _G['WinFrame' .. i .. 'Icon']:SetAlpha(frame:GetAlpha() + 0.03)
                    end
                    if WinFrame.animFrame.wonItems[i].frameIndex == 35 then --stop and hold last frame
                        WinFrame.animFrame.wonItems[i].doAnim = false
                    end

                    if WinFrame.animFrame.wonItems[i].frameIndex > 119 then
                        frame:SetAlpha(frame:GetAlpha() - 0.03)
                        _G['WinFrame' .. i .. 'Icon']:SetAlpha(frame:GetAlpha() + 0.03)
                    end
                    if WinFrame.animFrame.wonItems[i].frameIndex == 150 then

                        WinFrame.animFrame.wonItems[i].frameIndex = 0
                        frame:Hide()
                        WinFrame.animFrame.wonItems[i].active = false

                        WinFrame.xmog = false

                    end
                end
            end
        end
    end
end)


function Talc_TestWinFrame()
    WinFrame:addWonItem('|cffa335ee|Hitem:19364:0:0:0:0:0:0:0:0|h[Ashkandi, Greatsword of the Brotherhood]|h|r', 'You Won ! (test message)')
end

function Talc_WinFrameClosePlacement()
    talc_print('Anchor window closed. Type |cfffff569/talc |cff69ccf0win |rto show the Anchor window.')
    WinFrame.animFrame:hideAnchor()
end


