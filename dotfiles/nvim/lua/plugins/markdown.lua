return {
  { 'ixru/nvim-markdown' },

  {
    'iamcco/markdown-preview.nvim',
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
