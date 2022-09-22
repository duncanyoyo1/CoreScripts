local time = require('time')

local scriptConfig = {
    ResetTime = time.toSeconds(time.days(1)),
    Blacklist = {
        -- You can add cells here or via the command, which is saved/laoded via SSS
    },

    --- Advanced
    --- It should be known that SliceAmount * CellResetCheckPeriod = total time to check all cells for reset

    SliceAmount = 30, --- Number of slices
    CellNameLoadPeriod = time.hours(1), --- Period for loading complete cell name list
    CellResetCheckPeriod = time.minutes(1), --- Period for checking for cell resets
}
return scriptConfig
