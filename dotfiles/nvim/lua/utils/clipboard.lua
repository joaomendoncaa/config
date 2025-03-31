local M = {}

function M.replace_with_yanked_and_write()
    vim.cmd 'norm! GVggp'
    vim.cmd 'w'
end

return M
