local utils = require('core.utils')
local theme = utils.read_theme()
local accent = utils.color_strip(theme.accent or '7b534e')

return {
	gaps_in = 7,
	gaps_out = 10,
	border_size = 2,
	resize_on_border = false,
	allow_tearing = false,
	layout = 'dwindle',
	col = {
		active_border = 'rgb(' .. accent .. ')',
		inactive_border = 'rgba(59595900)',
	},
}
