return {
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local harpoon = require 'harpoon'
      harpoon:setup()

      -- Apend to the list and open list
      vim.keymap.set('n', '<leader>ha', function()
        harpoon:list():add()
      end, { desc = '[H]arpoon List [A]ppend' })
      vim.keymap.set('n', '<leader>hl', function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, { desc = '[H]ist [L]ist' })

      -- Select an item from the list
      vim.keymap.set('n', '<a-1>', function()
        harpoon:list():select(1)
      end, { desc = 'Select Harpoon Buffer in Position 1' })
      vim.keymap.set('n', '<a-2>', function()
        harpoon:list():select(2)
      end, { desc = 'Select Harpoon Buffer in Position 2' })
      vim.keymap.set('n', '<a-3>', function()
        harpoon:list():select(3)
      end, { desc = 'Select Harpoon Buffer in Position 3' })
      vim.keymap.set('n', '<a-4>', function()
        harpoon:list():select(4)
      end, { desc = 'Select Harpoon Buffer in Position 4' })

      -- Toggle previous & next buffers stored within Harpoon list
      vim.keymap.set('n', '<a-h>', function()
        harpoon:list():prev()
      end, { desc = 'Select previous Harpoon item on the list' })
      vim.keymap.set('n', '<a-l>', function()
        harpoon:list():next()
      end, { desc = 'Select next Harpoon item on the list' })
    end,
  },
}