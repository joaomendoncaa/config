local M = {}

--- Truncate a string in the middle, inserting a separator.
---
---@param str string The string to be truncated
---@param opts table Optional parameters
---             length - The maximum allowed length of the string
---             separator - The separator to insert in the middle of the truncated string
---@return string The truncated string
---
---TODO: be able to choose the position of the separator (left, right, center)
function M.truncateString(str, opts)
    opts = opts or {}

    local length = opts.length or 80
    local separator = opts.separator or '...'

    local sep_length = #separator
    local part_length = math.floor((length - sep_length) / 2)

    return str:sub(1, part_length) .. separator .. str:sub(-part_length)
end

---Truncate chunks with a separator while preserving highlight groups.
---
---@param chunks any[] A list of `[text, hl_group]` arrays, each representing a
---               text chunk with specified highlight. `hl_group` element can
---               be omitted for no highlight.
---@param opts table Optional parameters
---             length - The maximum allowed length of the string
---             separator - The separator to insert in the middle of the truncated string
---             separator_hg - The highlight group to use for the separator
---@return any[] The truncated chunks
---
---TODO: be able to choose the position of the separator (left, right, center)
function M.truncateChunks(chunks, opts)
    opts = opts or {}

    local length = opts.length or 80
    local separator = opts.separator or '...'
    local separator_hg = opts.separator_hg or ''

    print('length', length)

    -- calculate total length of all chunks
    local total_length = 0
    for _, chunk in ipairs(chunks) do
        total_length = total_length + #chunk[1]
    end

    print('total_length', total_length)

    -- if total length is less or equal to the maxium length, return the original chunks
    if total_length <= length then
        return chunks
    end

    local sep_length = #separator
    local part_length = math.floor((length - sep_length) / 2)
    local truncated_chunks = {}
    local unrolled_chunks = {}

    print('part_length', part_length)

    -- unroll chunks to a list of [character, highlight_group]
    for _, chunk in ipairs(chunks) do
        local chunk_text = chunk[1]
        local chunk_hg = chunk[2] or ''

        -- Insert each character of chunk_text as a separate chunk
        local i = 1
        while i <= #chunk_text do
            local char = chunk_text:sub(i, i)

            -- Check if the current character is a multi-byte character
            -- This assumes that all bytes in a multi-byte character have a byte value greater than 127
            if string.byte(char) >= 128 then
                -- Append the next byte(s) to form the full multi-byte character
                local j = i + 1
                while j <= #chunk_text do
                    local next_char = chunk_text:sub(j, j)
                    if string.byte(next_char) >= 128 then
                        char = char .. next_char
                        j = j + 1
                    else
                        break
                    end
                end
            end

            -- Insert the character slice into unrolled_chunks
            table.insert(unrolled_chunks, { char, chunk_hg })

            -- Move to the next character
            i = i + #char
        end
    end

    local pos_start = part_length
    local pos_end = #unrolled_chunks - part_length

    -- loop through each table inside unrolled_chunks and in case it
    -- is within the range of start and end to remove it
    for k, v in ipairs(unrolled_chunks) do
        local is_string = type(v[1]) == 'string'
        local has_text = v[1]:len() > 0
        local is_in_range = k >= pos_start and k <= pos_end

        local is_valid = is_string and has_text and not is_in_range

        if is_valid then
            table.insert(truncated_chunks, v)
        end
    end

    table.insert(truncated_chunks, #truncated_chunks / 2, { separator, separator_hg })

    return truncated_chunks
end

---Stringify a table
---
---@param tbl table The table to stringify.
---@return string string The stringified table.
function M.fromTable(tbl)
    local result = '{'

    for k, v in pairs(tbl) do
        if type(v) == 'table' then
            result = result .. k .. '=' .. M.fromTable(v) .. ', '
        else
            result = result .. k .. '=' .. tostring(v) .. ', '
        end
    end

    -- Remove the trailing comma and space
    -- TODO: hacky, but works
    if result:sub(-2) == ', ' then
        result = result:sub(1, -3)
    end

    result = result .. '}'

    return result
end

return M
