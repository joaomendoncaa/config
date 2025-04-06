local FT_NVIMTREE = 'nvimtree'
local FT_CODECOMPANION = 'codecompanion'

local commands = require 'utils.commands'
local clipboard = require 'utils.clipboard'

local toggle_wrap = function()
    vim.cmd 'set wrap!'
end

local buffer_delete = function()
    vim.cmd 'call delete(expand("%")) | bdelete!'
end

local touch_command = function(opts)
    local args = vim.split(opts.args, '%s+')
    local subcommand, path = args[1], args[2]

    if not path then
        vim.notify('Path argument required', vim.log.levels.ERROR)
        return
    end

    local final_path = subcommand == 'relative' and (vim.fn.getcwd() .. '/' .. path) or path

    if not vim.tbl_contains({ 'absolute', 'relative' }, subcommand) then
        vim.notify('Invalid subcommand. Use: Touch absolute|relative <path>', vim.log.levels.ERROR)
        return
    end

    local parent = vim.fn.fnamemodify(final_path, ':h')
    vim.fn.mkdir(parent, 'p')

    local f = io.open(final_path, 'a')
    if f then
        f:close()
    end
end

local touch_complete = function(arglead, cmdline)
    local args = vim.split(cmdline, '%s+')
    if #args == 2 then
        return { 'absolute', 'relative' }
    elseif #args >= 3 then
        return vim.fn.getcompletion(arglead, 'file')
    end
    return {}
end

local buffer_messages = function()
    local result = vim.api.nvim_exec2('messages', { output = true })

    vim.cmd 'new'
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(result.output, '\n'))
    vim.bo.buftype = 'nofile'
    vim.bo.bufhidden = 'wipe'
    vim.bo.swapfile = false
end

local auto_highlight_yank = function()
    vim.highlight.on_yank()
end

local auto_keep_unique_sidebar = function()
    local buf_l = vim.api.nvim_get_current_buf()
    local buf_l_ft = string.lower(vim.bo[buf_l].filetype or '')

    if not (buf_l_ft == FT_NVIMTREE or buf_l_ft == FT_CODECOMPANION) then
        return
    end

    local windows = vim.api.nvim_list_wins()

    for _, win in ipairs(windows) do
        local buf_r = vim.api.nvim_win_get_buf(win)

        if buf_r ~= buf_l then
            local buf_r_ft = string.lower(vim.bo[buf_r].filetype or '')

            local should_close_win = (buf_l_ft == FT_CODECOMPANION and buf_r_ft == FT_NVIMTREE) or (buf_l_ft == FT_NVIMTREE and buf_r_ft == FT_CODECOMPANION)

            if should_close_win then
                pcall(vim.api.nvim_win_close, win, false)
                return
            end
        end
    end
end

commands.user('ToggleWrap', toggle_wrap)

commands.user('BufferDelete', buffer_delete)

commands.user('BufferMessages', buffer_messages)

commands.user('ReplaceContentWithClipboard', clipboard.replace_with_yanked_and_write)

commands.auto({ 'BufEnter', 'BufWinEnter' }, {
    callback = auto_keep_unique_sidebar,
    group = commands.augroup 'KeepUniqueSidebar',
})

commands.auto({ 'TextYankPost' }, { callback = auto_highlight_yank })

commands.user('Touch', touch_command, { nargs = '+', complete = touch_complete })
