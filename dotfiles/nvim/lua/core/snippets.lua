local commands = require 'utils.commands'

local M = {}

local snippets = {
    { name = 'thought', text = '```thought\n<Cursor>\n```', desc = 'Markdown thought block' },
    { name = 'todo', text = '- [ ] <Cursor>', desc = 'TODO item' },
}

function M.pick()
    local items = vim.tbl_map(function(s)
        return { name = s.name, text = s.text, desc = s.desc }
    end, snippets)

    vim.ui.select(items, {
        prompt = 'Snippets',
        format_item = function(item)
            return item.name .. ' - ' .. item.desc
        end,
    }, function(item)
        if not item then
            return
        end

        local row = vim.api.nvim_win_get_cursor(0)[1]
        local lines = vim.split(item.text, '\n', { plain = true })
        vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, lines)

        local cursor_pattern = '<Cursor>'
        local found = vim.fn.search(cursor_pattern, 'c')
        if found > 0 then
            vim.fn.cursor(found, vim.fn.col '.')
            vim.cmd.normal { args = { #cursor_pattern .. 'x' }, bang = true }
        end
    end)
end

commands.user('SnippetPick', M.pick)

return M
