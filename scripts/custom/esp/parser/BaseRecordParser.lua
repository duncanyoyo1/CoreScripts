local ParseRecord        = require('custom.esp.parser.primitive.ParseRecord')
local BinaryStringReader = require('custom.io.BinaryStringReader')
local BaseFieldsParser   = require('custom.esp.parser.BaseFieldsParser')

---@param binaryReader BinaryStringReader
---@param funcMap FuncMap
---@param compositeType CompositeType
---@param arrayType ArrayType
return function(binaryReader, funcMap, compositeType, arrayType)
    local record = ParseRecord(binaryReader)
    local fieldsParser = BinaryStringReader(record.data)
    record.fields = BaseFieldsParser(fieldsParser, funcMap, compositeType, arrayType)
    return record
end