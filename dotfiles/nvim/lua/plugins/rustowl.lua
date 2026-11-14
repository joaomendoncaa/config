return {
    {
        'cordx56/rustowl',
        version = '*',
        lazy = false,
        opts = {},
        cond = function()
            return vim.fn.executable 'rustowl' == 1
        end,
    },
}
