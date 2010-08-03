-- -------------------------------------------------------------------------- --
-- Aurora - answer.lua - Mostly for testing the "auth" module.                --
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


local answers = {
	normal = {},
	auth = {}
}

local interface = {
	construct = function(normal, auth)
		assert(normal, "[answers] Wrong parameter type")

		answers.normal = normal

		if auth then
			answers.auth = auth
		else
			answers.auth = normal
		end

		return true
	end,

	destruct = function()
	end,

	handlers = {
		privmsg = function(network, sender, channel, message)
			for question, answer in pairs(answers.normal) do
				if pcre.match(message, question) then
					network.send("PRIVMSG", channel, answer)
				end
			end
		end,
	},

	authorized_handlers = {
		privmsg = function(network, sender, channel, message)
			for question, answer in pairs(answers.auth) do
				if pcre.match(message, question) then
					network.send("PRIVMSG", channel, answer)
				end
			end
		end
	}
}

return interface
