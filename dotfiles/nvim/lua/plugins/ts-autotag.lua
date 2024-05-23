return {
    -- Use treesitter to auto close and auto rename html tag.
    -- SEE: https://github.com/windwp/nvim-ts-autotag
    'windwp/nvim-ts-autotag',

    ft = {
        'astro',
        'glimmer',
        'handlebars',
        'html',
        'javascript',
        'jsx',
        'markdown',
        'php',
        'rescript',
        'svelte',
        'tsx',
        'twig',
        'typescript',
        'vue',
        'xml',
    },

    config = function()
        require('nvim-ts-autotag').setup {
            opts = {
                enable_close = true,
                enable_rename = true,
                enable_close_on_slash = true,
            },
        }
    end,
}
