local luasnip = require 'luasnip'

require('luasnip.session.snippet_collection').clear_snippets 'go'

local s = luasnip.snippet
local i = luasnip.insert_node
local f = require('luasnip.extras.fmt').fmt

luasnip.add_snippets('go', {})
