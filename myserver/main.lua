local skynet = require "skynet"

skynet.start(function()
	skynet.error("Server start")
	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end
	skynet.newservice("debug_console",8000)
	skynet.uniqueservice("protoloader")
	local hub = skynet.uniqueservice "hub"
	skynet.call(hub, "lua", "open", "0.0.0.0", 5678)
	skynet.exit()
end)
