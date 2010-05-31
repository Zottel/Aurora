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
	local drink_orig = pcre.match (message, "([^ \\+]+)\\+\\+") 
	local new_drink = pcre.match(message, "drinks\.new\\(([^\\)\\+ ]+)\\)")
	local incr_drink = pcre.match(message, "([^ \\+]+\\+=\\d*)")
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
	elseif new_drink then
		--print("new:", pcre.match(message, "drinks\.new\\(([^\\)\\+ ]+)\\)"))
		if coffee.db[new_drink] == nil then
			coffee.db[string.lower(new_drink)] = {[string.lower(sender.nick)] = 0}
			write_coffee_db()
		else
			network.send("privmsg", channel, "Error in coffee.lua: Drink exists!           Stack traceback: coffee, beer, mate, baileys…")
		end
	elseif incr_drink then
		local incr_drink_name = pcre.match(incr_drink, "^([^ \\+]+)\\+=.*")
		local incr_drink_number = tonumber(pcre.match(incr_drink, "^[^\\d]*([\\d]*)$"))
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
