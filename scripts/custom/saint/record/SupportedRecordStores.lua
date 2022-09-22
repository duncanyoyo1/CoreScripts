local RecordTypesEnum = require('custom.saint.record.RecordTypesEnum')

local SupportedRecordStores = {
    [RecordTypesEnum.RECORD_TYPES.ACTIVATOR] = true,
    [RecordTypesEnum.RECORD_TYPES.ALCHEMY_APPARATUS] = true,
    [RecordTypesEnum.RECORD_TYPES.ARMOR] = true,
    [RecordTypesEnum.RECORD_TYPES.BODY_PARTS] = true,
    [RecordTypesEnum.RECORD_TYPES.BOOK] = true,
    [RecordTypesEnum.RECORD_TYPES.CELL] = true,
    [RecordTypesEnum.RECORD_TYPES.CLOTHING] = true,
    [RecordTypesEnum.RECORD_TYPES.CONTAINER] = true,
    [RecordTypesEnum.RECORD_TYPES.CREATURE] = true,
    [RecordTypesEnum.RECORD_TYPES.DOOR] = true,
    [RecordTypesEnum.RECORD_TYPES.ENCHANTMENT] = true,
    [RecordTypesEnum.RECORD_TYPES.GAME_SETTING] = true,
    [RecordTypesEnum.RECORD_TYPES.INGREDIENT] = true,
    [RecordTypesEnum.RECORD_TYPES.LIGHT] = true,
    [RecordTypesEnum.RECORD_TYPES.LOCKPICKING_ITEMS] = true,
    [RecordTypesEnum.RECORD_TYPES.MISCELLANEOUS_ITEM] = true,
    [RecordTypesEnum.RECORD_TYPES.NPC] = true,
    [RecordTypesEnum.RECORD_TYPES.POTION] = true,
    [RecordTypesEnum.RECORD_TYPES.PROBE_ITEMS] = true,
    [RecordTypesEnum.RECORD_TYPES.REPAIR_ITEMS] = true,
    [RecordTypesEnum.RECORD_TYPES.SCRIPT] = true,
    [RecordTypesEnum.RECORD_TYPES.SOUND] = true,
    [RecordTypesEnum.RECORD_TYPES.SPELL] = true,
    [RecordTypesEnum.RECORD_TYPES.STATIC] = true,
    [RecordTypesEnum.RECORD_TYPES.WEAPON] = true,
}

return SupportedRecordStores
