local M = {}

---Calculate the fs distance between two paths
---@param destination string
---@param origin string
---@return number An integer representing the distance between the two paths
local get_distance_between_paths = function(destination, origin)
    if destination == nil then
        return math.huge
    end

    local common_prefix = ''
    local current_remaining = ''
    local other_remaining = ''

    for i = 1, math.min(#origin, #destination) do
        if origin:sub(i, i) == destination:sub(i, i) then
            common_prefix = common_prefix .. origin:sub(i, i)
        else
            current_remaining = origin:sub(i)
            other_remaining = destination:sub(i)
            break
        end
    end

    local distance = 0

    for _ in current_remaining:gmatch '/' do
        distance = distance + 1
    end

    for _ in other_remaining:gmatch '/' do
        distance = distance + 1
    end

    return distance
end

---Get the formatter related to the current buffer
---@param formatters table<string, string[]>
function M.get_closest(formatters)
    local current_buffer_path = vim.api.nvim_buf_get_name(0)

    local conform_formatters = require('conform').list_formatters(0)
    local desired_formatters = {}

    for _, value in ipairs(conform_formatters) do
        table.insert(desired_formatters, value.name)
    end

    -- shadow formatters with only the available ones
    formatters = require('utils.tables').filter(formatters, desired_formatters)

    ---Get the distance to the closest formatter config file
    ---@type table<string, number>
    local distance = {}

    -- we'll look for the closest config file given the
    -- formatters table we have above
    for formatter_name, formatter_config_paths in pairs(formatters) do
        local config_path = nil

        for _, path in ipairs(formatter_config_paths) do
            -- we'll look for a config file recursively until we hit
            -- the root of the project (which is considered a .git folder)
            local config_file_found = vim.fs.find(path, {
                path = current_buffer_path,
                stop = require('lspconfig.util').root_pattern '.git'(path),
                upward = true,
            })

            -- if we find a config file that matches one of the file names
            -- at formatter_config_paths set it as the preferred config
            -- and break out of the loop
            if config_file_found and config_file_found[1] ~= nil then
                config_path = config_file_found[1]
                break
            end
        end

        if config_path ~= nil then
            distance[formatter_name] = get_distance_between_paths(config_path, current_buffer_path)
        end
    end

    local shortest_path_key = nil
    local shortest_path_val = math.huge

    for formatter_name, formatter_distance in pairs(distance) do
        if formatter_distance < shortest_path_val then
            shortest_path_key = formatter_name
            shortest_path_val = formatter_distance
        end
    end

    if shortest_path_key == nil then
        return nil
    end

    return { shortest_path_key }
end

return M
