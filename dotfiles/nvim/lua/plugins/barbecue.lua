return {
    -- A VS Code like winbar for Neovim.
    -- SEE: https://github.com/utilyre/barbecue.nvim
    'utilyre/barbecue.nvim',

    name = 'barbecue',
    version = '*',
    event = 'BufEnter',

    dependencies = {
        'SmiteshP/nvim-navic',
        { 'nvim-tree/nvim-web-devicons', enabled = vim.g._NERD_FONT },
    },

    config = function()
        require('barbecue').setup {
            -- prevent barbecue from updating itself automatically
            create_autocmd = false,
            -- replace icon with modified flag
            show_modified = true,
        }

        -- custom update for barbecue to be more performant when moving the cursor around
        vim.api.nvim_create_autocmd({
            'WinScrolled',
            'BufWinEnter',
            'CursorHold',
            'InsertLeave',

            -- `show_modified` to `true`
            'BufModifiedSet',
        }, {
            group = vim.api.nvim_create_augroup('barbecue.updater', {}),
            callback = function()
                require('barbecue.ui').update()
            end,
        })
    end,
}
