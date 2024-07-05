return {
    -- 💥 Create key bindings that stick. WhichKey is a lua plugin for Neovim 0.5 that displays a popup with possible keybindings of the command you started typing.
    -- SEE: https://github.com/folke/which-key.nvim
    'folke/which-key.nvim',

    event = 'VeryLazy',

    config = function()
        require('which-key').setup {
            plugins = {
                registers = true,

                presets = {
                    operators = false,
                    motions = false,
                    text_objects = false,
                    windows = false,
                    nav = false,
                    z = false,
                    g = false,
                },
            },
        }
    end,
}
