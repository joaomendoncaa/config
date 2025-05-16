local M = {}

M.sync_timers = {}

function M.sync_with_remote(opts)
    opts = opts or {}

    local paths = opts.paths or vim.fn.getcwd()
    local delay = opts.delay or 500
    local commit_prefix = opts.commit_prefix or 'sync: '
    local cwd = vim.fn.getcwd()

    if type(paths) == 'string' then
        paths = { paths }
    end

    local matching_path = nil

    for _, path in ipairs(paths) do
        if string.match(cwd, path .. '$') then
            matching_path = path
            break
        end
    end

    if not matching_path then
        return
    end

    local handle_on_exit = function(_, code)
        if code ~= 0 then
            vim.notify('Failed to sync changes to remote for ' .. matching_path, vim.log.levels.ERROR)
        end
    end

    local handle_on_start = vim.schedule_wrap(function()
        local commit_msg = string.format('%s: %s', commit_prefix, os.date '%Y-%m-%d %H:%M:%S')
        local cmd = {
            'sh',
            '-c',
            "git add . && git commit -m '" .. commit_msg .. "' && git push",
        }

        vim.fn.jobstart(cmd, {
            cwd = current_dir,
            on_exit = handle_on_exit,
        })

        if M.sync_timers[matching_path] then
            M.sync_timers[matching_path]:close()
            M.sync_timers[matching_path] = nil
        end
    end)

    if M.sync_timers[matching_path] then
        vim.uv.timer_stop(M.sync_timers[matching_path])
        M.sync_timers[matching_path]:close()
    end

    M.sync_timers[matching_path] = vim.uv.new_timer()
    M.sync_timers[matching_path]:start(delay, 0, handle_on_start)

    return M.sync_timers[matching_path]
end

function M.kill_sync_timer(path)
    if not path then
        return false
    end

    local timer = M.sync_timers[path]
    if timer then
        pcall(vim.uv.timer_stop, timer)
        pcall(function()
            timer:close()
        end)
        M.sync_timers[path] = nil
        return true
    end

    return false
end

function M.kill_sync_timers()
    local count = 0

    for path, timer in pairs(M.sync_timers) do
        if timer then
            pcall(vim.uv.timer_stop, timer)
            pcall(function()
                timer:close()
            end)
            M.sync_timers[path] = nil
            count = count + 1
        end
    end

    M.sync_timers = {}

    return count
end

return M
