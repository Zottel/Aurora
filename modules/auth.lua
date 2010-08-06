-- -------------------------------------------------------------------------- --
-- Aurora - auth.lua - Access control for modules.                            --
-- -------------------------------------------------------------------------- --
-- Copyright (C) 2010 Julius Roob <julius@juliusroob.de>                      --
--                                                                            --
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

local pcre = require("rex_pcre")


-- User database - passwords, state and some attributes for identification
-- are stored here.
local users = {}
-- Layout:
-- users[network][nick] = {
--	state = "unidentified",
--	password = "",
--	ident = "",
--	host = "",
--	channels = {["#test"] = true}
-- }


-- Local equivalent to global "modules" table.
local auth_modules = {}


-- Here the public handlers will be stored.
-- These are all wrapper functions that call authorized or unauthorized
-- handlers, based on the user calling them.
local handlers = {}


-- Returns whether the sender is authorized to use…
local function authorized(network, sender)
	return users[network.name()]
	       and users[network.name()][sender.nick]
	       and users[network.name()][sender.nick].ident == sender.ident
	       and users[network.name()][sender.nick].host == sender.host
	       and users[network.name()][sender.nick].state == "identified"
end


-- All the handlers reachable by non-authorized users.
local unauthorized_handlers = {
	JOIN = {
		function(network, sender, channel)
			if users[network.name()]
			   and users[network.name()][sender.nick]
			   and users[network.name()][sender.nick].state == "offline" then
				users[network.name()][sender.nick].state = "unidentified"
			end
		end
	},


	PART = {
		function(network, sender, channel)
			if users[network.name()]
			   and users[network.name()][sender.nick] then
				if channel ~= sender.nick then
					-- Remove channel from list
					users[network.name()][sender.nick].channels[channel] = false
				end

				-- Check if the user is still present in any channel we're in
				if users[network.name()][sender.nick].state ~= "offline" then
					local anywhere = false

					for _, present in pairs(users[network.name()][sender.nick].channels) do
						anywhere = anywhere or present
					end

					if not anywhere then
						users[network.name()][sender.nick].state = "offline"
					end
				end
			end
		end
	},


	QUIT = {
		function(network, sender, message)
			if users[network.name()]
			   and users[network.name()][sender.nick] then
				-- Mark user as offline.
				users[network.name()][sender.nick].state = "offline"

				-- And remove all channels from the "present" list.
				for name, _ in pairs(users[network.name()][sender.nick].channels) do
					users[network.name()][sender.nick].channels[name] = false
				end
			end
		end
	},


	PRIVMSG = {
		function(network, sender, channel, message)
			if users[network.name()]
			   and users[network.name()][sender.nick] then
				if channel ~= sender.nick then
					-- Remember the user is present in the channel
					users[network.name()][sender.nick].channels[channel] = true

					-- We can mark the user as no longer offline if he's not in a query.
					users[network.name()][sender.nick].state = "unidentified"
				end

				if users[network.name()][sender.nick].state == "offline"
				   and pcre.match(message,
				                  "(!identify) " .. users[network.name()][sender.nick].password) then
					network.send("PRIVMSG", channel, "You should be at least in one channel with me.")
				elseif users[network.name()][sender.nick].state == "unidentified"
				   and pcre.match(message,
				                  "(!identify) " .. users[network.name()][sender.nick].password) then
					users[network.name()][sender.nick].state = "identified"

					users[network.name()][sender.nick].ident = sender.ident

					users[network.name()][sender.nick].host = sender.host

					network.send("PRIVMSG", channel, "Authentication successful")
				end
			end
		end
	},

	
	DISCONNECT = {
		function(network, wanted, err)
			-- Can't use any previous authentication data anymore - resetting the user data.
			for nick, data in pairs(users[network.name()]) do
				users[network.name()][nick] = {state = "offline", password = data.password, channels = {}}
			end
		end
	},

	
	CONNECTED = {
		function(net)
			-- Don't care - do I?
		end
	}
}


-- These handlers can only be reached by authenticated users.
local authorized_handlers = {
	JOIN = {
		function(network, sender, channel)
			users[network.name()][sender.nick].channels[channel] = true
		end
	},


	PART = {
		function(network, sender, channel)
			if channel ~= sender.nick then
				-- Remove channel from list
				users[network.name()][sender.nick].channels[channel] = false
			end

			-- Check if the user is still present in any channel we're in
			if users[network.name()][sender.nick].state ~= "offline" then
				local anywhere = false

				for _, present in pairs(users[network.name()][sender.nick].channels) do
					anywhere = anywhere or present
				end

				if not anywhere then
					users[network.name()][sender.nick].state = "offline"
				end
			end
		end
	},


	QUIT = {
		function(network, sender, message)
			-- User gone - reset authentication data.
			users[network.name()][sender.nick] = {state = "offline", password = data.password, channels = {}}
		end
	}
}


-- Fill user database with configured accounts.
local function setup_users(config_users)
	for network, network_users in pairs(config_users) do
		users[network] = {}

		for user, password in pairs(network_users) do
			users[network][user] = {password = password, state = "offline", channels = {}}
		end
	end
end


-- Load and construct configured modules.
local function setup_modules(config_modules)
	for name, mod_conf in pairs(config_modules) do
		auth_modules[name] = assert(loadfile(mod_conf.file))()

		assert(auth_modules[name].construct(unpack(mod_conf.parameters)))

		if auth_modules[name].authorized_handlers then
			for event, callback in pairs(auth_modules[name].authorized_handlers) do
				if authorized_handlers[string.upper(event)] then
					table.insert(authorized_handlers[string.upper(event)], callback)
				else
					authorized_handlers[string.upper(event)] = {callback}
				end
			end

			for event, callback in pairs(auth_modules[name].handlers) do
				if unauthorized_handlers[string.upper(event)] then
					table.insert(unauthorized_handlers[string.upper(event)], callback)
				else
					unauthorized_handlers[string.upper(event)] = {callback}
				end
			end
		else
			for event, callback in pairs(auth_modules[name].handlers) do
				if authorized_handlers[string.upper(event)] then
					table.insert(authorized_handlers[string.upper(event)], callback)
				else
					authorized_handlers[string.upper(event)] = {callback}
				end
			end
		end
	end
end


-- Create wrapper functions for all handlers that decide which handler and
-- if to call depending on the user.
local function setup_handlers()
	for event, _ in pairs(unauthorized_handlers) do
		if authorized_handlers[event] then
			handlers[event] = function(network, sender, ...)
				local user_handlers = nil

				if authorized(network, sender) then
					user_handlers = authorized_handlers[event]
				else
					user_handlers = unauthorized_handlers[event]
				end

				for _, callback in pairs(user_handlers) do
					callback(network, sender, ...)
				end
			end
		else
			handlers[event] = function(network, sender, ...)
				for _, callback in pairs(unauthorized_handlers[event]) do
					callback(network, sender, ...)
				end
			end
		end
	end
	
	for event, _ in pairs(authorized_handlers) do
		if not unauthorized_handlers[event] then
			handlers[event] = function(network, sender, ...)
				if authorized(network, sender) then
					for _, callback in pairs(authorized_handlers[event]) do
						callback(network, sender, ...)
					end
				end
			end
		end
	end
end


local interface = {
	construct = function(config_users, config_modules)
		setup_users(config_users)
		
		setup_modules(config_modules)

		setup_handlers()

		return true
	end,


	destruct = function()
		-- Remove authorized handlers to avoid calling destroyed modules.
		for event, _ in authorized_handlers do
			authorized_handlers[event] = {}
		end

		-- Remove…
		for event, _ in unauthorized_handlers do
			unauthorized_handlers[event] = {}
		end

		-- Destruct Modules
		for name, interface in pairs(auth_modules) do
			if interface.destruct then
				interface.destruct()
			end
		end
	end,


	step = function()
		for name, interface in pairs(auth_modules) do
			if interface.step then
				interface.step()
			end
		end
	end,


	handlers = handlers
}

return interface
