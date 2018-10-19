-- Copyright (C) 2017 yushi studio <ywb94@qq.com> github.com/ywb94
-- Licensed to the public under the GNU General Public License v3.

local m, s, sec, o, kcp_enable
local shadowsocksr = "shadowsocksr"
local uci = luci.model.uci.cursor()
local ipkg = require("luci.model.ipkg")

local sys = require "luci.sys"

local function has_bin(name)
    return luci.sys.call("command -v %s >/dev/null" %{name}) == 0
end

local function has_udp_relay()
    return luci.sys.call("lsmod | grep -q TPROXY && command -v ip >/dev/null") == 0
end

local gfwmode = 0

if nixio.fs.access("/etc/dnsmasq.ssr/gfw_list.conf") then
    gfwmode = 1
end

local tabname = {translate("Client"), translate("Status")};
local tabmenu = {
    luci.dispatcher.build_nodeurl("admin", "network", "shadowsocksr"),
    luci.dispatcher.build_nodeurl("admin", "network", "shadowsocksr", "status"),
};
local isact = {true, false};
if has_bin("ssr-server") then
    table.insert(tabname, 2, translate("Server"))
    table.insert(tabmenu, 2, luci.dispatcher.build_nodeurl("admin", "network", "shadowsocksr", "server"))
    table.insert(isact, 2, false)
end
local tabcount = #tabname;

m = Map("shadowsocksr", translate(""))
m.description = translate("ShadowsocksR Client")
m.istabform = true
m.tabcount = tabcount
m.tabname = tabname;
m.tabmenu = tabmenu;
m.isact = isact;

local server_table = {}
local server_count = 0
local encrypt_methods = {
    "none",
    "table",
    "rc4",
    "rc4-md5",
    "rc4-md5-6",
    "aes-128-cfb",
    "aes-192-cfb",
    "aes-256-cfb",
    "aes-128-ctr",
    "aes-192-ctr",
    "aes-256-ctr",
    "bf-cfb",
    "camellia-128-cfb",
    "camellia-192-cfb",
    "camellia-256-cfb",
    "cast5-cfb",
    "des-cfb",
    "idea-cfb",
    "rc2-cfb",
    "seed-cfb",
    "salsa20",
    "chacha20",
    "chacha20-ietf",
}

local protocol = {
    "origin",
    "verify_simple",
    "verify_sha1",
    "auth_sha1",
    "auth_sha1_v2",
    "auth_sha1_v4",
    "auth_aes128_sha1",
    "auth_aes128_md5",
    "auth_chain_a",
    "auth_chain_b",
    "auth_chain_c",
    "auth_chain_d",
    "auth_chain_e",
    "auth_chain_f",
}

obfs = {
    "plain",
    "http_simple",
    "http_post",
    "tls_simple",
    "tls1.2_ticket_auth",
}

uci:foreach(shadowsocksr, "servers", function(s)
    if s.alias then
        server_table[s[".name"]] = s.alias
        server_count = server_count + 1
    elseif s.server and s.server_port then
        server_table[s[".name"]] = "%s:%s" % {s.server, s.server_port}
        server_count = server_count + 1
    end
end)

-- [[ Servers Setting ]]--
sec = m:section(TypedSection, "servers", translate("Servers Setting"))
sec.anonymous = true
sec.addremove = true
sec.sortable = true
sec.template = "cbi/tblsection"
sec.extedit = luci.dispatcher.build_url("admin/network/shadowsocksr/client/%s")
function sec.create(...)
    local sid = TypedSection.create(...)
    if sid then
        luci.http.redirect(sec.extedit % sid)
        return
    end
end

o = sec:option(DummyValue, "alias", translate("Alias (optional)"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or translate("None")
end

o = sec:option(DummyValue, "server", translate("Server Address"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "server_port", translate("Server Port"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "encrypt_method", translate("Encrypt Method"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "protocol", translate("Protocol"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "obfs", translate("Obfs"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or "?"
end

if has_bin("ssr-kcptun") then
    o = sec:option(DummyValue, "kcp_enable", translate("Enable KcpTun"))
    function o.cfgvalue(...)
        return Value.cfgvalue(...) == "1" and translate("Enable") or translate("Disable")
    end
end

o = sec:option(DummyValue, "switch_enable", translate("Auto Switch"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) == "1" and translate("Enable") or translate("Disable")
end

o = sec:option(DummyValue, "weight", translate("Weight"))
function o.cfgvalue(...)
    return Value.cfgvalue(...) or "10"
end

-- [[ Global Setting ]]--
s = m:section(TypedSection, "global")
s.anonymous = true

s:tab("base", translate("Global Setting"))

o = s:taboption("base", Flag, "enable", translate("Enable"))
o.rmempty = false

o = s:taboption("base", ListValue, "global_server", translate("Server"))
if has_bin("haproxy") and server_count > 1 then
    o:value("__haproxy__", translate("Load Balancing"))
end
for k, v in pairs(server_table) do o:value(k, v) end
o.default = "nil"
o.rmempty = false

if has_udp_relay() then
    o = s:taboption("base", ListValue, "udp_relay_server", translate("UDP Relay Server"))
    o:value("", translate("Disable"))
    o:value("same", translate("Same as Global Server"))
    for k, v in pairs(server_table) do o:value(k, v) end
end

o = s:taboption("base", Flag, "monitor_enable", translate("Enable Process Monitor"))
o.rmempty = false

o = s:taboption("base", Flag, "enable_switch", translate("Enable Auto Switch"))
o.rmempty = false

o = s:taboption("base", Value, "switch_time", translate("Switch check interval (second)"))
o.datatype = "uinteger"
o:depends("enable_switch", "1")
o.default = 600

o = s:taboption("base", Value, "switch_timeout", translate("Check timout (second)"))
o.datatype = "uinteger"
o:depends("enable_switch", "1")
o.default = 3

if gfwmode == 0 then
    o = s:taboption("base", Flag, "tunnel_enable", translate("Enable Tunnel (DNS)"))
    o.default = 0
    o.rmempty = false
    
    o = s:taboption("base", Value, "tunnel_port", translate("Tunnel Port"))
    o.datatype = "port"
    o.default = 5300
    o.rmempty = false
else
    o = s:taboption("base", ListValue, "gfw_enable", translate("Operating mode"))
    o:value("router", translate("IP Route Mode"))
    o:value("gfw", translate("GFW List Mode"))
    o.rmempty = false

    o = s:taboption("base", DynamicList, "gfw_list", translate("Optional GFW domains"))
    o:depends("gfw_enable", "gfw")
    o.datatype = "hostname"
    
    o = s:taboption("base", ListValue, "pdnsd_enable", translate("DNS Mode"))
    o:value("0", translate("Use DNS Tunnel"))
    if has_bin("pdnsd") then
        o:value("1", translate("Use pdnsd"))
    end
    o.rmempty = false
end

o = s:taboption("base", Value, "tunnel_forward", translate("DNS Server IP and Port"))
o.default = "8.8.4.4:53"
o.rmempty = false

if has_bin("ssr-subscribe") and has_bin("bash") then
    s:tab("subscribe", translate("Server Subscription"))

    o = s:taboption("subscribe", Flag, "subscribe_enable", translate("Auto Update"))
    o.rmempty = false
    o = s:taboption("subscribe", ListValue, "subscribe_update_time", translate("Update Time (every day)"))
    for t = 0,23 do
        o:value(t, t..":00")
    end
    o.default=2
    o.rmempty = false

    o = s:taboption("subscribe", DynamicList, "subscribe_url", translate("Subscription URL"))
    o.rmempty = true

    o = s:taboption("subscribe", Button, "update", translate("Subscription Status"))
    o.inputtitle = translate("Update Subscription")
    o.inputstyle = "reload"
    o.write = function()
        luci.sys.call("/usr/bin/ssr-subscribe >/dev/null 2>&1")
        luci.http.redirect(luci.dispatcher.build_url("admin", "network", "shadowsocksr", "client"))
    end
end

-- [[ SOCKS5 Proxy ]]--
if has_bin("ssr-local") then
    s = m:section(TypedSection, "socks5_proxy", translate("SOCKS5 Proxy"))
    s.anonymous = true

    o = s:option(ListValue, "server", translate("Server"))
    o:value("nil", translate("Disable"))
    for k, v in pairs(server_table) do o:value(k, v) end
    o.default = "nil"
    o.rmempty = false

    o = s:option(Value, "local_port", translate("Local Port"))
    o.datatype = "port"
    o.default = 1234
    o.rmempty = false
end

-- [[ Access Control ]]--
s = m:section(TypedSection, "access_control", translate("Access Control"))
s.anonymous = true

-- Part of WAN
s:tab("wan_ac", translate("Interfaces - WAN"))

o = s:taboption("wan_ac", Value, "wan_bp_list", translate("Bypassed IP List"))
o:value("/dev/null", translate("NULL - As Global Proxy"))

o.default = "/dev/null"
o.rmempty = false

o = s:taboption("wan_ac", DynamicList, "wan_bp_ips", translate("Bypassed IP"))
o.datatype = "ip4addr"

o = s:taboption("wan_ac", DynamicList, "wan_fw_ips", translate("Forwarded IP"))

-- Part of LAN
s:tab("lan_ac", translate("Interfaces - LAN"))

o = s:taboption("lan_ac", ListValue, "router_proxy", translate("Router Proxy"))
o:value("1", translatef("Normal Proxy"))
o:value("0", translatef("Bypassed Proxy"))
o:value("2", translatef("Forwarded Proxy"))
o.rmempty = false

o = s:taboption("lan_ac", ListValue, "lan_ac_mode", translate("LAN Access Control"))
o:value("0", translate("Disable"))
o:value("w", translate("Allow listed only"))
o:value("b", translate("Allow all except listed"))
o.rmempty = false

o = s:taboption("lan_ac", DynamicList, "lan_ac_ips", translate("LAN Host List"))
o.datatype = "ipaddr"

return m
