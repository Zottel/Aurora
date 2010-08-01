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
			
		end
	},


	PART = {
		function(network, sender, channel)
			
		end
	},


	QUIT = {
		function(network, sender, message)
			
		end
	},


	PRIVMSG = {
		function(network, sender, channel, message)
			if users[network.name()] and users[network.name()][sender.nick] then
				users[network.name()][sender.nick].channels[channel] = true
				if users[network.name()][sender.nick].state == "unidentified"
				   and pcre.match(message,
				                  "(!identify) " .. users[network.name()][sender.nick].password) then
					users[network.name()][sender.nick].state = "identified"
				end
			end
		end
	},

	
	DISCONNECT = {
		function(net, wanted, err)
			
		end
	},

	
	CONNECTED = {
		function(net)
			
		end
	}
}


-- These handlers can only be reached by authenticated users.
local authorized_handlers = {
	JOIN = {
		function(network, sender, channel)
			
		end
	},


	PART = {
		function(network, sender, channel)
			
		end
	},


	QUIT = {
		function(network, sender, message)
			
		end
	}
}


local function setup_users(config_users)
	for network, network_users in pairs(config_users) do
		users[network] = {}
		for user, password in pairs(network_users) do
			users[network][user] = {password = password, state = "unidentified"}
		end
	end
end


local function setup_modules()
	
end


local function setup_handlers()
	
end


local interface = {
	construct = function(config_users, config_modules)
		-- Fill user database with configured accounts.
		setup_users(config_users)
		
		-- Load and construct configured modules.
		setup_modules(config_modules)

		-- Create wrapper functions for all handlers that decide which handler and
		-- if to call depending on the user.
		setup_handlers()

		return true
	end,


	destruct = function()
		for name, interface in pairs(auth_modules) do
			
		end
	end,


	step = function()
		
	end,


	handlers = handlers
}

return interface
