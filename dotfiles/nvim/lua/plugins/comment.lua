return {
  {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup {
        pre_hook = function()
          return vim.bo.commentstring
        end,
      }
    end,
  },
  {
    'JoosepAlviste/nvim-ts-context-commentstring',
    config = true,
  },
}
