return {
  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for install instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      require('telescope').setup {
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      -- enable telescope extensions, if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      local builtin = require 'telescope.builtin'
      local keymap = vim.keymap.set

      keymap('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp.' })

      keymap('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps.' })

      keymap('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles.' })

      keymap('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope.' })

      keymap('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord.' })

      keymap('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep.' })

      keymap('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics.' })

      keymap('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume.' })

      keymap('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat).' })

      keymap('n', '<leader>/', function()
        -- You can pass additional configuration to telescope to change theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer.' })

      keymap('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files.' })

      keymap('n', '<leader>sc', function()
        builtin.find_files { cwd = os.getenv 'HOME' .. '/lab/config' }
      end, { desc = '[S]earch [C]onfig files' })

      keymap('n', '<leader>ns', function()
        builtin.find_files { cwd = os.getenv 'HOME' .. '/lab/notes' }
      end, { desc = '[N]otes: fuzzy [S]earch.' })

      keymap('n', '<leader>nn', function()
        local prompt_title = 'Create New Note'
        local directory = os.getenv 'HOME' .. '/lab/notes'

        require('telescope.pickers')
          .new({}, {
            prompt_title = prompt_title,
            finder = require('telescope.finders').new_oneshot_job { 'echo' },
            attach_mappings = function(prompt_buffer)
              require('telescope.actions').select_default:replace(function(prompt_buffer)
                local selection = require('telescope.actions.state').get_selected_entry()

                print('you selected:' .. selection.value)
              end)
            end,
          })
          :find()
      end, { desc = '[N]otes: [N]ew note.' })
    end,
  },
}
