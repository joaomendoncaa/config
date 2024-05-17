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

require 'config.general'
require 'config.keymaps'
require 'config.lazy'

require('lazy').setup('plugins', { change_detection = { notify = false } })
