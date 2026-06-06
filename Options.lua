optionsPanel = CreateFrame("Frame", "DeathFeedOptionsPanel")
optionsPanel.name = "DeathFeed"

local optionsTitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
optionsTitle:SetPoint("TOPLEFT", 16, -16)
optionsTitle:SetText("DeathFeed")

deathFeedCategory = nil

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