local pcre = require("rex_pcre")
local interface = {}

local function unload(name)
	if modules[name] == nil then
		return nil, "module '" .. name .. "' not loaded!"
	end
	for _, handler in pairs(modules[name].handlers) do
		for _, net in pairs(networks) do
			net.unregister_handler(handler)
		end
	end
	modules[name] = nil
	return true
end

local function load(name, file, param)
	if modules[name] ~= nil then
		return nil, "'" .. name .. "' is already loaded!"
	end

	local succ, parameters = pcall(json.decode, param)
	if not succ then
		return nil, "'" .. param .. "' is no valid JSON!"
	end
	
	local res, err = loadfile(file)
	if not res then
		return nil, "Could not load file: " .. err
	end

	local succ, module = pcall(res)
	if not succ then
		return nil, "Could not load module: " .. module
	end
	
	if type(parameters) ~= "table" then
		if type(parameters) == "string" or type(parameters) == "number" or type(parameters) == "boolean" then
			parameters = {parameters}
		else
			return nil, "Could not initialize module: Wrong parameter type!"
		end
	end

	local succ, err = pcall(module.init, unpack(parameters))
	if not succ then
		return nil, "Could not initialize module: " .. err
	end
	
	for _, net in pairs(networks) do
		for op, handler in pairs(module.handlers) do
			net.register_handler(op, handler)
		end
	end
	
	modules[name] = module

	return true
end

interface.init = function()
	return true
end

interface.handlers =
{
	privmsg = function(net, sender, channel, message)
		local name = pcre.match(message, "^!unload_module ([^ ]+)$")
		if name then
			succ, err = unload(name)
			if not succ then net.send("privmsg", channel, "error: " .. err) end
		end

		local name, file, param = pcre.match(message, "^!load_module ([^ ]+) ([^\" ]+)(.*)$")
		if name then 
			succ, err = load(name, file, param)
			if not succ then net.send("privmsg", channel, "error: " .. err) end
		end
	end
}

return interface
