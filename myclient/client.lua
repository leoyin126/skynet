local Para = ...

IP = "127.0.0.1"
-- 需要连接watchdog 的ip port
port = 8888
if Para ~= nil then
	IP = Para[1] or "127.0.0.1"
	port = Para[2] or 8888
end

package.cpath = string.format("luaclib/?.so;lsocket/?.so")
package.path = "lualib/?.lua;myclient/?.lua"

local socket = require "socket"
local message = require "message"

message:register("myproto/proto")

message:peer(IP, port)
message:connect()

local event = {}

message:bind("event", event)

function event:__error(what, err, req, session)
	print("error", what, err)
end

function event:ping()
	print("ping")
end

function event:signin(req, resp)
	print("signin", req.userid, resp.ok)
	if resp.ok then
		message.request "ping"	-- should error before login
		message.request "login"
	else
		-- signin failed, signup
		message.request("signup", { userid = "alice" })
	end
end

function event:signup(req, resp)
	print("signup", resp.ok)
	if resp.ok then
		message.request("signin", { userid = req.userid })
	else
		error "Can't signup"
	end
end

function event:login(_, resp)
	print("login", resp.ok)
	if resp.ok then
		message.request "ping"
	else
		error "Can't login"
	end
end

function event:push(args)
	print("server push", args.text)
end

message:request("signin", { userid = "alice" })

while true do
	message:update()
end