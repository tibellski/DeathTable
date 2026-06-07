function setupMinimapIcon()
    if not LibStub then
        printMessage("Minimap icon unavailable: LibStub is missing.")
        return
    end

    local LDB = LibStub("LibDataBroker-1.1", true)
    if not LDB then
        printMessage("Minimap icon unavailable: LibDataBroker-1.1 is missing.")
        return
    end

    ldbIcon = LibStub("LibDBIcon-1.0", true)
    if not ldbIcon then
        printMessage("Minimap icon unavailable: LibDBIcon-1.0 is missing.")
        return
    end

    local broker = LDB:NewDataObject("DeathFeed", {
        type = "launcher",
        text = "DeathFeed",
        icon = "Interface\\Icons\\INV_Misc_Bone_Skull_02",

        OnClick = function(_, button)
            if button == "RightButton" then
                if Settings and Settings.OpenToCategory and DeathFeedOptionsCategory then
                    Settings.OpenToCategory(DeathFeedOptionsCategory.ID)
                elseif InterfaceOptionsFrame_OpenToCategory then
                    InterfaceOptionsFrame_OpenToCategory(DeathFeedOptionsPanel)
                    InterfaceOptionsFrame_OpenToCategory(DeathFeedOptionsPanel)
                end
            else
                setWindowShown(not isWindowShown())
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
