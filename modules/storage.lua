local pcre = require("rex_pcre")
local json = require("json")

local interface = {handlers = {}}

local storage =
{
	filename = nil,
	db = nil
}


local function write_storage_db()
	local file = assert(io.open(storage.filename, "w+"))
	assert(file:write(json.encode(storage.db)))
	file:close()
end


local function read_storage_db()
	local file = assert(io.open(storage.filename))
	storage.db = json.decode(assert(file:read("*a")))
	file:close()
	return db
end

local function storage_help(network, sender, channel, cmd)
	if cmd == "list" then 
		network.send("PRIVMSG", channel, "Usage: !storage.list()")
		network.send("PRIVMSG", channel, "Listet alle irgendwo lagerbaren Objekte.")
	elseif cmd == "stat" then
		network.send("PRIVMSG", channel, "Usage: !storage.stat({<nick>})")
		network.send("PRIVMSG", channel, "Zeit Lagerbestände (von <nick>) an.")
	elseif cmd == "find" then
		network.send("PRIVMSG", channel, "Usage: !storage.find(<objekt>)")
		network.send("PRIVMSG", channel, "Zeit Lagerbestände für <objekt> an, bei wem auch immer.")
	elseif cmd == "new" then
		network.send("PRIVMSG", channel, "Usage: !storage.new(<name>)")
		network.send("PRIVMSG", channel, "Fügt <name> zur List der gekannten Objekte hinzu.")
	elseif cmd == "mod" then
		network.send("PRIVMSG", channel, "Usage: !storage.mod(<name>, <menge>)")
		network.send("PRIVMSG", channel, "Modifiziert deine Lagerbestände.")
	else
		network.send("PRIVMSG", channel, "Bekannte Befehle: !storage.[list, stat, find(objekt), new, mod(objekt, menge)]")
		network.send("PRIVMSG", channel, "Informationen zu den einzelnen Befehlen: !help storage <command>")
	end
end

local storage_functions = {}

function storage_functions.find(network, sender, channel, object)
	if not storage.db[object] then
		network.send("PRIVMSG", channel, "Kein " .. object .. " von dem ich wüsste ...")
		return
	end
	network.send("PRIVMSG", channel, "Lagerbestände für " .. object .. ":")
	local found = false
	for name, content in pairs(storage.db[object]) do
		network.send("PRIVMSG", channel, name .. ": " .. content)
		found = true
	end
	if not found then
		network.send("PRIVMSG", channel, "Nichts")
	end
end

function storage_functions.mod(network, sender, channel, object, amt)
	if not storage.db[object] then
		network.send("PRIVMSG", channel, "Kein " .. object .. " von dem ich wüsste ...")
		return
	end
	local user = string.lower(sender.nick)
	if not storage.db[object][user] then
		storage.db[object][user] = 0
	end
	if storage.db[object][user] + amt < 0 then
		network.send("PRIVMSG", channel, "Du kannst nicht mehr auslagern, als du hast.")
		return
	end
	storage.db[object][user] = storage.db[object][user] + amt
	network.send("PRIVMSG", channel, sender.nick .. " lagert " .. storage.db[object][user] .. " " .. object)
	write_storage_db()
end

function storage_functions.stat(network, sender, channel, user)
	if user == "" then 
		user = sender.nick
	end

	network.send("PRIVMSG", channel, user .. " lagert:")

	local found = false

	for name, inhalt in pairs(storage.db) do
		if storage.db[name][string.lower(user)] then
			network.send("PRIVMSG", channel, name .. ": " .. storage.db[name][string.lower(user)])

			found = true
		end
	end

	if not found then
		network.send("PRIVMSG", channel, "nichts")
	end
end

function storage_functions.list(network, sender, channel)
	network.send("PRIVMSG", channel, "Ich kenne folgende Objekte:")
	list = ""
	for name, inhalt in pairs(storage.db) do
		if list ~= "" then
			list = list .. ", "
		end
			list = list .. name
	end
	network.send("PRIVMSG", channel, list)
end

function storage_functions.new(network, sender, channel, object)
	if object and object ~= "" then
		if storage.db[object] == nil then
			storage.db[string.lower(object)] = {[string.lower(sender.nick)] = 0}
			write_storage_db()
		else
			network.send("privmsg", channel, "Error in storage.lua: Object exists!")
		end
	end
end


function interface.construct(filename)
    if not type(filename) == "string" then
        return nil, "Error in storage.lua: Please call with db filename."
    end
	storage.filename = filename
	read_storage_db()
	return true
end


function interface.handlers.privmsg(network, sender, channel, message)
	local help, help_cmd = pcre.match (message, "^!help (storage)( .*|)")

	local storage_cmd, storage_param1, storage_param2 = pcre.match(message, "^!storage\.(\\w+)\\((.*?)(?:,\\s*(-?\\d+).*?)?\\)")

	
	if help then
		storage_help(network, sender, channel, help_cmd)
	end

	if storage_cmd then
		if storage_functions[storage_cmd] then
			storage_functions[storage_cmd](network, sender, channel, storage_param1, storage_param2)
		else
			network.send("privmsg", channel, "Error in storage.lua: Unknown cmd '" .. storage_cmd .. "'!")
		end
	end
end


return interface
