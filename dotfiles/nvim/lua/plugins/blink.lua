return {
    'saghen/blink.cmp',

    version = '1.*',
    dependencies = {
        'moyiz/blink-emoji.nvim',
        'rafamadriz/friendly-snippets',
    },

    config = function()
        local plugin = require 'blink.cmp'
        local key = require('utils.misc').key
        local disabled_filetypes = { '', 'NvimTree', 'DressingInput', 'SnacksInput', 'TelescopePrompt' }

        local handle_enabling = function()
            return not vim.tbl_contains(disabled_filetypes, vim.bo.filetype) or is_blink_enabled
        end

        local toggle_blink = function()
            if vim.b.completion == nil then
                vim.b.completion = handle_enabling()
            end

            vim.b.completion = not vim.b.completion
            local state = vim.b.completion and 'enabled' or 'disabled'
            vim.notify('Blink is now ' .. state, vim.log.levels.INFO)
        end

        key('n', '<leader>sS', toggle_blink, '[B]link toggle.')

        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        plugin.setup {
            appearance = {
                -- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
                -- adjusts spacing to ensure icons are aligned
                nerd_font_variant = vim.g.NVIM_NERD_FONT and 'mono' or 'normal',
            },

            fuzzy = { implementation = 'prefer_rust_with_warning' },

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

            enabled = handle_enabling,

            sources = {
                default = function()
                    if vim.bo.filetype == 'codecompanion' then
                        return { 'codecompanion' }
                    end

                    return { 'lsp', 'path', 'snippets', 'buffer', 'markdown', 'emoji' }
                end,

                providers = {
                    cmdline = {
                        enabled = function()
                            return vim.fn.getcmdtype() ~= ':' or not vim.fn.getcmdline():match "^[%%0-9,'<>%-]*!"
                        end,
                    },
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
