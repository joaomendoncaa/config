return {
    -- Simple nvim plugin for keeping your cursor centered.
    -- SEE: https://github.com/sarrisv/readermode.nvim
    'sarrisv/readermode.nvim',

    keys = '<leader>R',

    config = function()
        require('readermode').setup()

        vim.keymap.set('n', '<leader>R', '<CMD>ReaderMode<CR>', { desc = 'Toggle [R]eader mode.' })
    end,
}
