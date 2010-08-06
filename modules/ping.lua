local interface = {}

local timeout = 10
local last_ping = {}

interface.construct = function(new_timeout)
	if new_timeout then
		timeout = new_timeout
	end
--	for name, net in pairs(networks) do
--		last_ping[net] = os.time()
--	end
	return true
end

interface.step = function()
	for net, time in pairs(last_ping) do
		if (time + (2 * timeout)) < os.time() then
			net.disconnect()
		elseif (time + timeout) < os.time() then
			net.send("ping", os.time())
		end
	end
end

interface.handlers =
{
	ping = function(net)
		last_ping[net] = os.time() + timeout
	end,
	privmsg = function(net)
		last_ping[net] = os.time() + timeout
	end,
	pong = function(net)
		last_ping[net] = os.time() + timeout
	end,
	connected = function(net)
		last_ping[net] = os.time() + (timeout * 2)
	end,
	disconnect = function(net, wanted, err)
		last_ping[net] = nil
	end,
}

return interface
