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

SLASH_DEATHFEEDTEST1 = "/dftest"

SlashCmdList["DEATHFEEDTEST"] = function()
    -- local message = "[Rurahc] was burnt to a crisp by lava in Ironforge! They were level 45"
    local message = "[Rurahc] was hejhejhej"
    local death = parseDeathMessage(message)

    if death then
        addDeathMessage(death)
        printMessage("Test death added.")
    else
        printParseError(message)
    end
end