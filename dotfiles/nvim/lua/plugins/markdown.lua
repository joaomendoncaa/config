return {
  {
    -- Markdown Vim Mode.
    -- SEE: https://github.com/ixru/nvim-markdown
    'ixru/nvim-markdown',

    lazy = true,

    config = function() end,
  },

  {
    -- Markdown preview plugin for (neo)vim.
    -- SEE: https://github.com/iamcco/markdown-preview.nvim
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
