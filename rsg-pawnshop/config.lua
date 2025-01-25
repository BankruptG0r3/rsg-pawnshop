Config = {}

Config.Keybind = 0x760A9C6F -- G key

Config.Prompt = {
    title = "Pawn Shop",
    key = Config.Keybind,
    holdTime = 0.6,
}

Config.Locations = {
    ['valentine'] = {
        coords = vector3(-322.0, 803.0, 117.0),
        prompt = nil -- Will store prompt handle
    },
    ['blackwater'] = {
        coords = vector3(-871.0, -1337.0, 43.0),
        prompt = nil -- Will store prompt handle
    }
}

Config.Blip = {
    sprite = 1475879922,
    scale = 0.2,
    name = "Pawn Shop"
}

Config.SellableItems = {
    ['gold_nugget'] = {
        price = 10
    },
    ['gold_bar'] = {
        price = 100
    }
}