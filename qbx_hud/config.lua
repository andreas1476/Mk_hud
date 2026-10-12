Config = {}

Config.ServerName = 'test'

-- 'kmh' eller 'mph'
Config.SpeedUnit = 'kmh'

-- Skjul GTA's standard HUD-elementer (penge, vejnavn, wanted stars osv.)
Config.HideDefaultHud = true

-- Sorte penge: scriptet tjekker først en money-konto i qbx_core (money.black_money)
-- og hvis den ikke findes, tæller det items i ox_inventory med dette navn.
Config.BlackMoneyAccount = 'black_money'
Config.BlackMoneyItem = 'black_money'
