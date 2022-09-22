local ParseRecord        = require('custom.saint.record.parser.primitive.ParseRecord')
local BinaryStringReader = require('custom.io.BinaryStringReader')
local BaseFieldsParser   = require('custom.saint.record.parser.BaseFieldsParser')

---@param binaryReader BinaryStringReader
---@param funcMap FuncMap
---@param compositeType CompositeType
---@param arrayType ArrayType
---@param context table|nil
return function(binaryReader, funcMap, compositeType, arrayType, context)
    context = context or {}
    local record = ParseRecord(binaryReader)
    local fieldsParser = BinaryStringReader(record.data)
    local fields = BaseFieldsParser(fieldsParser, funcMap, compositeType, arrayType, context)
    return {
        name = record.name,
        flags = record.flags,
        fields = fields,
    }
end