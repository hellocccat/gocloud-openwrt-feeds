module("luci.controller.koolproxy",package.seeall)
function index()
	if not nixio.fs.access("/etc/config/koolproxy")then
		return
	end

	entry({"admin","network","koolproxy"},cbi("koolproxy/global"),_("KP"),35).dependent=true
	entry({"admin","network","koolproxy","rss_rule"},cbi("koolproxy/rss_rule"), nil).leaf=true
end
