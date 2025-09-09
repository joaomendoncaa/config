local M = {}

function M.replace_with_yanked_and_write()
    vim.cmd 'norm! GVggp'
    vim.cmd 'w'
end

function M.yank_buffer()
    local file = vim.fn.expand '%:t'
    local ext = vim.fn.expand '%:e' or ''

    vim.cmd 'silent! %yank z'

    local contents = vim.fn.getreg 'z' or ''
    if contents:sub(-1) == '\n' then
        contents = contents:sub(1, -2)
    end

    local md = string.format('### %s\n```%s\n%s\n```', file, ext, contents)

    vim.fn.setreg('+', md)
    vim.fn.setreg('*', md)

    vim.notify(string.format('%s yanked', file), vim.log.levels.INFO)
end

return M
