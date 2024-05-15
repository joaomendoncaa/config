return {
  {
    'ixru/nvim-markdown',
    lazy = true,
    config = function() end,
  },

  {
    'iamcco/markdown-preview.nvim',
    lazy = true,
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    ft = { 'markdown' },
    build = function()
      vim.fn['mkdp#util#install']()
    end,
    config = function()
      vim.keymap.set('n', '<leader>p', '<CMD>MarkdownPreviewToggle<CR>', { desc = 'Markdown [P]review.' })
    end,
  },
}
