return {
    'utilyre/barbecue.nvim',

    name = 'barbecue',
    version = false,
    event = 'VeryLazy',

    enabled = false,

    dependencies = {
        'SmiteshP/nvim-navic',
        { 'nvim-tree/nvim-web-devicons', enabled = vim.g.NVIM_NERD_FONT },
    },

    init = function()
        vim.g.navic_silence = true
    end,

    config = function()
        local plugin = require 'barbecue'
        local ui = require 'barbecue.ui'
        local commands = require 'utils.commands'

        local update_timer = vim.uv.new_timer()
        local update_delay = 500

        local debounced_ui_update = function()
            update_timer:stop()
            update_timer:start(update_delay, 0, vim.schedule_wrap(ui.update))
        end

        commands.auto({
            'BufWinEnter',
        }, {
            group = commands.augroup 'BarbecueUpdate',
            callback = function()
                ui.update()
            end,
        })

        commands.auto({
            'WinScrolled',
            'CursorHold',
            'InsertLeave',
            'BufModifiedSet',
        }, {
            group = commands.augroup 'BarbecueUpdate',
            callback = debounced_ui_update,
        })

        plugin.setup {
            create_autocmd = false,
            show_modified = true,
            theme = {
                normal = { bg = 'none' },
            },
        }
    end,
}
