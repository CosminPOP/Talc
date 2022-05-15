local db, core
local _G = _G

RollFrame = CreateFrame("Frame")

RollFrame.watchRolls = false
RollFrame.rolls = {}

function RollFrame:handleSync(pre, msg, ch, sender)
    if core.isRL(sender) then

        if core.find(msg, 'rollFor=', 1, true) then

            local rfEx = core.split('=', msg)
            if rfEx[6] then
                if rfEx[6] == core.me then
                    self.frames:addRolledItem(msg)
                    if not TalcRollFrame:IsVisible() then
                        TalcRollFrame:Show()
                    end
                    self.watchRolls = true
                end
            end
        end

        if core.find(msg, 'rollframe=', 1, true) then
            local command = core.split('=', msg)
            if command[2] == "reset" then
                self:ResetVars()
            end
        end
    end
end

function RollFrame:handleSystem(arg1)
    if not self.watchRolls then return false end

    if core.find(arg1, "rolls", 1, true) and core.find(arg1, "(1-100)", 1, true) then

        local r = core.split(" " , arg1)
        if not r[2] or not r[3] then
            return false
        end

        self.rolls[r[1]] = core.int(r[3])

    end
end

function RollFrame:init()

    core = TALC
    db = TALC_DB

    self:hideAnchor()

    talc_print('RollFrame Loaded. Type |cfffff569/talc |cff69ccf0roll |rto show the Anchor window.')

    if db['ROLL_ENABLE_SOUND'] then
        talc_print('Roll Sound is Enabled(' .. db['ROLL_VOLUME'] .. '). Type |cfffff569/talc |cff69ccf0roll|cfffff569sound |rto toggle win sound on or off.')
    else
        talc_print('Roll Sound is Disabled. Type |cfffff569/talc |cff69ccf0roll|cfffff569sound |rto toggle win sound on or off.')
    end


    if db['ROLL_TROMBONE'] then
        talc_print('Sad Trombone Sound is Enabled. Type |cfffff569/talc |cff69ccf0trombone |rto toggle sad trombone sound on or off.')
    else
        talc_print('Sad Trombone Sound is Disabled. Type |cfffff569/talc |cff69ccf0trombone |rto toggle sad trombone sound on or off.')
    end

    self:ResetVars()
end


function RollFrame:showAnchor()
    TalcRollFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        tile = true,
    })
    TalcRollFrame:Show()
    TalcRollFrame:EnableMouse(true)
    TalcRollFrameTitle:Show()
    TalcRollFrameTestPlacement:Show()
    TalcRollFrameClosePlacement:Show()
end

function RollFrame:hideAnchor()
    TalcRollFrame:SetBackdrop({
        bgFile = "",
        tile = true,
    })
    TalcRollFrame:Hide()
    TalcRollFrame:EnableMouse(false)
    TalcRollFrameTitle:Hide()
    TalcRollFrameTestPlacement:Hide()
    TalcRollFrameClosePlacement:Hide()
end

function RollFrame:fadeInFrame(id)
    if db['ROLL_ENABLE_SOUND'] then
        PlaySoundFile("Interface\\AddOns\\Talc\\sound\\please_roll_" .. db['ROLL_VOLUME'] .. ".ogg");
    end
    RollFrame.fadeInAnimationFrame.ids[id] = true
    RollFrame.fadeInAnimationFrame.frameIndex[id] = 0
    RollFrame.fadeInAnimationFrame:Show()
end

function RollFrame:fadeOutFrame(id)
    RollFrame.fadeOutAnimationFrame.ids[id] = true
    RollFrame.fadeOutAnimationFrame:Show()
end

function RollFrame:ResetVars()

    for index in next, self.frames.itemFrames do
        self.frames.itemFrames[index]:Hide()
    end

    self.frames.freeSpots = {}

    TalcRollFrame:Hide()

    self.countdown:Hide()
    self.countdown.T = 1

    self.fadeInAnimationFrame:Hide()

    self.fadeInAnimationFrame.ids = {}
    self.frames.itemQuality = {}

    self.watchRolls = false
    self.rolls = {}
end


function Talc_RollFrameHideAnchor()
    talc_print('Anchor window closed. Type |cfffff569/talc |cff69ccf0roll |rto show the Anchor window.')
    RollFrame:hideAnchor()
end

RollFrame.countdown = CreateFrame("Frame")

RollFrame.countdown:Hide()
RollFrame.countdown.timeToRoll = 30 --default, will be gotten via addonMessage

RollFrame.countdown.T = 1
RollFrame.countdown.C = RollFrame.countdown.timeToRoll

RollFrame.countdown:SetScript("OnShow", function()
    this.startTime = GetTime();
end)

RollFrame.countdown:SetScript("OnUpdate", function()
    local plus = 0.03
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000

    if gt >= st then
        if this.T ~= this.timeToRoll + plus then

            for index in next, RollFrame.frames.itemFrames do
                if core.floor(this.C - this.T + plus) < 0 then
                    _G['RollFrame' .. index .. 'TimeLeftBarText']:SetText("CLOSED")
                else
                    _G['RollFrame' .. index .. 'TimeLeftBarText']:SetText(core.ceil(this.C - this.T + plus) .. "s")
                end

                _G['RollFrame' .. index .. 'TimeLeftBar']:SetWidth((this.C - this.T + plus) * 190 / this.timeToRoll)
            end
        end
        this:Hide()
        if this.T < this.C + plus then
            --still tick
            this.T = this.T + plus
            this:Show()
        elseif this.T > this.timeToRoll + plus then

            for index in next, RollFrame.frames.itemFrames do
                if RollFrame.frames.itemFrames[index]:IsVisible() then
                    PlayerRollItemButton_OnClick(this:GetID(), 'roll');
                end
            end

            self:Hide()
            this.T = 1

        end
    end
end)

RollFrame.frames = CreateFrame("Frame")
RollFrame.frames.itemFrames = {}
RollFrame.frames.execs = 0
RollFrame.frames.itemQuality = {}


RollFrame.fadeInAnimationFrame = CreateFrame("Frame")
RollFrame.fadeInAnimationFrame:Hide()
RollFrame.fadeInAnimationFrame.ids = {}
RollFrame.fadeInAnimationFrame.frameIndex = {}


RollFrame.fadeInAnimationFrame:SetScript("OnShow", function()
    this.startTime = GetTime()
end)

RollFrame.fadeInAnimationFrame:SetScript("OnShow", function()
    this.startTime = GetTime()
end)

RollFrame.fadeInAnimationFrame:SetScript("OnUpdate", function()
    if ((GetTime()) >= (this.startTime) + 0.03) then

        this.startTime = GetTime()

        local atLeastOne = false
        for id in next, this.ids do
            if this.ids[id] then
                atLeastOne = true
                local frame = _G["RollFrame" .. id]

                local frameNr = this.frameIndex[id]
                if this.frameIndex[id] < 10 then
                    frameNr = '0' .. this.frameIndex[id]
                end

                if this.frameIndex[id] > 30 then
                    frameNr = 30
                end

                frame:SetBackdrop({
                    bgFile = "Interface\\addons\\Talc\\images\\roll\\roll_frame_" .. RollFrame.frames.itemQuality[id] .. "_" .. frameNr,
                    tile = false,
                })

                --fadein
                if this.frameIndex[id] >= 0 and this.frameIndex[id] <= 5 then
                    frame:SetAlpha(this.frameIndex[id] * 0.2)
                end

                --fadeout
                if this.frameIndex[id] >= (RollFrame.countdown.timeToRoll - 1) * 30 and this.frameIndex[id] <= RollFrame.countdown.timeToRoll * 30 then
                    frame:SetAlpha(frame:GetAlpha() - 0.2)
                end

                if this.frameIndex[id] < RollFrame.countdown.timeToRoll * 30 then
                    _G['RollFrame' .. id .. 'TimeLeftBarText']:SetText(core.ceil(RollFrame.countdown.timeToRoll - this.frameIndex[id] / 30) - 1 .. "s")
                    _G['RollFrame' .. id .. 'TimeLeftBar']:SetWidth(core.ceil(RollFrame.countdown.timeToRoll - this.frameIndex[id] / 30 - 1) * 190 / RollFrame.countdown.timeToRoll)
                    this.frameIndex[id] = this.frameIndex[id] + 1
                else
                    if frame:IsVisible() then
                        talc_debug('auto roll because it ended')
                        Talc_RollItemButtonOnClick(id, 'roll');
                    else
                        talc_debug('timer ended and frame is invisible, should not roll')
                    end
                    this.ids[id] = false
                    this.ids[id] = nil


                    if RollFrame.watchRolls == true then --and enabled global var

                        local maxRoll = 0
                        for _, roll in next, RollFrame.rolls do
                            if maxRoll < roll then maxRoll = roll end
                        end

                        talc_debug(' maxroll = ' .. maxRoll)

                        if RollFrame.rolls[core.me] ~= maxRoll and db['ROLL_TROMBONE'] then
                            PlaySoundFile("Interface\\AddOns\\Talc\\sound\\sadtrombone.ogg")
                            RollFrame.watchRolls = false
                        end

                    end

                end
            end
        end
        if not atLeastOne then
            this:Hide()
        end
    end
end)


RollFrame.fadeOutAnimationFrame = CreateFrame("Frame")
RollFrame.fadeOutAnimationFrame:Hide()
RollFrame.fadeOutAnimationFrame.ids = {}

RollFrame.fadeOutAnimationFrame:SetScript("OnShow", function()
    this.startTime = GetTime()
end)

RollFrame.fadeOutAnimationFrame:SetScript("OnUpdate", function()
    if ((GetTime()) >= (this.startTime) + 0.03) then

        this.startTime = GetTime()

        local atLeastOne = false
        for id in next, this.ids do
            if this.ids[id] then
                atLeastOne = true
                local frame = _G["RollFrame" .. id]
                if frame:GetAlpha() > 0 then
                    frame:SetAlpha(frame:GetAlpha() - 0.15)
                else
                    this.ids[id] = false
                    this.ids[id] = nil
                    frame:Hide()
                end
            end
        end
        if not atLeastOne then
            this:Hide()
        end
    end
end)

RollFrame.delayAddItem = CreateFrame("Frame")
RollFrame.delayAddItem:Hide()
RollFrame.delayAddItem.data = {}

RollFrame.delayAddItem:SetScript("OnShow", function()
    this.startTime = GetTime();
end)

RollFrame.delayAddItem:SetScript("OnUpdate", function()
    local plus = 1
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then

        local atLeastOne = false
        for id, data in next, this.data do
            if this.data[id] then
                atLeastOne = true
                talc_debug('delay  add item on update')
                RollFrame.frames:addRolledItem(data)
                this.data[id] = nil
            end
        end

        if not atLeastOne then
            this:Hide()
        end
    end
end)


RollFrame.frames.freeSpots = {}

function RollFrame.frames:firstFree(index)
    for i = 1, #self.freeSpots do
        if self.freeSpots[i] == 0 then
            return i
        end
    end

    self.freeSpots[#self.freeSpots + 1] = index
    return #self.freeSpots
end

function RollFrame.frames:addRolledItem(data)
    local item = core.split("=", data)

    RollFrame.countdown.timeToRoll = db['VOTE_TTR']
    RollFrame.countdown.C = RollFrame.countdown.timeToRoll

    self.execs = self.execs + 1

    local index = core.int(item[2])
    local texture = item[3]
    local link = item[5]

    local _, _, itemLink = core.find(link, "(item:%d+:%d+:%d+:%d+)");

    GameTooltip:SetHyperlink(itemLink)
    GameTooltip:Hide()

    local name, _, quality = GetItemInfo(itemLink)

    if not name or not quality then
        RollFrame.delayAddItem.data[index] = data
        RollFrame.delayAddItem:Show()
        return false
    end

    self.itemQuality[index] = quality
    self.execs = 0

    if self.itemFrames[index] then
        if self.itemFrames[index]:IsVisible() then
            self.itemFrames[index]:Hide()
            self.addRolledItem(data)
            return false
        end
    else
        self.itemFrames[index] = CreateFrame("Frame", "RollFrame" .. index, TalcRollFrame, "Talc_RollFrameItemTemplate")
    end

    self.itemFrames[index]:Show()
    self.itemFrames[index]:SetAlpha(0)

    self.itemFrames[index]:ClearAllPoints()
    if index == 0 then --test button
        self.itemFrames[index]:SetPoint("TOP", TalcRollFrame, "TOP", 0, 40 + (80 * 1))
    else
        self.itemFrames[index]:SetPoint("TOP", TalcRollFrame, "TOP", 0, 40 + (80 * self:firstFree(index)))
    end
    self.itemFrames[index].link = link

    _G['RollFrame' .. index .. 'ItemIcon']:SetNormalTexture(texture);
    _G['RollFrame' .. index .. 'ItemIcon']:SetPushedTexture(texture);
    _G['RollFrame' .. index .. 'ItemIconItemName']:SetText(link);

    _G['RollFrame' .. index .. 'Roll']:SetID(index);
    _G['RollFrame' .. index .. 'Pass']:SetID(index);

    local r, g, b = GetItemQualityColor(quality)

    _G['RollFrame' .. index .. 'TimeLeftBar']:SetBackdropColor(r, g, b, .76)

    core.addButtonOnEnterTooltip(_G['RollFrame' .. index .. 'ItemIcon'], link, nil, true)

    RollFrame:fadeInFrame(index)
end





function Talc_RollFrameTest()

    local linkString = '|cffa335ee|Hitem:19364:0:0:0:0:0:0:0:0|h[Ashkandi, Greatsword of the Brotherhood]|h|r'
    local _, _, itemLink = core.find(linkString, "(item:%d+:%d+:%d+:%d+)");
    local name, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)

    if name and tex then
        RollFrame.frames:addRolledItem('rollFor=0=' .. tex .. '=' .. name .. '=' .. linkString .. '=30=' .. core.me)
        if not TalcRollFrame:IsVisible() then
            TalcRollFrame:Show()
        end
    else
        talc_debug("needs cache")
        GameTooltip:SetHyperlink(itemLink)
        GameTooltip:Hide()
    end
end



function Talc_RollItemButtonOnClick(id, roll)

    for i = 1, #RollFrame.frames.freeSpots do
        if RollFrame.frames.freeSpots[i] == id then
            RollFrame.frames.freeSpots[i] = 0
            break
        end
    end

    if id == 0 then
        RollFrame:fadeOutFrame(id)
        return
    end

    if roll == 'pass' then
        core.asend("rollChoice=" .. id .. "=-1")
    end

    if roll == 'roll' then
        RandomRoll(1, 100)
    end

    RollFrame:fadeOutFrame(id)
end