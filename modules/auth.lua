pcre = require("rex_pcre")

local interface = {handlers = {}}

local modules = {}

local module_handlers = {}

local auth_handlers = {}

local user = {}


function auth_handlers.PRIVMSG(net, sender, channel, message)
	if user[sender.nick] ~= nil then
		local password = pcre.match(message, "!identify (.*)$")

		if password == user[sender.nick].password then
			user[sender.nick].authenticated = true
		end
	end
end


function auth_handlers.QUIT(net, sender, message)
	if user[sender.nick] ~= nil then
		user[sender.nick].authenticated = nil
	end
end


function auth_handlers.NICK(net, sender, new)
	if user[sender.nick] ~= nil then
		user[sender.nick].authenticated = nil
	end
end


local function is_authenticated(net, sender)
	if user[sender.nick] ~= nil then
		return user[sender.nick].authenticated
	else
		return false
	end
end


function interface.construct(modules, users)
	-- Save the username/password db for later use
	for name, password in pairs(users) do
		user[name] = {["password"] = password}
	end

	-- Start all our sub-modules and register their callbacks in our local database
	for name, options in pairs(modules) do
		local mod = assert(loadfile(options.file))()

		assert(mod.construct(unpack(options.parameters)))

		for op, callback in pairs(mod.handlers) do
			op = string.upper(op)

			if module_handlers[op] == nil then
				module_handlers[op] = {callback}
			else
				table.insert(module_handlers[op], callback)
			end
		end

		modules[name] = mod
	end

	-- For each registered callback from our sub-modules we install a small handler to check
	-- the sender's authentication prior to calling it.
	for name, call in pairs(module_handlers) do
		interface.handlers[name] = function(net, sender, ...)
			if auth_handlers[name] ~= nil then
				auth_handlers[name](net, sender, ...)
			end

			if is_authenticated(net, sender, ...)  or not sender then 
				for _, callback in pairs(module_handlers[name]) do
					callback(net, sender, ...)
				end
			end
		end
	end
	
	-- The authentication module has needs too!
	for name, call in pairs(auth_handlers) do
		if interface.handlers[name] == nil then
			interface.handlers[name] = call
		end
	end

	return true
end

function interface.destruct()
	for name, interface in pairs(modules) do
		interface.destruct()
	end
end


return interface
