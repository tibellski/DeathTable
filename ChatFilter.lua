ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", function(
    self,
    event,
    message,
    sender,
    language,
    channelName
)
    if DeathFeedDB.hideOriginalChat and isHardcoreDeathChannel(channelName) then
        return true
    end

    return false
end)
