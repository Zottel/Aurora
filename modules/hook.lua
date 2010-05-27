local pcre = require("rex_pcre")

local interface = {}

interface.init = function(msg)
	return true
end

interface.handlers =
{
	privmsg = function(net, sender, channel, message)
		cmd, source = pcre.match(message, "^!hook ([^ ]+) (.+)$")
		if cmd then
			hook, err = loadstring(source)
			if hook then
				setfenv(hook, {pcre = pcre})
				net.register_handler(cmd, hook())
			else
				net.send("privmsg", channel, "hook error: " .. err)
			end
		end
	end
}

return interface
