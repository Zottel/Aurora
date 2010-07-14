local pcre = require("rex_pcre")

--[[ TODO
Must have:
  - handle multiple votes at the same time
  - handle votes on different channels
Should have:
  - votes with more options than just yes / no
  - Persistency over disconnects / shutdowns
  - Set a time for a vote to end automatically
Nice to have:
  - Option for votes across multiple channels - announce them, count, whatever
  - Interface to some module for setting the channel topic, if this should ever exist
]]

local vote = nil

local function votemsg(name, v)
  if vote.votes[name] then
    return name .. " changed their vote to " .. v
  else
    return name .. " voted " .. v
  end
end

local interface = {
	construct = function(...)
		return true
	end,

	destruct = function()
	end,

	step = function()
	end,

	handlers = {
		privmsg = function(network, sender, channel, message)
      local callvote = pcre.match(message, "^!callvote (.+)$")
      if callvote then
        if vote then
          network.send("PRIVMSG", channel, "There is a vote in progress. You can't call a new one till the current one is ended.")
        else
          vote = { subject = callvote , votes = {} } -- at the moment, let's just support one vote at a time
          network.send("PRIVMSG", channel, "Vote called: " .. vote.subject .. " -- vote with !yes, !no or !abs")
        end
      end

      local v = pcre.match(message, "^!(yes|no)") -- no $ here, so you can write something like "!yes, I like it"
      if v then
        if vote then
          network.send("PRIVMSG", channel, votemsg(sender.nick, v))
          vote.votes[sender.nick] = v
        end
      end

      if pcre.match(message, "^!abs") then
        if vote then
          vote.votes[sender.nick] = "abs"
          network.send("PRIVMSG", channel, sender.nick .. " abstains from vote.")
        end
      end

      if pcre.match(message, "^!votestat$") then
        if vote then
          count = { yes = 0, no = 0, abs = 0 } -- TODO Put the counting part into a function to avoid duplicated code
          for _,v in pairs(vote.votes) do
            if v == "yes" then
              count.yes = count.yes + 1
            end
            if v == "no" then
              count.no = count.no + 1
            end
            if v == "abs" then
              count.abs = count.abs + 1
            end
          end
          network.send("PRIVMSG", channel, "Current vote: " .. vote.subject .. " -- Yes: " .. count.yes .. " - No: " .. count.no .. " - Abs: " .. count.abs)
        else
          network.send("PRIVMSG", channel, "Currently no vote.")
        end
      end


      if pcre.match(message, "^!endvote$") then
        if vote then
          count = { yes = 0, no = 0, abs = 0 }
          for _,v in pairs(vote.votes) do
            if v == "yes" then
              count.yes = count.yes + 1
            end
            if v == "no" then
              count.no = count.no + 1
            end
            if v == "abs" then
              count.abs = count.abs + 1
            end
          end
          network.send("PRIVMSG", channel, "Vote ended! " .. vote.subject .. " -- Yes: " .. count.yes .. " - No: " .. count.no .. " - Abs: " .. count.abs)
          vote = nil
        else
          network.send("PRIVMSG", channel, "Currently no vote.")
        end
      end

      if pcre.match(message, "^!help vote") then
        network.send("PRIVMSG", channel, "Vote module - usage: \"!callvote <subject>\" to call a new vote")
        network.send("PRIVMSG", channel, "\"!votestat\" to display an intermediate result of the current vote")
        network.send("PRIVMSG", channel, "\"!endvote\" to end the vote and display the result")
        network.send("PRIVMSG", channel, "When a vote is open, use \"!yes\" or \"!no\" to vote, \"!abs\" to abstain from the vote.")
      end
		end
	}
}

return interface
