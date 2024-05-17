return {
  -- Nvim Treesitter configurations and abstraction layer.
  -- SEE: https://github.com/nvim-treesitter/nvim-treesitter
  'nvim-treesitter/nvim-treesitter',

  event = { 'VeryLazy', 'BufEnter' },
  build = ':TSUpdate',
  opts = {
    auto_install = true,
    ensure_installed = { 'tsx', 'typescript', 'go', 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'vim', 'vimdoc' },
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = { 'ruby' },
    },
    indent = { enable = true, disable = { 'ruby' } },
  },

  config = function(_, opts)
    -- improve install connection by preferring git instead of curl
    require('nvim-treesitter.install').prefer_git = true

    require('nvim-treesitter.configs').setup(opts)
  end,
}
