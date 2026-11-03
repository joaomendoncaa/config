hl.monitor({ output = "DP-2", mode = "preferred", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@75", position = "-1080x-240", scale = 1, transform = 1 })
hl.workspace_rule({ workspace = "11", monitor = "HDMI-A-1", default = true, persistent = true })

for i = 1, 10 do
	hl.workspace_rule({ workspace = tostring(i), monitor = "DP-2", default = i == 1 })
end

hl.on("hyprland.start", function()
	hl.timer(function()
		if hl.get_workspace("1") then
			hl.dispatch(hl.dsp.focus({ workspace = "1" }))
		end
	end, { timeout = 1, type = "oneshot" })
end)
