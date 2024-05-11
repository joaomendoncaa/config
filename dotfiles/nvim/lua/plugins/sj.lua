return {
  'woosaaahh/sj.nvim',
  config = function()
    local sj = require 'sj'
    local keymap = vim.keymap.set

    sj.setup()

    keymap('n', 'S', function()
      sj.run {
        auto_jump = true,
        stop_on_fail = false,
        separator = ':',
      }
    end, { desc = 'Jump to [S]earch pattern.' })
  end,
}
