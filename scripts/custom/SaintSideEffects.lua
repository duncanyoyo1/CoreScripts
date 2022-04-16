-------------------------------------------------------------------------------
--- SaintSideEffects
--- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--- Creates side effects whenever a player has a the first journal entry added.
--- This is intended to alleviate issues with kill counts for quests that check
--- them.
-------------------------------------------------------------------------------
local customEventHooks = require('customEventHooks')
local SaintCellReset = require('custom.SaintCellReset')
local SaintLogger = require('custom.SaintLogger')
local SaintCellResetManager = require('custom.SaintCellResetManager')

--TODO: This is largely incomplete and would need some proper databas-ing to be valuable for later quests.
--TODO: This does help alleviate the balmora beginning conflicts sorta, but has issues with quests later on

local logger = SaintLogger:CreateLogger('SaintSideEffects')

-- Hoisting workaround
local SaintSideEffects = {}
local CreatedSideEffects = {}
local scriptConfig = {}

-- The entry point
---@param eventStatus EventStatus validation object
---@param pid number player id for who triggered event
SaintSideEffects.OnPlayerJournalHandler = function(eventStatus, pid)
    if not eventStatus.validCustomHandlers then
        return eventStatus
    end
    local player = Players[pid]
    local journal = player.data.journal
    local latestEntry = journal[#journal]

    -- TODO: Investigate more performant solution here. Perhaps, cache quests into a map for faster access
    -- TODO: Not performant by any means, but TECHNICALLY works
    local firstJournalEntryForQuest = true
    for _, value in ipairs(journal) do
        local sameQuestDiffIndex = value.quest == latestEntry.quest and value.index ~= latestEntry.index
        if sameQuestDiffIndex then
            firstJournalEntryForQuest = false
        end
    end

    if firstJournalEntryForQuest then
        local cleanedQuestName = string.lower(latestEntry.quest)
        local sideEffect = scriptConfig.questSideEffectHadlers[cleanedQuestName]
        if sideEffect ~= nil then
            logger:Info("Attempting to clear data for quest '" .. latestEntry.quest .. "'")
            sideEffect(pid)
        else
            logger:Info("No side effect found for quest '" .. latestEntry.quest .. "'")
        end
    end
    return eventStatus
end

---@param eventStatus EventStatus
SaintSideEffects.Init = function(eventStatus)
    local sideEffectCount = 0
    for _ in pairs(scriptConfig.questSideEffectHadlers) do
        sideEffectCount = sideEffectCount + 1
    end
    logger:Info("Loading " .. sideEffectCount .. " side effects")
    return eventStatus
end

-- Processing --

---Clear data for cell or mark it as clearable
---@param cellDescriptions string[] Names of cells to clear data on
---@return boolean whether the operation succeeded or not
local ClearCellDataForCells = function (cellDescriptions)
    local didReset = true
    for _, cellDescription in pairs(cellDescriptions) do
        if SaintCellResetManager.IsCellResetValid(cellDescription) then
            ---Saint Note: Create function in cell reset manager for requesting a reset, this knows too much
            SaintCellReset.ResetCell(cellDescription)
        else
            logger:Warn("[SaintSideEffect - WARN] Unable to reset cell '" .. cellDescription .. "' despite checking.")
            ---Saint Note: This method seems better suited in the manager?
            SaintCellReset.MarkCellForReset(cellDescription)
            didReset = false
        end
    end
    if didReset then
        logger:Info("Cells have been reset.")
    else
        logger:Info("One or more cells failed to reset.")
    end
    return didReset
end

---@param actorList string[] names of actors to clear kill counts for
local ClearKillCountsForCharacters = function(actorList)
    for _, refId in pairs(actorList) do
        WorldInstance.data.kills[refId] = 0
    end
    WorldInstance:QuicksaveToDrive()
    for pid in pairs(Players) do
        WorldInstance:LoadKills(pid, true)
    end
end

---Create a side effect for when a quest is added to a player's journal
---@param cellDescriptionList string[] cells to reset
---@param actorList string[] actors to reset
---@return function callback that will clear cell data and inform players if a clear may not be possible
SaintSideEffects.CreateSideEffect = function(cellDescriptionList, actorList)
    return function(pid)
        if not ClearCellDataForCells(cellDescriptionList) then
            tes3mp.CustomMessageBox(pid, config.customMenuIds.questFault, scriptConfig.faultMessage, "Ok")
        end
        ClearKillCountsForCharacters(actorList)
    end
end

-- Side Effects

CreatedSideEffects.AntabolisInformant = SaintSideEffects.CreateSideEffect({
    "Arkngthand, Cells of Hollow Hand"
}, {})

CreatedSideEffects.GraMuzgobInformant = SaintSideEffects.CreateSideEffect({
    "Andrano Ancestral Tomb"
}, {})

CreatedSideEffects.RatHunt = SaintSideEffects.CreateSideEffect({
    "Balmora, Drarayne Thelas' House",
    "Balmora, Drarayne Thelas' Storage"
}, {
    "rat_cave_fgrh"
})

CreatedSideEffects.EggPoachers = SaintSideEffects.CreateSideEffect({
    "Shulk Egg Mine, Queen's Lair"
}, {
    "sevilo othan",
    "daynila valas"
})

CreatedSideEffects.TelvanniAgents = SaintSideEffects.CreateSideEffect({
    "Ashanammu"
}, {
    "fothnya herothran",
    "sathasa nerothren",
    "alynu aralen",
    "alveleg"
})

CreatedSideEffects.DuraGraBol = SaintSideEffects.CreateSideEffect({
    "Balmora, Dura gra-Bol's House"
}, {
    "dura gra-bol"
})

CreatedSideEffects.LarriusVaroTellsAStory = SaintSideEffects.CreateSideEffect({
    "Balmora, Council Club"
}, {
    "madrale thirith",
    "marasa aren",
    "sovor trandel",
    "thanelen velas",
    "vadusa sathryon"
})

-- SCRIPT CONFIG

-- TODO: this sucks, creating a side effect should auto-add to something
-- Do a thing when certain quests get added for the first time
scriptConfig.questSideEffectHadlers = {
    ["a1_2_antabolisinformant"] = CreatedSideEffects.AntabolisInformant,
    ["a1_4_muzgobinformant"] = CreatedSideEffects.GraMuzgobInformant,
    ["fg_rathunt"] = CreatedSideEffects.RatHunt,
    ["fg_egg_poachers"] = CreatedSideEffects.EggPoachers,
    ["fg_telvanni_agents"] = CreatedSideEffects.TelvanniAgents,
    ["fg_orcbounty"] = CreatedSideEffects.DuraGraBol,
    ["town_balmora"] = CreatedSideEffects.LarriusVaroTellsAStory
}

scriptConfig.faultMessage =
[[Unable to fully reset this quest.

The locations and NPC's should be reset after approximately 5 minutes.]]

-- Register listeners
customEventHooks.registerHandler("OnPlayerJournal", SaintSideEffects.OnPlayerJournalHandler)
customEventHooks.registerHandler("OnServerPostInit", SaintSideEffects.Init)

return SaintSideEffects
