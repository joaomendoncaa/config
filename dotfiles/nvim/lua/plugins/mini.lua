return {
    {
        -- Library of 35+ independent Lua modules improving overall Neovim (version 0.7 and higher) experience with minimal effort.
        -- SEE: https://github.com/echasnovski/mini.nvim
        'echasnovski/mini.nvim',

        config = function()
            local ai = require 'mini.ai'
            local surround = require 'mini.surround'
            local sessions = require 'mini.sessions'
            local move = require 'mini.move'
            local commands = require 'utils.commands'
            local jump2d = require 'mini.jump2d'
            local diff = require 'mini.diff'

            local function get_session_path()
                return vim.fn.getcwd():gsub('[/\\]', '_') .. '.vim'
            end

            commands.auto('VimEnter', {
                callback = function()
                    local path = get_session_path()
                    if vim.fn.filereadable(sessions.config.directory .. path) == 1 then
                        vim.schedule(function()
                            sessions.read(path)
                        end)
                    end
                end,
            })

            commands.auto('VimLeave', {
                callback = function()
                    sessions.write(get_session_path())
                end,
            })

            surround.setup {}
            move.setup {}
            diff.setup {}
            ai.setup { n_lines = 500 }
            sessions.setup {
                autoread = false,
                autowrite = false,
                directory = vim.fn.stdpath 'data' .. '/sessions/',
                verbose = { read = false, write = false, delete = false },
            }
            jump2d.setup {
                mappings = {
                    start_jumping = '<CR>',
                },
                silent = true,
            }
        end,
    },
}
