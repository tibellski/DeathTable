DeathFeedDB = DeathFeedDB or {}

local defaults = {
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = 0,
    width = 180,
    height = 120,
    hidden = false,
    hideOriginalChat = true,
    showKiller = true,
    showZone = true,
    showHeaders = true,
    playGuildSound = true,
    minimumLevel = 10,
    minimap = {
        hide = false
    },
    history = {}
}

copyDefaults(defaults, DeathFeedDB)

window = CreateFrame("Frame", "DeathFeedFrame", UIParent, "BackdropTemplate")
window:SetSize(DeathFeedDB.width, DeathFeedDB.height)

window:SetPoint(
    DeathFeedDB.point,
    UIParent,
    DeathFeedDB.relativePoint,
    DeathFeedDB.x,
    DeathFeedDB.y
)

window:SetMovable(true)
window:SetResizable(true)
window:EnableMouse(true)
window:RegisterForDrag("LeftButton")
window:SetClampedToScreen(true)

function updateResizeBounds()
    local minWidth = 180

    if DeathFeedDB.showKiller and DeathFeedDB.showZone then
        minWidth = 430
    elseif DeathFeedDB.showKiller then
        minWidth = 320
    elseif DeathFeedDB.showZone then
        minWidth = 320
    end

    if window.SetResizeBounds then
        window:SetResizeBounds(minWidth, 120, 650, 500)
    end

    if window:GetWidth() < minWidth then
        window:SetWidth(minWidth)
        DeathFeedDB.width = minWidth
    end
end

window:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

window:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()

    local point, _, relativePoint, x, y = self:GetPoint()

    DeathFeedDB.point = point
    DeathFeedDB.relativePoint = relativePoint
    DeathFeedDB.x = x
    DeathFeedDB.y = y
end)

local resizeHandle = CreateFrame("Button", nil, window)
resizeHandle:SetSize(16, 16)
resizeHandle:SetPoint("BOTTOMRIGHT", 0, 0)
resizeHandle:SetHitRectInsets(-4, -4, -4, -4)

resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

resizeHandle:SetFrameLevel(window:GetFrameLevel() + 50)

resizeHandle:SetScript("OnMouseDown", function()
    window:StartSizing("BOTTOMRIGHT")
end)

resizeHandle:SetScript("OnMouseUp", function()
    window:StopMovingOrSizing()

    DeathFeedDB.width = window:GetWidth()
    DeathFeedDB.height = window:GetHeight()

    updateLayout()
    updateRows(false)
end)

window:SetScript("OnSizeChanged", function()
    DeathFeedDB.width = window:GetWidth()
    DeathFeedDB.height = window:GetHeight()

    updateLayout()
    updateRows(false)
end)

window:SetBackdrop({
    bgFile = "Interface/Buttons/WHITE8x8",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 10,
    insets = {
        left = 3,
        right = 3,
        top = 3,
        bottom = 3
    }
})

window:SetBackdropColor(0.05, 0.05, 0.05, 0.90)
window:SetBackdropBorderColor(0.55, 0.55, 0.55, 1)

local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOPLEFT", 10, -8)
title:SetText("|cffcc4444Death Feed|r")

function getHeaderOffset()
    if DeathFeedDB.showHeaders then
        return 31
    end

    return 18
end

function getFrameChromeHeight()
    if DeathFeedDB.showHeaders then
        return 42
    end

    return 29
end

function getMaxRows()
    local usableHeight = window:GetHeight() - getFrameChromeHeight()
    return math.max(1, math.min(maxHistory, math.floor(usableHeight / rowHeight)))
end

local function makeColumn(parent, x, y, width)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", x, y)
    text:SetWidth(width)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    text:SetNonSpaceWrap(false)
    return text
end

local headerTexts = {}

local function makeHeader(text)
    local header = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header:SetText(text)
    return header
end

headerTexts.time = makeHeader("|cff888888Time|r")
headerTexts.level = makeHeader("|cff888888Lvl|r")
headerTexts.name = makeHeader("|cff888888Name|r")
headerTexts.killer = makeHeader("|cff888888Killed by|r")
headerTexts.zone = makeHeader("|cff888888Zone|r")

local rowFrames = {}
local rowTexts = {}

for i = 1, maxHistory do
    local y = -getHeaderOffset() - (i * rowHeight)

    rowFrames[i] = CreateFrame("Button", nil, window)
    rowFrames[i]:SetPoint("TOPLEFT", 6, y + 2)
    rowFrames[i]:SetSize(165, rowHeight)
    rowFrames[i]:SetFrameLevel(window:GetFrameLevel() + 10)
    rowFrames[i]:EnableMouse(true)
    rowFrames[i]:RegisterForClicks("LeftButtonUp")

    rowFrames[i]:SetScript("OnClick", function(self)
        runWho(self.deathName)
    end)

    rowFrames[i]:SetScript("OnEnter", function(self)
        if self.row then
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:AddLine(self.row.name)
            GameTooltip:AddLine("Level: " .. self.row.level, 1, 1, 1)
            GameTooltip:AddLine("Killed by: " .. self.row.killer, 1, 0.45, 0.45)
            GameTooltip:AddLine("Zone: " .. self.row.zone, 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end
    end)

    rowFrames[i]:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    rowTexts[i] = {}
    rowTexts[i].time = makeColumn(window, 8, y, 35)
    rowTexts[i].level = makeColumn(window, 48, y, 22)
    rowTexts[i].name = makeColumn(window, 78, y, 90)
    rowTexts[i].killer = makeColumn(window, 180, y, 120)
    rowTexts[i].zone = makeColumn(window, 315, y, 120)
end

function updateLayout()
    local width = window:GetWidth()
    local rightPadding = 12

    local timeX = 8
    local levelX = 48
    local nameX = 78
    local killerX = 180
    local zoneX = 315

    local nameWidth = width - nameX - rightPadding
    local killerWidth = 0
    local zoneWidth = 0

    if DeathFeedDB.showKiller and DeathFeedDB.showZone then
        nameWidth = 90
        killerWidth = 120
        zoneWidth = math.max(60, width - zoneX - rightPadding)
    elseif DeathFeedDB.showKiller then
        nameWidth = 90
        killerWidth = math.max(80, width - killerX - rightPadding)
    elseif DeathFeedDB.showZone then
        nameWidth = 90
        zoneX = 180
        zoneWidth = math.max(80, width - zoneX - rightPadding)
    end

    headerTexts.time:ClearAllPoints()
    headerTexts.time:SetPoint("TOPLEFT", timeX, -26)

    headerTexts.level:ClearAllPoints()
    headerTexts.level:SetPoint("TOPLEFT", levelX, -26)

    headerTexts.name:ClearAllPoints()
    headerTexts.name:SetPoint("TOPLEFT", nameX, -26)

    headerTexts.killer:ClearAllPoints()
    headerTexts.killer:SetPoint("TOPLEFT", killerX, -26)

    headerTexts.zone:ClearAllPoints()
    headerTexts.zone:SetPoint("TOPLEFT", zoneX, -26)

    headerTexts.time:SetShown(DeathFeedDB.showHeaders)
    headerTexts.level:SetShown(DeathFeedDB.showHeaders)
    headerTexts.name:SetShown(DeathFeedDB.showHeaders)
    headerTexts.killer:SetShown(DeathFeedDB.showHeaders and DeathFeedDB.showKiller)
    headerTexts.zone:SetShown(DeathFeedDB.showHeaders and DeathFeedDB.showZone)

    for i = 1, maxHistory do
        rowFrames[i]:SetSize(math.max(1, width - 14), rowHeight)

        rowTexts[i].time:ClearAllPoints()
        rowTexts[i].time:SetPoint("TOPLEFT", timeX, -getHeaderOffset() - (i * rowHeight))
        rowTexts[i].time:SetWidth(35)

        rowTexts[i].level:ClearAllPoints()
        rowTexts[i].level:SetPoint("TOPLEFT", levelX, -getHeaderOffset() - (i * rowHeight))
        rowTexts[i].level:SetWidth(22)

        rowTexts[i].name:ClearAllPoints()
        rowTexts[i].name:SetPoint("TOPLEFT", nameX, -getHeaderOffset() - (i * rowHeight))
        rowTexts[i].name:SetWidth(math.max(40, nameWidth))

        rowTexts[i].killer:ClearAllPoints()
        rowTexts[i].killer:SetPoint("TOPLEFT", killerX, -getHeaderOffset() - (i * rowHeight))
        rowTexts[i].killer:SetWidth(killerWidth)

        rowTexts[i].zone:ClearAllPoints()
        rowTexts[i].zone:SetPoint("TOPLEFT", zoneX, -getHeaderOffset() - (i * rowHeight))
        rowTexts[i].zone:SetWidth(zoneWidth)

        rowTexts[i].killer:SetShown(DeathFeedDB.showKiller)
        rowTexts[i].zone:SetShown(DeathFeedDB.showZone)
    end
end

function updateRows(animated)
    trimHistory()

    local maxRows = getMaxRows()
    local visibleRows = getVisibleRows()

    for i = 1, maxHistory do
        local row = visibleRows[i]

        if i <= maxRows and row then
            rowFrames[i].row = row
            rowFrames[i].deathName = row.name
            rowFrames[i]:EnableMouse(true)
            rowFrames[i]:Show()

            rowTexts[i].time:SetText("|cff888888" .. row.time .. "|r")

            rowTexts[i].level:SetText(colorLevel(row.level))

            if isGuildMember(row.name) then
                rowTexts[i].name:SetText("|cff55ff55" .. row.name .. "|r")
            else
                rowTexts[i].name:SetText("|cffdddddd" .. row.name .. "|r")
            end
            
            if row.killer == "Fall damage" then
                rowTexts[i].killer:SetText("|cff996633" .. row.killer .. "|r")
            elseif row.killer == "Drowning" then
                rowTexts[i].killer:SetText("|cff3399ff" .. row.killer .. "|r")
            elseif row.killer == "Lava" then
                rowTexts[i].killer:SetText("|cffffaa00" .. row.killer .. "|r")
            elseif row.killer == "Fatigue" then
                rowTexts[i].killer:SetText("|cff66ccff" .. row.killer .. "|r")
            else
                rowTexts[i].killer:SetText("|cffff7777" .. row.killer .. "|r")
            end

            rowTexts[i].zone:SetText("|cffcccccc" .. row.zone .. "|r")

            rowTexts[i].time:Show()
            rowTexts[i].level:Show()
            rowTexts[i].name:Show()

            rowTexts[i].killer:SetShown(DeathFeedDB.showKiller)
            rowTexts[i].zone:SetShown(DeathFeedDB.showZone)

            if animated and i == 1 and historyOffset == 0 then
                rowTexts[i].time:SetAlpha(0)
                rowTexts[i].level:SetAlpha(0)
                rowTexts[i].name:SetAlpha(0)
                if DeathFeedDB.showKiller then
                    rowTexts[i].killer:SetAlpha(0)
                end

                if DeathFeedDB.showZone then
                    rowTexts[i].zone:SetAlpha(0)
                end

                UIFrameFadeIn(rowTexts[i].time, 0.35, 0, 1)
                UIFrameFadeIn(rowTexts[i].level, 0.35, 0, 1)
                UIFrameFadeIn(rowTexts[i].name, 0.35, 0, 1)
                if DeathFeedDB.showKiller then
                    UIFrameFadeIn(rowTexts[i].killer, 0.35, 0, 1)
                end

                if DeathFeedDB.showZone then
                    UIFrameFadeIn(rowTexts[i].zone, 0.35, 0, 1)
                end
            else
                rowTexts[i].time:SetAlpha(1)
                rowTexts[i].level:SetAlpha(1)
                rowTexts[i].name:SetAlpha(1)
                rowTexts[i].killer:SetAlpha(1)
                rowTexts[i].zone:SetAlpha(1)
            end
        else
            rowFrames[i].row = nil
            rowFrames[i].deathName = nil
            rowFrames[i]:EnableMouse(false)
            rowFrames[i]:Hide()

            rowTexts[i].time:SetText("")
            rowTexts[i].level:SetText("")
            rowTexts[i].name:SetText("")
            rowTexts[i].killer:SetText("")
            rowTexts[i].zone:SetText("")

            rowTexts[i].time:Hide()
            rowTexts[i].level:Hide()
            rowTexts[i].name:Hide()
            rowTexts[i].killer:Hide()
            rowTexts[i].zone:Hide()
        end
    end
end

window:EnableMouseWheel(true)

window:SetScript("OnMouseWheel", function(_, delta)
    local maxOffset = math.max(0, getVisibleRowCount() - getMaxRows())

    if delta < 0 then
        historyOffset = math.min(historyOffset + 1, maxOffset)
    else
        historyOffset = math.max(historyOffset - 1, 0)
    end

    updateRows(false)
end)

function printParseError(message)
    printMessage("Failed to parse death message:")
    printMessage(message)
    printMessage("Please report this parser issue and include the message above:")
    printMessage("https://www.curseforge.com/wow/addons/deathfeed/comments")
end

function setWindowShown(shown)
    DeathFeedDB.hidden = not shown

    if shown then
        window:Show()
    else
        window:Hide()
    end
end
