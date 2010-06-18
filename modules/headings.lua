local pcre = require("rex_pcre")
local http = require("socket.http")

local interface = {

  construct = function()
    return true
  end,

  destruct = function()
  end,

  handlers = {
    privmsg = function (network, sender, channel, message)
    local link = pcre.match(message,"(http://[^\\s,]+)")
    if not link then
        link = pcre.match(message,"(www\\.[^\\s,]+)")
        if link then
          link = "http://" .. link
        end
      end
    if link then
      page = http.request(link)
      if page then
        header = pcre.match(page,"<title[^>]*>([^<]+)",1,"i")
      end
      if header then
        -- get rid of spaces
        headerwords = pcre.gmatch(header,"([^\\s]+)")
        headertext = ""
        for word in headerwords do
          headertext = headertext .. " " .. word -- headertext will start with a space, comes in handy later
        end
        -- make some &...; codes from HTML work
        headertext = string.gsub(headertext, "&Auml;", "Ä")
        headertext = string.gsub(headertext, "&Ouml;", "Ö")
        headertext = string.gsub(headertext, "&Uuml;", "Ü")
        headertext = string.gsub(headertext, "&auml;", "ä")
        headertext = string.gsub(headertext, "&ouml;", "ö")
        headertext = string.gsub(headertext, "&uuml;", "ü")
        headertext = string.gsub(headertext, "&szlig;", "ß")
        headertext = string.gsub(headertext, "&nbsp;", " ")
        headertext = string.gsub(headertext, "&.-;", "_") -- replace everything we don't know by a _
        network.send("PRIVMSG", channel, "link:" .. headertext)
      end
    end
  end,
  }

}

return interface
