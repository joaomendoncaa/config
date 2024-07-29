return {
    -- A completion plugin for neovim coded in Lua.
    -- SEE: https://github.com/hrsh7th/nvim-cmp
    'hrsh7th/nvim-cmp',

    event = 'InsertEnter',
    dependencies = {
        -- `nvim-cmp` does not ship with all sources by default. They are split
        -- into multiple repos for maintenance purposes.
        -- SEE: https://github.com/hrsh7th/nvim-cmp?tab=readme-ov-file#recommended-configuration
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-path',

        -- Luasnip completion source for `nvim-cmp`.
        --  SEE: https://github.com/saadparwaiz1/cmp_luasnip
        'saadparwaiz1/cmp_luasnip',

        -- Pictograms for each LSP completion item type
        -- SEE: https://github.com/onsails/lspkind.nvim
        'onsails/lspkind.nvim',

        {
            -- Snippet Engine for Neovim written in Lua.
            -- SEE: https://github.com/L3MON4D3/LuaSnip
            'L3MON4D3/LuaSnip',

            dependencies = {
                {
                    -- Set of preconfigured snippets for different languages.
                    --  SEE: https://github.com/rafamadriz/friendly-snippets
                    'rafamadriz/friendly-snippets',

                    config = function()
                        require('luasnip.loaders.from_vscode').lazy_load()
                    end,
                },
            },

            build = (function()
                if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
                    return
                end

                return 'make install_jsregexp'
            end)(),

            config = function()
                local luasnip = require 'luasnip'

                luasnip.config.set_config {
                    history = false,
                    updateevents = 'TextChanged,TextChangedI',
                }

                -- load all snippets defined at `snippets/`
                for _, ft_path in ipairs(vim.api.nvim_get_runtime_file('lua/snippets/*.lua', true)) do
                    loadfile(ft_path)()
                end

                vim.keymap.set({ 'i', 's' }, '<c-k>', function()
                    if luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    end
                end, { silent = true, desc = 'Expand/Jump to next snippet node.' })

                vim.keymap.set({ 'i', 's' }, '<c-j>', function()
                    if luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    end
                end, { silent = true, desc = 'Expand/Jump to previous snippet node.' })
            end,
        },
    },

    config = function()
        local cmp = require 'cmp'
        local luasnip = require 'luasnip'
        local lspkind = require 'lspkind'

        luasnip.config.setup {}
        lspkind.init {
            symbol_map = {
                Supermaven = '',
            },
        }

        cmp.setup {
            sources = {
                {
                    name = 'lazydev',
                    -- set group index to 0 to skip loading LuaLS completions as lazydev recommends it
                    -- SEE: https://github.com/folke/lazydev.nvim?tab=readme-ov-file#-installation
                    group_index = 0,
                },
                { name = 'nvim_lsp' },
                { name = 'luasnip' },
                { name = 'path' },
                { name = 'supermaven' },
            },

            -- wire luasnip to lsp so the lsp knows how to handle snippet expansion
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end,
            },

            mapping = cmp.mapping.preset.insert {
                ['<C-n>'] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert },
                ['<C-p>'] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert },

                ['<C-y>'] = cmp.mapping(
                    cmp.mapping.confirm {
                        select = true,
                        behavior = cmp.ConfirmBehavior.Insert,
                    },
                    { 'i', 'c' }
                ),

                ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),

                ['<C-Space>'] = cmp.mapping.complete {},

                ['<C-l>'] = cmp.mapping(function()
                    if luasnip.expand_or_locally_jumpable() then
                        luasnip.expand_or_jump()
                    end
                end, { 'i', 's' }),
                ['<C-h>'] = cmp.mapping(function()
                    if luasnip.locally_jumpable(-1) then
                        luasnip.jump(-1)
                    end
                end, { 'i', 's' }),
            },
        }
    end,
}
