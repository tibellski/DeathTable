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