function getVisibleRows()
    local visibleRows = {}
    local maxRows = getMaxRows()

    for i = 1, maxRows do
        visibleRows[i] = DeathFeedDB.history[i + historyOffset]
    end

    return visibleRows
end

function addDeathMessage(death)
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