module("luci.controller.terminal", package.seeall)

function index()
	if not (luci.sys.call("pidof ttyd > /dev/null") == 0) then
		return
	end
	
	entry({"admin", "tools", "terminal"}, template("terminal"), _("终端"), 10).leaf = true
end
