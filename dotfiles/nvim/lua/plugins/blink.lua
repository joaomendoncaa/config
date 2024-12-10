return {
    -- Performant, batteries-included completion plugin for Neovim.
    --SEE: https://github.com/Saghen/blink.cmp
    'saghen/blink.cmp',

    -- event = { 'LspAttach' },
    lazy = false,

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

            keymap = {
                preset = 'default',
                ['<A-1>'] = {
                    function(cmp)
                        cmp.accept { index = 1 }
                    end,
                },
                ['<A-2>'] = {
                    function(cmp)
                        cmp.accept { index = 2 }
                    end,
                },
                ['<A-3>'] = {
                    function(cmp)
                        cmp.accept { index = 3 }
                    end,
                },
                ['<A-4>'] = {
                    function(cmp)
                        cmp.accept { index = 4 }
                    end,
                },
                ['<A-5>'] = {
                    function(cmp)
                        cmp.accept { index = 5 }
                    end,
                },
                ['<A-6>'] = {
                    function(cmp)
                        cmp.accept { index = 6 }
                    end,
                },
                ['<A-7>'] = {
                    function(cmp)
                        cmp.accept { index = 7 }
                    end,
                },
                ['<A-8>'] = {
                    function(cmp)
                        cmp.accept { index = 8 }
                    end,
                },
                ['<A-9>'] = {
                    function(cmp)
                        cmp.accept { index = 9 }
                    end,
                },
            },

            completion = {
                menu = {
                    draw = {
                        columns = { { 'item_idx' }, { 'kind_icon' }, { 'label', 'label_description', gap = 1 } },
                        components = {
                            item_idx = {
                                text = function(ctx)
                                    return tostring(ctx.idx)
                                end,
                            },
                        },
                    },
                },
            },

            sources = {
                completion = {
                    enabled_providers = function(_)
                        if vim.bo.filetype == 'codecompanion' then
                            return { 'codecompanion' }
                        end

                        return { 'lsp', 'path', 'snippets', 'buffer', 'markdown' }
                    end,
                },
                providers = {
                    markdown = { name = 'RenderMarkdown', module = 'render-markdown.integ.blink' },
                    codecompanion = {
                        name = 'CodeCompanion',
                        module = 'codecompanion.providers.completion.blink',
                        enabled = true,
                    },
                },
            },
        }
    end,
}
