return {
    -- Performant, batteries-included completion plugin for Neovim.
    --SEE: https://github.com/Saghen/blink.cmp
    'saghen/blink.cmp',

    event = { 'LspAttach' },

    dependencies = {
        {
            -- Set of preconfigured snippets for different languages.
            --  SEE: https://github.com/rafamadriz/friendly-snippets
            'rafamadriz/friendly-snippets',
        },
    },

    build = 'cargo build --release',

    config = function()
        local plugin = require 'blink.cmp'

        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        plugin.setup {
            highlight = {
                use_nvim_cmp_as_default = true,
            },

            -- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
            -- adjusts spacing to ensure icons are aligned
            nerd_font_variant = vim.g.NVIM_NERD_FONT and 'mono' or 'normal',

            accept = {
                -- experimental auto-brackets support
                auto_brackets = {
                    enabled = true,
                },
            },
        }
    end,
}
