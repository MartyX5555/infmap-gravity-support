TESTGRAVITY = TESTGRAVITY or {}

do
	-- The name of the folder for the loader. Relative to lua folder
	local mainfolder_name = "gravitysystem"

	local function HasPrefix( File, Prefix)
		return string.lower(string.Left(File , 3)) == Prefix
	end

	-- Find recursively every file, through of subfolders.
	local function GetAllFiles(folder, foundFiles, Dircount)
		foundFiles = foundFiles or {}

		local files, directories = file.Find(folder .. "/*", "LUA")

		for _, fileName in ipairs(files) do
			table.insert(foundFiles, { File = fileName, Dir = folder .. "/" .. fileName })
		end

		for _, dirName in ipairs(directories) do
			GetAllFiles(folder .. "/" .. dirName, foundFiles, Dircount)
		end

		return foundFiles
	end

	-- Include all the found files to their respective realms
	local function IncludeAllFiles(files)

		for _, file_data in ipairs(files) do

			local fileName = file_data.File
			local dirName = file_data.Dir

			if SERVER and HasPrefix( fileName, "sv_" ) then
				include(dirName)
			elseif HasPrefix( fileName, "cl_" ) then
				if SERVER then
					AddCSLuaFile(dirName)
				else
					include(dirName)
				end
			elseif not HasPrefix( fileName, "sv_" ) then
				if SERVER then
					AddCSLuaFile(dirName)
				end

				include(dirName)
			end
		end
	end

	local function LoadAll()

		local files = GetAllFiles(mainfolder_name)
		if not next(files) then return end

		IncludeAllFiles(files)
	end
	LoadAll()

end
