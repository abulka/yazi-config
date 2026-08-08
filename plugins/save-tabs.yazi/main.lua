local get_data = ya.sync(function()
	local urls = {}
	for i = 1, #cx.tabs do
		urls[#urls + 1] = tostring(cx.tabs[i].current.cwd)
	end
	return urls
end)

return {
	entry = function()
		local home = os.getenv("HOME")
		if not home then
			ya.notify { title = "Failed to save tabs", content = "HOME not set", level = "warn", timeout = 5 }
			return
		end
		local file = Url(home .. "/.config/yazi/tabs.txt")
		local urls = get_data()
		local content = #urls > 0 and table.concat(urls, "\n") .. "\n" or ""
		local ok, err = fs.write(file, content)
		if ok then
			ya.notify { title = "Tabs saved", content = "Restored next time you start yazi", timeout = 5 }
		else
			ya.notify { title = "Failed to save tabs", content = tostring(err), level = "warn", timeout = 5 }
		end
	end,
}
