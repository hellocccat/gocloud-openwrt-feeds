-- Copyright (C) 2017 yushi studio <ywb94@qq.com>
-- Licensed to the public under the GNU General Public License v3.

module("luci.controller.shadowsocksr", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/shadowsocksr") then
        return
    end
    
    if nixio.fs.access("/usr/bin/ssr-redir") then
        entry({"admin", "network", "shadowsocksr"}, alias("admin", "network", "shadowsocksr", "client"), _("SSR"), 35).dependent = true
        
        page = entry({"admin", "network", "shadowsocksr", "client"}, arcombine(cbi("shadowsocksr/client"), cbi("shadowsocksr/client-config")), _("Client"), 10)
        page.hidden = true
        page.i18n = "ssr"
        page.leaf = true
    elseif nixio.fs.access("/usr/bin/ssr-server") then
        entry({"admin", "network", "shadowsocksr"}, alias("admin", "network", "shadowsocksr", "server"), _("SSR"), 35).dependent = true
    else
        return
    end
    
    if nixio.fs.access("/usr/bin/ssr-server") then
        page = entry({"admin", "network", "shadowsocksr", "server"}, arcombine(cbi("shadowsocksr/server"), cbi("shadowsocksr/server-config")), _("Server"), 20)
        page.hidden = true
        page.i18n = "ssr"
        page.leaf = true
    end
    
    page = entry({"admin", "network", "shadowsocksr", "status"}, cbi("shadowsocksr/status"), _("Status"), 30)
    page.hidden = true
    page.i18n = "ssr"
    page.leaf = true
    
    entry({"admin", "network", "shadowsocksr", "check"}, call("check_status"), nil)
    entry({"admin", "network", "shadowsocksr", "refresh"}, call("refresh_data"), nil)
    entry({"admin", "network", "shadowsocksr", "checkport"}, call("check_port"), nil)
end

function check_status()
    local set = "/usr/bin/ssr-check www." .. luci.http.formvalue("set") .. ".com 80 3 1"
    sret = luci.sys.call(set)
    if sret == 0 then
        retstring = "0"
    else
        retstring = "1"
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json({ret = retstring})
end

function refresh_data()
    local set = luci.http.formvalue("set")
    local icount = 0
    local conf, action, retstring
    
    if set == "gfw_data" then
        conf="/etc/dnsmasq.ssr/gfw_list.conf"
        action="gfwlist"
    else
        conf="/etc/china_ssr.txt"
        action="china_ip"
    end

    oldcount = luci.sys.exec("cat " .. conf .. " | wc -l")
    sret = luci.sys.call("/etc/init.d/shadowsocksr cron " .. action .. " 2>/dev/null")
    if sret == 0 then
        icount = luci.sys.exec("cat " .. conf .. " | wc -l")
        if tonumber(icount) ~= tonumber(oldcount) then
            if set == "gfw_data" then
                retstring = tostring(math.ceil(tonumber(icount) / 2))
            else
                retstring = tostring(tonumber(icount))
            end
        else
            retstring = "0"
        end
    else
        retstring = "-1"
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json({ret = retstring, retcount = icount})
end

function check_port()
    local set = ""
    local retstring = "<br /><br />"
    local s
    local server_name = ""
    local shadowsocksr = "shadowsocksr"
    local uci = luci.model.uci.cursor()
    local iret = 1
    
    uci:foreach(shadowsocksr, "servers", function(s)
        if s.alias then
            server_name = s.alias
        elseif s.server and s.server_port then
            server_name = "%s:%s" % {s.server, s.server_port}
        end
        iret = luci.sys.call(" ipset add ss_spec_wan_ac " .. s.server .. " 2>/dev/null")
        socket = nixio.socket("inet", "stream")
        socket:setopt("socket", "rcvtimeo", 3)
        socket:setopt("socket", "sndtimeo", 3)
        ret = socket:connect(s.server, s.server_port)
        if tostring(ret) == "true" then
            socket:close()
            retstring = retstring .. "<font color='green'>[" .. server_name .. "] OK.</font><br />"
        else
            retstring = retstring .. "<font color='red'>[" .. server_name .. "] Error.</font><br />"
        end
        if iret == 0 then
            luci.sys.call(" ipset del ss_spec_wan_ac " .. s.server)
        end
    end)
    
    luci.http.prepare_content("application/json")
    luci.http.write_json({ret = retstring})
end
