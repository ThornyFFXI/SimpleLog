local status = {
	PlayerId = 0,
	PlayerJob = 0,
	PlayerName = '',
	SettingsFolder = nil,
	CurrentFilters = nil;
};

status.Init = function()
	if (AshitaCore:GetMemoryManager():GetParty():GetMemberIsActive(0) == 1) then
		gStatus.PlayerId = AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0);
		gStatus.PlayerName = AshitaCore:GetMemoryManager():GetParty():GetMemberName(0);
		gStatus.PlayerJob = AshitaCore:GetMemoryManager():GetPlayer():GetMainJob();
		gStatus.SettingsFolder = ('%sconfig\\addons\\simplelog\\%s_%u\\'):fmt(AshitaCore:GetInstallPath(), gStatus.PlayerName, gStatus.PlayerId);
	end
	
	gFuncs.PopulateSkills()
	gFuncs.PopulateSpells()
	gFuncs.PopulateItems()
	gStatus.AutoLoadProfile();
end

status.AutoLoadProfile = function()
	-- Disable static_config flag, it will be re-enabled if any portion of profile fails to load.
	static_config = false;
	status.LoadConfiguration();
	status.LoadFilters();
	status.LoadColors();
end

local function TryLoadFile(path)
    local success, loadError = loadfile(path);
	if not success then
		print(chat.header('SimpleLog') .. chat.error('Failed to load file: ') .. chat.color1(2, path));
		print(chat.header('SimpleLog') .. chat.error(loadError));
		return;
	end
	
    local result, output = pcall(success);
    if not result then
		print(chat.header('SimpleLog') .. chat.error('Failed to execute file: ') .. chat.color1(2, path));
		print(chat.header('SimpleLog') .. chat.error(loadError));
        return;
    end

	return output;
end

status.LoadConfiguration = function()
	if gStatus.SettingsFolder then
		-- Check if settings exist, create if not.
		local configPath = gStatus.SettingsFolder .. 'config.lua';
		if not ashita.fs.exists(configPath) then
			local sourceFile = ('%saddons\\simplelog\\configuration.lua'):fmt(AshitaCore:GetInstallPath());
			gFileTools.CopyFile(sourceFile, configPath, false);
		end

		-- Attempt to load settings.
		local config = TryLoadFile(configPath);
		if config then
			print(chat.header('SimpleLog') .. chat.message('Loaded configuration file: ') .. chat.color1(2, configPath:match("[^\\]*.$")));
			gProfileSettings = config;
			return;
		end

		print(chat.header('SimpleLog') .. chat.error("Could not load default configuration file. Saving will be disabled."));
	end
	
	-- Fall back on defaults..
	gProfileSettings = static_settings;
	static_config = true;
end

status.LoadFilters = function()
	if gStatus.SettingsFolder then

		-- Check if job specific filters exist and attempt to load if so.
		local defaultFilterPath = gStatus.SettingsFolder .. 'default_filters.lua';
		local jobFilterPath = (gStatus.SettingsFolder .. '%s.lua'):fmt(AshitaCore:GetResourceManager():GetString("jobs.names_abbr", gStatus.PlayerJob));
		if ashita.fs.exists(jobFilterPath) then
			local filters = TryLoadFile(jobFilterPath);
			if filters then
				gProfileFilter = filters;
				local shortFileName = jobFilterPath:match("[^\\]*.$")
				print(chat.header('SimpleLog') .. chat.message('Loaded job filters: ') .. chat.color1(2, shortFileName));
				gStatus.CurrentFilters = shortFileName
				return;
			end
		end

		-- Create default filters file if it doesn't exist yet.
		if not ashita.fs.exists(defaultFilterPath) then
			local sourceFile = ('%saddons\\simplelog\\filters.lua'):fmt(AshitaCore:GetInstallPath());
			gFileTools.CopyFile(sourceFile, defaultFilterPath, false);
		end

		-- Attempt to load filters.
		local filters = TryLoadFile(defaultFilterPath);
		if filters then
			gProfileFilter = filters;
			local shortFileName = defaultFilterPath:match("[^\\]*.$")
			print(chat.header('SimpleLog') .. chat.message('Loaded filters: ') .. chat.color1(2, shortFileName));
			gStatus.CurrentFilters = shortFileName
			return;
		end
		
		print(chat.header('SimpleLog') .. chat.error("Could not load default filters. Saving will be disabled."));
	end
	
	-- Fall back on defaults..
	gProfileFilter = static_filters;
	static_config = true;
	gStatus.CurrentFilters = 'default_filters.lua'
end

status.LoadColors = function()
	if gStatus.SettingsFolder then
		-- Check if colors file exists and create if not.
		local colorsPath = gStatus.SettingsFolder .. 'chat_colors.lua';
		if not ashita.fs.exists(colorsPath) then
			local sourceFile = ('%saddons\\simplelog\\colors.lua'):fmt(AshitaCore:GetInstallPath());
			gFileTools.CopyFile(sourceFile, colorsPath, false);
		end

		-- Attempt to load color file.
		local colors = TryLoadFile(colorsPath);
		if colors then
			print(chat.header('SimpleLog') .. chat.message('Loaded colors file: ') .. chat.color1(2, colorsPath:match("[^\\]*.$")));
			gProfileColor = colors;
			return;
		end

		print(chat.header('SimpleLog') .. chat.error("Could not load default colors file. Saving will be disabled."));
	end
	
	-- Fall back on defaults..
	gProfileColor = static_colors;
	static_config = true;
end

return status;