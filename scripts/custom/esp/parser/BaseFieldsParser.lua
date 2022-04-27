local ParseField         = require('custom.esp.parser.primitive.ParseField')
local BinaryStringReader = require('custom.io.BinaryStringReader')
local Size               = require('custom.esp.parser.primitive.Size')
local DELEFieldParser    = require('custom.esp.parser.primitive.DELEFieldParser')

---@param binaryReader BinaryStringReader
---@param funcMap FuncMap
---@param compositeType CompositeType
---@param arrayType ArrayType
---@param context table
return function(binaryReader, funcMap, compositeType, arrayType, context)
    local fields = {}
    while binaryReader:HasData() do
        local fieldName = binaryReader:Peak(Size.INTEGER)
        local singularFunc = funcMap[fieldName]
        local compositeFunc = compositeType[fieldName]
        local arrayFieldName = arrayType[fieldName]
        local data

        -- IDK bout this, but this should PROBABLY be true
        if fields[fieldName] ~= nil and not arrayFieldName then
            -- probably should be a break condition
            -- error('Attempting to write to an already written field!')
            -- We are looking into something that is either ANOTHER record
            -- or another array item
            ---Saint Note: This feels like a hack
            break
        end

        ---Saint Note: Move 'DELE' to somewhere else
        if fieldName == 'DELE' then
            local field = ParseField(binaryReader)
            data = DELEFieldParser(BinaryStringReader(field.data))
        elseif compositeFunc then
            data = compositeFunc(binaryReader, context)
        elseif singularFunc then
            local field = ParseField(binaryReader)
            data = singularFunc(BinaryStringReader(field.data), context)
        else
            -- We are looking into something that is either ANOTHER record
            -- or another array item
            ---Saint Note: This feels like a hack
            break
        end

        if arrayFieldName then
            local array = fields[arrayFieldName] or {}
            table.insert(array, data)
            fields[arrayFieldName] = array
        elseif compositeFunc then
            -- if the field is composite but not an array
            for key, value in pairs(data) do
                fields[key] = value
            end
        else
            fields[fieldName] = data
        end
    end
    return fields
end