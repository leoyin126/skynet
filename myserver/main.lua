local skynet = require "skynet"

local max_client = 128

skynet.start(function()
	skynet.error("Server start")

	skynet.uniqueservice("protoloader")
	
	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end

	skynet.newservice("debug_console",8000)

	local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", {
		port = 8888,
		maxclient = max_client,
		nodelay = true,
	})
	skynet.error("Watchdog listen on", 8888)

	skynet.exit()
end)
