return {
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
