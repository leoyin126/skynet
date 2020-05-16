local socket = require "socket"
local sproto = require "sproto"
require "function"

local message = {}

function message:register(name)
	print(name .. ".s2c.sproto")
	local f = assert(io.open(name .. ".s2c.sproto"))
	local t = f:read "a"
	f:close()
	self.host = sproto.parse(t):host "package"
	local f = assert(io.open(name .. ".c2s.sproto"))
	local t = f:read "a"
	f:close()
	self.protoReq = self.host:attach(sproto.parse(t))
end

function message:peer(addr, port)
	self.addr = addr
	self.port = port
end

function message:connect()
	socket:connect(self.addr, self.port)
	socket:isconnect()
end

function message:bind(obj, handler)
	self.object = self.object or {}
	self.object[obj] = handler
end

function message:request(name, args)
	self.session = self.session or {}
	self.session_id = self.session_id or 1
	self.session_id = self.session_id + 1
	self.session[self.session_id] = { name = name, req = args }
	print(string.format( "message.request session_id=%d, name=%s, req=%s",self.session_id, name, serialize(args) ))
	socket:write(self.protoReq(name , args, self.session_id))
	return self.session_id
end

function message:update(ti)
	local msg = socket:read(ti)
	if not msg then
		return false
	end
	local t, session_id, resp, err = self.host:dispatch(msg)
	if t == "REQUEST" then
		for obj, handler in pairs(self.object) do
			local f = handler[session_id]	-- session_id is request type
			if f then
				local ok, err_msg = pcall(f, obj, resp)	-- resp is content of push
				if not ok then
					print(string.format("push %s for [%s] error : %s", session_id, tostring(obj), err_msg))
				end
			end
		end
	else
		local session = self.session[session_id]
		self.session[session_id] = nil

		for obj, handler in pairs(self.object) do
			if err then
				local f = handler.__error
				if f then
					local ok, err_msg = pcall(f, obj, session.name, err, session.req, session_id)
					if not ok then
						print(string.format("session %s[%d] error(%s) for [%s] error : %s", session.name, session_id, err, tostring(obj), err_msg))
					end
				end
			else
				local f = handler[session.name]
				if f then
					local ok, err_msg = pcall(f, obj, session.req, resp, session_id)
					if not ok then
						print(string.format("session %s[%d] for [%s] error : %s", session.name, session_id, tostring(obj), err_msg))
					end
				end
			end
		end
	end

	return true
end

return message