-- -------------------------------------------------------------------------- --
-- Aurora - morgen.lua - Greets people in the morning - or evening - whatever --
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

-- Settings
-- TODO: Decide if those should be configurable in the global config.
local settings = {
	from = "04",
	to = "12",
	min_sleep_duration = 5 * 60 * 60
}

-- Store last user action here.
local users = {}
-- Layout:
-- users[network.name()][channel][sender.nick] = os.time()


local function greetable(network, sender, channel)
	if users[network.name()] and users[network.name()][channel] and users[network.name()][channel][sender.nick] then
		if os.difftime(os.time(), users[network.name()][channel][sender.nick]) > settings.min_sleep_duration then
			local hour = os.date("%H")

			if hour >= settings.from and hour <= settings.to then
				return true
			end
		end
	end
	return false
end


local function greet(network, sender, channel)
	network.send("PRIVMSG", channel, string.format("Guten Morgen %s", sender.nick))
end


local function try_greet(network, sender, channel)
	if greetable(network, sender, channel) then	
		greet(network, sender, channel)
	end

	if users[network.name()] and users[network.name()][channel] then
		users[network.name()][channel][sender.nick] = os.time()
	end
end


local interface = {
	construct = function(config_channels)
		for net_name, channels in pairs(config_channels) do
			users[net_name] = {}
			for _, channel in pairs(channels) do
				users[net_name][channel] = {}
			end
		end
		return true
	end,

	destruct = function()
	end,

	step = function()
	end,

	handlers = {
		privmsg = try_greet,
		ctcp = try_greet,
		part = try_greet,
		join = try_greet
	}
}

return interface
