local luasnip = require 'luasnip'

require('luasnip.session.snippet_collection').clear_snippets 'lua'
local s = luasnip.snippet
local i = luasnip.insert_node
local d = luasnip.dynamic_node
local f = require('luasnip.extras.fmt').fmta

local function replicate(args, _)
    local text = args[1][1]
    return luasnip.snippet_node(nil, i(1, text))
end

luasnip.add_snippets('lua', {
    -- stylua: ignore
    s('plug', f([[
        {
            -- <>
            -- SEE: https://github.com/<>
            '<>', 

            config = function() 
                <>
            end,
        },
    ]], {
        i(1),
        i(2),
        d(3, replicate, {2}),
        i(4)
    }))
,
})
