local interface = {handlers = {}}

-- We don't want to spam servers with our reconnects,
-- so we remember every reconnect and give up if there are
-- to many consecutive attempts.
local past_reconnects = {}
local to_reconnect = {}

function interface.construct()
	return true
end

function interface.step()
	for net, time in pairs(to_reconnect) do
		if net and time <= os.time() then
			options = config.networks[net.name()]
			success, err = net.connect(options.nickname, options.host, options.port)
			if success then
				copas.addthread(net.run)
				to_reconnect[net] = nil
			else
				to_reconnect[net] = os.time() + 30
			end
		end
	end
end

function interface.handlers.disconnect(net, wanted, err)
	if not wanted then
		to_reconnect[net] = os.time() + 5
	end
end


return interface
