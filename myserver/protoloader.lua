package.path = "./myserver/?.lua;" .. package.path

local skynet = require "skynet"
local sprotoparser = require "sprotoparser"
local sprotoloader = require "sprotoloader"
require "function"

local function load(name)
	local filename = string.format("myproto/%s.sproto", name)
	local f = assert(io.open(filename), "Can't open " .. name)
	local t = f:read "a"
	f:close()
	return sprotoparser.parse(t)
end

skynet.start(function()
	proto = proto or {}
	proto.c2s = load("proto.c2s")
	proto.s2c = load("proto.s2c")
	print_r(proto.c2s)
	print_r(proto.s2c)
	sprotoloader.save(proto.c2s, 1)
	sprotoloader.save(proto.s2c, 2)
	--[[
	skynet.call(proto, "lua", "load", {
		"proto.c2s",
		"proto.s2c",
	})
	]]
	-- don't call skynet.exit() , because sproto.core may unload and the global slot become invalid
end)
