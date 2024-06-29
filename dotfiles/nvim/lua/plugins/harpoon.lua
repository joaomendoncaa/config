return {
    -- Getting you where you want with the fewest keystrokes.
    -- SEE: https://github.com/ThePrimeagen/harpoon/tree/harpoon2
    'ThePrimeagen/harpoon',

    branch = 'harpoon2',
    keys = {
        '<leader>h',
    },

    dependencies = {
        'nvim-lua/plenary.nvim',
    },

    config = function()
        local plugin = require 'harpoon'

        local keymap = vim.keymap.set

        local add = function()
            local file_name = vim.fn.expand '%'
            plugin:list():add()
            print('Harpoon buffer added: ' .. file_name)
        end

        local remove = function()
            local file_name = vim.fn.expand '%'
            plugin:list():remove()
            print('Harpoon buffer removed: ' .. file_name)
        end

        local clear = function()
            plugin:list():clear()
            print 'Harpoon buffers cleared.'
        end

        local list = function()
            plugin.ui:toggle_quick_menu(plugin:list())
        end

        local select = function(n)
            plugin:list():select(n)
        end

        keymap('n', '<leader>ha', add, { desc = '[H]arpoon list [A]ppend.' })
        keymap('n', '<leader>hc', clear, { desc = '[H]arpoon list [C]lear.' })
        keymap('n', '<leader>hr', remove, { desc = '[H]arpoon view [R]emove current buffer..' })
        keymap('n', '<leader>hl', list, { desc = '[H]arpoon view [L]ist.' })

        for i = 1, 9 do
            keymap('n', '<leader>h' .. i, function()
                select(i)
            end, { desc = 'Select [H]arpoon buffer in position ' .. i .. '.' })
        end

        plugin:setup {
            settings = {
                save_on_toggle = true,
                sync_on_ui_close = true,
            },
        }
    end,
}
