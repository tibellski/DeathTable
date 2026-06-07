function getVisibleRows()
    local visibleRows = {}
    local maxRows = getMaxRows()
    local visibleIndex = 1

    for _, row in ipairs(DeathFeedDB.history) do
        local level = tonumber(row.level) or 0

        if level >= DeathFeedDB.minimumLevel then
            if visibleIndex > historyOffset and #visibleRows < maxRows then
                table.insert(visibleRows, row)
            end

            visibleIndex = visibleIndex + 1
        end
    end

    return visibleRows
end

function getVisibleRowCount()
    local count = 0

    for _, row in ipairs(DeathFeedDB.history) do
        local level = tonumber(row.level) or 0

        if level >= DeathFeedDB.minimumLevel then
            count = count + 1
        end
    end

    return count
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
