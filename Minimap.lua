function setupMinimapIcon()
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