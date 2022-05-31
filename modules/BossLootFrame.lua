local db, core
local _G = _G

BossLootFrame = CreateFrame("Frame")
BossLootFrame.sendItems = true
----------------------------------------------------
--- Event Handler
----------------------------------------------------

function BossLootFrame:HandleSync(_, msg, _, sender)
    if core.subFind(msg, 'BossLootFrame=') then

        if sender ~= core.me then
            self.sendItems = false
        end

        local lootEx = core.split('=', msg)

        if lootEx[2] == 'Reset' then
            self:ResetVars()
        elseif lootEx[2] == 'Start' then
            self.animation.itemFrames = {}
        elseif lootEx[2] == 'End' then
            if TALC_DB['BOSS_LOOT_FRAME_ENABLE'] then
                self:ShowLoot()
            end
        else
            core.insert(self.animation.itemFrames, {
                frameRef = nil,
                name = '',
                frame = 0, glowX = 0,
                link = lootEx[3],
                r = 0, g = 0, b = 0
            })
        end
    end
end

function BossLootFrame:Init()

    core = TALC
    db = TALC_DB

    TalcBossLootFrame:Hide()
end

function BossLootFrame:ResetVars()
    self.sendItems = true
end

function BossLootFrame:ShowLoot()

    -- check if everything is cached
    for _, frame in next, self.animation.itemFrames do
        local itemID = core.split(":", frame.link)[2]
        if not GetItemInfo(itemID) then
            talc_debug("bosslootframe item need cache")
            core.CacheItem(itemID);
            self.delayAddBossLoot:Show()
            return
        end
    end

    TalcBossLootFrame:Show()

    for index, frame in next, self.animation.itemFrames do

        if not _G['TalcBossLootFrameItem' .. index] then
            frame.frameRef = CreateFrame("Frame", "TalcBossLootFrameItem" .. index, TalcBossLootFrame, "Talc_BossLootItemTemplate")
        end

        frame.name = "TalcBossLootFrameItem" .. index

        frame.frame = 0
        frame.glowX = 0

        local name, _, quality, _, _, _, _, _, _, tex = GetItemInfo(frame.link)

        frame.r = ITEM_QUALITY_COLORS[quality].r
        frame.g = ITEM_QUALITY_COLORS[quality].g
        frame.b = ITEM_QUALITY_COLORS[quality].b

        core.addButtonOnEnterTooltip(_G[frame.name .. 'Button'], frame.link, nil, true)

        _G[frame.name .. 'ButtonName']:SetAlpha(0)
        _G[frame.name .. 'ButtonName']:SetText(ITEM_QUALITY_COLORS[quality].hex .. name)
        _G[frame.name .. 'ButtonTexture']:SetAlpha(0)
        _G[frame.name .. 'ButtonTexture']:SetTexture(tex)
        _G[frame.name .. 'ButtonBorder']:SetVertexColor(frame.r, frame.g, frame.b, 0)

        _G[frame.name .. 'WhiteGlow']:SetAlpha(0)
        _G[frame.name .. 'WhiteGlow']:Show(0)
        _G[frame.name .. 'WhiteGlow']:SetSize(20, 20)
        _G[frame.name .. 'WhiteGlow']:SetPoint('CENTER', 0, 0)
        _G[frame.name]:SetBackdropColor(1, 0, 0, 0)
        _G[frame.name]:SetPoint('TOP', 0, -30 - (index) * 42)
        _G[frame.name]:Show()
    end

    TalcBossLootFrame:SetAlpha(1)

    TalcBossLootFrameTop:SetAlpha(0)
    TalcBossLootFrameTopGlyph:SetAlpha(0)
    TalcBossLootFrameMiddle:SetAlpha(0)
    TalcBossLootFrameMiddle:SetHeight(1)
    TalcBossLootFrameBottom:SetAlpha(0)
    TalcBossLootFrameBottomGlyph:SetAlpha(0)

    self.animation.middleHeight = 22 + 40 * #self.animation.itemFrames
    self.animation.frame = 0
    self.animation:Show()
end

BossLootFrame.animation = CreateFrame("Frame")
BossLootFrame.animation:Hide()
BossLootFrame.animation:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
BossLootFrame.animation.middleHeight = 1
BossLootFrame.animation.frame = 0
BossLootFrame.animation.itemFrames = {}

BossLootFrame.animation:SetScript("OnUpdate", function()

    if this.frame >= 0 and this.frame <= 30 then

        if TalcBossLootFrameTopGlyph:GetAlpha() < 1 then
            TalcBossLootFrameTopGlyph:SetAlpha(this.frame / 30)
        end

        if TalcBossLootFrameTop:GetAlpha() < 1 then
            TalcBossLootFrameTop:SetAlpha(this.frame / 30)
            TalcBossLootFrameBottom:SetAlpha(this.frame / 30)
            TalcBossLootFrameMiddle:SetAlpha(this.frame / 30)
        end

    end

    if TalcBossLootFrameMiddle:GetHeight() < this.middleHeight then
        TalcBossLootFrameMiddle:SetHeight(TalcBossLootFrameMiddle:GetHeight() + 2)
    end

    for index, frame in next, this.itemFrames do

        if this.frame > 5 + (index * 30) then

            if _G[frame.name .. 'WhiteGlow']:GetAlpha() < 1 then
                _G[frame.name .. 'WhiteGlow']:SetAlpha(_G[frame.name .. 'WhiteGlow']:GetAlpha() + 0.2)
            end

            if _G[frame.name .. 'WhiteGlow']:GetWidth() < 40 then
                _G[frame.name .. 'WhiteGlow']:SetSize(_G[frame.name .. 'WhiteGlow']:GetWidth() + 1.5,
                        _G[frame.name .. 'WhiteGlow']:GetWidth() + 1.5)
            else
                if frame.glowX > -100 then
                    frame.glowX = frame.glowX - 3
                    _G[frame.name .. 'WhiteGlow']:SetPoint('CENTER', frame.glowX, 0)

                    _G[frame.name]:SetBackdropColor(frame.r, frame.g, frame.b, (frame.glowX * -1) / 300)
                else

                    if _G[frame.name .. 'ButtonTexture']:GetAlpha() < 1 then
                        _G[frame.name .. 'ButtonTexture']:SetAlpha(_G[frame.name .. 'ButtonTexture']:GetAlpha() + 0.1)

                        _G[frame.name .. 'ButtonBorder']:SetAlpha(_G[frame.name .. 'ButtonTexture']:GetAlpha())
                        _G[frame.name .. 'ButtonName']:SetAlpha(_G[frame.name .. 'ButtonTexture']:GetAlpha())
                    else
                        _G[frame.name .. 'WhiteGlow']:Hide()
                    end
                end
            end

            frame.frame = frame.frame + 1

        end

    end

    this.frame = this.frame + 1

    if this.frame >= 1100 and this.frame < 1200 then
        TalcBossLootFrame:SetAlpha(TalcBossLootFrame:GetAlpha() - 0.02)
    end

    if this.frame >= 1200 then
        TalcBossLootFrame:Hide()
        this:Hide()
        return
    end

    this.startTime = GetTime()

end)

----------------------------------------------------
--- Delay/Cache Add
----------------------------------------------------

BossLootFrame.delayAddBossLoot = CreateFrame("Frame")
BossLootFrame.delayAddBossLoot:Hide()
BossLootFrame.delayAddBossLoot:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
BossLootFrame.delayAddBossLoot:SetScript("OnUpdate", function()
    local plus = 0.3
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this:Hide()
        BossLootFrame:ShowLoot()
    end
end)

----------------------------------------------------
--- Test
----------------------------------------------------

function BossLootFrame:StartTestAnimation()
    self.animation.itemFrames = {}

    local items = {
        'item:54582:0:0:0:0:0:0:0:0',
        'item:51484:0:0:0:0:0:0:0:0',
        'item:51205:0:0:0:0:0:0:0:0'
    }
    for _, item in next, items do
        core.insert(self.animation.itemFrames, {
            frameRef = nil,
            name = '',
            frame = 0, glowX = 0,
            link = item,
            r = 0, g = 0, b = 0
        })

    end

    self:ShowLoot()
end