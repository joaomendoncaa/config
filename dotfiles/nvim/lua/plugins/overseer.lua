return {
    -- A task runner and job management plugin for Neovim.
    -- SEE: https://github.com/stevearc/overseer.nvim
    'stevearc/overseer.nvim',

    event = 'VeryLazy',

    init = function()
        local commands = require 'utils.commands'

        local keymap = vim.keymap.set

        local toggle_panel = function()
            vim.cmd 'OverseerToggle'
        end

        local run = function()
            vim.cmd 'OverseerRun'
        end

        keymap('n', '<leader>pr', run, { desc = '[R]un [P]rocess.' })
        keymap('n', '<leader>pp', toggle_panel, { desc = 'Toggle [P]rocesses [P]anel.' })

        commands.user('ProcessesRun', run)
        commands.user('ProcessesPanel', toggle_panel)
    end,

    config = function()
        require('overseer').setup {
            task_list = {
                direction = 'bottom',
                default_detail = 1,
            },
        }

        -- load all task files defined at `tasks/`
        -- SEE: https://github.com/stevearc/overseer.nvim/blob/master/doc/guides.md#template-definition
        for _, ft_path in ipairs(vim.api.nvim_get_runtime_file('lua/tasks/*.lua', true)) do
            loadfile(ft_path)()
        end
    end,
}
