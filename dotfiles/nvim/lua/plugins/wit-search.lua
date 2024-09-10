return {
    -- Plugin that allows you to perform web searches directly from within neovim!
    -- SEE: https://github.com/aliqyan-21/wit.nvim
    'joaomendoncaa/wit.nvim',

    event = 'VeryLazy',

    config = function()
        local plugin = require 'wit'

        plugin.setup {
            engine = 'google',
            command_search = 'Search',
            command_search_wiki = 'SearchWiki',
            command_search_visual = 'SearchVisual',
        }
    end,
}
