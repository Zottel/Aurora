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


-- Local equivalent to global "modules" table.
local auth_modules = {}


-- All the handlers reachable by non-authenticated users.
local handlers = {
	privmsg = {
		function(network, sender, channel, message)
		
		end
	},

	
	disconnect = {
		function(net, wanted, err)
		
		end
	},

	
	connected = {
		function(net)
		
		end
	}
}


-- These handlers can only be reached by authenticated users.
local authenticated_handlers = {
	part = {
		function(network, sender, channel)

		end
	},


	quit = {
		function(network, sender, message)

		end
	}
}


local interface = {
	construct = function(config_users, config_modules)
		-- Fill user database with configured accounts.
		for network, network_users in pairs(config_users) do
			users[network] = {}
			for user, password in pairs(network_users) do
				users[network][user] = {password = password, state = "unidentified"}
			end
		end

		-- Load and construct configured modules.
		
		return true
	end,

	destruct = function()
		
	end,

	step = function()
		
	end,

	handlers = handlers
}

return interface
