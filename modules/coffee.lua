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


function interface.init(filename)
    if not type(filename) == "string" then
        return nil, "Error in coffee.lua: Please call with db filename."
    end
	coffee.filename = filename
	read_coffee_db()
	return true
end


function interface.handlers.privmsg(network, sender, channel, message)
	--print("++", pcre.match (message, "^([^ \\+]+)\\+\\+$"))
	local help = pcre.match (message, "^!help coffee ?(.*)")
	local drink_orig = pcre.match (message, "([^ \\+]+)\\+\\+") 
	local new_drink = pcre.match(message, "^!drinks\.new\\(([^\\)\\+ ]+)\\)")
	local incr_drink_name,incr_drink_number = pcre.match(message, "([^ \\+]+)\\+=(\\d+)")
	local drink_list = pcre.match(message, "^!(drinks\.list\\(\\))")
	local drink_stat = pcre.match(message, "^!drinks\.stat\\((.*)\\)")
	if help then
		if help == "" then
			network.send("PRIVMSG", channel, "Bekannte Befehle: !drinks.list, !drinks.stat, !drinks.new, {drink}++, {drink}+=n")
			network.send("PRIVMSG", channel, "Informationen zu den einzelnen Befehlen: !help coffee <command>")
		elseif pcre.match(help, "drinks\.list") then
			network.send("PRIVMSG", channel, "Usage: !drinks.list()")
			network.send("PRIVMSG", channel, "Gibt eine Liste aller bekannten Getränke aus.")
		elseif pcre.match(help, "drinks\.stat") then
			network.send("PRIVMSG", channel, "Usage: !drinks.stat([<nick>])")
			network.send("PRIVMSG", channel, "Gibt die Statistik für <nick> aus.")
		elseif pcre.match(help, "drinks\.new") then
			network.send("PRIVMSG", channel, "Usage: !drinks.new(<name>)")
			network.send("PRIVMSG", channel, "Fügt <name> zur List der gekannten Getränke hinzu.")
		end
	end
	if drink_list then
		network.send("PRIVMSG", channel, "Ich kenne folgende Getränke:")
		for name, inhalt in pairs(coffee.db) do
			network.send("PRIVMSG", channel, name)
		end
	end
	if drink_stat then
		if drink_stat == "" then
			user = sender.nick
		else
			user = drink_stat
		end
		network.send("PRIVMSG", channel, user .. " hat folgende Getränke konsumiert:")
		local anydrink = false
		for name, inhalt in pairs(coffee.db) do
			if coffee.db[name][string.lower(user)] then
				network.send("PRIVMSG", channel, name .. ": " .. coffee.db[name][string.lower(user)])
				anydrink = true
			end
		end
		if not anydrink then
			network.send("PRIVMSG", channel, "Luft und Liebe")
		end
	end
	if new_drink then
		--print("new:", pcre.match(message, "drinks\.new\\(([^\\)\\+ ]+)\\)"))
		if coffee.db[new_drink] == nil then
			coffee.db[string.lower(new_drink)] = {[string.lower(sender.nick)] = 0}
			write_coffee_db()
		else
			network.send("privmsg", channel, "Error in coffee.lua: Drink exists!           Stack traceback: coffee, beer, mate, baileys…")
		end
	end
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
