return {
    dir = '~/lab/gitfsd.nvim',

    config = function()
        require('gitfsd').setup {
            name = 'João',
        }
    end,
}
