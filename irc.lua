-- -------------------------------------------------------------------------- --
-- Aurora - irc.lua - Handles the lowermost irc network connection details.   --
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

-- Our dependencies:
--local luarocks_loader = require("luarocks.loader")
local socket          = require("socket")
local pcre            = require("rex_pcre")


-- Local Constants - these should not matter outside the module
local num_replies = {}
local err_replies = {}

-- Debugging "toolkit"
local function dump_message(data)
	if(data.sender.server) then
		print("'" .. data.command .. "' from '" .. data.sender.server .. "'")
	elseif(data.sender.nick) then
		print("'" .. data.command .. "' from '" .. data.sender.nick .. "'")
	else
		print("'" .. data.command .. "' without sender")
	end
	for bla, str in pairs(data.parameters) do
		print("  " ..  str)
	end
	print()
end

-- Class definition, I preferred the factory method because I like to keep
-- the external interface clean
function irc(name, copas, debug)
	
	-- Default: No debugging
	if(debug == nil) then debug = 0 end
	
	-- Local variables
	local nickname = nil
	local irc_socket = nil
	local exit = false

	-- 'interface' will be passed out later at the end of our function
	local interface = {}

	-- These are called first for every incoming message and should,
	-- after some preprocessing, pass them to…
	local internal_handlers = {}
	-- …the external handlers - which are responsible for every functionality
	-- not directly concerned with the protocol.
	local external_handlers = {}


	-- --------------- --
	-- Local functions --
	-- --------------- --
	
	local function call_external_handler(command, ...)
		command = string.upper(command)
		if(external_handlers[command] ~= nil) then
			for i, v in pairs(external_handlers[command]) do
				v(interface, ...)
			end
		end
	end

	local function parse_message(message)
		local result = {sender = {}}

		assert(type(message) == "string", "'parse_message' requires a string as first parameter, got '" .. type(message) .. "'")

		result.sender.nick, result.sender.ident, result.sender.host, result.sender.server, result.command, result.parameters
		= pcre.match(message, "^(?::(?:([^ ]+)!([^ ]+)@([^ ]+) |([^ ]+) )|^)([^ ]+)($|.*)$")

		
		local iterator = pcre.gmatch(result.parameters, "[^: ]{1}[^ ]*|:.*")
		result.parameters = {}
		for param in iterator do
			if(string.sub(param, 1, 1) == ":") then
				table.insert(result.parameters, string.sub(param, 2))
			else
				table.insert(result.parameters, param)
			end
		end

		return result
	end


	local function handle(message)
		local data = parse_message(message)
		if(debug) then
			dump_message(data)
		end
		if(internal_handlers[string.upper(data.command)] == nil) then
			call_external_handler(data.command, data.sender, unpack(data.parameters))
		else
			if(debug) then
				print("found handler for:")
			end
			internal_handlers[string.upper(data.command)](data.sender, unpack(data.parameters))
		end
	end

	
	-- ---------------- --
	-- Public functions --
	-- ---------------- --

	interface.run = function()
		assert(irc_socket, "[" .. name .. "] OMG TEH SOCKET IS ASPLODE!")
		exit = false
		current_socket = irc_socket
		while not exit and irc_socket do
			local line, err, partial = irc_socket:receive("*l")
			--local line, err, partial = copas.receive(irc_socket, "*l")
			if(line == nil) then
				-- Did another method reconnect while we were waiting for data?
				if irc_socket == current_socket then
					-- If not, handle.
					irc_socket = nil
					call_external_handler("disconnect", false, err)
				end
				exit = true
				return line, err, partial
			else
				handle(line)
			end
		end
	end


	interface.send = function (...)
		if not irc_socket then
			return nil, "There is no open socket to send to!"
		end
		message = ""
		for key, value in pairs(arg) do
			if(key ~= "n") then
				if(string.find(value, " ")) then
					message = message .. ":" .. value .. " "
				else
					message = message .. value .. " "
				end
			end
		end
		if(debug) then
			print(message .. "\r\n")
		end

		--local succ, err copas.send(irc_socket, message .. "\r\n")
		local succ, err = irc_socket:send(message .. "\r\n")
		if not succ then
			irc_socket = nil
			call_external_handler("disconnect", false, err)
		end

		return succ
	end


	interface.connect = function(nick, server, port, password)
		--irc_socket = assert(socket.tcp())
		local new_socket, err = socket.connect(server, port)
		if new_socket == nil then
			if(debug) then print("could not connect: " .. err) end
			return nil, err
		else
			irc_socket = new_socket
			assert(irc_socket:settimeout(1))
			irc_socket:setoption("keepalive", true)
			irc_socket = assert(copas.wrap(irc_socket))

			if(password) then assert(interface.send("PASS", password)) end

			assert(interface.send("NICK", nick))
			nickname = nick
			
			assert(interface.send("USER", "0", "0", "0", "0"))

			return true
		end
	end


	function interface.register_handler(name, handler)
		name = string.upper(name)
		if(external_handlers[name] == nil) then
			external_handlers[name] = {handler}
		elseif(type(external_handlers[name]) == "table") then
			table.insert(external_handlers[name], handler)
		end
	end


	function interface.unregister_handler(to_remove)
		for name, list in pairs(external_handlers) do
			if type(list) == "table" then
				for key, handler in pairs(external_handlers[name]) do
					if handler == to_remove then
						external_handlers[name][key] = nil
					end
				end
			end
		end
	end


	function interface.disconnect(wanted)
		irc_socket = nil
		call_external_handler("disconnect", wanted, err)
	end

	function interface.name() return name end
	function interface.nick() return nickname end
	

	-- ------------------------- --
	-- Internal message handlers --
	-- ------------------------- --

	internal_handlers.PING = function(sender, param)
		interface.send("PONG", param)
	end

	internal_handlers.NICK = function(sender, new)
		if sender.nick == nickname then
			nickname = new
		end
		call_external_handler("nick", sender, new)
	end

	internal_handlers.PRIVMSG = function(sender, channel, message)
		-- Checking whether the channel is our nick - in which case the message is private - and overwrite the channel with our sender's nickname.
		if(string.upper(channel) == string.upper(nickname)) then
			channel = sender.nick
		end

		-- Did we receive a CTCP?
		local cmd, param = pcre.match(message, "\001([^ ]+)(?: (.*))\001")
		if(cmd) then
			call_external_handler("ctcp", sender, channel, param)
		else
			call_external_handler("privmsg", sender, channel, message)
		end
	end


	internal_handlers["376"] = function(...)
		call_external_handler("connected")
		call_external_handler("376", ...)
	end
	
	-- ----- --
	-- Fini! --
	-- ----- --
	return interface
end

return irc
