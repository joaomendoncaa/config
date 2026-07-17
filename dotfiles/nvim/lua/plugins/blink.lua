return {
    'saghen/blink.cmp',

    dependencies = {
        'saghen/blink.lib',
        'rafamadriz/friendly-snippets',
    },

    build = function()
        -- build the fuzzy matcher, optionally add a timeout to `pwait(timeout_ms)`
        -- you can use `gb` in `:Lazy` to rebuild the plugin as needed
        require('blink.cmp').build():pwait()
    end,

    config = function()
        local plugin = require 'blink.cmp'

        -- HACK: blink.cmp's Neovim 0.13 compat layer has wrong argument order for vim.pos API
        if vim.fn.has 'nvim-0.13' == 1 then
            local utils = require 'blink.cmp.lib.utils'
            utils.get_vim_pos_cursor = function(buf, pos)
                if pos then
                    if buf == 0 then
                        buf = vim.api.nvim_get_current_buf()
                    end
                else
                    local win = buf
                    if win == 0 then
                        win = vim.api.nvim_get_current_win()
                    end
                    buf = vim.api.nvim_win_get_buf(win)
                    pos = vim.api.nvim_win_get_cursor(win)
                end
                return vim.pos.cursor(pos, { buf = buf })
            end
            utils.get_vim_pos = function(buf, row, col)
                return vim.pos(row, col, { buf = buf })
            end
            utils.vim_pos_to_cursor = function(pos)
                return { pos:to_cursor() }
            end
        end

        local key = require('utils.misc').key
        local commands = require 'utils.commands'
        local disabled_filetypes = { '', 'NvimTree', 'DressingInput', 'SnacksInput', 'TelescopePrompt' }

        local handle_enabling = function()
            local ok, neocodeium = pcall(require, 'neocodeium')
            if ok and neocodeium.visible() then
                return false
            end
            return not vim.tbl_contains(disabled_filetypes, vim.bo.filetype)
        end

        local toggle_blink = function()
            if vim.b.completion == nil then
                vim.b.completion = handle_enabling()
            end

            vim.b.completion = not vim.b.completion
            vim.notify('Blink is now ' .. vim.b.completion and 'enabled' or 'disabled', vim.log.levels.INFO)
        end

        key('n', '<leader>sS', toggle_blink, 'Toggle Blink [S]ugestions')

        commands.user('BlinkToggle', toggle_blink)

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
                ['<C-.>'] = { 'show' },
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
                documentation = { auto_show = false },
                menu = {
                    auto_show = true,
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

            cmdline = {
                completion = {
                    menu = { auto_show = true },
                },
            },

            enabled = handle_enabling,

            sources = {
                default = function()
                    if vim.bo.filetype == 'codecompanion' then
                        return { 'codecompanion' }
                    end

                    if vim.bo.filetype == 'markdown' then
                        return { 'markdown', 'path' }
                    end

                    return { 'lsp', 'path', 'snippets', 'buffer', 'markdown' }
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
                },
            },
        }
    end,
}
