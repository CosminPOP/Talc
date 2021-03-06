local db, core
local _G = _G

RollFrame = CreateFrame("Frame")

----------------------------------------------------
--- Vars
----------------------------------------------------

RollFrame.watchRolls = false
RollFrame.id = 0
RollFrame.rolled = false

----------------------------------------------------
--- Event Handler
----------------------------------------------------

function RollFrame:HandleSync(_, msg, _, sender)
    if core.isRaidLeader(sender) then
        if core.subFind(msg, 'RollFor=') then
            local rfEx = core.split('=', msg)
            if rfEx[6] then
                if rfEx[6] == core.me then
                    self:AddRolledItem(msg)
                    if not TalcRollFrame:IsVisible() then
                        TalcRollFrame:Show()
                    end
                    self.watchRolls = true
                    self.rolled = false
                end
            end
            return
        end

        if core.subFind(msg, 'RollFrame=') then
            local command = core.split('=', msg)
            if command[2] == "Reset" then
                self:ResetVars()
            end
            return
        end

        if core.subFind(msg, 'PlayerWon=') and self.watchRolls then
            if not core.isRaidLeader(sender) then
                return
            end

            local wonData = core.split("=", msg)

            if not wonData[7] then
                talc_error('bad playerWon syntax rollframe')
                talc_error(msg)
                return false
            end

            if wonData[3] ~= core.me and db['ROLL_TROMBONE'] and db['ROLL_ENABLE_SOUND'] then
                PlaySoundFile("Interface\\AddOns\\Talc\\sound\\sadtrombone.ogg")
            end
            self.watchRolls = false
            return
        end
    end
end

----------------------------------------------------
--- Init
----------------------------------------------------

function RollFrame:Init()

    core = TALC
    db = TALC_DB

    self:ResetVars()
end

function RollFrame:ResetVars()
    TalcRollFrame:Hide()
    self:HideAnchor()
    self.watchRolls = false
    self.rolled = false
end

function RollFrame:ShowAnchor()
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

function RollFrame:HideAnchor()
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

function RollFrame:AddRolledItem(data)
    local item = core.split("=", data)
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

    if quality > 5 then
        return
    end

    self.id = index
    TalcRollFrameItem.elapsed = 0

    TalcRollFrameItemButton:SetNormalTexture(texture);
    TalcRollFrameItemButton:SetPushedTexture(texture);
    TalcRollFrameItemButtonName:SetText(link);

    TalcRollFrameItemButtonQuality2:Hide()
    TalcRollFrameItemButtonQuality3:Hide()
    TalcRollFrameItemButtonQuality4:Hide()
    TalcRollFrameItemButtonQuality5:Hide()

    if quality < 2 then
        TalcRollFrameItemButtonQuality2:Show()
        SetDesaturation(TalcRollFrameItemButtonQuality2, 1)
    else
        _G['TalcRollFrameItemButtonQuality' .. quality]:Show()
    end

    core.addButtonOnEnterTooltip(TalcRollFrameItemButton, link, nil, true)

    RollFrame:FadeInFrame()
end

function RollFrame:FadeInFrame()

    if db['ROLL_ENABLE_SOUND'] then
        PlaySoundFile("Interface\\AddOns\\Talc\\sound\\please_roll_" .. db['ROLL_VOLUME'] .. ".ogg");
    end

    TalcRollFrameItem:Show();
    TalcRollFrameItem.animIn:Stop();
    TalcRollFrameItem.animIn.animIn:SetStartDelay(0);
    TalcRollFrameItem.animIn:Play();

    TalcRollFrameItem.glow.animIn:Stop();
    TalcRollFrameItem.glow.animIn.animIn:SetStartDelay(0);
    TalcRollFrameItem.glow.animIn:Play();

    TalcRollFrameItem.star.animIn:Stop();
    TalcRollFrameItem.star.animIn.animIn:SetStartDelay(0);
    TalcRollFrameItem.star.animIn:Play();

    TalcRollFrameItem.shine.animIn:Stop();
    TalcRollFrameItem.shine.animIn.animIn:SetStartDelay(0);
    TalcRollFrameItem.shine.animIn:Play();

    TalcRollFrameItemButton.fadeIn.animIn:Stop();
    TalcRollFrameItemButton.fadeIn.animIn.animIn:SetStartDelay(0.2);
    TalcRollFrameItemButton.fadeIn.animIn:Play();

    TalcRollFrameItemButton.glow.animIn:Stop();
    TalcRollFrameItemButton.glow.animIn.animIn:SetStartDelay(0.2);
    TalcRollFrameItemButton.glow.animIn:Play();

    TalcRollFrameItemButton.qualityBorder.animIn:Stop();
    TalcRollFrameItemButton.qualityBorder.animIn.animIn:SetStartDelay(0.2);
    TalcRollFrameItemButton.qualityBorder.animIn:Play();

    TalcRollFrameItemRoll.fadeIn.animIn:Stop();
    TalcRollFrameItemRoll.fadeIn.animIn.animIn:SetStartDelay(1);
    TalcRollFrameItemRoll.fadeIn.animIn:Play();

    TalcRollFrameItemPass.fadeIn.animIn:Stop();
    TalcRollFrameItemPass.fadeIn.animIn.animIn:SetStartDelay(1.2);
    TalcRollFrameItemPass.fadeIn.animIn:Play();
end

function RollFrame:FadeInFinished()
    TalcRollFrameItem.timeleft.countdown:Stop();
    TalcRollFrameItem.timeleft.countdown.animIn:SetStartDelay(0);
    TalcRollFrameItem.timeleft.countdown.countdown:SetStartDelay(0);
    TalcRollFrameItem.timeleft.countdown.countdown:SetDuration(db['VOTE_TTR'] - 1);
    TalcRollFrameItem.timeleft.countdown:Play();
end

function RollFrame:CountdownFinished()
    RollFrame:FadeOutFrame()
end

function RollFrame:UpdateCountdown()
    local frame = this:GetRegionParent():GetParent()
    frame.elapsed = frame.elapsed + core.int(arg1)
    TalcRollFrameItemButtonInfo:SetText("Roll or Pass (".. core.floor(db['VOTE_TTR'] - frame.elapsed) .."s)")
end

function RollFrame:FadeOutFrame()
    TalcRollFrameItem.animOut:Stop();
    TalcRollFrameItem.animOut.animOut:SetStartDelay(0);
    TalcRollFrameItem.animOut:Play();

    --TalcRollFrameItemButton.qualityBorder.animOut:Stop();
    --TalcRollFrameItemButton.qualityBorder.animOut.animOut:SetStartDelay(0);
    --TalcRollFrameItemButton.qualityBorder.animOut:Play();
end

function RollFrame:FadeOutFinished()
    TalcRollFrameItem:Hide()
    if not self.rolled then
        self:PickRoll('roll')
    end
end

function RollFrame:PickRoll(roll)

    if self.id and self.id == 0 then
        self:FadeOutFrame()
        return
    end

    if roll == 'pass' then
        core.asend("RollChoice=" .. self.id .. "=-1")
    elseif roll == 'roll' then
        RandomRoll(1, 100)
    end

    self.rolled = true

    self:FadeOutFrame()
end

----------------------------------------------------
--- Delay/Cache Add
----------------------------------------------------

RollFrame.delayAddItem = CreateFrame("Frame")
RollFrame.delayAddItem:Hide()
RollFrame.delayAddItem:SetScript("OnShow", function()
    this.startTime = GetTime();
end)
RollFrame.delayAddItem:SetScript("OnUpdate", function()
    local gt = GetTime() * 1000
    local st = (this.startTime + 0.5) * 1000
    if gt >= st then
        talc_debug('delay  add item on update')
        RollFrame:AddRolledItem(data)
        this:Hide()
    end
end)


----------------------------------------------------
--- Test
----------------------------------------------------

function RollFrame:Test()

    local linkString = '|cffa335ee|Hitem:19364:0:0:0:0:0:0:0:0|h[Ashkandi, Greatsword of the Brotherhood]|h|r'
    local _, _, itemLink = core.find(linkString, "(item:%d+:%d+:%d+:%d+)");
    local name, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemLink)

    if name and tex then
        self:AddRolledItem('rollFor=0=' .. tex .. '=' .. name .. '=' .. linkString .. '=30=' .. core.me)
        if not TalcRollFrame:IsVisible() then
            TalcRollFrame:Show()
        end
    else
        talc_debug("needs cache")
        GameTooltip:SetHyperlink(itemLink)
        GameTooltip:Hide()
    end
end