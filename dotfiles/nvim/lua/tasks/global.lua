local overseer = require 'overseer'

overseer.register_template {
    name = 'Hello world',
    descriptions = "Echo 'hello world' to the command line",

    builder = function(_)
        return {
            cmd = { 'echo' },
            args = { 'hello', 'world' },
        }
    end,

    condition = {
        callback = function(search)
            print(vim.inspect(search))
            return true
        end,
    },
}

overseer.register_template {
    name = 'Bye world',
    descriptions = "Echo 'bye world' to the command line",

    builder = function(_)
        return {
            cmd = { 'echo' },
            args = { 'bye', 'world' },
        }
    end,

    condition = {
        callback = function(search)
            print(vim.inspect(search))
            return true
        end,
    },
}
