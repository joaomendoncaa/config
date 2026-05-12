return {
    {
        'nvim-neo-tree/neo-tree.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'MunifTanjim/nui.nvim',
            'nvim-tree/nvim-web-devicons',
        },
        keys = {
            {
                '<C-e>',
                function()
                    vim.cmd 'Neotree toggle position=current'
                end,
                desc = 'Toggle [E]xplorer',
            },
        },
        config = function()
            require('neo-tree').setup {
                default_component_configs = {
                    container = {
                        enable_character_fade = false,
                    },
                },
                filesystem = {
                    follow_current_file = {
                        enabled = true,
                    },
                },
            }
        end,
    },
}
