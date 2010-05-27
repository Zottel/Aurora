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
	coffee.filename = filename
	read_coffee_db()
	return true
end


function interface.handlers.privmsg(network, sender, channel, message)
	--print("++", pcre.match (message, "^([^ \\+]+)\\+\\+$"))
	local drink_orig = pcre.match (message, "^([^ \\+]+)\\+\\+$") 
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
	else
		--print("new:", pcre.match(message, "drinks\.new\\(([^\\)\\+ ]+)\\)"))
		local new_drink = pcre.match(message, "drinks\.new\\(([^\\)\\+ ]+)\\)")
		if new_drink and coffee.db[new_drink] == nil then
			coffee.db[string.lower(new_drink)] = {[string.lower(sender.nick)] = 0}
			write_coffee_db()
		elseif new_drink then
			network.send("privmsg", channel, "Error in coffee.lua: Drink exists!           Stack traceback: coffee, beer, mate, baileys…")
		end
	end
end


return interface
