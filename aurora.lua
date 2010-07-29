-- -------------------------------------------------------------------------- --
-- Aurora - aurora.lua - glues together all bot components.                   --
-- -------------------------------------------------------------------------- --
-- Copyright (C) 2010 Julius Roob                                             --
-- This program is free software; you can redistribute it and/or modify it    --
-- under the terms of the GNU General Public License as published by the      --
-- Free Software Foundation; either version 3 of the License,                 --
-- or (at your option) any later version.                                     --
--                                                                            --
-- This program is distributed in the hope that it will be useful, but        --
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License    --
-- for more details.                                                          --
--                                                                            --
-- You should have received a copy of the GNU General Public License along    --
-- with this program; if not, see <http://www.gnu.org/licenses/>.             --
-- -------------------------------------------------------------------------- --

-- We have to require copas in our main file because the network connections
-- have to share one event handling system to work properly.
local copas = require("copas")

-- Our logging facility - the early bird logs the best errors.
require("logging.console")
-- Non-local to be accessible by all components.
log = logging.console()
log:setLevel(logging.INFO)
log:info("Aurora starting.")

local irc = require("irc")


-- May be set to true by modules to terminate the reading loop and this the bot
exit = false

-- Load config file into function and execute it to get the table containing
-- our configuration data.
log:debug("Loading config.")
config, err = loadfile("config.lua")
if not config then
	log:fatal(err)
	os.exit(1)
end
config = config()
config = assert(loadfile("config.lua"))()
log:debug("Done loading config.")


-- These need to be declared as early as possible to be accessible for
-- all modules.
networks = {}
modules = {}


-- Load all modules and call their construct() functions with
-- the configured parameters.
for name, mod_conf in pairs(config.modules) do
	log:debug("Loading module " .. tostring(name))
	modules[name] = assert(loadfile(mod_conf.file))()
	if modules[name] ~= nil then
		assert(modules[name].construct(unpack(mod_conf.parameters)))
	end
end


-- Create network tables, register the module handlers, connect them and
-- create reading pseudo-threads.
for name, options in pairs(config.networks) do
	log:debug("Creating network " .. tostring(name))
	networks[name] = irc(name, copas)
	networks[name].register_handler("connected", function(net) for _, channel in pairs(options.channels) do net.send("join", channel) end end)
	for _, interface in pairs(modules) do
		for op, callback in pairs(interface.handlers) do
			networks[name].register_handler(op, callback)
		end
	end
	local sock, err = networks[name].connect(options.nickname, options.host, options.port)
	if sock then
		copas.addthread(networks[name].run)
	else
		log:error("Could not connect to '" .. tostring(name) .. "': " .. err)
	end
end


-- 
while not exit do
	copas.step(2)
	log:debug("STEP")
	for _, interface in pairs(modules) do
		if interface.step ~= nil then
			interface.step()
		end
	end
end
