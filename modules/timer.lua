local pcre = require("rex_pcre")
local os = require("os")

local interface = {

  construct = function()
    timers = {}
    return true
  end,

  destruct = function()
  end,

  step = function()
    for i,timer in pairs(timers) do
      if os.time() >= timer.expires then
        timer.network.send("PRIVMSG", timer.channel, timer.user .. ": " .. timer.subject)
        timers[i] = nil
      end
    end
  end,

  handlers = {
    privmsg = function (network, sender, channel, message)
      local command = pcre.match(message, "^!timer (.*)")
      if command then
        
        local time, subject = pcre.match(command, "^add ([0-9]+) (.*)")
        if time then
          local expires = os.time() + (60 * time)
          table.insert(timers, { user = sender.nick, channel = channel, network = network, expires = expires, subject = subject })
          network.send("PRIVMSG", channel, "Okay, " .. sender.nick .. ": " .. subject .. " in " .. time .. " minutes!")
        end

        if pcre.match(command, "^listall$") then
          if #timers > 0 then
            network.send("PRIVMSG", channel, "These clocks are ticking:")
            for i,timer in pairs(timers) do -- what in the fuck..?
              if timer.channel == channel then
                network.send("PRIVMSG", channel, "(" .. i .. ") " .. timer.user .. ": " .. timer.subject .. " in " .. math.floor(((timer.expires - os.time()) / 60) + 0.5) .. " min.")
              end
            end
          else
              network.send("PRIVMSG", channel, "Nope, no timers set.")
          end
        end

        if pcre.match(command, "^list$") then
          if #timers > 0 then
            network.send("PRIVMSG", channel, sender.nick .. "'s timers:")
            for i,timer in pairs(timers) do -- what in the fuck..?
              if timer.channel == channel and timer.user == sender.nick then
                network.send("PRIVMSG", channel, "(" .. i .. ") " .. timer.user .. ": " .. timer.subject .. " in " .. math.floor(((timer.expires - os.time()) / 60) + 0.5) .. " min.")
              end
            end
          else
              network.send("PRIVMSG", channel, "No timers for " .. sender.nick)
          end
        end

        local del = pcre.match(command, "^del(?:ete)? ([0-9]+)$")
        if del then
          del_index = tonumber(del)
          if timers[del_index] then
            network.send("PRIVMSG", channel, "Deleting timer \"" .. timers[del_index].subject .. "\".")
            timers[del_index] = nil
          else
            network.send("PRIVMSG", channel, "Nothing there...")
          end
        end
      end

      if pcre.match(message, "^!help timer") then
        network.send("PRIVMSG", channel, "Usage: \"!timer <command>\"")
        network.send("PRIVMSG", channel, "Commands are \"add <time> <message>\", \"list\", \"listall\", \"delete <index>\"")
      end

    end,
  }
}

return interface
