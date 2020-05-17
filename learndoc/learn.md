## skynet 的 server 启动
### 首先执行的是bootstarp.lua
1. require "skynet"
最先运行的是不在skyent.lua 的非function代码，代码有如下部分， 我抠出来了。
```lua
-- profile 文件
local profile = require "skynet.profile"
-- code缓存
skynet.cache = require "skynet.codecache"
skynet.trace_timeout(false)	-- turn off by default
-- 这里有服务器开始时间哦~
skynet.now = c.now
-- 性能计数
skynet.hpc = c.hpc	-- high performance counter

-- 一下的函数都用了 c 的哦
skynet.genid = assert(c.genid)
skynet.pack = assert(c.pack)
skynet.packstring = assert(c.packstring)
skynet.unpack = assert(c.unpack)
skynet.tostring = assert(c.tostring)
skynet.trash = assert(c.trash)

-- error 和 log
skynet.error = c.error
skynet.tracelog = c.trace

----- register protocol
-- 上面是原注销，这里的protocol是skynet节点间通信协议，不是游戏的。
-- 目前就设置了 lua、 response、 erros这三种节点间通信协议
function skynet.register_protocol(class)
	local name = class.name
	local id = class.id
	assert(proto[name] == nil and proto[id] == nil)
	assert(type(name) == "string" and type(id) == "number" and id >=0 and id <=255)
	proto[name] = class
	proto[id] = class
end

-- 下面这种写法很恶心，其实相当于
-- skynet.register_protocol({ 
--    name = "lua",
--		id = skynet.PTYPE_LUA,
--		pack = skynet.pack,
--		unpack = skynet.unpack, })
do
	local REG = skynet.register_protocol

	REG {
		name = "lua",
		id = skynet.PTYPE_LUA,
		pack = skynet.pack,
		unpack = skynet.unpack,
	}

	REG {
		name = "response",
		id = skynet.PTYPE_RESPONSE,
	}

	REG {
		name = "error",
		id = skynet.PTYPE_ERROR,
		unpack = function(...) return ... end,
		dispatch = _error_dispatch,
	}
end


-- Inject internal debug framework
local debug = require "skynet.debug"
debug.init(skynet, {
	dispatch = skynet.dispatch_message,
	suspend = suspend,
	resume = coroutine_resume,
})
```

2. require "skynet.harbor"
这里没非funciton函数，只是返回一个 harbor 的table，里面注册几个barbor需要用的函数。
```lua
-- harbor 的所有函数都用上面 register_protocol 定义的通信调用
skynet.send(".cslave", "lua", "REGISTER", name, handle)
```
3. require "skynet.manager"
这里没非funciton函数，只是返回一个 manager 的table，里面注册几个skynet对service的管理函数。

4. 进入 skynet.start() 的函数
这里主要 
```lua
pcall(skynet.newservice,"cmaster")
pcall(skynet.newservice,"cslave")
--最后
skynet.newservice "service_mgr"
-- pcall 和下面的 newservice 一样的，只是pcall可以用于lua的异常处理用
````

### 执行cmaster.lua
1. 