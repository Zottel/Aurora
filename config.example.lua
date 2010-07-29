-- -------------------------------------------------------------------------- --
-- Aurora - config.lua - Here is where you bot's settings are stored.         --
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

config = {
	modules = {
		botmode = { -- Considered good manners on most networks
			file = "modules/botmode.lua",
			parameters = {}
		},
		ping = { -- Detects disconnects
			file = "modules/ping.lua",
			parameters = {60}
		},
		reconnect = { -- Self-explanatory
			file = "modules/reconnect.lua",
			parameters = {}
		},
		altnick = { -- Allows for alternate nicknames when the original one is taken.
			file = "modules/altnick.lua",
			parameters = {"Aurora_"}
		},
		nickserv = { -- This one is awesome - or at least what it does is…
			file = "modules/nickserv.lua",
			parameters = {{
				xinutec = {
					nickname = "Aurora",
					password = "nope",
					email = "aurora@gempai.de",
					ghost = true,
					remote = "NickServ@services.xinutec.org",
				},
				freenode = {
					nickname = "Aurora",
					password = "nope",
					email = "aurora@gempai.de",
					ghost = true,
					remote = "NickServ@services.freenode.org",
				}
			}}
		},
		auth = { -- Aurora uses nested modules for features like authenticated modules
			file = "modules/auth.lua",
			parameters =
			-- Auth modules
			{{
				modules = { -- Loading and unloading "public" modules
				file = "modules/modules.lua",
				parameters = {}
				},
				answer = { -- To see if the authentication was successful
				file = "modules/answer.lua",
				parameters = {"Aurora?", "Yeah Boss?"}
				}
			},
			-- Auth users
			{
				admin = "password",
				anotheradmin = "anotherpassword!"
			}}
		},
		coffee = { -- Some simple Testcase…
			file = "modules/coffee.lua",
			parameters = {"data/coffee.example.json"}
		},
		storage = {
			file = "modules/storage.lua",
			parameters = {"data/storage.example.json"}
		},
    headings = {
      file = "modules/headings.lua",
      parameters = {}
    },
    timer = {
      file = "modules/timer.lua",
      parameters = {}
    },
    twitter = {
      file ="modules/twitter.lua",
      -- the second parameter is the interval between twitter checks in minutes.
      -- keep in mind that twitter allows only 150 requests per hour, and one request is made per user per interval
      parameters = {"data/twitter.example.json", 5}
    }
	},
	
	-- These should be self-explanatory for everybody who even remotely knows the IRC.
	networks = {
		xinutec = {
			nickname = "Aurora", realname = "Aurora", ident = "aurora",

			host = "irc.xinutec.org", port = 6667,
			
			channels = {"#gempai", "#test"}
		}
	}
}

return config
