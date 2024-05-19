local strings = {}

function strings.fromTable(tbl)
    local result = '{'

    for k, v in pairs(tbl) do
        if type(v) == 'table' then
            result = result .. k .. '=' .. strings.fromTable(v) .. ', '
        else
            result = result .. k .. '=' .. tostring(v) .. ', '
        end
    end

    -- Remove the trailing comma and space, and close the table
    if result:sub(-2) == ', ' then
        result = result:sub(1, -3)
    end

    return result .. '}'
end

return strings
