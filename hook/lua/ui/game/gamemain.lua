do
	local originalCreateUI = CreateUI
	function CreateUI(isReplay)
		originalCreateUI(isReplay)
		if not isReplay then
			import("/mods/QuickShare/share.lua").init()
		end
	end
end
