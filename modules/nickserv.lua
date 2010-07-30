-- -------------------------------------------------------------------------- --
-- Aurora - nickserv.lua - One simple example for the module interface.       --
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

-- There are four possible states for one network:
-- unidentified - usually after connection - shouldn't last long.
-- to_ghost     - the nick is taken - so we'll have to ghost on connect.
-- problem      - negative response from Nickserv
--                TODO Are there any reasonable measures in this state?
-- identified   - all right

local pcre = require("rex_pcre")

local nickserv_networks = {}

local interface = {
	construct = function(config_networks)
		if log then log:debug("[nickserv] Entering constructor.") end
		if type(config_networks) == "table" then
			for name, net_config in pairs(config_networks) do
				nickserv_networks[name] = {config = net_config, state = "unidentified"}
			end
		end
		return true
	end,

	destruct = function()
	end,

	step = function()
	end,

	handlers = {
		notice = function(network, sender, recipient, message)
			if nickserv_networks[network.name()] and sender.nick and string.lower(sender.nick) == "nickserv" then
				if log then log:debug("[nickserv] Got a notice from Nickserv on " .. network.name() .. ": " .. message) end
				if  nickserv_networks[network.name()].config.remote then
					-- TODO Fix name of option and log a warning here
				end
				
				if pcre.match(message, "You are now identified for", nil, "i") then
					nickserv_networks[network.name()].state = "identified"
				end

				if pcre.match(message, "has been ghosted", nil, "i") and nickserv_networks[network.name()].state == "to_ghost" then
					nickserv_networks[network.name()].state = "unidentified"
					network.send("NICK", nickserv_networks[network.name()].config.nickname)
				end

				if pcre.match(message, "is not a registered nickname\\.$", nil, "i") or pcre.match(message, "Your nick isn't registered\\.$", nil, "i") then
					if log then log:info("[nickserv] Nickname \"" .. network.nick() .. "\" not registered on " .. network.name() .. "!") end
					network.send("PRIVMSG", "Nickserv", string.format("register %s %s", nickserv_networks[network.name()].config.password, nickserv_networks[network.name()].config.email))
				end
			end
		end,

		
		nick = function(network, sender, old, new)
			if new == network.nick() and new == nickserv_networks[network.name()].config.nickname then
				network.send("PRIVMSG", "nickserv", "identify " ..  nickserv_networks[network.name()].config.password)
			end
		end,

		
		disconnect = function(network, wanted, err)
			if nickserv_networks[network.name()] then
				nickserv_networks[network.name()].state = "unidentified"
			end
		end,


		connected = function(network)
			if log then log:debug("[nickserv] Now connected to " .. network.name()) end
			if nickserv_networks[network.name()] then
				if log then log:debug("[nickserv] I am responsible for " .. network.name()) end
				if nickserv_networks[network.name()].state == "unidentified" then
					network.send("PRIVMSG", "nickserv", "identify " ..  nickserv_networks[network.name()].config.password)
				elseif nickserv_networks[network.name()].state == "to_ghost" then
					network.send("PRIVMSG", "nickserv", string.format("ghost %s %s", nickserv_networks[network.name()].config.nickname, nickserv_networks[network.name()].config.password))
				end
			end
		end,

		["433"] = function(network, sender, channel, message)
			if nickserv_networks[network.name()] then
				if log then log:info("[nickserv] Nickname \"" .. network.nick() .. "\" already taken on " .. network.name() .. "!") end
				nickserv_networks[network.name()].state = "to_ghost"
			end
		end,

		["463"] = function(network, sender, channel, message)
			if nickserv_networks[network.name()] then
				if log then log:info("[nickserv] Nickname \"" .. network.nick() .. "\" already taken on " .. network.name() .. "!") end
				nickserv_networks[network.name()].state = "to_ghost"
			end
		end
	}
}

return interface
