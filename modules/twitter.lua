local pcre = require("rex_pcre")
local http = require("socket.http")
local os = require("os")
local json = require("json")

--[[ TODO The data structure could be redone to something like { username, lasttweet, {network, channel} }
          This would also make getting the tweets a bit easier... ]]

function writedb(filename, userlist)
  local file = assert(io.open(filename, "w+"))
  assert(file:write(json.encode(userlist)))
  file:close()
end


local interface = {

  construct = function(filename, interval)
    db_file = filename
    update_timeout = 60 * interval

    users = {}
    last_checked = os.time()

    -- read database
	  local file = assert(io.open(filename))
	  users = json.decode(assert(file:read("*a")))
	  file:close()

    -- store ID for each user's last tweet
    for _,user in pairs(users) do
      user.last = pcre.match(http.request("http://api.twitter.com/1/statuses/user_timeline/" .. user.username .. ".xml?count=1"), "<id>([0-9]+)</id>") -- yah man, it's a one liner
    end

    return true
  end,

  destruct = function()
  end,

  step = function()
    -- only check once every n minutes
    -- when configuring this, keep in mind that twitter only allows 150 requests per hour
    if last_checked + update_timeout < os.time() then

      -- we only wanna check each user once, even if they're in multiple channels / networks
      local users_to_check = {}
      for _,user in pairs(users) do
        users_to_check[user.username] = user.last -- if we have multiple entries with the same username, it just overwrites this a few times, but each user only has one entry here
      end

      local usertweets = {}
      for username,last_id in pairs(users_to_check) do
        local last_query = ""
        if last_id == "0" then
          last_query = "?count=1" -- if last_id is 0, then just get the last tweet. Something went wrong earlier.
        else
          last_query = "?since_id=" .. last_id
        end
        local page = http.request("http://api.twitter.com/1/statuses/user_timeline/" .. username .. ".xml" .. last_query)
        if page then 
          usertweets[username] = pcre.gmatch(page, "<text>([^<]+)</text>")
        end

        -- update user.last; assuming the latest tweet is going to be on top
        local last = pcre.match(page, "<id>([0-9]+)</id>")
        if last then -- last is only set if a tweet was actually fetched...
          for _,user in pairs(users) do
            if user.username == username then
              user.last = last
            end
          end
        end
      end

      -- now put those tweets out into the IRC
      for _,user in pairs(users) do
        if usertweets[user.username] then
          for tweet in usertweets[user.username] do
            networks[user.network].send("PRIVMSG", user.channel, "twEET! " .. user.username .. ": " .. tweet)
          -- TODO Handle &...;-codes. Twitter even uses those for German Ümlauts.
          end
        end
      end

      last_checked = os.time()
    end
  end,

  handlers = {
    privmsg = function (network, sender, channel, message)
      local follow = pcre.match(message, "^!twitter follow ([^\\s]+)$")
      if follow then
        local user = {username = follow, last = "0", channel = channel, network = network.name()}

        -- get the user's latest tweet, and save the ID so that only new tweets are displayed.
        user.last = pcre.match(http.request("http://api.twitter.com/1/statuses/user_timeline/" .. user.username .. ".xml?count=1"), "<id>([0-9]+)</id>")

        if not user.last then
          user.last = "0"
        end

        already_in_table = false
        for _,table_user in pairs(users) do
          if table_user.username == user.username and table_user.channel == user.channel and table_user.network == user.network then
            already_in_table = true
          end
        end

        if not already_in_table then
          table.insert(users, user)
          network.send("PRIVMSG", channel, "Okay, now following " .. user.username)

          -- write out data file
          writedb(db_file, users)
        else
          network.send("PRIVMSG", channel, "Already following " .. user.username)
        end
      end

      local unfollow = pcre.match(message, "^!twitter unfollow ([^\\s]+)$")
      if unfollow then
        for i,user in pairs(users) do
          if user.username == unfollow then
            users[i] = nil
            writedb(db_file, users)

            network.send("PRIVMSG", channel, "Okay, no longer following " .. unfollow)
          end

        end
      end

      if pcre.match(message, "^!twitter list$") then
        following = ""
        for _,user in pairs(users) do
          if user.network == network.name() and user.channel == channel then
            following = following .. " " .. user.username
          end
        end
        network.send("PRIVMSG", channel, "Following:" .. following)
      end

      if pcre.match(message, "!help twitter") then
        network.send("PRIVMSG", channel, "Usage: \"!twitter command\"")
        network.send("PRIVMSG", channel, "Commands are \"follow <username>\", \"unfollow <username>\", \"list\".")

      end
    end,
  }

}

return interface
