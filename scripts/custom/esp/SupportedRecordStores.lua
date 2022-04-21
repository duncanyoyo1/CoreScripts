local RecordTypesEnum = require('custom.esp.RecordTypesEnum')

local SupportedRecordStores = {
    RecordTypesEnum.RECORD_TYPES.ACTIVATOR,
    RecordTypesEnum.RECORD_TYPES.ALCHEMY_APPARATUS,
    RecordTypesEnum.RECORD_TYPES.ARMOR,
    RecordTypesEnum.RECORD_TYPES.BODY_PARTS,
    RecordTypesEnum.RECORD_TYPES.BOOK,
    RecordTypesEnum.RECORD_TYPES.CELL,
    RecordTypesEnum.RECORD_TYPES.CLOTHING,
    RecordTypesEnum.RECORD_TYPES.CONTAINER,
    RecordTypesEnum.RECORD_TYPES.CREATURE,
    RecordTypesEnum.RECORD_TYPES.DOOR,
    RecordTypesEnum.RECORD_TYPES.ENCHANTMENT,
    RecordTypesEnum.RECORD_TYPES.GAME_SETTING,
    RecordTypesEnum.RECORD_TYPES.INGREDIENT,
    RecordTypesEnum.RECORD_TYPES.LIGHT,
    RecordTypesEnum.RECORD_TYPES.LOCKPICKING_ITEMS,
    RecordTypesEnum.RECORD_TYPES.MISCELLANEOUS_ITEM,
    RecordTypesEnum.RECORD_TYPES.NPC,
    RecordTypesEnum.RECORD_TYPES.POTION,
    RecordTypesEnum.RECORD_TYPES.PROBE_ITEMS,
    RecordTypesEnum.RECORD_TYPES.REPAIR_ITEMS,
    RecordTypesEnum.RECORD_TYPES.SCRIPT,
    RecordTypesEnum.RECORD_TYPES.SOUND,
    RecordTypesEnum.RECORD_TYPES.SPELL,
    RecordTypesEnum.RECORD_TYPES.STATIC,
    RecordTypesEnum.RECORD_TYPES.WEAPON,
}

return SupportedRecordStores
