return {
    -- The fastest Neovim colorizer.
    -- SEE: https://github.com/norcalli/nvim-colorizer.lua
    'norcalli/nvim-colorizer.lua',

    event = 'VeryLazy',

    config = function()
        require('colorizer').setup(nil, { css = true })
    end,
}
