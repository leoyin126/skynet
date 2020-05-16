local lsocket = require "lsocket"

socket = socket or {}

socket.error = setmetatable({}, { 
	__tostring = function() 
		return table.concat(debug.getinfo(1)) .. "sss"
	end 
} 
)

function socket:connect(addr, port)
	assert(self.fd == nil)
	self.fd = lsocket.connect(addr, port)
	if self.fd == nil then
		--error(socket.error)
		print(string.format( "socket connect err addr=%s, port=%d", addr, port ))
	else
		print(string.format( "socket connect success addr=%s, port=%d", addr, port ))
	end

	lsocket.select(nil, {self.fd})
	local ok, errmsg = self.fd:status()
	if not ok then
		--error(socket.error)
		print(string.format( "socket status err, msg=%s", errmsg))
	end

	self.message = ""
end

function socket:isconnect(ti)
	local rd, wt = lsocket.select(nil, { self.fd }, ti)
	return next(wt) ~= nil
end

function socket:close()
	self.fd:close()
	self.fd = nil
	self.message = nil
end

function socket.read(ti)
	while true do
		local ok, msg, n = pcall(string.unpack, ">s2", self.message)
		if not ok then
			local rd = lsocket.select({self.fd}, ti) 
			if not rd then
				return nil
			end
			if next(rd) == nil then
				return nil
			end
			local p = self.fd:recv()
			if not p then
				error(self.error)
			end
			self.message = self.message .. p
		else
			self.message = self.message:sub(n)
			return msg
		end
	end
end

function socket:write(msg)
	local pack = string.pack(">s2", msg)
	repeat
		local bytes = self.fd:send(pack)
		if not bytes then
			error(self.error)
		end
		pack = pack:sub(bytes+1)
	until pack == ""
end

return socket