local skynet = require "skynet"
local service = require "service"
local client = require "client"
local log = require "log"

local agent = {}
local data = {}
local cli = client.handler()

--[[
	在网络游戏中，你可以为每个在线用户创建一个 lua 虚拟机（skynet 称之为 lua 服务），
姑且把它称为 agent 。用户在不和其它用户交互而仅仅自娱自乐时，agent 完全可以满足要求。
agent 在用户上线时，从数据库加载关联于它的所有数据到 lua vm 中，对用户的网络请求做出反应。
当然你也可以让一个 lua 服务管理多个在线用户，每个用户是 lua 虚拟机内的一个对象。

	你还可以用独立的服务处理网络游戏中的副本（或是战场），处理玩家和玩家间，玩家协同对战 AI 的战斗。
agent 会和副本服务通过消息进行交互，而不必让用户客户端直接与副本通讯
]]

function cli:ping()
	assert(self.login)
	log "ping"
end

function cli:login()
	assert(not self.login)
	if data.fd then
		log("login fail %s fd=%d", data.userid, self.fd)
		return { ok = false }
	end
	data.fd = self.fd
	self.login = true
	log("login succ %s fd=%d", data.userid, self.fd)
	client.push(self, "push", { text = "welcome" })	-- push message to client
	return { ok = true }
end

local function new_user(fd)
	local ok, error = pcall(client.dispatch , { fd = fd })
	log("fd=%d is gone. error = %s", fd, error)
	client.close(fd)
	if data.fd == fd then
		data.fd = nil
		skynet.sleep(1000)	-- exit after 10s
		if data.fd == nil then
			-- double check
			if not data.exit then
				data.exit = true	-- mark exit
				skynet.call(service.manager, "lua", "exit", data.userid)	-- report exit
				log("user %s afk", data.userid)
				skynet.exit()
			end
		end
	end
end

function agent.assign(fd, userid)
	if data.exit then
		return false
	end
	if data.userid == nil then
		data.userid = userid
	end
	assert(data.userid == userid)
	skynet.fork(new_user, fd)
	return true
end

service.init {
	command = agent,
	info = data,
	require = {
		"manager",
	},
	init = client.init "proto",
}

