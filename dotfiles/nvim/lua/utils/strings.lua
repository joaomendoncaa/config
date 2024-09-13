local M = {}

---@alias HighlightedChunks table<string, string>[]

---Truncate a string in the middle, inserting a separator.
---
---@param str string The string to be truncated
---@param opts table? Optional parameters
---             length - The maximum allowed length of the string
---             separator - The separator to insert in the middle of the truncated string
---@return string string The truncated string
---TODO: be able to choose the position of the separator (left, right, center)
function M.truncateString(str, opts)
    opts = opts or {}

    local length = opts.length or vim.o.columns / 2
    local separator = opts.separator or '...'

    local sep_length = #separator
    local part_length = math.floor((length - sep_length) / 2)

    return str:sub(1, part_length) .. separator .. str:sub(-part_length)
end

---Truncate chunks with a separator while preserving highlight groups.
---
---@param chunks HighlightedChunks A list of `{ text, hl_group }` arrays, each representing a text chunk with specified highlight. `hl_group` element can be omitted for no highlight.
---@param opts table? Optional parameters.
---             length - The maximum allowed length of the string
---             separator - The separator to insert in the middle of the truncated string
---             separator_hg - The highlight group to use for the separator
---@return HighlightedChunks chunks The truncated chunks
---TODO: be able to choose the position of the separator (left, right, center)
---TODO: support chunks nesting
function M.truncateChunks(chunks, opts)
    opts = opts or {}

    local length = opts.length or vim.o.columns / 2
    local separator = opts.separator or '...'
    local separator_hg = opts.separator_hg or ''

    -- calculate total length of all chunks
    local total_length = 0
    for _, chunk in ipairs(chunks) do
        total_length = total_length + #chunk[1]
    end

    -- if total length is less or equal to the maxium length, return the original chunks
    if total_length <= length then
        return chunks
    end

    local sep_length = #separator
    local part_length = math.floor((length - sep_length) / 2)
    local truncated_chunks = {}
    local unrolled_chunks = {}

    -- unroll chunks to a linear list of single [character, highlight_group]s
    -- but construct these single character chunks with utf8 encoding
    for _, chunk in ipairs(chunks) do
        local chunk_text = chunk[1]
        local chunk_hg = chunk[2] or ''
        local chunk_length = #chunk_text

        local char_pointer = 1

        while char_pointer <= chunk_length do
            local utf8_char_buffer = chunk_text:sub(char_pointer, char_pointer)

            -- check if the current character is a multi-byte character
            -- assuming all bytes in a "multi-byte" character have a byte value greater than 127
            if string.byte(utf8_char_buffer) >= 128 then
                local next_char_pointer = char_pointer + 1

                while next_char_pointer <= chunk_length do
                    local next_char = chunk_text:sub(next_char_pointer, next_char_pointer)

                    if string.byte(next_char) >= 128 then
                        utf8_char_buffer = utf8_char_buffer .. next_char
                        next_char_pointer = next_char_pointer + 1
                    else
                        break
                    end
                end
            end

            -- insert the newly constructed utf8 character into unrolled_chunks as one
            table.insert(unrolled_chunks, { utf8_char_buffer, chunk_hg })

            -- move pointer to the next character
            char_pointer = char_pointer + #utf8_char_buffer
        end
    end

    local pos_start = part_length
    local pos_end = #unrolled_chunks - part_length

    -- loop through each table inside unrolled_chunks and in case it
    -- is not empty and within the range to be truncated remove it
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

return M
