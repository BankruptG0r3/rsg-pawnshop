Config = {}

Config.Keybind = 0x760A9C6F -- G key

Config.Prompt = {
    title = "Pawn Shop",
    key = Config.Keybind,
    holdTime = 0.6,
}

Config.Locations = {
    ['valentine'] = {
        coords = vector3(-321.51, 799.62, 117.88),
        prompt = nil -- Will store prompt handle
    },
}

Config.Blip = {
    sprite = 1475879922,
    scale = 0.2,
    name = "Pawn Shop"
}

Config.SellableItems = {
    ['gold_bar'] = {
        price = 100
    }
}