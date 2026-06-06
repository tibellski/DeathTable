function parseDeathMessage(message)
    local nameEnd = string.find(message, "]", 1, true)

    if not nameEnd then
        return nil
    end

    local name = string.sub(message, 2, nameEnd - 1)

    name = string.gsub(name, "^Hplayer:", "")
    name = string.gsub(name, "|h.*$", "")
    name = string.gsub(name, "%-.*$", "")

    local afterName = string.sub(message, nameEnd + 1)

    afterName = string.gsub(afterName, "\194\160", " ")
    afterName = string.gsub(afterName, " ", " ")

    local rest, level = string.match(
        afterName,
        "%s*has been slain by (.+)! They were level (%d+)"
    )

    local frenchKiller, frenchZone, frenchLevel = string.match(
        afterName,
        "a succombé en combattant ce personnage adverse%s*:%s*(.-)%s*%((.-)%)%s*!%s*Ce personnage%-joueur était de niveau (%d+)"
    )

    if frenchKiller and frenchZone and frenchLevel then
        return {
            name = name,
            killer = frenchKiller,
            zone = frenchZone,
            level = frenchLevel
        }
    end

    local germanKiller, germanZone, germanLevel = string.match(
        afterName,
        "%s*wurde von einer Kreatur %((.-)%) in (.-) getötet! Die Stufe war (%d+)"
    )

    if germanKiller and germanZone and germanLevel then
        return {
            name = name,
            killer = germanKiller,
            zone = germanZone,
            level = germanLevel
        }
    end

    local germanPlayerKiller, germanPlayerZone, germanPlayerLevel = string.match(
        afterName,
        "wurde von (.-) in (.-) getötet! Die Stufe war (%d+)"
    )

    if germanPlayerKiller and germanPlayerZone and germanPlayerLevel then
        return {
            name = name,
            killer = germanPlayerKiller,
            zone = germanPlayerZone,
            level = germanPlayerLevel
        }
    end

    if not rest then
        local fallZone, fallLevel = string.match(
            afterName,
            "%s*fell to their death in (.+)! They were level (%d+)"
        )

        if fallZone and fallLevel then
            return {
                name = name,
                killer = "Fall damage",
                zone = fallZone,
                level = fallLevel
            }
        end

        local germanFallZone, germanFallLevel = string.match(
            afterName,
            "ist in (.-) in den Tod gestürzt! Die Stufe war (%d+)"
        )

        if germanFallZone and germanFallLevel then
            return {
                name = name,
                killer = "Fall damage",
                zone = germanFallZone,
                level = germanFallLevel
            }
        end

        local drownZone, drownLevel = string.match(
            afterName,
            "%s*drowned to death in (.+)! They were level (%d+)"
        )

        if drownZone and drownLevel then
            return {
                name = name,
                killer = "Drowning",
                zone = drownZone,
                level = drownLevel
            }
        end

        local frenchDrownZone, frenchDrownLevel = string.match(
            afterName,
            "%s*a succombé en se noyant %((.-)%)%s*.%s*Ce personnage%-joueur était de niveau (%d+)"
        )

        if frenchDrownZone and frenchDrownLevel then
            return {
                name = name,
                killer = "Drowning",
                zone = frenchDrownZone,
                level = frenchDrownLevel
            }
        end

        local germanDrownZone, germanDrownLevel = string.match(
            afterName,
            "ist in (.-) ertrunken! Die Stufe war (%d+)"
        )

        if germanDrownZone and germanDrownLevel then
            return {
                name = name,
                killer = "Drowning",
                zone = germanDrownZone,
                level = germanDrownLevel
            }
        end

        local lavaZone, lavaLevel = string.match(
        afterName,
            "%s*was burnt to a crisp by lava in (.+)! They were level (%d+)"
        )

        if lavaZone and lavaLevel then
            return {
                name = name,
                killer = "Lava",
                zone = lavaZone,
                level = lavaLevel
            }
        end

        local frenchLavaZone, frenchLavaLevel = string.match(
            afterName,
            "%s*a péri dans la lave %((.-)%)%s*!%s*Ce personnage%-joueur était de niveau (%d+)"
        )

        if frenchLavaZone and frenchLavaLevel then
            return {
                name = name,
                killer = "Lava",
                zone = frenchLavaZone,
                level = frenchLavaLevel
            }
        end

        local fatigueZone, fatigueLevel = string.match(
            afterName,
            "%s*died of fatigue in (.+)! They were level (%d+)"
        )

        if fatigueZone and fatigueLevel then
            return {
                name = name,
                killer = "Fatigue",
                zone = fatigueZone,
                level = fatigueLevel
            }
        end

        return nil
    end

    local killer, zone = string.match(rest, "^(.*) in (.*)$")

    if not killer or not zone then
        return nil
    end

    killer = string.gsub(killer, "^a ", "")
    killer = string.gsub(killer, "^an ", "")

    return {
        name = name,
        killer = killer,
        zone = zone,
        level = level
    }
end