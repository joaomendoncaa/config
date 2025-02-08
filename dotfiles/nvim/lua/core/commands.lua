local commands = require 'utils.commands'

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

local replace_content_with_clipboard = function()
    vim.cmd 'norm! GVggp'
    vim.cmd 'w'
end

commands.user('ToggleWrap', toggle_wrap)

commands.user('BufferDelete', buffer_delete)

commands.user('BufferMessages', buffer_messages)

commands.user('ReplaceContentWithClipboard', replace_content_with_clipboard)

commands.auto({ 'TextYankPost' }, { callback = auto_highlight_yank })

commands.user('Touch', touch_command, { nargs = '+', complete = touch_complete })
