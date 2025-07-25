local M = {}

local ignored_patterns = {}

if not vim._schedule_wrapped then
    local shallow_schedule = vim.schedule

    vim.schedule = function(fn)
        shallow_schedule(function()
            local ok, err = pcall(fn)

            if not ok and type(err) == 'string' then
                for _, pat in ipairs(ignored_patterns) do
                    if err:match(pat) then
                        return
                    end
                end
                error(err)
            end
        end)
    end

    vim._schedule_wrapped = true
end

function M.ignore(patterns)
    for _, pat in ipairs(patterns) do
        table.insert(ignored_patterns, pat)
    end
end

return M
