--
--                                           .
--                                            `.
--
--                                       ...
--                                          `.
--                                    ..
--                                      `.
--                              `.        `.
--                           ___`.\.//
--                              `---.---
--                             /     \.--
--                            /       \-
--                           |   /\    \
--                           |\==/\==/  |
--                           | `@'`@'  .--.
--                    .--------.           )
--                  .'             .   `._/
--                 /               |     \
--                .               /       |
--                |              /        |
--                |            .'         |   .--.
--               .'`.        .'_          |  /    \
--             .'    `.__.--'.--`.       / .'      |
--           .'            .|    \\     |_/        |
--         .'            .' |     \\               |
--       .-`.           /   |      .      __       |
--     .'    `.     \   |   `           .'  )      \
--    /        \   / \  |            .-'   /       |
--   (  /       \ /   \ |                 |        |
--    \/         (     \/                 |        |
--    (  /        )    /                 /   _.----|
--     \/   //   /   .'                  |.-'       `
--     (   /(   /   /                    /      `.   |
--      `.(  `-')  .---.                |    `.   `._/
--         `._.'  /     `.   .---.      |  .   `._.'
--                |       \ /     `.     \  `.___.'
--                |        Y        `.    `.___.'
--                |      . |          \         \
--                |       `|           \         |
--                |        |       .    \        |
--                |        |        \    \       |
--              .--.       |         \           |
--             /    `.  .----.        \          /
--            /       \/      \        \        /
--            |       |        \       |       /
--             \      |         \   `-. \     /
--              \      \         \     \|.__.'
--               \      \         \     |
--                \      \         \    |
--                 \      \         \   |
--                  \    .'`.        \  |
--                   `.-'    `.    _.'\ |
--                     |       `.-'    ||
--                .     \     . `.     ||      .'
--                 `.    `-.-'    `.__.'     .'
--                   `.                    .'
--               .                       .'
--                `.
--                                             .-'
--                                          .-'
--
--        \                 \
--         \         ..      \
--          \       /  `-.--.___ __.-.___
--  `-.      \     /  #   `-._.-'    \   `--.__
--     `-.        /  ####    /   ###  \        `.
--  ________     /  #### ############  |       _|           .'
--              |\ #### ##############  \__.--' |    /    .'
--              | ####################  |       |   /   .'
--              | #### ###############  |       |  /
--              | #### ###############  |      /|      ----
--            . | #### ###############  |    .'<    ____
--          .'  | ####################  | _.'-'\|
--        .'    |   ##################  |       |
--               `.   ################  |       |
--                 `.    ############   |       | ----
--                ___`.     #####     _..____.-'     .
--               |`-._ `-._       _.-'    \\\         `.
--            .'`-._  `-._ `-._.-'`--.___.-' \          `.
--          .' .. . `-._  `-._        ___.---'|   \   \
--        .' .. . .. .  `-._  `-.__.-'        |    \   \
--       |`-. . ..  . .. .  `-._|             |     \   \
--       |   `-._ . ..  . ..   .'            _|
--        `-._   `-._ . ..   .' |      __.--'
--            `-._   `-._  .' .'|__.--'
--                `-._   `' .'
--                    `-._.'
--
--
--
--   "It's a great idea to spend countless hours writing .lua scripts for a 40 year old text-editor instead of doing real work."
--
--   - Noone
--

-- set nvim globals, options and auto commands
require 'options'

-- define custom keymaps
require 'keymaps'

-- install "lazyvim" plugin manager
-- see: https://www.lazyvim.org/configuration/lazy.nvim
require 'lazyvim'

-- load all plugins at `./lua/plugins/` and setup general lazy settings
require('lazy').setup('plugins', {
  change_detection = { enabled = false },
})
