local maxHistory = 25
local rowHeight = 16
local historyOffset = 0
local ldbIcon = nil
local guildMembers = {}

DeathFeedDB = DeathFeedDB or {}

local defaults = {
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = 0,
    width = 180,
    height = 132,
    hidden = false,
    hideOriginalChat = true,
    showKiller = true,
    showZone = true,
    playGuildSound = true,
    minimap = {
        hide = false
    },
    history = {}
}

local hardcoreDeathChannels = {
    ["HardcoreDeaths"] = true,
    ["Morts extrêmes"] = true,
    ["HardcoreTode"] = true,
}

local function copyDefaults(source, target)
    for key, value in pairs(source) do
        if type(value) == "table" then
            target[key] = target[key] or {}
            copyDefaults(value, target[key])
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

copyDefaults(defaults, DeathFeedDB)

local function trimHistory()
    while #DeathFeedDB.history > maxHistory do
        table.remove(DeathFeedDB.history)
    end
end

local function printMessage(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[DeathFeed]|r " .. message)
end

local function runWho(name)
    if not name or name == "" then
        return
    end

    if C_FriendList and C_FriendList.SendWho then
        C_FriendList.SendWho(name)
    elseif SendWho then
        SendWho(name)
    else
        ChatFrame_OpenChat("/who " .. name)
    end
end

local function updateGuildMembers()
    wipe(guildMembers)

    if not IsInGuild() then
        return
    end

    GuildRoster()

    for i = 1, GetNumGuildMembers() do
        local fullName = GetGuildRosterInfo(i)

        if fullName then
            local name = string.match(fullName, "([^%-]+)") or fullName
            guildMembers[name] = true
        end
    end
end

local function isGuildMember(name)
    return guildMembers[name] == true
end

local window = CreateFrame("Frame", "DeathFeedFrame", UIParent, "BackdropTemplate")
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

local function updateResizeBounds()
    local minWidth = 180

    if DeathFeedDB.showKiller and DeathFeedDB.showZone then
        minWidth = 430
    elseif DeathFeedDB.showKiller then
        minWidth = 320
    elseif DeathFeedDB.showZone then
        minWidth = 320
    end

    if window.SetResizeBounds then
        window:SetResizeBounds(minWidth, 132, 650, 500)
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
resizeHandle:SetSize(28, 28)
resizeHandle:SetPoint("BOTTOMRIGHT", 2, -2)
resizeHandle:SetHitRectInsets(-6, -6, -6, -6)

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

window:SetBackdropColor(0, 0, 0, 0.82)
window:SetBackdropBorderColor(0.75, 0.55, 0.25, 1)

local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOPLEFT", 10, -8)
title:SetText("|cffffcc00Hardcore Deaths|r")

local function getMaxRows()
    local usableHeight = window:GetHeight() - 42
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

headerTexts.time = makeHeader("|cffaaaaaaTime|r")
headerTexts.level = makeHeader("|cffaaaaaaLvl|r")
headerTexts.name = makeHeader("|cffaaaaaaName|r")
headerTexts.killer = makeHeader("|cffaaaaaaKilled by|r")
headerTexts.zone = makeHeader("|cffaaaaaaZone|r")

local rowFrames = {}
local rowTexts = {}

for i = 1, maxHistory do
    local y = -31 - (i * rowHeight)

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

    headerTexts.killer:SetShown(DeathFeedDB.showKiller)
    headerTexts.zone:SetShown(DeathFeedDB.showZone)

    for i = 1, maxHistory do
        rowFrames[i]:SetSize(math.max(1, width - 14), rowHeight)

        rowTexts[i].time:ClearAllPoints()
        rowTexts[i].time:SetPoint("TOPLEFT", timeX, -31 - (i * rowHeight))
        rowTexts[i].time:SetWidth(35)

        rowTexts[i].level:ClearAllPoints()
        rowTexts[i].level:SetPoint("TOPLEFT", levelX, -31 - (i * rowHeight))
        rowTexts[i].level:SetWidth(22)

        rowTexts[i].name:ClearAllPoints()
        rowTexts[i].name:SetPoint("TOPLEFT", nameX, -31 - (i * rowHeight))
        rowTexts[i].name:SetWidth(math.max(40, nameWidth))

        rowTexts[i].killer:ClearAllPoints()
        rowTexts[i].killer:SetPoint("TOPLEFT", killerX, -31 - (i * rowHeight))
        rowTexts[i].killer:SetWidth(killerWidth)

        rowTexts[i].zone:ClearAllPoints()
        rowTexts[i].zone:SetPoint("TOPLEFT", zoneX, -31 - (i * rowHeight))
        rowTexts[i].zone:SetWidth(zoneWidth)

        rowTexts[i].killer:SetShown(DeathFeedDB.showKiller)
        rowTexts[i].zone:SetShown(DeathFeedDB.showZone)
    end
end

local function colorLevel(level)
    local number = tonumber(level)

    if not number then
        return level
    end

    if number >= 50 then
        return "|cffff3333" .. level .. "|r"
    elseif number >= 30 then
        return "|cffff8800" .. level .. "|r"
    elseif number >= 20 then
        return "|cffffff00" .. level .. "|r"
    else
        return "|cff88ff88" .. level .. "|r"
    end
end

local function parseDeathMessage(message)
    local nameEnd = string.find(message, "]", 1, true)

    if not nameEnd then
        return nil
    end

    local name = string.sub(message, 2, nameEnd - 1)

    name = string.gsub(name, "^Hplayer:", "")
    name = string.gsub(name, "|h.*$", "")
    name = string.gsub(name, "%-.*$", "")

    local afterName = string.sub(message, nameEnd + 1)

    afterName = string.gsub(afterName, "\194\160", " ")
    afterName = string.gsub(afterName, " ", " ")

    local rest, level = string.match(
        afterName,
        "%s*has been slain by (.+)! They were level (%d+)"
    )

    local frenchKiller, frenchZone, frenchLevel = string.match(
        afterName,
        "a succombé en combattant ce personnage adverse%s*:%s*(.-)%s*%((.-)%)%s*!%s*Ce personnage%-joueur était de niveau (%d+)"
    )

    if frenchKiller and frenchZone and frenchLevel then
        return {
            name = name,
            killer = frenchKiller,
            zone = frenchZone,
            level = frenchLevel
        }
    end

    local germanKiller, germanZone, germanLevel = string.match(
        afterName,
        "%s*wurde von einer Kreatur %((.-)%) in (.-) getötet! Die Stufe war (%d+)"
    )

    if germanKiller and germanZone and germanLevel then
        return {
            name = name,
            killer = germanKiller,
            zone = germanZone,
            level = germanLevel
        }
    end

    if not rest then
        local fallZone, fallLevel = string.match(
            afterName,
            "%s*fell to their death in (.+)! They were level (%d+)"
        )

        if fallZone and fallLevel then
            return {
                name = name,
                killer = "Fall damage",
                zone = fallZone,
                level = fallLevel
            }
        end

        local drownZone, drownLevel = string.match(
            afterName,
            "%s*drowned to death in (.+)! They were level (%d+)"
        )

        if drownZone and drownLevel then
            return {
                name = name,
                killer = "Drowning",
                zone = drownZone,
                level = drownLevel
            }
        end

        local frenchDrownZone, frenchDrownLevel = string.match(
            afterName,
            "%s*a succombé en se noyant %((.-)%)%s*.%s*Ce personnage%-joueur était de niveau (%d+)"
        )

        if frenchDrownZone and frenchDrownLevel then
            return {
                name = name,
                killer = "Drowning",
                zone = frenchDrownZone,
                level = frenchDrownLevel
            }
        end

        local lavaZone, lavaLevel = string.match(
        afterName,
            "%s*was burnt to a crisp by lava in (.+)! They were level (%d+)"
        )

        if lavaZone and lavaLevel then
            return {
                name = name,
                killer = "Lava",
                zone = lavaZone,
                level = lavaLevel
            }
        end

        local frenchLavaZone, frenchLavaLevel = string.match(
            afterName,
            "%s*a péri dans la lave %((.-)%)%s*!%s*Ce personnage%-joueur était de niveau (%d+)"
        )

        if frenchLavaZone and frenchLavaLevel then
            return {
                name = name,
                killer = "Lava",
                zone = frenchLavaZone,
                level = frenchLavaLevel
            }
        end

        local fatigueZone, fatigueLevel = string.match(
            afterName,
            "%s*died of fatigue in (.+)! They were level (%d+)"
        )

        if fatigueZone and fatigueLevel then
            return {
                name = name,
                killer = "Fatigue",
                zone = fatigueZone,
                level = fatigueLevel
            }
        end

        return nil
    end

    local killer, zone = string.match(rest, "^(.*) in (.*)$")

    if not killer or not zone then
        return nil
    end

    killer = string.gsub(killer, "^a ", "")
    killer = string.gsub(killer, "^an ", "")

    return {
        name = name,
        killer = killer,
        zone = zone,
        level = level
    }
end

local function getVisibleRows()
    local visibleRows = {}
    local maxRows = getMaxRows()

    for i = 1, maxRows do
        visibleRows[i] = DeathFeedDB.history[i + historyOffset]
    end

    return visibleRows
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
                rowTexts[i].name:SetText("|cff40ff40" .. row.name .. "|r")
            else
                rowTexts[i].name:SetText("|cffffffff" .. row.name .. "|r")
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
                rowTexts[i].killer:SetAlpha(0)
                rowTexts[i].zone:SetAlpha(0)

                UIFrameFadeIn(rowTexts[i].time, 0.35, 0, 1)
                UIFrameFadeIn(rowTexts[i].level, 0.35, 0, 1)
                UIFrameFadeIn(rowTexts[i].name, 0.35, 0, 1)
                UIFrameFadeIn(rowTexts[i].killer, 0.35, 0, 1)
                UIFrameFadeIn(rowTexts[i].zone, 0.35, 0, 1)
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
    local maxOffset = math.max(0, #DeathFeedDB.history - getMaxRows())

    if delta < 0 then
        historyOffset = math.min(historyOffset + 1, maxOffset)
    else
        historyOffset = math.max(historyOffset - 1, 0)
    end

    updateRows(false)
end)

local function addDeathMessage(death)
    table.insert(DeathFeedDB.history, 1, {
        time = date("%H:%M"),
        name = death.name,
        level = death.level,
        killer = death.killer,
        zone = death.zone
    })

    trimHistory()

    if DeathFeedDB.playGuildSound and isGuildMember(death.name) then
        PlaySound(1172, "Master")
    end

    historyOffset = 0
    updateRows(true)
end

local function printParseError(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[DeathFeed]|r Failed to parse death message:")
    DEFAULT_CHAT_FRAME:AddMessage("|cffaaaaaa" .. tostring(message) .. "|r")
end

local function setWindowShown(shown)
    DeathFeedDB.hidden = not shown

    if shown then
        window:Show()
    else
        window:Hide()
    end
end

local optionsPanel = CreateFrame("Frame", "DeathFeedOptionsPanel")
optionsPanel.name = "DeathFeed"

local optionsTitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
optionsTitle:SetPoint("TOPLEFT", 16, -16)
optionsTitle:SetText("DeathFeed")

local deathFeedCategory = nil

if Settings and Settings.RegisterCanvasLayoutCategory then
    deathFeedCategory = Settings.RegisterCanvasLayoutCategory(optionsPanel, "DeathFeed")
    Settings.RegisterAddOnCategory(deathFeedCategory)
elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(optionsPanel)
end

local hideChatCheckbox = CreateFrame(
    "CheckButton",
    "DeathFeedHideChatCheckbox",
    optionsPanel,
    "InterfaceOptionsCheckButtonTemplate"
)

hideChatCheckbox:SetPoint("TOPLEFT", optionsTitle, "BOTTOMLEFT", 0, -16)
hideChatCheckbox.Text:SetText("Hide original HardcoreDeaths chat")

hideChatCheckbox:SetScript("OnShow", function(self)
    self:SetChecked(DeathFeedDB.hideOriginalChat)
end)

hideChatCheckbox:SetScript("OnClick", function(self)
    DeathFeedDB.hideOriginalChat = self:GetChecked()
end)

local showKillerCheckbox = CreateFrame(
    "CheckButton",
    nil,
    optionsPanel,
    "InterfaceOptionsCheckButtonTemplate"
)

showKillerCheckbox:SetPoint("TOPLEFT", hideChatCheckbox, "BOTTOMLEFT", 0, -8)
showKillerCheckbox.Text:SetText("Show killed by column")

showKillerCheckbox:SetScript("OnShow", function(self)
    self:SetChecked(DeathFeedDB.showKiller)
end)

showKillerCheckbox:SetScript("OnClick", function(self)
    DeathFeedDB.showKiller = self:GetChecked()

    updateResizeBounds()
    updateLayout()
    updateRows(false)
end)

local showZoneCheckbox = CreateFrame(
    "CheckButton",
    nil,
    optionsPanel,
    "InterfaceOptionsCheckButtonTemplate"
)

showZoneCheckbox:SetPoint("TOPLEFT", showKillerCheckbox, "BOTTOMLEFT", 0, -8)
showZoneCheckbox.Text:SetText("Show zone column")

showZoneCheckbox:SetScript("OnShow", function(self)
    self:SetChecked(DeathFeedDB.showZone)
end)

showZoneCheckbox:SetScript("OnClick", function(self)
    DeathFeedDB.showZone = self:GetChecked()

    updateResizeBounds()
    updateLayout()
    updateRows(false)
end)

local playSoundCheckbox = CreateFrame(
    "CheckButton",
    nil,
    optionsPanel,
    "InterfaceOptionsCheckButtonTemplate"
)

playSoundCheckbox:SetPoint("TOPLEFT", showZoneCheckbox, "BOTTOMLEFT", 0, -8)
playSoundCheckbox.Text:SetText("Play sound on guild death")

playSoundCheckbox:SetScript("OnShow", function(self)
    self:SetChecked(DeathFeedDB.playGuildSound)
end)

playSoundCheckbox:SetScript("OnClick", function(self)
    DeathFeedDB.playGuildSound = self:GetChecked()
end)

local hideMinimapCheckbox = CreateFrame(
    "CheckButton",
    nil,
    optionsPanel,
    "InterfaceOptionsCheckButtonTemplate"
)

hideMinimapCheckbox:SetPoint("TOPLEFT", playSoundCheckbox, "BOTTOMLEFT", 0, -8)
hideMinimapCheckbox.Text:SetText("Hide minimap icon")

hideMinimapCheckbox:SetScript("OnShow", function(self)
    self:SetChecked(DeathFeedDB.minimap.hide)
end)

hideMinimapCheckbox:SetScript("OnClick", function(self)
    DeathFeedDB.minimap.hide = self:GetChecked()

    if ldbIcon then
        if DeathFeedDB.minimap.hide then
            ldbIcon:Hide("DeathFeed")
        else
            ldbIcon:Show("DeathFeed")
        end
    end
end)

local clearButton = CreateFrame(
    "Button",
    nil,
    optionsPanel,
    "UIPanelButtonTemplate"
)

clearButton:SetSize(120, 24)
clearButton:SetPoint("TOPLEFT", hideMinimapCheckbox, "BOTTOMLEFT", 0, -16)
clearButton:SetText("Clear history")

clearButton:SetScript("OnClick", function()
    wipe(DeathFeedDB.history)
    historyOffset = 0
    updateRows(false)
end)

local function setupMinimapIcon()
    local LDB = LibStub("LibDataBroker-1.1")
    ldbIcon = LibStub("LibDBIcon-1.0")

    local broker = LDB:NewDataObject("DeathFeed", {
        type = "launcher",
        text = "DeathFeed",
        icon = "Interface\\Icons\\INV_Misc_Bone_Skull_02",

        OnClick = function(_, button)
            if button == "RightButton" then
                if Settings and Settings.OpenToCategory and deathFeedCategory then
                    Settings.OpenToCategory(deathFeedCategory.ID)
                elseif InterfaceOptionsFrame_OpenToCategory then
                    InterfaceOptionsFrame_OpenToCategory(optionsPanel)
                    InterfaceOptionsFrame_OpenToCategory(optionsPanel)
                end
            else
                setWindowShown(not window:IsShown())
            end
        end,

        OnTooltipShow = function(tooltip)
            tooltip:AddLine("DeathFeed")
            tooltip:AddLine("Left click: show/hide", 1, 1, 1)
            tooltip:AddLine("Right click: open settings", 1, 1, 1)
        end
    })

    ldbIcon:Register("DeathFeed", broker, DeathFeedDB.minimap)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")

eventFrame:SetScript("OnEvent", function(_, event, message, sender, language, channelName)
    if event == "PLAYER_LOGIN" then
        updateGuildMembers()

        if DeathFeedDB.hidden then
            window:Hide()
        end

        updateResizeBounds()
        updateLayout()
        trimHistory()
        setupMinimapIcon()
        updateRows(false)

        return
    end

    if event == "GUILD_ROSTER_UPDATE" then
        updateGuildMembers()
        return
    end

    local isHardcoreDeathChannel =
        channelName
        and (
            string.find(channelName, "HardcoreDeaths")
            or string.find(channelName, "Morts extrêmes")
            or string.find(channelName, "HardcoreTode")
        )

    if not isHardcoreDeathChannel then
        return
    end

    print("DeathFeed channel:", tostring(channelName))

    local death = parseDeathMessage(message)

    if death then
        addDeathMessage(death)
    else
        printParseError(message)
    end
end)

ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", function(
    self,
    event,
    message,
    sender,
    language,
    channelName
)
    local isHardcoreDeathChannel =
        channelName
        and (
            string.find(channelName, "HardcoreDeaths")
            or string.find(channelName, "Morts extrêmes")
            or string.find(channelName, "HardcoreTode")
        )

    if DeathFeedDB.hideOriginalChat and isHardcoreDeathChannel then
        return true
    end

    return false
end)

SLASH_DEATHFEED1 = "/deathfeed"

SlashCmdList["DEATHFEED"] = function(input)
    input = string.lower(input or "")

    if input == "show" then
        setWindowShown(true)
    elseif input == "hide" then
        setWindowShown(false)
    elseif input == "clear" then
        wipe(DeathFeedDB.history)
        historyOffset = 0
        updateRows(false)
        printMessage("History cleared.")
    elseif input == "chat on" then
        DeathFeedDB.hideOriginalChat = true
        printMessage("Original HardcoreDeaths chat hidden.")
    elseif input == "chat off" then
        DeathFeedDB.hideOriginalChat = false
        printMessage("Original HardcoreDeaths chat visible.")
    elseif input == "minimap" then
        DeathFeedDB.minimap.hide = not DeathFeedDB.minimap.hide

        if ldbIcon then
            if DeathFeedDB.minimap.hide then
                ldbIcon:Hide("DeathFeed")
                printMessage("Minimap icon hidden.")
            else
                ldbIcon:Show("DeathFeed")
                printMessage("Minimap icon shown.")
            end
        end
    else
        setWindowShown(not window:IsShown())
    end
end

SLASH_DEATHFEEDTEST1 = "/dttest"

SlashCmdList["DEATHFEEDTEST"] = function()
    local message = "[Rurahc] was burnt to a crisp by lava in Ironforge! They were level 16"
    local death = parseDeathMessage(message)

    if death then
        addDeathMessage(death)
        printMessage("Test death added.")
    else
        printMessage("Test parse failed.")
    end
end