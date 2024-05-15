return {
  -- A lua powered greeter like vim-startify / dashboard-nvim.
  -- SEE: https://github.com/goolord/alpha-nvim
  'goolord/alpha-nvim',

  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },

  config = function()
    local alpha = require 'alpha'
    local dashboard = require 'alpha.themes.dashboard'

    vim.api.nvim_set_hl(0, 'I2A0', { fg = '#70ef61' })
    vim.api.nvim_set_hl(0, 'I2A1', { fg = '#51212d' })
    vim.api.nvim_set_hl(0, 'I2A2', { fg = '#e41f26' })
    vim.api.nvim_set_hl(0, 'I2A3', { fg = '#a2314e' })
    vim.api.nvim_set_hl(0, 'I2A4', { fg = '#ff5386' })
    vim.api.nvim_set_hl(0, 'I2A5', { fg = '#a24569' })
    vim.api.nvim_set_hl(0, 'I2A6', { fg = '#512d41' })
    vim.api.nvim_set_hl(0, 'I2A7', { fg = '#5d3f5b' })
    vim.api.nvim_set_hl(0, 'I2A8', { fg = '#ff5e9d' })
    vim.api.nvim_set_hl(0, 'I2A9', { fg = '#f41f3b' })
    vim.api.nvim_set_hl(0, 'I2A10', { fg = '#f62147' })
    vim.api.nvim_set_hl(0, 'I2A11', { fg = '#d91529' })
    vim.api.nvim_set_hl(0, 'I2A12', { fg = '#e01f2a' })
    vim.api.nvim_set_hl(0, 'I2A13', { fg = '#e41f26' })
    vim.api.nvim_set_hl(0, 'I2A14', { fg = '#d1202a' })
    vim.api.nvim_set_hl(0, 'I2A15', { fg = '#dd212b' })
    vim.api.nvim_set_hl(0, 'I2A16', { fg = '#dc334f' })
    vim.api.nvim_set_hl(0, 'I2A17', { fg = '#5d1f30' })
    vim.api.nvim_set_hl(0, 'I2A18', { fg = '#7f263e' })
    vim.api.nvim_set_hl(0, 'I2A19', { fg = '#fa1237' })
    vim.api.nvim_set_hl(0, 'I2A20', { fg = '#eb1835' })
    vim.api.nvim_set_hl(0, 'I2A21', { fg = '#e11632' })
    vim.api.nvim_set_hl(0, 'I2A22', { fg = '#bd1f2c' })
    vim.api.nvim_set_hl(0, 'I2A23', { fg = '#f0213a' })
    vim.api.nvim_set_hl(0, 'I2A24', { fg = '#e5172d' })
    vim.api.nvim_set_hl(0, 'I2A25', { fg = '#d0355c' })
    vim.api.nvim_set_hl(0, 'I2A26', { fg = '#e61c38' })
    vim.api.nvim_set_hl(0, 'I2A27', { fg = '#fa1c37' })
    vim.api.nvim_set_hl(0, 'I2A28', { fg = '#f42136' })
    vim.api.nvim_set_hl(0, 'I2A29', { fg = '#f72136' })
    vim.api.nvim_set_hl(0, 'I2A30', { fg = '#7f1a23' })
    vim.api.nvim_set_hl(0, 'I2A31', { fg = '#3a6832' })
    vim.api.nvim_set_hl(0, 'I2A32', { fg = '#ff4c7f' })
    vim.api.nvim_set_hl(0, 'I2A33', { fg = '#fc305c' })
    vim.api.nvim_set_hl(0, 'I2A34', { fg = '#ff4b86' })
    vim.api.nvim_set_hl(0, 'I2A35', { fg = '#ff1639' })
    vim.api.nvim_set_hl(0, 'I2A36', { fg = '#fb2040' })
    vim.api.nvim_set_hl(0, 'I2A37', { fg = '#fd3352' })
    vim.api.nvim_set_hl(0, 'I2A38', { fg = '#bb2e3c' })
    vim.api.nvim_set_hl(0, 'I2A39', { fg = '#ec2942' })
    vim.api.nvim_set_hl(0, 'I2A40', { fg = '#d5203b' })
    vim.api.nvim_set_hl(0, 'I2A41', { fg = '#c62134' })
    vim.api.nvim_set_hl(0, 'I2A42', { fg = '#fe345d' })
    vim.api.nvim_set_hl(0, 'I2A43', { fg = '#ac3642' })
    vim.api.nvim_set_hl(0, 'I2A44', { fg = '#fe345d' })
    vim.api.nvim_set_hl(0, 'I2A45', { fg = '#781922' })
    vim.api.nvim_set_hl(0, 'I2A46', { fg = '#781922' })
    vim.api.nvim_set_hl(0, 'I2A47', { fg = '#ff6eb0' })
    vim.api.nvim_set_hl(0, 'I2A48', { fg = '#f1315d' })
    vim.api.nvim_set_hl(0, 'I2A49', { fg = '#f5182f' })
    vim.api.nvim_set_hl(0, 'I2A50', { fg = '#dc1f2a' })
    vim.api.nvim_set_hl(0, 'I2A51', { fg = '#ea223e' })
    vim.api.nvim_set_hl(0, 'I2A52', { fg = '#ec1631' })
    vim.api.nvim_set_hl(0, 'I2A53', { fg = '#ff4a73' })
    vim.api.nvim_set_hl(0, 'I2A54', { fg = '#ff243f' })
    vim.api.nvim_set_hl(0, 'I2A55', { fg = '#bc2d3a' })
    vim.api.nvim_set_hl(0, 'I2A56', { fg = '#bc2c32' })
    vim.api.nvim_set_hl(0, 'I2A57', { fg = '#e1222f' })
    vim.api.nvim_set_hl(0, 'I2A58', { fg = '#fe2745' })
    vim.api.nvim_set_hl(0, 'I2A59', { fg = '#7c805b' })
    vim.api.nvim_set_hl(0, 'I2A60', { fg = '#80364f' })
    vim.api.nvim_set_hl(0, 'I2A61', { fg = '#468036' })
    vim.api.nvim_set_hl(0, 'I2A62', { fg = '#7f111a' })
    vim.api.nvim_set_hl(0, 'I2A63', { fg = '#ff4d88' })
    vim.api.nvim_set_hl(0, 'I2A64', { fg = '#ee203f' })
    vim.api.nvim_set_hl(0, 'I2A65', { fg = '#ed2032' })
    vim.api.nvim_set_hl(0, 'I2A66', { fg = '#fc1f3a' })
    vim.api.nvim_set_hl(0, 'I2A67', { fg = '#df212d' })
    vim.api.nvim_set_hl(0, 'I2A68', { fg = '#ec2c40' })
    vim.api.nvim_set_hl(0, 'I2A69', { fg = '#ff2b44' })
    vim.api.nvim_set_hl(0, 'I2A70', { fg = '#f3303e' })
    vim.api.nvim_set_hl(0, 'I2A71', { fg = '#e8394f' })
    vim.api.nvim_set_hl(0, 'I2A72', { fg = '#e83c45' })
    vim.api.nvim_set_hl(0, 'I2A73', { fg = '#b5db56' })
    vim.api.nvim_set_hl(0, 'I2A74', { fg = '#c4da9b' })
    vim.api.nvim_set_hl(0, 'I2A75', { fg = '#62d263' })
    vim.api.nvim_set_hl(0, 'I2A76', { fg = '#70ef61' })
    vim.api.nvim_set_hl(0, 'I2A77', { fg = '#498941' })
    vim.api.nvim_set_hl(0, 'I2A78', { fg = '#57740d' })
    vim.api.nvim_set_hl(0, 'I2A79', { fg = '#82a828' })
    vim.api.nvim_set_hl(0, 'I2A80', { fg = '#848a44' })
    vim.api.nvim_set_hl(0, 'I2A81', { fg = '#5a7f64' })
    vim.api.nvim_set_hl(0, 'I2A82', { fg = '#5a7f64' })
    vim.api.nvim_set_hl(0, 'I2A83', { fg = '#3b7b3e' })
    vim.api.nvim_set_hl(0, 'I2A84', { fg = '#2e5b2a' })
    vim.api.nvim_set_hl(0, 'I2A85', { fg = '#971c26' })
    vim.api.nvim_set_hl(0, 'I2A86', { fg = '#ed2042' })
    vim.api.nvim_set_hl(0, 'I2A87', { fg = '#f42036' })
    vim.api.nvim_set_hl(0, 'I2A88', { fg = '#e72736' })
    vim.api.nvim_set_hl(0, 'I2A89', { fg = '#f02d39' })
    vim.api.nvim_set_hl(0, 'I2A90', { fg = '#b22f3a' })
    vim.api.nvim_set_hl(0, 'I2A91', { fg = '#dc3644' })
    vim.api.nvim_set_hl(0, 'I2A92', { fg = '#dc3644' })
    vim.api.nvim_set_hl(0, 'I2A93', { fg = '#ffffff' })
    vim.api.nvim_set_hl(0, 'I2A94', { fg = '#84b490' })
    vim.api.nvim_set_hl(0, 'I2A95', { fg = '#192e17' })
    vim.api.nvim_set_hl(0, 'I2A96', { fg = '#172d19' })
    vim.api.nvim_set_hl(0, 'I2A97', { fg = '#396a3d' })
    vim.api.nvim_set_hl(0, 'I2A98', { fg = '#4a9e58' })
    vim.api.nvim_set_hl(0, 'I2A99', { fg = '#c7ae8c' })
    vim.api.nvim_set_hl(0, 'I2A100', { fg = '#84b490' })
    vim.api.nvim_set_hl(0, 'I2A101', { fg = '#578e55' })
    vim.api.nvim_set_hl(0, 'I2A102', { fg = '#4aba60' })
    vim.api.nvim_set_hl(0, 'I2A103', { fg = '#48c445' })
    vim.api.nvim_set_hl(0, 'I2A104', { fg = '#3ac745' })
    vim.api.nvim_set_hl(0, 'I2A105', { fg = '#d4f26b' })
    vim.api.nvim_set_hl(0, 'I2A106', { fg = '#a5e981' })
    vim.api.nvim_set_hl(0, 'I2A107', { fg = '#70ef61' })
    vim.api.nvim_set_hl(0, 'I2A108', { fg = '#6bf548' })
    vim.api.nvim_set_hl(0, 'I2A109', { fg = '#48da3e' })
    vim.api.nvim_set_hl(0, 'I2A110', { fg = '#75df5e' })
    vim.api.nvim_set_hl(0, 'I2A111', { fg = '#122a0f' })
    vim.api.nvim_set_hl(0, 'I2A112', { fg = '#75df5e' })
    vim.api.nvim_set_hl(0, 'I2A113', { fg = '#ad2e37' })
    vim.api.nvim_set_hl(0, 'I2A114', { fg = '#fd5379' })
    vim.api.nvim_set_hl(0, 'I2A115', { fg = '#f81e3a' })
    vim.api.nvim_set_hl(0, 'I2A116', { fg = '#a9232d' })
    vim.api.nvim_set_hl(0, 'I2A117', { fg = '#ff364a' })
    vim.api.nvim_set_hl(0, 'I2A118', { fg = '#5d1616' })
    vim.api.nvim_set_hl(0, 'I2A119', { fg = '#53a03f' })
    vim.api.nvim_set_hl(0, 'I2A120', { fg = '#2e4936' })
    vim.api.nvim_set_hl(0, 'I2A121', { fg = '#511e2b' })
    vim.api.nvim_set_hl(0, 'I2A122', { fg = '#132e0b' })
    vim.api.nvim_set_hl(0, 'I2A123', { fg = '#43c83d' })
    vim.api.nvim_set_hl(0, 'I2A124', { fg = '#f42036' })
    vim.api.nvim_set_hl(0, 'I2A125', { fg = '#41c03c' })
    vim.api.nvim_set_hl(0, 'GAH1', { fg = '#ffffff' })
    vim.api.nvim_set_hl(0, 'GAF1', { fg = '#6f7388' })

    dashboard.section.header.opts.hl = {
      {
        { 'I2A2', 0, 3 },
        { 'I2A2', 3, 6 },
        { 'I2A2', 6, 9 },
        { 'I2A2', 9, 12 },
        { 'I2A2', 12, 15 },
        { 'I2A2', 15, 18 },
        { 'I2A2', 18, 21 },
        { 'I2A2', 21, 24 },
        { 'I2A2', 24, 27 },
        { 'I2A2', 27, 30 },
        { 'I2A2', 30, 33 },
        { 'I2A2', 33, 36 },
        { 'I2A2', 36, 39 },
        { 'I2A2', 39, 42 },
        { 'I2A2', 42, 45 },
        { 'I2A2', 45, 48 },
        { 'I2A2', 48, 51 },
        { 'I2A0', 51, 54 },
        { 'I2A0', 54, 57 },
        { 'I2A0', 57, 60 },
        { 'I2A0', 60, 63 },
        { 'I2A0', 63, 66 },
        { 'I2A0', 66, 69 },
        { 'I2A0', 69, 72 },
        { 'I2A0', 72, 75 },
        { 'I2A0', 75, 78 },
        { 'I2A0', 78, 81 },
        { 'I2A0', 81, 84 },
        { 'I2A0', 84, 87 },
        { 'I2A0', 87, 90 },
        { 'I2A0', 90, 93 },
        { 'I2A0', 93, 96 },
        { 'I2A0', 96, 99 },
        { 'I2A0', 99, 102 },
        { 'I2A0', 102, 105 },
        { 'I2A0', 105, 108 },
        { 'I2A0', 108, 111 },
        { 'I2A0', 111, 114 },
        { 'I2A0', 114, 117 },
        { 'I2A0', 117, 120 },
      },
      {
        { 'I2A2', 0, 3 },
        { 'I2A2', 3, 6 },
        { 'I2A2', 6, 9 },
        { 'I2A2', 9, 12 },
        { 'I2A2', 12, 15 },
        { 'I2A2', 15, 18 },
        { 'I2A2', 18, 21 },
        { 'I2A2', 21, 24 },
        { 'I2A2', 24, 27 },
        { 'I2A2', 27, 30 },
        { 'I2A3', 30, 33 },
        { 'I2A4', 33, 36 },
        { 'I2A5', 36, 39 },
        { 'I2A6', 39, 42 },
        { 'I2A2', 42, 45 },
        { 'I2A2', 45, 48 },
        { 'I2A2', 48, 51 },
        { 'I2A2', 51, 54 },
        { 'I2A2', 54, 57 },
        { 'I2A2', 57, 60 },
        { 'I2A2', 60, 63 },
        { 'I2A2', 63, 66 },
        { 'I2A2', 66, 69 },
        { 'I2A2', 69, 72 },
        { 'I2A2', 72, 75 },
        { 'I2A2', 75, 78 },
        { 'I2A2', 78, 81 },
        { 'I2A2', 81, 84 },
        { 'I2A2', 84, 87 },
        { 'I2A2', 87, 90 },
        { 'I2A2', 90, 93 },
        { 'I2A2', 93, 96 },
        { 'I2A2', 96, 99 },
        { 'I2A2', 99, 102 },
        { 'I2A2', 102, 105 },
        { 'I2A2', 105, 108 },
        { 'I2A2', 108, 111 },
        { 'I2A2', 111, 114 },
        { 'I2A2', 114, 117 },
        { 'I2A2', 117, 120 },
      },
      {
        { 'I2A2', 0, 3 },
        { 'I2A2', 3, 6 },
        { 'I2A2', 6, 9 },
        { 'I2A2', 9, 12 },
        { 'I2A2', 12, 15 },
        { 'I2A2', 15, 18 },
        { 'I2A7', 18, 21 },
        { 'I2A8', 21, 24 },
        { 'I2A9', 24, 27 },
        { 'I2A10', 27, 30 },
        { 'I2A11', 30, 33 },
        { 'I2A12', 33, 36 },
        { 'I2A13', 36, 39 },
        { 'I2A14', 39, 42 },
        { 'I2A15', 42, 45 },
        { 'I2A16', 45, 48 },
        { 'I2A17', 48, 51 },
        { 'I2A2', 51, 54 },
        { 'I2A2', 54, 57 },
        { 'I2A2', 57, 60 },
        { 'I2A2', 60, 63 },
        { 'I2A2', 63, 66 },
        { 'I2A2', 66, 69 },
        { 'I2A2', 69, 72 },
        { 'I2A2', 72, 75 },
        { 'I2A2', 75, 78 },
        { 'I2A2', 78, 81 },
        { 'I2A2', 81, 84 },
        { 'I2A0', 84, 87 },
        { 'I2A0', 87, 90 },
        { 'I2A0', 90, 93 },
        { 'I2A0', 93, 96 },
        { 'I2A0', 96, 99 },
        { 'I2A0', 99, 102 },
        { 'I2A0', 102, 105 },
        { 'I2A0', 105, 108 },
        { 'I2A0', 108, 111 },
        { 'I2A0', 111, 114 },
        { 'I2A0', 114, 117 },
        { 'I2A0', 117, 120 },
      },
      {
        { 'I2A2', 0, 3 },
        { 'I2A2', 3, 6 },
        { 'I2A2', 6, 9 },
        { 'I2A2', 9, 12 },
        { 'I2A2', 12, 15 },
        { 'I2A18', 15, 18 },
        { 'I2A19', 18, 21 },
        { 'I2A20', 21, 24 },
        { 'I2A21', 24, 27 },
        { 'I2A22', 27, 30 },
        { 'I2A23', 30, 33 },
        { 'I2A24', 33, 36 },
        { 'I2A25', 36, 39 },
        { 'I2A26', 39, 42 },
        { 'I2A27', 42, 45 },
        { 'I2A28', 45, 48 },
        { 'I2A29', 48, 51 },
        { 'I2A30', 51, 54 },
        { 'I2A2', 54, 57 },
        { 'I2A2', 57, 60 },
        { 'I2A2', 60, 63 },
        { 'I2A2', 63, 66 },
        { 'I2A2', 66, 69 },
        { 'I2A31', 69, 72 },
        { 'I2A0', 72, 75 },
        { 'I2A0', 75, 78 },
        { 'I2A0', 78, 81 },
        { 'I2A0', 81, 84 },
        { 'I2A0', 84, 87 },
        { 'I2A0', 87, 90 },
        { 'I2A0', 90, 93 },
        { 'I2A0', 93, 96 },
        { 'I2A0', 96, 99 },
        { 'I2A0', 99, 102 },
        { 'I2A0', 102, 105 },
        { 'I2A0', 105, 108 },
        { 'I2A0', 108, 111 },
        { 'I2A0', 111, 114 },
        { 'I2A0', 114, 117 },
        { 'I2A0', 117, 120 },
      },
      {
        { 'I2A2', 0, 3 },
        { 'I2A2', 3, 6 },
        { 'I2A2', 6, 9 },
        { 'I2A2', 9, 12 },
        { 'I2A32', 12, 15 },
        { 'I2A33', 15, 18 },
        { 'I2A34', 18, 21 },
        { 'I2A35', 21, 24 },
        { 'I2A36', 24, 27 },
        { 'I2A37', 27, 30 },
        { 'I2A38', 30, 33 },
        { 'I2A39', 33, 36 },
        { 'I2A40', 36, 39 },
        { 'I2A41', 39, 42 },
        { 'I2A42', 42, 45 },
        { 'I2A43', 45, 48 },
        { 'I2A44', 48, 51 },
        { 'I2A45', 51, 54 },
        { 'I2A2', 54, 57 },
        { 'I2A2', 57, 60 },
        { 'I2A2', 60, 63 },
        { 'I2A2', 63, 66 },
        { 'I2A2', 66, 69 },
        { 'I2A46', 69, 72 },
        { 'I2A0', 72, 75 },
        { 'I2A0', 75, 78 },
        { 'I2A0', 78, 81 },
        { 'I2A0', 81, 84 },
        { 'I2A0', 84, 87 },
        { 'I2A0', 87, 90 },
        { 'I2A0', 90, 93 },
        { 'I2A0', 93, 96 },
        { 'I2A0', 96, 99 },
        { 'I2A0', 99, 102 },
        { 'I2A0', 102, 105 },
        { 'I2A0', 105, 108 },
        { 'I2A0', 108, 111 },
        { 'I2A0', 111, 114 },
        { 'I2A0', 114, 117 },
        { 'I2A0', 117, 120 },
      },
      {
        { 'I2A0', 0, 3 },
        { 'I2A0', 3, 6 },
        { 'I2A0', 6, 9 },
        { 'I2A47', 9, 12 },
        { 'I2A48', 12, 15 },
        { 'I2A49', 15, 18 },
        { 'I2A50', 18, 21 },
        { 'I2A51', 21, 24 },
        { 'I2A52', 24, 27 },
        { 'I2A53', 27, 30 },
        { 'I2A54', 30, 33 },
        { 'I2A55', 33, 36 },
        { 'I2A56', 36, 39 },
        { 'I2A57', 39, 42 },
        { 'I2A58', 42, 45 },
        { 'I2A59', 45, 48 },
        { 'I2A0', 48, 51 },
        { 'I2A0', 51, 54 },
        { 'I2A0', 54, 57 },
        { 'I2A60', 57, 60 },
        { 'I2A24', 60, 63 },
        { 'I2A24', 63, 66 },
        { 'I2A24', 66, 69 },
        { 'I2A24', 69, 72 },
        { 'I2A61', 72, 75 },
        { 'I2A0', 75, 78 },
        { 'I2A0', 78, 81 },
        { 'I2A0', 81, 84 },
        { 'I2A0', 84, 87 },
        { 'I2A0', 87, 90 },
        { 'I2A0', 90, 93 },
        { 'I2A0', 93, 96 },
        { 'I2A0', 96, 99 },
        { 'I2A0', 99, 102 },
        { 'I2A0', 102, 105 },
        { 'I2A0', 105, 108 },
        { 'I2A0', 108, 111 },
        { 'I2A0', 111, 114 },
        { 'I2A0', 114, 117 },
        { 'I2A0', 117, 120 },
      },
      {
        { 'I2A2', 0, 3 },
        { 'I2A2', 3, 6 },
        { 'I2A2', 6, 9 },
        { 'I2A2', 9, 12 },
        { 'I2A62', 12, 15 },
        { 'I2A63', 15, 18 },
        { 'I2A64', 18, 21 },
        { 'I2A65', 21, 24 },
        { 'I2A66', 24, 27 },
        { 'I2A67', 27, 30 },
        { 'I2A68', 30, 33 },
        { 'I2A69', 33, 36 },
        { 'I2A70', 36, 39 },
        { 'I2A71', 39, 42 },
        { 'I2A72', 42, 45 },
        { 'I2A73', 45, 48 },
        { 'I2A74', 48, 51 },
        { 'I2A75', 51, 54 },
        { 'I2A76', 54, 57 },
        { 'I2A77', 57, 60 },
        { 'I2A78', 60, 63 },
        { 'I2A79', 63, 66 },
        { 'I2A80', 66, 69 },
        { 'I2A0', 69, 72 },
        { 'I2A81', 72, 75 },
        { 'I2A0', 75, 78 },
        { 'I2A0', 78, 81 },
        { 'I2A0', 81, 84 },
        { 'I2A0', 84, 87 },
        { 'I2A0', 87, 90 },
        { 'I2A0', 90, 93 },
        { 'I2A0', 93, 96 },
        { 'I2A0', 96, 99 },
        { 'I2A0', 99, 102 },
        { 'I2A0', 102, 105 },
        { 'I2A0', 105, 108 },
        { 'I2A82', 108, 111 },
        { 'I2A83', 111, 114 },
        { 'I2A84', 114, 117 },
        { 'I2A0', 117, 120 },
      },
      {
        { 'I2A2', 0, 3 },
        { 'I2A2', 3, 6 },
        { 'I2A2', 6, 9 },
        { 'I2A2', 9, 12 },
        { 'I2A85', 12, 15 },
        { 'I2A86', 15, 18 },
        { 'I2A87', 18, 21 },
        { 'I2A88', 21, 24 },
        { 'I2A89', 24, 27 },
        { 'I2A90', 27, 30 },
        { 'I2A91', 30, 33 },
        { 'I2A92', 33, 36 },
        { 'I2A2', 36, 39 },
        { 'I2A2', 39, 42 },
        { 'I2A93', 42, 45 },
        { 'I2A94', 45, 48 },
        { 'I2A95', 48, 51 },
        { 'I2A96', 51, 54 },
        { 'I2A97', 54, 57 },
        { 'I2A98', 57, 60 },
        { 'I2A99', 60, 63 },
        { 'I2A100', 63, 66 },
        { 'I2A101', 66, 69 },
        { 'I2A102', 69, 72 },
        { 'I2A103', 72, 75 },
        { 'I2A104', 75, 78 },
        { 'I2A105', 78, 81 },
        { 'I2A106', 81, 84 },
        { 'I2A107', 84, 87 },
        { 'I2A108', 87, 90 },
        { 'I2A109', 90, 93 },
        { 'I2A110', 93, 96 },
        { 'I2A111', 96, 99 },
        { 'I2A112', 99, 102 },
        { 'I2A0', 102, 105 },
        { 'I2A0', 105, 108 },
        { 'I2A0', 108, 111 },
        { 'I2A0', 111, 114 },
        { 'I2A0', 114, 117 },
        { 'I2A0', 117, 120 },
      },
      {
        { 'I2A2', 0, 3 },
        { 'I2A2', 3, 6 },
        { 'I2A2', 6, 9 },
        { 'I2A2', 9, 12 },
        { 'I2A2', 12, 15 },
        { 'I2A113', 15, 18 },
        { 'I2A114', 18, 21 },
        { 'I2A115', 21, 24 },
        { 'I2A116', 24, 27 },
        { 'I2A117', 27, 30 },
        { 'I2A118', 30, 33 },
        { 'I2A2', 33, 36 },
        { 'I2A2', 36, 39 },
        { 'I2A2', 39, 42 },
        { 'I2A2', 42, 45 },
        { 'I2A2', 45, 48 },
        { 'I2A2', 48, 51 },
        { 'I2A2', 51, 54 },
        { 'I2A2', 54, 57 },
        { 'I2A2', 57, 60 },
        { 'I2A2', 60, 63 },
        { 'I2A2', 63, 66 },
        { 'I2A2', 66, 69 },
        { 'I2A0', 69, 72 },
        { 'I2A119', 72, 75 },
        { 'I2A120', 75, 78 },
        { 'I2A0', 78, 81 },
        { 'I2A0', 81, 84 },
        { 'I2A0', 84, 87 },
        { 'I2A0', 87, 90 },
        { 'I2A0', 90, 93 },
        { 'I2A0', 93, 96 },
        { 'I2A0', 96, 99 },
        { 'I2A0', 99, 102 },
        { 'I2A0', 102, 105 },
        { 'I2A0', 105, 108 },
        { 'I2A0', 108, 111 },
        { 'I2A0', 111, 114 },
        { 'I2A0', 114, 117 },
        { 'I2A0', 117, 120 },
      },
      {
        { 'I2A2', 0, 3 },
        { 'I2A2', 3, 6 },
        { 'I2A2', 6, 9 },
        { 'I2A2', 9, 12 },
        { 'I2A2', 12, 15 },
        { 'I2A2', 15, 18 },
        { 'I2A2', 18, 21 },
        { 'I2A2', 21, 24 },
        { 'I2A2', 24, 27 },
        { 'I2A121', 27, 30 },
        { 'I2A2', 30, 33 },
        { 'I2A2', 33, 36 },
        { 'I2A2', 36, 39 },
        { 'I2A2', 39, 42 },
        { 'I2A2', 42, 45 },
        { 'I2A2', 45, 48 },
        { 'I2A2', 48, 51 },
        { 'I2A2', 51, 54 },
        { 'I2A2', 54, 57 },
        { 'I2A2', 57, 60 },
        { 'I2A2', 60, 63 },
        { 'I2A2', 63, 66 },
        { 'I2A122', 66, 69 },
        { 'I2A123', 69, 72 },
        { 'I2A0', 72, 75 },
        { 'I2A0', 75, 78 },
        { 'I2A0', 78, 81 },
        { 'I2A0', 81, 84 },
        { 'I2A0', 84, 87 },
        { 'I2A0', 87, 90 },
        { 'I2A0', 90, 93 },
        { 'I2A0', 93, 96 },
        { 'I2A0', 96, 99 },
        { 'I2A0', 99, 102 },
        { 'I2A0', 102, 105 },
        { 'I2A0', 105, 108 },
        { 'I2A0', 108, 111 },
        { 'I2A0', 111, 114 },
        { 'I2A0', 114, 117 },
        { 'I2A0', 117, 120 },
      },
      {
        { 'I2A2', 0, 3 },
        { 'I2A2', 3, 6 },
        { 'I2A2', 6, 9 },
        { 'I2A2', 9, 12 },
        { 'I2A2', 12, 15 },
        { 'I2A2', 15, 18 },
        { 'I2A2', 18, 21 },
        { 'I2A2', 21, 24 },
        { 'I2A2', 24, 27 },
        { 'I2A2', 27, 30 },
        { 'I2A2', 30, 33 },
        { 'I2A2', 33, 36 },
        { 'I2A2', 36, 39 },
        { 'I2A2', 39, 42 },
        { 'I2A2', 42, 45 },
        { 'I2A2', 45, 48 },
        { 'I2A2', 48, 51 },
        { 'I2A0', 51, 54 },
        { 'I2A0', 54, 57 },
        { 'I2A0', 57, 60 },
        { 'I2A0', 60, 63 },
        { 'I2A125', 63, 66 },
        { 'I2A0', 66, 69 },
        { 'I2A0', 69, 72 },
        { 'I2A0', 72, 75 },
        { 'I2A0', 75, 78 },
        { 'I2A0', 78, 81 },
        { 'I2A0', 81, 84 },
        { 'I2A0', 84, 87 },
        { 'I2A0', 87, 90 },
        { 'I2A0', 90, 93 },
        { 'I2A0', 93, 96 },
        { 'I2A0', 96, 99 },
        { 'I2A0', 99, 102 },
        { 'I2A0', 102, 105 },
        { 'I2A0', 105, 108 },
        { 'I2A0', 108, 111 },
        { 'I2A0', 111, 114 },
        { 'I2A0', 114, 117 },
        { 'I2A0', 117, 120 },
      },
      { { 'GAH1', 0, 120 } },
      { { 'GAH1', 0, 120 } },
    }

    dashboard.section.header.val = {
      [[ ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ]],
      [[ ⠀⠀⠀⠀⠀⠀⠀⢀⣠⣶⣤⣶⣤⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ]],
      [[ ⠀⠀⠀⠀⠀⠀⣄⣿⣿⣿⣿⣿⣿⣿⣿⣧⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ]],
      [[ ⠀⠀⠀⠀⢀⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣇⠀⠀⠀⠀⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ]],
      [[ ⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠛⠃⠀⠀⠀⠀⠀⠘⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ]],
      [[ ⠀⠀⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⡄⠀⢂⠀⢠⣧⠀⠀⠀⢇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ]],
      [[ ⠀⠀⠀⠛⢻⣿⣿⣿⣿⣿⣿⣿⡿⠿⠿⠿⠷⢤⣑⣄⠻⢿⣄⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⠄⠀ ]],
      [[ ⠀⠀⠀⠀⣻⣿⣿⣿⣿⣿⣿⡀⠁⠀⢀⣀⣀⣀⡡⠿⠷⠶⠤⢵⣦⣵⣦⣤⣤⣤⣤⣴⣒⡚⠉⠉⠁⠀⠀⠀ ]],
      [[ ⠀⠀⠀⠀⠘⠿⣿⣿⣿⣿⠟⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠎⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠉⠉⠁⠀ ]],
      [[ ⠀⠀⠀⠀⠀⠀⠙⠛⠛⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡴⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ]],
      [[ ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡴⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ]],
      [[                                          ]],
      [[Freedom today, Freedom tomorrow, Freedom forever]],
    }

    dashboard.section.buttons.type = 'group'
    dashboard.section.buttons.val = {
      { type = 'padding', val = 1 },
      dashboard.button('i', '󰷫  Insert', ':ene <BAR> startinsert <CR>'),
      dashboard.button('s', '  Search', '<CMD>Telescope find_files<CR>'),
      dashboard.button('g', '󰈞  Grep', '<CMD>Telescope live_grep<CR>'),
      dashboard.button('u', '󰮭  Update', '<CMD>Lazy sync<CR>'),
      dashboard.button('q', '󰩈  Quit', '<CMD>qa<CR>'),
      { type = 'padding', val = 1 },
    }

    vim.api.nvim_create_autocmd('User', {
      pattern = 'LazyVimStarted',
      callback = function()
        local stats = require('lazy').stats()
        local count = (math.floor(stats.startuptime * 100) / 100)

        dashboard.section.footer.opts.hl = 'GAF1'

        dashboard.section.footer.val = {
          '',
          '󱐋 ' .. stats.loaded .. ' plugins loaded in ' .. count .. ' ms',
        }

        pcall(vim.cmd.AlphaRedraw)
      end,
    })

    alpha.setup(dashboard.opts)
  end,
}
