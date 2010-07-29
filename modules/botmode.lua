-- -------------------------------------------------------------------------- --
-- Aurora - botmode.lua - Inform the server/opers about our nature.           --
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
		return true
	end,

	destruct = function()
	end,

	handlers = {
		connected = function(network)
			-- Simply set both known bot modes, the server may pick the one it likes.
			network.send("MODE", network.nick(), "+B")
			network.send("MODE", network.nick(), "+b")
		end
	}
}

return interface
