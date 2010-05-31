-- -------------------------------------------------------------------------- --
-- Aurora - events.lua - implements basic event managment.                    --
-- -------------------------------------------------------------------------- --
-- Copyright (C) 2010 Simon Birnbach <aurora@simon-birnbach.de>               --
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

local pcre = require("rex_pcre")
local json = require("json")

local interface = {handlers = {}}

local events =
{
	filename = nil,
	db = nil
}


local function write_events_db()
	local file = assert(io.open(events.filename, "w+"))
	assert(file:write(json.encode(events.db)))
	file:close()
end


local function read_events_db()
	local file = assert(io.open(events.filename))
	events.db = json.decode(assert(file:read("*a")))
	file:close()
	return db
end


function interface.init(filename)
    if not type(filename) == "string" then
        return nil, "Error in events.lua: Please call with db filename."
    end
	events.filename = filename
	read_events_db()
	return true
end

function interface.handlers.privmsg(network, sender, channel, message)
    local help, command = pcre.match (message, "^!help events(?: ([^ ]+)|)")
	local new_event = pcre.match (message, "^!new_event ") 
    local event_in = pcre.match (message, "^!in ")
    local event_out = pcre.match (message, "^!out ")

    if help then
        if command == "new_event" then
            network.send("privmsg", channel, "To add a new event use: !new_event <date> <time> <name> <location> <description>")
            network.send("privmsg", channel, "Example: !new_event 11.06.2010 19:00 \"Chaostreff\" \"TU 48-462\" \"Nächster Chaostreff\" ")
        elseif command == "in" then
            network.send("privmsg", channel, "To confirm that you are attending an event use: !in <name> [<date> [<time>]] [location]")
            network.send("privmsg", channel, "Example: !in \"Chaostreff\" 11.06.2010 19:00 \"TU 48-462\" ")
        elseif command == "out" then
            network.send("privmsg", channel, "To deny that you are attending an event use: !out <name> [<date> [<time>]] [location]")
            network.send("privmsg", channel, "Example: !out \"Chaostreff\" 11.06.2010 19:00 \"TU 48-462\" ")
        else
            network.send("privmsg", channel, "Supported commands: new_event, in, out. See !help events <command> for further details.")
        end
    end
end

return interface
