local ReviveLang = {}

---@class LangMap
local lang = {
	["awaitingReviveMessage"] = "You are awaiting revival.",
	["awaitingReviveOtherMessage"] = "%name has been downed! Activate them to revive them.",
	["bleedingOutMessage"] = "You have %seconds seconds before you bleed out.",
	["giveInPrompt"] = "Type /die to give in.",
	["revivedReceiveMessage"] = "You have been revived by %name.",
	["revivedGiveMessage"] = "You have revived %name.",
	["revivedOtherMessage"] = "%receive has been revived by %give.",
	["bleedoutPlayerMessage"] = "You have died.",
	["bleedoutOtherMessage"] = "%name has bled out.",
	["defaultSuicide"] = "%name committed suicide.",
	["defaultKilledByPlayer"] = "%name was killed by player %killer.",
	["defaultKilledByOther"] = "%name was killed by %killer.",
	["reviveMarkerName"] = "Player corpse - Use to revive!",
}

---comment
---@param key string
---@param data any|nil
---@return string
ReviveLang.GetLangText = function(key, data)
    local function replacer(wildcard)
        if data[wildcard] then
            return data[wildcard]
        else
            return ""
        end
    end

    local text = lang[key] or ""
    text = text:gsub("%%(%w+)", replacer)

    return text
end

return ReviveLang
