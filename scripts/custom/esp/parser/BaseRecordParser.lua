local ParseRecord        = require('custom.esp.parser.primitive.ParseRecord')
local BinaryStringReader = require('custom.io.BinaryStringReader')
local BaseFieldsParser   = require('custom.esp.parser.BaseFieldsParser')

---@param binaryReader BinaryStringReader
---@param funcMap FuncMap
---@param compositeType CompositeType
---@param arrayType ArrayType
---@param context table|nil
return function(binaryReader, funcMap, compositeType, arrayType, context)
    context = context or {}
    local record = ParseRecord(binaryReader)
    local fieldsParser = BinaryStringReader(record.data)
    record.fields = BaseFieldsParser(fieldsParser, funcMap, compositeType, arrayType, context)
    return record
end