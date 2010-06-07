local pcre = require("rex_pcre")
local json = require("json")

local interface = {handlers = {}}

local coffee =
{
	filename = nil,
	db = nil
}


local function write_coffee_db()
	local file = assert(io.open(coffee.filename, "w+"))
	assert(file:write(json.encode(coffee.db)))
	file:close()
end


local function read_coffee_db()
	local file = assert(io.open(coffee.filename))
	coffee.db = json.decode(assert(file:read("*a")))
	file:close()
	return db
end

local function coffee_help(network, sender, channel, cmd)
		if cmd == "list" then --help message for drinks.list
			network.send("PRIVMSG", channel, "Usage: !drinks.list()")
			network.send("PRIVMSG", channel, "Gibt eine Liste aller bekannten Getränke aus.")
		elseif cmd == "stat" then --help message for drinks.stat
			network.send("PRIVMSG", channel, "Usage: !drinks.stat([<nick>])")
			network.send("PRIVMSG", channel, "Gibt die Statistik für <nick> aus.")
		elseif cmd == "new" then --help message for drinks.new
			network.send("PRIVMSG", channel, "Usage: !drinks.new(<name>)")
			network.send("PRIVMSG", channel, "Fügt <name> zur List der gekannten Getränke hinzu.")
		else
			network.send("PRIVMSG", channel, "Bekannte Befehle: !drinks.list, !drinks.stat, !drinks.new, {drink}++, {drink}+=n")
			network.send("PRIVMSG", channel, "Informationen zu den einzelnen Befehlen: !help coffee <command>")
		end
end

local coffee_functions = {}

function coffee_functions.stat(network, sender, channel, user)
	if user == "" then --check if nick was given otherwise take sender
		user = sender.nick
	end

	network.send("PRIVMSG", channel, user .. " hat folgende Getränke konsumiert:")

	local anydrink = false --initialize variable to check if any drink was found

	for name, inhalt in pairs(coffee.db) do
		if coffee.db[name][string.lower(user)] then
			network.send("PRIVMSG", channel, name .. ": " .. coffee.db[name][string.lower(user)])

			anydrink = true
		end
	end

	if not anydrink then --if no drink was found add "Luft und Liebe"
		network.send("PRIVMSG", channel, "Luft und Liebe")
	end
end

function coffee_functions.list(network, sender, channel)
	network.send("PRIVMSG", channel, "Ich kenne folgende Getränke:")
	list = ""
	for name, inhalt in pairs(coffee.db) do --print name for each drink in coffee.db
		if list ~= "" then
			list = list .. ", "
		end
			list = list .. name
	end
	network.send("PRIVMSG", channel, list)
end

function coffee_functions.new(network, sender, channel, new_drink)
	if new_drink and new_drink ~= "" then
		if coffee.db[new_drink] == nil then
			coffee.db[string.lower(new_drink)] = {[string.lower(sender.nick)] = 0}
			write_coffee_db()
		else
			network.send("privmsg", channel, "Error in coffee.lua: Drink exists!           Stack traceback: coffee, beer, mate, baileys…")
		end
	end
end


function interface.construct(filename)
    if not type(filename) == "string" then
        return nil, "Error in coffee.lua: Please call with db filename."
    end
	coffee.filename = filename
	read_coffee_db()
	return true
end


function interface.handlers.privmsg(network, sender, channel, message)
	--print("++", pcre.match (message, "^([^ \\+]+)\\+\\+$"))

	--match incoming strings
	local help, help_cmd = pcre.match (message, "^!help (coffee)( .*|)")

	local drink_cmd, drink_param = pcre.match(message, "^!drinks\.(\\w+)\\((.*)\\)")

	local drink_orig = pcre.match (message, "([^ \\+]+)\\+\\+") 
	local incr_drink_name,incr_drink_number = pcre.match(message, "([^ \\+]+) ?\\+= ?(\\d+)")

	
	--print help
	if help then
		coffee_help(network, sender, channel, help_cmd)
	end

	--print misc coffee functions...
	if drink_cmd then
		if coffee_functions[drink_cmd] then
			coffee_functions[drink_cmd](network, sender, channel, drink_param)
		else
			network.send("privmsg", channel, "Error in coffee.lua: Unknown cmd '" .. drink_cmd .. "'!           Stack traceback: coffee, beer, mate, baileys…")
		end
	end


	--react on {drink}++
	if drink_orig then
		drink = string.lower(drink_orig)
		if coffee.db[drink] then
			if coffee.db[drink][string.lower(sender.nick)] then
				coffee.db[drink][string.lower(sender.nick)] = 1 + coffee.db[drink][string.lower(sender.nick)]
				network.send("PRIVMSG", channel, sender.nick .. " hatte schon " .. coffee.db[drink][string.lower(sender.nick)] .. " " .. drink_orig .. ".")
			else
				coffee.db[drink][string.lower(sender.nick)] = 1 
				network.send("PRIVMSG", channel, "Wie putzig, " .. sender.nick .. " fängt an mit " .. drink_orig .. ".")
			end
			write_coffee_db()
		else
			network.send("privmsg", channel, "Error in coffee.lua: Drink does not exist!!  Stack traceback: coffee, beer, mate, baileys…")
		end
	end

	--react on {drink}+=n
	if incr_drink_name then
		incr_drink_number = tonumber(incr_drink_number)
		if coffee.db[incr_drink_name] then
			if coffee.db[incr_drink_name][string.lower(sender.nick)] then
				coffee.db[incr_drink_name][string.lower(sender.nick)] = incr_drink_number + coffee.db[incr_drink_name][string.lower(sender.nick)]
				network.send("PRIVMSG", channel, sender.nick .. " hatte schon " .. coffee.db[incr_drink_name][string.lower(sender.nick)] .. " " .. incr_drink_name .. ".")
			else
				coffee.db[incr_drink_name][string.lower(sender.nick)] = incr_drink_number 
				network.send("PRIVMSG", channel, "Wie putzig, " .. sender.nick .. " fängt an mit " .. incr_drink_name .. ".")
			end
			write_coffee_db()
		else
			network.send("privmsg", channel, "Error in coffee.lua: Drink does not exist!!  Stack traceback: coffee, beer, mate, baileys…")
		end
	end
end


return interface
