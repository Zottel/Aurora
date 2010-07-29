-- -------------------------------------------------------------------------- --
-- Aurora - dummy.lua - One simple example for the module interface.          --
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

local interface = {
	construct = function(...)
		-- The constructor is called after module instantiation and is supposed
		-- to initialize all local data - possibly depending on the given
		-- module parameters.
		
		-- When present - the constructor should return true upon successful module
		-- loading - the loader will assume a module is unusable if the constructor
		-- returns false and drop it.
		return true
	end,

	destruct = function()
		-- The destructor is called prior to module unloading and should - if
		-- necessary - save all data back to disk/db/etc and close any open files
		-- or sockets.
	end,

	step = function()
		-- step() is called in configuration-dependent intervals to allow basic
		-- timeout handling.
	end,

	handlers = {
		-- Functions to handle irc messages - since the underlying network library
		-- is fairly minimal these can be taken directly from the IRC RFC.
		
		-- One typical IRC message handler:
		privmsg = function(network, sender, channel, message)
			-- Do something with message…
		end,

		
		-- There are two special non-standard handlers:
		disconnect = function(net, wanted, err)
			-- Is called when the network connection is closed.
			-- The parameter "wanted" indicates - if set to true that the network
			-- connection was closed by a module or the user and - probably - won't
			-- come back on-line.
		end,
		-- and
		connected = function(net)
			-- Fairly self-explanatory.
			-- Is - currently - called once the irc network sends an
			-- "End of MOTD" message - after which the connection can be regarded as
			-- established and the server should recognize every message sent to him.
		end
	}
}

return interface
