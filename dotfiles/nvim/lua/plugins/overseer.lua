return {
    -- A task runner and job management plugin for Neovim.
    -- SEE: https://github.com/stevearc/overseer.nvim
    'stevearc/overseer.nvim',

    event = 'VeryLazy',

    init = function()
        local commands = require 'utils.commands'

        local keymap = vim.keymap.set

        local tasks = function()
            vim.cmd 'OverseerToggle'
        end

        local run = function()
            vim.cmd 'OverseerRun'
        end

        keymap('n', '<leader>rp', tasks, { desc = 'Toggle [R]un tasks [P]anel.' })
        keymap('n', '<leader>rt', run, { desc = '[R]un [T]asks.' })

        commands.user('Run', run)
        commands.user('Tasks', tasks)
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
