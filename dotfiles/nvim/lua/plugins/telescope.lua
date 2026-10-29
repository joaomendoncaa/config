return {
    {
        'nvim-telescope/telescope.nvim',

        dependencies = {
            'nvim-telescope/telescope-ui-select.nvim',
        },

        config = function()
            local plugin = require 'telescope'
            local builtin = require 'telescope.builtin'
            local key = require('utils.misc').key

            key({ 'n', 'v' }, '<leader>sc', builtin.command_history)

            plugin.setup {
                defaults = {
                    color_devicons = true,
                    sorting_strategy = 'ascending',
                    borderchars = { '', '', '', '', '', '', '', '' },
                    path_displays = 'smart',
                    layout_strategy = 'horizontal',
                    layout_config = {
                        height = 100,
                        width = 400,
                        prompt_position = 'top',
                        preview_cutoff = 40,
                    },
                },
                extensions = {
                    ['ui-select'] = {
                        require('telescope.themes').get_dropdown {},
                    },
                },
            }

            plugin.load_extension 'ui-select'
        end,
    },
}
