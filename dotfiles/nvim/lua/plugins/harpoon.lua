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
        local commands = require 'utils.commands'

        local keymap = vim.keymap.set

        local function add()
            local file_name = vim.fn.expand '%'
            plugin:list():add()
            print('Harpoon buffer added: ' .. file_name)
        end

        local function remove()
            local file_name = vim.fn.expand '%'
            plugin:list():remove()
            print('Harpoon buffer removed: ' .. file_name)
        end

        local function clear()
            plugin:list():clear()
            print 'Harpoon buffers cleared.'
        end

        local function list()
            plugin.ui:toggle_quick_menu(plugin:list())
        end

        local function select(n)
            plugin:list():select(n)
        end

        -- local function handle_file_renames(args)
        --     local p = vim.fn.expand '<afile>:p'
        --     local n = vim.api.nvim_buf_get_name(args.buf)

        --     print 'File renamed!'
        --     print(vim.inspect { p, n })

        --     -- if p ~= n then
        --     --     local l = plugin:list()

        --     --     for i, f in ipairs(l) do
        --     --         if f.value == p then
        --     --             l.[i] = n
        --     --         end
        --     --     end
        --     -- end
        -- end

        keymap('n', '<leader>ha', add, { desc = '[H]arpoon list [A]ppend.' })
        keymap('n', '<leader>hc', clear, { desc = '[H]arpoon list [C]lear.' })
        keymap('n', '<leader>hr', remove, { desc = '[H]arpoon view [R]emove current buffer..' })
        keymap('n', '<leader>hl', list, { desc = '[H]arpoon view [L]ist.' })

        for i = 1, 9 do
            keymap('n', '<leader>h' .. i, function()
                select(i)
            end, { desc = 'Select [H]arpoon buffer in position ' .. i .. '.' })
        end

        -- commands.auto({ 'BufWritePre' }, {
        --     callback = handle_file_renames,
        -- })

        plugin:setup {
            settings = {
                save_on_toggle = true,
                sync_on_ui_close = true,
            },
        }
    end,
}
