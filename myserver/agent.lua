local skynet = require "skynet"
local socket = require "skynet.socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
require "function"

local WATCHDOG
local host
local send_request

local CMD = {}
local REQUEST = {}
local client_fd

function REQUEST:get()
	print("get", self.what)
	local r = skynet.call("SIMPLEDB", "lua", "get", self.what)
	return { result = r }
end

function REQUEST:set()
	print("set", self.what, self.value)
	local r = skynet.call("SIMPLEDB", "lua", "set", self.what, self.value)
end

function REQUEST:handshake()
	return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end

function REQUEST:quit()
	skynet.call(WATCHDOG, "lua", "close", client_fd)
end

local function request(name, args, response)
	local f = assert(REQUEST[name])
	local r = f(args)
	if response then
		return response(r)
	end
end

local function send_package(pack)
	local package = string.pack(">s2", pack)
	socket.write(client_fd, package)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch(msg, sz)
	end,
	dispatch = function (cfd, _, type, ...)
		assert(cfd == client_fd)	-- You can use cfd to reply message
		skynet.ignoreret()	-- session is cfd, don't call skynet.ret
		skynet.trace()
		if type == "REQUEST" then
			local ok, result  = pcall(request, ...)
			if ok then
				if result then
					send_package(result)
				end
			else
				skynet.error(result)
			end
		else
			assert(type == "RESPONSE")
			error "This example doesn't support request client"
		end
	end
}

-- fork 协程来发送心跳包
function CMD.start(watchdogpara)
	local cfd = watchdogpara.client
	local gate = watchdogpara.gate
	WATCHDOG = watchdogpara.watchdog

	--print("[agent]CMD.star cfd="..cfd)
	--print("[agent]CMD.star gate="..gate)
	--print("[agent]CMD.star WATCHDOG="..WATCHDOG)
	-- slot 1,2 set at main.lua
	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
	--print("[agent]CMD.star send_request=")
	--print_r(send_request)
	skynet.fork(function()
		while true do
			send_package(send_request("heartbeat"))
			skynet.sleep(500)
		end
	end)

	client_fd = cfd
	skynet.call(gate, "lua", "forward", cfd)
end

function CMD.disconnect()
	-- todo: do something before exit
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		print("[agent]CMD="..command)
		print(...)
		skynet.ret(skynet.pack(f(...)))
	end)
end)
