eventFrame = CreateFrame("Frame")
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

    local death = parseDeathMessage(message)

    if death then
        addDeathMessage(death)
    else
        printParseError(message)
    end
end)