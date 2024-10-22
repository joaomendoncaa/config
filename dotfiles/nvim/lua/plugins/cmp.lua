return {
    -- A completion plugin for neovim coded in Lua.
    -- SEE: https://github.com/hrsh7th/nvim-cmp
    'hrsh7th/nvim-cmp',

    enabled = false,

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
    },

    config = function()
        local cmp = require 'cmp'
        local lspkind = require 'lspkind'

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
            },
        }
    end,
}
