-- Copyright (C) 2017 yushi studio <ywb94@qq.com>
-- Licensed to the public under the GNU General Public License v3.

local function has_bin(name)
    return luci.sys.call("command -v %s >/dev/null" %{name}) == 0
end

local function has_udp_relay()
    return luci.sys.call("lsmod | grep -q TPROXY && command -v ip >/dev/null") == 0
end

local function is_running(name)
    return luci.sys.call("pidof %s >/dev/null" %{name}) == 0
end

local function hunman_status(name)
    if is_running(name) then
        return font_blue .. bold_on .. translate("Running") .. bold_off .. font_off
    else
        return translate("Not Running")
    end
end

local function last_mod_time(conf)
    if not nixio.fs.access(conf) then
        return ""
    end
    local mod_time = luci.sys.exec("date -r " .. conf .. " '+%Y-%m-%d %H:%M:%S' | tr -d '\n'")
    return [[<font color="gray">]] .. "（" .. translate("Updated at") .. " " .. mod_time .. "）" .. [[</font>]]
end

local uci = require "luci.model.uci".cursor()
local m, s, o
local reudp_run = 0
local gfw_count = 0
local ip_count = 0
local gfwmode = 0

local gfwlist_conf="/etc/dnsmasq.ssr/gfw_list.conf"
local china_ip_conf="/etc/china_ssr.txt"

if nixio.fs.access(gfwlist_conf) then
    gfwmode = 1
end

local shadowsocksr = "shadowsocksr"
-- html constants
font_blue = [[<font color="blue">]]
font_off = [[</font>]]
bold_on = [[<strong>]]
bold_off = [[</strong>]]

local fs = require "nixio.fs"
local sys = require "luci.sys"

if gfwmode == 1 then
    gfw_count = tonumber(sys.exec("cat " .. gfwlist_conf .. " | wc -l")) / 2
end

if nixio.fs.access(china_ip_conf) then
    ip_count = sys.exec("cat " .. china_ip_conf .. " | wc -l")
end

if has_udp_relay() then
    local icount = sys.exec("ps -w | grep ssr-reudp | grep -v grep| wc -l")
    if tonumber(icount) > 0 then
        reudp_run = 1
    else
        icount = sys.exec("ps -w | grep ssr-retcp | grep \"\\-u\"| grep -v grep | wc -l")
        if tonumber(icount) > 0 then
            reudp_run = 1
        end
    end
end

local tabname = {translate("Client"), translate("Status")};
local tabmenu = {
    luci.dispatcher.build_nodeurl("admin", "network", "shadowsocksr"),
    luci.dispatcher.build_nodeurl("admin", "network", "shadowsocksr", "status"),
};
local isact = {false, true};
if has_bin("ssr-server") then
    table.insert(tabname, 2, translate("Server"))
    table.insert(tabmenu, 2, luci.dispatcher.build_nodeurl("admin", "network", "shadowsocksr", "server"))
    table.insert(isact, 2, false)
end
local tabcount = #tabname;

m = SimpleForm("Version", translate("Running Status"))
m.istabform = true
m.tabcount = tabcount
m.tabname = tabname;
m.tabmenu = tabmenu;
m.isact = isact;
m.reset = false
m.submit = false

s = m:field(DummyValue, "redir_run", translate("Global Client"))
s.rawhtml = true
s.value = hunman_status("ssr-redir")

if has_bin("ssr-server") then
    s = m:field(DummyValue, "server_run", translate("Global Server"))
    s.rawhtml = true
    s.value = hunman_status("ssr-server")
end

if has_udp_relay() then
    s = m:field(DummyValue, "reudp_run", translate("UDP Relay"))
    s.rawhtml = true
    if reudp_run == 1 then
        s.value = font_blue .. bold_on .. translate("Running") .. bold_off .. font_off
    else
        s.value = translate("Not Running")
    end
end

if has_bin("ssr-local") then
    s = m:field(DummyValue, "sock5_run", translate("SOCKS5 Proxy"))
    s.rawhtml = true
    s.value = hunman_status("ssr-local")
end

s = m:field(DummyValue, "tunnel_run", translate("DNS Tunnel"))
s.rawhtml = true
s.value = hunman_status("ssr-tunnel")

if has_bin("pdnsd") then
    s = m:field(DummyValue, "pdnsd_run", translate("pdnsd Server"))
    s.rawhtml = true
    s.value = hunman_status("pdnsd")
end

if has_bin("haproxy") then
    s = m:field(DummyValue, "haproxy_run", translate("haproxy Server"))
    s.rawhtml = true
    if is_running("haproxy") then
        local stats_url = "http://" .. uci:get("network", "lan", "ipaddr") .. ":1111/stats"
        local haproxy_stats = bold_on .. [[<a target="_blank" href="]] .. stats_url .. [[">]] .. translate("Status") .. [[</a>]] .. bold_off
        s.value = font_blue .. bold_on .. translate("Running") .. bold_off .. font_off .. " (" .. haproxy_stats .. ")"
    else
        s.value = translate("Not Running")
    end
end

if has_bin("ssr-kcptun") then
    s = m:field(DummyValue, "kcptun_run", translate("KcpTun Client"))
    s.rawhtml = true
    s.value = hunman_status("ssr-kcptun")
end

s = m:field(DummyValue, "google", translate("Google Connectivity"))
s.value = translate("No Check")
s.template = "shadowsocksr/check"

s = m:field(DummyValue, "baidu", translate("Baidu Connectivity"))
s.value = translate("No Check")
s.template = "shadowsocksr/check"

if gfwmode == 1 then
    s = m:field(DummyValue, "gfw_data", translate("GFW List Data"))
    s.rawhtml = true
    s.template = "shadowsocksr/refresh"
    s.value = font_blue .. tostring(math.ceil(gfw_count)) .. font_off .. " " .. translate("Records") .. last_mod_time(gfwlist_conf)
end

s = m:field(DummyValue, "ip_data", translate("China IP Data"))
s.rawhtml = true
s.template = "shadowsocksr/refresh"
s.value = font_blue .. ip_count .. font_off .. " " .. translate("Records") .. last_mod_time(china_ip_conf)

s = m:field(DummyValue, "check_port", translate("Check Server Port"))
s.template = "shadowsocksr/checkport"
s.value = translate("No Check")

return m
