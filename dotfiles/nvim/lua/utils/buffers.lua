local M = {}

function M.handle_save_quit()
    local buf = vim.api.nvim_get_current_buf()
    local ft = string.lower(vim.bo[buf].filetype or '')
    local bufname = vim.api.nvim_buf_get_name(buf)
    local is_unnamed = bufname == '' and vim.bo[buf].modified
    local is_nowrite = vim.tbl_contains({ 'codecompanion', 'nvimtree' }, ft)

    if is_nowrite then
        return vim.cmd 'q'
    end

    if is_unnamed then
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local is_empty = #lines == 0 or (#lines == 1 and lines[1] == '')

        if is_empty then
            vim.bo[buf].modified = false
            return vim.cmd 'q'
        end
    end

    vim.cmd 'wq'
end

return M
