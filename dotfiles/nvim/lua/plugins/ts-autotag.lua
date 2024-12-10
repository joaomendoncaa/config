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
        'javascriptreact',
        'typescript',
        'typescriptreact',
        'jsx',
        'markdown',
        'php',
        'rescript',
        'svelte',
        'tsx',
        'twig',
        'vue',
        'xml',
    },

    opts = {
        opts = {
            enable_close = true,
            enable_rename = true,
            enable_close_on_slash = true,
        },
    },
}
