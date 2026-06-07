-----------------------------------------------------------------------
-- Death Message Parser
--
-- Supported languages:
--   English
--   French
--   German
--
-- Supported death types:
--   Creature kills
--   Player kills
--   Fall damage
--   Drowning
--   Lava
--   Fatigue
-----------------------------------------------------------------------

local function trim(value)
    if not value then
        return value
    end

    return string.gsub(value, "^%s*(.-)%s*$", "%1")
end

local function normalizeMessageText(message)
    message = string.gsub(message, "\194\160", " ")
    return message
end

local function cleanPlayerName(name)
    name = string.gsub(name, "^Hplayer:", "")
    name = string.gsub(name, "|h.*$", "")
    name = string.gsub(name, "%-.*$", "")
    return trim(name)
end

local function makeDeath(name, killer, zone, level)
    return {
        name = cleanPlayerName(name),
        killer = trim(killer),
        zone = trim(zone),
        level = trim(level)
    }
end

function parseDeathMessage(message)
    message = normalizeMessageText(message)

    -------------------------------------------------------------------
    -- Extract player name
    -------------------------------------------------------------------

    local nameEnd = string.find(message, "]", 1, true)

    if not nameEnd then
        return nil
    end

    local name = cleanPlayerName(string.sub(message, 2, nameEnd - 1))

    local afterName = string.sub(message, nameEnd + 1)

    -------------------------------------------------------------------
    -- Normalize special spaces used by some localized clients
    -------------------------------------------------------------------

    afterName = normalizeMessageText(afterName)

    -------------------------------------------------------------------
    -- English creature kill
    -------------------------------------------------------------------

    local rest, level = string.match(
        afterName,
        "%s*has been slain by (.+)! They were level (%d+)"
    )

    -------------------------------------------------------------------
    -- French creature kill
    -------------------------------------------------------------------

    local frenchKiller, frenchZone, frenchLevel = string.match(
        afterName,
        "a succombé en combattant ce personnage adverse%s*:%s*(.-)%s*%((.-)%)%s*!%s*Ce personnage%-joueur était de niveau (%d+)"
    )

    if frenchKiller and frenchZone and frenchLevel then
        return makeDeath(name, frenchKiller, frenchZone, frenchLevel)
    end

    -------------------------------------------------------------------
    -- French player kill (PvP)
    -------------------------------------------------------------------

    local frenchPlayerKiller, frenchPlayerZone, frenchPlayerLevel = string.match(
        afterName,
        "%s*a succombé en combattant (.-)%s*%((.-)%)%s*!%s*Ce personnage%-joueur était de niveau (%d+)"
    )

    if frenchPlayerKiller and frenchPlayerZone and frenchPlayerLevel then
        return makeDeath(name, frenchPlayerKiller, frenchPlayerZone, frenchPlayerLevel)
    end

    -------------------------------------------------------------------
    -- German creature kill
    -------------------------------------------------------------------

    local germanKiller, germanZone, germanLevel = string.match(
        afterName,
        "%s*wurde von einer Kreatur %((.-)%) in (.-) getötet! Die Stufe war (%d+)"
    )

    if germanKiller and germanZone and germanLevel then
        return makeDeath(name, germanKiller, germanZone, germanLevel)
    end

    -------------------------------------------------------------------
    -- German player kill (PvP)
    -------------------------------------------------------------------

    local germanPlayerKiller, germanPlayerZone, germanPlayerLevel = string.match(
        afterName,
        "wurde von (.-) in (.-) getötet! Die Stufe war (%d+)"
    )

    if germanPlayerKiller and germanPlayerZone and germanPlayerLevel then
        return makeDeath(name, germanPlayerKiller, germanPlayerZone, germanPlayerLevel)
    end

    -------------------------------------------------------------------
    -- Special deaths
    -------------------------------------------------------------------

    if not rest then

        ----------------------------------------------------------------
        -- Fall damage
        ----------------------------------------------------------------

        -- English
        local fallZone, fallLevel = string.match(
            afterName,
            "%s*fell to their death in (.+)! They were level (%d+)"
        )

        if fallZone and fallLevel then
            return makeDeath(name, "Fall damage", fallZone, fallLevel)
        end

        -- French
        local frenchFallZone, frenchFallLevel = string.match(
            afterName,
            "%s*a succombé en tombant %((.-)%)%s*!%s*Ce personnage%-joueur était de niveau (%d+)"
        )

        if frenchFallZone and frenchFallLevel then
            return makeDeath(name, "Fall damage", frenchFallZone, frenchFallLevel)
        end

        -- German
        local germanFallZone, germanFallLevel = string.match(
            afterName,
            "ist in (.-) in den Tod gestürzt! Die Stufe war (%d+)"
        )

        if germanFallZone and germanFallLevel then
            return makeDeath(name, "Fall damage", germanFallZone, germanFallLevel)
        end

        ----------------------------------------------------------------
        -- Drowning
        ----------------------------------------------------------------

        -- English
        local drownZone, drownLevel = string.match(
            afterName,
            "%s*drowned to death in (.+)! They were level (%d+)"
        )

        if drownZone and drownLevel then
            return makeDeath(name, "Drowning", drownZone, drownLevel)
        end

        -- French
        local frenchDrownZone, frenchDrownLevel = string.match(
            afterName,
            "%s*a succombé en se noyant %((.-)%)%s*.%s*Ce personnage%-joueur était de niveau (%d+)"
        )

        if frenchDrownZone and frenchDrownLevel then
            return makeDeath(name, "Drowning", frenchDrownZone, frenchDrownLevel)
        end

        -- German
        local germanDrownZone, germanDrownLevel = string.match(
            afterName,
            "ist in (.-) ertrunken! Die Stufe war (%d+)"
        )

        if germanDrownZone and germanDrownLevel then
            return makeDeath(name, "Drowning", germanDrownZone, germanDrownLevel)
        end

        ----------------------------------------------------------------
        -- Lava
        ----------------------------------------------------------------

        -- English
        local lavaZone, lavaLevel = string.match(
            afterName,
            "%s*was burnt to a crisp by lava in (.+)! They were level (%d+)"
        )

        if lavaZone and lavaLevel then
            return makeDeath(name, "Lava", lavaZone, lavaLevel)
        end

        -- French
        local frenchLavaZone, frenchLavaLevel = string.match(
            afterName,
            "%s*a péri dans la lave %((.-)%)%s*!%s*Ce personnage%-joueur était de niveau (%d+)"
        )

        if frenchLavaZone and frenchLavaLevel then
            return makeDeath(name, "Lava", frenchLavaZone, frenchLavaLevel)
        end

        -- German
        local germanLavaZone, germanLavaLevel = string.match(
            afterName,
            "%s*wurde in (.-) von Lava durchgebraten! Die Stufe war (%d+)"
        )

        if germanLavaZone and germanLavaLevel then
            return makeDeath(name, "Lava", germanLavaZone, germanLavaLevel)
        end

        ----------------------------------------------------------------
        -- Fatigue
        ----------------------------------------------------------------

        -- English
        local fatigueZone, fatigueLevel = string.match(
            afterName,
            "%s*died of fatigue in (.+)! They were level (%d+)"
        )

        if fatigueZone and fatigueLevel then
            return makeDeath(name, "Fatigue", fatigueZone, fatigueLevel)
        end

        -- French
        local frenchFatigueZone, frenchFatigueLevel = string.match(
            afterName,
            "%s*a succombé de fatigue %((.-)%)%s*!%s*Ce personnage%-joueur était de niveau (%d+)"
        )

        if frenchFatigueZone and frenchFatigueLevel then
            return makeDeath(name, "Fatigue", frenchFatigueZone, frenchFatigueLevel)
        end

        -- German
        local germanFatigueZone, germanFatigueLevel = string.match(
            afterName,
            "ist in (.-) an Erschöpfung gestorben! Die Stufe war (%d+)"
        )

        if germanFatigueZone and germanFatigueLevel then
            return makeDeath(name, "Fatigue", germanFatigueZone, germanFatigueLevel)
        end

        return nil
    end

    -------------------------------------------------------------------
    -- Final English creature kill parsing
    -------------------------------------------------------------------

    local killer, zone = string.match(rest, "^(.*) in (.*)$")

    if not killer or not zone then
        return nil
    end

    killer = string.gsub(killer, "^a ", "")
    killer = string.gsub(killer, "^an ", "")

    return makeDeath(name, killer, zone, level)
end
