SLASH_DEATHFEED1 = "/deathfeed"
SLASH_DEATHFEED2 = "/df"

local function printCommandHelp()
    printMessage("Commands:")
    printMessage("/deathfeed - Show or hide the feed.")
    printMessage("/deathfeed show - Show the feed.")
    printMessage("/deathfeed hide - Hide the feed.")
    printMessage("/deathfeed clear - Clear history.")
    printMessage("/deathfeed chat on - Hide original HardcoreDeaths chat.")
    printMessage("/deathfeed chat off - Show original HardcoreDeaths chat.")
    printMessage("/deathfeed minimap - Show or hide the minimap icon.")
    printMessage("/deathfeed help - Show this help.")
end

SlashCmdList["DEATHFEED"] = function(input)
    input = string.lower(input or "")

    if input == "" then
        setWindowShown(not isWindowShown())
    elseif input == "show" then
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
    elseif input == "help" then
        printCommandHelp()
    else
        printMessage("Unknown command: " .. input)
        printCommandHelp()
    end
end

SLASH_DEATHFEEDTEST1 = "/dftest"

SlashCmdList["DEATHFEEDTEST"] = function()
    local message = "[Rurahc] was burnt to a crisp by lava in Ironforge! They were level 45"
    local death = parseDeathMessage(message)

    if death then
        addDeathMessage(death)
        printMessage("Test death added.")
    else
        printParseError(message)
    end
end
