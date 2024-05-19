local luasnip = require 'luasnip'

require('luasnip.session.snippet_collection').clear_snippets 'typescript'

local s = luasnip.snippet
local i = luasnip.insert_node
local t = luasnip.text_node
local f = require('luasnip.extras.fmt').fmta

luasnip.add_snippets('typescript', {
    -- stylua: ignore
    s('main', f([[
        async function main() {
            <>
        }

        main().catch(err =<> {
            console.error("Aborting due to error:", err);
            process.exit(1);
        });    
    ]], { i(0), t('>') })),
})
