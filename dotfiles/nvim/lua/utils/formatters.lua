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

---@param formatters table<string, string[]>
function M.get_closest(formatters)
    local current_buffer_path = vim.api.nvim_buf_get_name(0)
    local current_working_dir = vim.fn.getcwd()
    local conform_formatters = require('conform').list_formatters(0)

    local desired_formatters = {}
    for _, value in ipairs(conform_formatters) do
        desired_formatters[value.name] = true
    end

    local available_formatters = {}
    for formatter_name, formatter_config_paths in pairs(formatters) do
        if desired_formatters[formatter_name] then
            available_formatters[formatter_name] = formatter_config_paths
        end
    end

    local distances = {}

    for formatter_name, formatter_config_paths in pairs(available_formatters) do
        local closest_config_path = nil
        local shortest_distance = math.huge

        for _, path in ipairs(formatter_config_paths) do
            local config_file_found = vim.fs.find(path, {
                path = current_buffer_path,
                upward = true,
                stop = current_working_dir,
            })

            if config_file_found and config_file_found[1] then
                local current_distance = get_distance_between_paths(config_file_found[1], current_buffer_path)
                if current_distance < shortest_distance then
                    shortest_distance = current_distance
                    closest_config_path = config_file_found[1]
                end
            end
        end

        if closest_config_path then
            distances[formatter_name] = shortest_distance
        end
    end

    local closest_formatter = nil
    local shortest_distance = math.huge
    for formatter_name, distance in pairs(distances) do
        if distance < shortest_distance then
            closest_formatter = formatter_name
            shortest_distance = distance
        end
    end

    return closest_formatter and { closest_formatter } or nil
end

return M
