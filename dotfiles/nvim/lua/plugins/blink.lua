return {
    -- Performant, batteries-included completion plugin for Neovim.
    --SEE: https://github.com/Saghen/blink.cmp
    'saghen/blink.cmp',

    event = { 'LspAttach' },
    version = 'v0.*',

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
            keymap = {
                hide = '<C-e>',
                accept = '<C-y>',
                select_prev = { '<Up>', '<C-p>' },
                select_next = { '<Down>', '<C-n>' },
            },

            highlight = {
                -- sets the fallback highlight groups to nvim-cmp's highlight groups
                -- useful for when your theme doesn't support blink.cmp
                -- will be removed in a future release, assuming themes add support
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
