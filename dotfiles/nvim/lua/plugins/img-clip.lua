return {
    -- Effortlessly embed images into any markup language, like LaTeX, Markdown or Typst.
    -- SEE: https://github.com/HakonHarnes/img-clip.nvim
    'HakonHarnes/img-clip.nvim',

    cmd = {
        'PasteImage',
        'ImgClipDebug',
        'ImgClipConfig',
    },

    config = function()
        local plugin = require 'img-clip'

        plugin.setup {}
    end,
}
