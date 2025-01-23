return {
    'saghen/blink.cmp',

    event = 'VeryLazy',

    dependencies = {
        'moyiz/blink-emoji.nvim',
        'rafamadriz/friendly-snippets',
    },

    build = 'cargo build --release',

    config = function()
        local plugin = require 'blink.cmp'

        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        plugin.setup {
            appearance = {
                -- Sets the fallback highlight groups to nvim-cmp's highlight groups
                -- Useful for when your theme doesn't support blink.cmp
                -- will be removed in a future release
                use_nvim_cmp_as_default = true,
                -- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
                -- adjusts spacing to ensure icons are aligned
                nerd_font_variant = vim.g.NVIM_NERD_FONT and 'mono' or 'normal',
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
                accept = {
                    -- experimental auto-brackets support
                    auto_brackets = {
                        enabled = true,
                    },
                },

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
                default = function()
                    if vim.bo.filetype == 'codecompanion' then
                        return { 'codecompanion' }
                    end

                    return { 'lsp', 'path', 'snippets', 'buffer', 'markdown', 'emoji' }
                end,

                providers = {
                    markdown = { name = 'RenderMarkdown', module = 'render-markdown.integ.blink' },
                    codecompanion = {
                        name = 'CodeCompanion',
                        module = 'codecompanion.providers.completion.blink',
                        enabled = true,
                    },
                    emoji = {
                        module = 'blink-emoji',
                        name = 'Emoji',
                        score_offset = 15,
                        opts = { insert = true },
                    },
                },
            },
        }
    end,
}
