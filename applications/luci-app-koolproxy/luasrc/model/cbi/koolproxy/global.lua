local fs = require "nixio.fs"
local sys = require "luci.sys"
local http = require "luci.http"

local o,t,e
local v=luci.sys.exec("/usr/share/koolproxy/koolproxy -v")
local s=luci.sys.exec("head -3 /usr/share/koolproxy/data/rules/koolproxy.txt | grep rules | awk -F' ' '{print $3,$4}'")
local u=luci.sys.exec("head -4 /usr/share/koolproxy/data/rules/koolproxy.txt | grep video | awk -F' ' '{print $3,$4}'")
local p=luci.sys.exec("head -3 /usr/share/koolproxy/data/rules/daily.txt | grep rules | awk -F' ' '{print $3,$4}'")
local l=luci.sys.exec("grep -v !x /usr/share/koolproxy/data/rules/koolproxy.txt | wc -l")
local q=luci.sys.exec("grep -v !x /usr/share/koolproxy/data/rules/daily.txt | wc -l")
local h=luci.sys.exec("grep -v '^!' /usr/share/koolproxy/data/rules/user.txt | wc -l")
local i=luci.sys.exec("cat /usr/share/koolproxy/dnsmasq.adblock | wc -l")
local arptable=luci.sys.net.arptable() or {}
local easylist_rules_local=luci.sys.exec("cat /usr/share/koolproxy/data/rules/easylistchina.txt | sed -n '3p'|awk '{print $3,$4}'")
local easylist_nu_local=luci.sys.exec("grep -v '^!' /usr/share/koolproxy/data/rules/easylistchina.txt | wc -l")
local abx_rules_local=luci.sys.exec("cat /usr/share/koolproxy/data/rules/chengfeng.txt | sed -n '3p'|awk '{print $3,$4}'")
local abx_nu_local=luci.sys.exec("grep -v '^!' /usr/share/koolproxy/data/rules/chengfeng.txt | wc -l")
local fanboy_rules_local=luci.sys.exec("cat /usr/share/koolproxy/data/rules/fanboy.txt | sed -n '4p'|awk '{print $3,$4}'")
local fanboy_nu_local=luci.sys.exec("grep -v '^!' /usr/share/koolproxy/data/rules/fanboy.txt | wc -l")

if luci.sys.call("pidof koolproxy >/dev/null") == 0 then
	status = translate("<font color=\"green\">运行中</font>")
else
	status = translate("<font color=\"red\">未运行</font>")
end

o = Map("koolproxy", translate("KoolProxy"), translate("KoolProxy 是能识别 Adblock 规则的代理软件，可以过滤普通网页广告、视频广告、HTTPS 广告<br />Adblock Plus 的 Host 列表 + KoolProxy 黑名单模式运行更流畅上网体验，开启全局模式获取更好的过滤效果<br /><font color=\"red\">如果要为客户端过滤 HTTPS 广告，必须在客户端安装根证书。</font><a target=\"_blank\" href=\"http://koolshare.cn/thread-79889-1-1.html\">==跳转链接到 Koolshare 论坛教程贴==</a>"))
o.redirect = luci.dispatcher.build_url("admin/network/koolproxy")

t = o:section(TypedSection, "global")
t.anonymous = true
t.description = translate(string.format("程序版本: <strong>%s</strong>, 运行状态：<strong>%s</strong><br />", v, status))

t:tab("base",translate("基本设置"))

e = t:taboption("base", Flag, "enabled", translate("启用"))
e.default = 0
e.rmempty = false

e = t:taboption("base", Value, "startup_delay", translate("启动延时"))
e:value(0, translate("不延时"))
for _, v in ipairs({5, 10, 15, 25, 40}) do
	e:value(v, translate("%u 秒") %{v})
end
e.datatype = "uinteger"
e.default = 0
e.rmempty = false

e = t:taboption("base", ListValue, "koolproxy_mode", translate("过滤模式"))
e.default = 1
e.rmempty = false
e:value(1, translate("全局模式"))
e:value(2, translate("IPSET模式"))
e:value(3, translate("视频模式"))

e = t:taboption("base", MultiValue, "koolproxy_rules", translate("内置规则"))
e.optional = false
e.rmempty = false
e:value("koolproxy.txt", translate("静态规则"))
e:value("daily.txt", translate("每日规则"))
e:value("kp.dat", translate("视频规则"))
e:value("user.txt", translate("自定义规则"))

e = t:taboption("base", MultiValue, "thirdparty_rules", translate("第三方规则"))
e.optional = false
e.rmempty = false
e:value("easylistchina.txt", translate("ABP规则"))
e:value("chengfeng.txt", translate("乘风规则"))
e:value("fanboy.txt", translate("Fanboy规则"))

e = t:taboption("base", ListValue, "koolproxy_port", translate("端口控制"))
e.default = 0
e.rmempty = false
e:value(0, translate("关闭"))
e:value(1, translate("开启"))

e = t:taboption("base", Value, "koolproxy_bp_port", translate("例外端口"))
e:depends("koolproxy_port", "1")
e.rmempty = false
e.description = translate(string.format("<font color=\"red\"><strong>单端口:80&nbsp;&nbsp;多端口:80,443</strong></font>"))

e=t:taboption("base",Flag,"koolproxy_host",translate("开启 Adblock Plus Host"))
e.default=0
e:depends("koolproxy_mode","2")


e = t:taboption("base", ListValue, "koolproxy_acl_default", translate("默认访问控制"))
e.default = 1
e.rmempty = false
e:value(0, translate("不过滤"))
e:value(1, translate("仅 HTTP"))
e:value(2, translate("HTTP 和 HTTPS"))
e:value(3, translate("所有端口"))
e.description = translate(string.format("<font color=\"blue\"><strong>访问控制设置中其他主机的默认规则</strong></font>"))

e = t:taboption("base", ListValue, "time_update", translate("定时更新"))
for t = 0,23 do
	e:value(t,translate("每天 "..t.." 点"))
end
e.default = 0
e.rmempty = false
e.description = translate(string.format("<font color=\"red\"><strong>定时更新订阅规则与Adblock Plus Host</strong></font>"))

e = t:taboption("base", Button, "restart", translate("规则状态"))
e.inputtitle = translate("更新规则")
e.inputstyle = "reload"
e.write = function()
	luci.sys.call("/usr/share/koolproxy/kpupdate 2>&1 >/dev/null")
	luci.http.redirect(luci.dispatcher.build_url("admin","network","koolproxy"))
end
e.description = translate(string.format("<font color=\"red\"><strong>更新订阅规则与Adblock Plus Host</strong></font><br /><font color=\"green\">静态规则: %s / %s条 视频规则: %s<br />每日规则: %s / %s条 自定义规则: %s条<br />Host: %s条</font><br /><font color=\"blue\">ABP规则: %s / %s条 乘风规则: %s / %s条<br />Fanboy规则: %s / %s条</font>", s, l, u, p, q, h, i, easylist_rules_local, easylist_nu_local, abx_rules_local, abx_nu_local, fanboy_rules_local, fanboy_nu_local))

t:tab("cert",translate("证书管理"))

e=t:taboption("cert",DummyValue,"c1status",translate("<div align=\"left\">证书恢复</div>"))
e=t:taboption("cert",FileUpload,"")
e.template="koolproxy/caupload"
e=t:taboption("cert",DummyValue,"",nil)
e.template="koolproxy/cadvalue"
if nixio.fs.access("/usr/share/koolproxy/data/certs/ca.crt")then
	e=t:taboption("cert",DummyValue,"c2status",translate("<div align=\"left\">证书备份</div>"))
	e=t:taboption("cert",Button,"certificate")
	e.inputtitle=translate("下载备份")
	e.inputstyle="reload"
	e.write=function()
		luci.sys.call("/usr/share/koolproxy/camanagement backup 2>&1 >/dev/null")
		Download()
		luci.http.redirect(luci.dispatcher.build_url("admin","network","koolproxy"))
	end
end

t:tab("white_weblist",translate("网站白名单设置"))

local i = "/etc/adblocklist/adbypass"
e = t:taboption("white_weblist", TextValue, "adbypass_domain")
e.description = translate("加入的网址将不会被过滤，只能输入 WEB 地址，每个行一个地址，如：google.com。")
e.rows = 28
e.wrap = "off"
e.rmempty = false

function e.cfgvalue()
	return fs.readfile(i) or ""
end

function e.write(self, section, value)
	if value then
		value = value:gsub("\r\n", "\n")
	else
		value = ""
	end
	fs.writefile("/tmp/adbypass", value)
	if (luci.sys.call("cmp -s /tmp/adbypass /etc/adblocklist/adbypass") == 1) then
		fs.writefile(i, value)
	end
	fs.remove("/tmp/adbypass")
end

t:tab("weblist",translate("网站黑名单设置"))

local i = "/etc/adblocklist/adblock"
e = t:taboption("weblist", TextValue, "adblock_domain")
e.description = translate("加入的网址将被过滤，只能输入 WEB 地址，每个行一个地址，如：google.com。")
e.rows = 28
e.wrap = "off"
e.rmempty = false

function e.cfgvalue()
	return fs.readfile(i) or ""
end

function e.write(self, section, value)
	if value then
		value = value:gsub("\r\n", "\n")
	else
		value = ""
	end
	fs.writefile("/tmp/adblock", value)
	if (luci.sys.call("cmp -s /tmp/adblock /etc/adblocklist/adblock") == 1) then
		fs.writefile(i, value)
	end
	fs.remove("/tmp/adblock")
end

t:tab("white_iplist",translate("IP白名单设置"))

local i = "/etc/adblocklist/adbypassip"
e = t:taboption("white_iplist", TextValue, "adbypass_ip")
e.description = translate("将入的地址将不会被过滤，请输入 IP 地址或地址段，每个行一个记录，如：112.123.134.145/24 或 112.123.134.145。")
e.rows = 28
e.wrap = "off"
e.rmempty = false

function e.cfgvalue()
	return fs.readfile(i) or ""
end

function e.write(self, section, value)
	if value then
		value = value:gsub("\r\n", "\n")
	else
		value = ""
	end
	fs.writefile("/tmp/adbypassip", value)
	if (luci.sys.call("cmp -s /tmp/adbypassip /etc/adblocklist/adbypassip") == 1) then
		fs.writefile(i, value)
	end
	fs.remove("/tmp/adbypassip")
end

t:tab("iplist",translate("IP 黑名单设置"))

local i = "/etc/adblocklist/adblockip"
e = t:taboption("iplist", TextValue, "adblock_ip")
e.description = translate("加入的地址将使用代理，请输入 IP 地址或地址段，每个行一个记录，如：112.123.134.145/24 或 112.123.134.145。")
e.rows = 28
e.wrap = "off"
e.rmempty = false

function e.cfgvalue()
	return fs.readfile(i) or ""
end

function e.write(self, section, value)
	if value then
		value = value:gsub("\r\n", "\n")
	else
		value = ""
	end
	fs.writefile("/tmp/adblockip", value)
	if (luci.sys.call("cmp -s /tmp/adblockip /etc/adblocklist/adblockip") == 1) then
		fs.writefile(i, value)
	end
	fs.remove("/tmp/adblockip")
end

t:tab("customlist", translate("自定义规则"))

local i = "/usr/share/koolproxy/data/user.txt"
e = t:taboption("customlist", TextValue, "user_rule")
e.description = translate("输入你的自定义规则，每条规则一行。")
e.rows = 28
e.wrap = "off"
e.rmempty = false

function e.cfgvalue()
	return fs.readfile(i) or ""
end

function e.write(self, section, value)
	if value then
		value = value:gsub("\r\n", "\n")
	else
		value = ""
	end
	fs.writefile("/tmp/user.txt", value)
	if (luci.sys.call("cmp -s /tmp/user.txt /usr/share/koolproxy/data/user.txt") == 1) then
		fs.writefile(i, value)
	end
	fs.remove("/tmp/user.txt")
end

t:tab("logs",translate("更新日志"))

local i = "/var/log/koolproxy.log"
e = t:taboption("logs", TextValue, "kpupdate_log")
e.description = translate("查看最近的更新日志")
e.rows = 28
e.wrap = "off"
e.rmempty = false

function e.cfgvalue()
	return fs.readfile(i) or ""
end

function e.write(self, section, value)
end

t=o:section(TypedSection,"acl_rule",translate("访问控制"),
translate("访问控制列表是用于指定特殊 IP 过滤模式的工具，如为已安装证书的客户端开启 HTTPS 广告过滤等，MAC 或者 IP 必须填写其中一项。"))
t.template="cbi/tblsection"
t.sortable=true
t.anonymous=true
t.addremove=true
e=t:option(Value,"remarks",translate("客户端备注"))
e.width="30%"
e.rmempty=true
e=t:option(Value,"ipaddr",translate("IP 地址"))
e.width="20%"
e.datatype="ip4addr"
for _, entry in ipairs(arptable) do
	e:value(entry["IP address"], "%s (%s)" %{entry["IP address"], entry["HW address"]:lower()})
end
e=t:option(Value,"mac",translate("MAC 地址"))
e.width="20%"
e.rmempty=true
for _, entry in ipairs(arptable) do
	e:value(entry["HW address"]:lower(), "%s (%s)" %{entry["HW address"]:lower(), entry["IP address"]})
end
e=t:option(ListValue,"proxy_mode",translate("访问控制"))
e.width="20%"
e.default=1
e.rmempty=false
e:value(0,translate("不过滤"))
e:value(1,translate("仅 HTTP"))
e:value(2,translate("HTTP 和 HTTPS"))
e:value(3,translate("所有端口"))

t=o:section(TypedSection,"rss_rule",translate("规则订阅"), translate("请确保订阅规则的兼容性。"))
t.anonymous=true
t.addremove=true
t.sortable=true
t.template="cbi/tblsection"
t.extedit=luci.dispatcher.build_url("admin/network/koolproxy/rss_rule/%s")

t.create=function(...)
	local sid=TypedSection.create(...)
	if sid then
		luci.http.redirect(t.extedit % sid)
		return
	end
end

e=t:option(Flag,"load",translate("启用"))
e.default=0
e.rmempty=false

e=t:option(DummyValue,"name",translate("规则名称"))
function e.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

e=t:option(DummyValue,"url",translate("规则地址"))
function e.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

e=t:option(DummyValue,"time",translate("更新时间"))

function Download()
	local t,e
	t=nixio.open("/tmp/upload/koolproxyca.tar.gz","r")
	luci.http.header('Content-Disposition','attachment; filename="koolproxyCA.tar.gz"')
	luci.http.prepare_content("application/octet-stream")
	while true do
		e=t:read(nixio.const.buffersize)
		if(not e)or(#e==0)then
			break
		else
			luci.http.write(e)
		end
	end
	t:close()
	luci.http.close()
end
local t,e
t="/tmp/upload/"
nixio.fs.mkdir(t)
luci.http.setfilehandler(
function(o,a,i)
	if not e then
		if not o then return end
		e=nixio.open(t..o.file,"w")
		if not e then
			return
		end
	end
	if a and e then
		e:write(a)
	end
	if i and e then
		e:close()
		e=nil
		luci.sys.call("/usr/share/koolproxy/camanagement restore 2>&1 >/dev/null")
	end
end
)
return o
