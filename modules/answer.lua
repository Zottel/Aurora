local interface = {}

local question = "ping?"
local answer = "pong!"

interface.init = function(receive, send)
	if receive then
		question = receive
	end
	if send then
		answer = send
	end
	return true
end

interface.handlers =
{
	privmsg = function(net, sender, channel, message) if message == question then net.send("privmsg", channel, answer) end end
}

return interface
