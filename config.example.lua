config = {
	modules = {
		ping = { -- Detects disconnects
			file = "modules/ping.lua",
			parameters = {60}
		},
		reconnect = { -- Self-explanatory
			file = "modules/reconnect.lua",
			parameters = {true}
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
			file = "modules/coffee/coffee.lua",
			parameters = {"data/coffee.json"}
		},
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
