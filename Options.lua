DeathFeedOptionsPanel = CreateFrame("Frame", "DeathFeedOptionsPanel")
DeathFeedOptionsPanel.name = "DeathFeed"

local optionsTitle = DeathFeedOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
optionsTitle:SetPoint("TOPLEFT", 16, -16)
optionsTitle:SetText("DeathFeed")

DeathFeedOptionsCategory = nil

if Settings and Settings.RegisterCanvasLayoutCategory then
    DeathFeedOptionsCategory = Settings.RegisterCanvasLayoutCategory(DeathFeedOptionsPanel, "DeathFeed")
    Settings.RegisterAddOnCategory(DeathFeedOptionsCategory)
elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(DeathFeedOptionsPanel)
end

    -------------------------------------------------------------------
    -- Chat
    -------------------------------------------------------------------

local hideChatCheckbox = CreateFrame(
    "CheckButton",
    "DeathFeedHideChatCheckbox",
    DeathFeedOptionsPanel,
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

    -------------------------------------------------------------------
    -- Killer
    -------------------------------------------------------------------

local showKillerCheckbox = CreateFrame(
    "CheckButton",
    nil,
    DeathFeedOptionsPanel,
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

    -------------------------------------------------------------------
    -- Zone
    -------------------------------------------------------------------

local showZoneCheckbox = CreateFrame(
    "CheckButton",
    nil,
    DeathFeedOptionsPanel,
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

-------------------------------------------------------------------
-- Headers
-------------------------------------------------------------------

local showHeadersCheckbox = CreateFrame(
    "CheckButton",
    nil,
    DeathFeedOptionsPanel,
    "InterfaceOptionsCheckButtonTemplate"
)

showHeadersCheckbox:SetPoint("TOPLEFT", showZoneCheckbox, "BOTTOMLEFT", 0, -8)
showHeadersCheckbox.Text:SetText("Show column headers")

showHeadersCheckbox:SetScript("OnShow", function(self)
    self:SetChecked(DeathFeedDB.showHeaders)
end)

showHeadersCheckbox:SetScript("OnClick", function(self)
    DeathFeedDB.showHeaders = self:GetChecked()

    updateLayout()
    updateRows(false)
end)

    -------------------------------------------------------------------
    -- Sound
    -------------------------------------------------------------------

local playSoundCheckbox = CreateFrame(
    "CheckButton",
    nil,
    DeathFeedOptionsPanel,
    "InterfaceOptionsCheckButtonTemplate"
)

playSoundCheckbox:SetPoint("TOPLEFT", showHeadersCheckbox, "BOTTOMLEFT", 0, -8)
playSoundCheckbox.Text:SetText("Play sound on guild death")

playSoundCheckbox:SetScript("OnShow", function(self)
    self:SetChecked(DeathFeedDB.playGuildSound)
end)

playSoundCheckbox:SetScript("OnClick", function(self)
    DeathFeedDB.playGuildSound = self:GetChecked()
end)

-------------------------------------------------------------------
-- Minimum level
-------------------------------------------------------------------

local minimumLevelLabel = DeathFeedOptionsPanel:CreateFontString(
    nil,
    "ARTWORK",
    "GameFontNormal"
)

minimumLevelLabel:SetPoint("TOPLEFT", playSoundCheckbox, "BOTTOMLEFT", 0, -18)
minimumLevelLabel:SetText("Minimum level to display")

local minimumLevelDropdown = CreateFrame(
    "Frame",
    "DeathFeedMinimumLevelDropdown",
    DeathFeedOptionsPanel,
    "UIDropDownMenuTemplate"
)

minimumLevelDropdown:SetPoint("TOPLEFT", minimumLevelLabel, "BOTTOMLEFT", -15, -4)

local minimumLevelOptions = {
    10,
    20,
    30,
    40,
    50,
    60
}

local function updateMinimumLevelDropdownText()
    UIDropDownMenu_SetText(
        minimumLevelDropdown,
        tostring(DeathFeedDB.minimumLevel or 10)
    )
end

UIDropDownMenu_Initialize(minimumLevelDropdown, function()
    for _, value in ipairs(minimumLevelOptions) do
        local info = UIDropDownMenu_CreateInfo()

        info.text = tostring(value)
        info.value = value
        info.checked = DeathFeedDB.minimumLevel == value

        info.func = function()
            DeathFeedDB.minimumLevel = value
            historyOffset = 0
            updateMinimumLevelDropdownText()
            updateRows(false)
            CloseDropDownMenus()
        end

        UIDropDownMenu_AddButton(info)
    end
end)

UIDropDownMenu_SetWidth(minimumLevelDropdown, 80)
updateMinimumLevelDropdownText()

minimumLevelDropdown:SetScript("OnShow", function()
    updateMinimumLevelDropdownText()
end)

    -------------------------------------------------------------------
    -- Minimap
    -------------------------------------------------------------------

local hideMinimapCheckbox = CreateFrame(
    "CheckButton",
    nil,
    DeathFeedOptionsPanel,
    "InterfaceOptionsCheckButtonTemplate"
)

hideMinimapCheckbox:SetPoint("TOPLEFT", minimumLevelDropdown, "BOTTOMLEFT", 15, -10)
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

    -------------------------------------------------------------------
    -- Clear
    -------------------------------------------------------------------

local clearButton = CreateFrame(
    "Button",
    nil,
    DeathFeedOptionsPanel,
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
