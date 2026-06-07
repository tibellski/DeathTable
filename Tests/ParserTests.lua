local parserPath = arg and arg[0] and arg[0]:match("^(.*[\\/])")

if parserPath then
    parserPath = parserPath .. "..\\Parser.lua"
else
    parserPath = "Parser.lua"
end

dofile(parserPath)

local cases = {
    {
        name = "English creature kill",
        message = "[Tibbo] has been slain by a Defias Pillager in Westfall! They were level 14",
        expected = {
            name = "Tibbo",
            killer = "Defias Pillager",
            zone = "Westfall",
            level = "14"
        }
    },
    {
        name = "English creature kill with extra spaces",
        message = "[Tibbo] has been slain by a   Defias Pillager   in   Westfall  ! They were level 14",
        expected = {
            name = "Tibbo",
            killer = "Defias Pillager",
            zone = "Westfall",
            level = "14"
        }
    },
    {
        name = "English lava",
        message = "[Rurahc] was burnt to a crisp by lava in Ironforge! They were level 45",
        expected = {
            name = "Rurahc",
            killer = "Lava",
            zone = "Ironforge",
            level = "45"
        }
    },
    {
        name = "English fall damage",
        message = "[Fallguy] fell to their death in Thunder Bluff! They were level 22",
        expected = {
            name = "Fallguy",
            killer = "Fall damage",
            zone = "Thunder Bluff",
            level = "22"
        }
    },
    {
        name = "English drowning",
        message = "[Swimmer] drowned to death in Stranglethorn Vale! They were level 31",
        expected = {
            name = "Swimmer",
            killer = "Drowning",
            zone = "Stranglethorn Vale",
            level = "31"
        }
    },
    {
        name = "English fatigue",
        message = "[Faraway] died of fatigue in The Great Sea! They were level 28",
        expected = {
            name = "Faraway",
            killer = "Fatigue",
            zone = "The Great Sea",
            level = "28"
        }
    },
    {
        name = "French PvP kill",
        message = "[Tibbo] a succombé en combattant Ronk (Durotar)\194\160! Ce personnage-joueur était de niveau 35.",
        expected = {
            name = "Tibbo",
            killer = "Ronk",
            zone = "Durotar",
            level = "35"
        }
    },
    {
        name = "French PvP kill with padded fields",
        message = "[Tibbo] a succombé en combattant   Ronk   (  Durotar  ) ! Ce personnage-joueur était de niveau 35.",
        expected = {
            name = "Tibbo",
            killer = "Ronk",
            zone = "Durotar",
            level = "35"
        }
    },
    {
        name = "French creature kill",
        message = "[Tibbo] a succombé en combattant ce personnage adverse : Sanglier (Durotar)\194\160! Ce personnage-joueur était de niveau 10",
        expected = {
            name = "Tibbo",
            killer = "Sanglier",
            zone = "Durotar",
            level = "10"
        }
    },
    {
        name = "German creature kill",
        message = "[Tibbo] wurde von einer Kreatur (Koboldminenarbeiter) in Wald von Elwynn getötet! Die Stufe war 7",
        expected = {
            name = "Tibbo",
            killer = "Koboldminenarbeiter",
            zone = "Wald von Elwynn",
            level = "7"
        }
    },
    {
        name = "German PvP kill",
        message = "[Tibbo] wurde von Ronk in Durotar getötet! Die Stufe war 35",
        expected = {
            name = "Tibbo",
            killer = "Ronk",
            zone = "Durotar",
            level = "35"
        }
    }
}

local function fail(caseName, field, expected, actual)
    error(
        string.format(
            "%s: expected %s to be %q, got %q",
            caseName,
            field,
            tostring(expected),
            tostring(actual)
        ),
        0
    )
end

for _, case in ipairs(cases) do
    local actual = parseDeathMessage(case.message)

    if not actual then
        error(case.name .. ": parser returned nil", 0)
    end

    for field, expected in pairs(case.expected) do
        if actual[field] ~= expected then
            fail(case.name, field, expected, actual[field])
        end
    end
end

print(string.format("Parser tests passed: %d", #cases))
