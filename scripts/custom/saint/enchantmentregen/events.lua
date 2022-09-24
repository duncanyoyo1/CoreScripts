local customEventHooks       = require('customEventHooks')
local SaintLogger            = require('custom.saint.common.logger.main')
local EnchantRegenerationApi = require('custom.saint.enchantmentregen.api')

local logger = SaintLogger:GetLogger('SaintEnchantmentRegeneration')

customEventHooks.registerHandler("OnPlayerFinishLogin", EnchantRegenerationApi.OnPlayerFinishLoginHandler)

customEventHooks.registerHandler("OnServerPostInit", function(eventStatus)
    logger:Info("Starting SaintEnchantmentRegeneration...")
    return eventStatus
end)
