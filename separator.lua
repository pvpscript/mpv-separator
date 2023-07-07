local mp = require "mp"
local msg = require "mp.msg"

table.unpack = table.unpack or unpack -- Workaround for Lua 5.1

local OUTPUT_LOCATION = os.getenv("MPV_SEPARATOR_OUTPUT")
						or mp.get_property("working-directory")

local BACKUP_LOCATION = ""
local FILES_SAVED = 0

local function notify(message, duration)
	local duration = duration or 2

	msg.info(message)
	mp.osd_message(message, duration)
end

local function get_current_file_relative_path()
	return mp.get_property("path")
end

local function execute_command(cmd, ...)
	local args = {...}
	local prepared_cmd = string.format(cmd, table.unpack(args))

	return io.popen(prepared_cmd):read("*l")
end

local function create_backup_dir()
	if #BACKUP_LOCATION == 0 then
		BACKUP_LOCATION = execute_command(
			'mktemp -d -p "%s" separator.XXXXXX',
			OUTPUT_LOCATION
		)
	end

	return BACKUP_LOCATION
end

local function operate_file(op, source, destination)
	local result = execute_command('%s -nv "%s" "%s"', op, source, destination)
	
	local skipped, _ = result:find('^skipped')

	return result, skipped == 1
end

local function copy_file(source, destination)
	return operate_file("cp", source, destination)
end

local function move_file(source, destination)
	return operate_file("mv", source, destination)
end

local function increment_saved_files()
	FILES_SAVED = FILES_SAVED + 1
end

local function copy_current_file()
	local file = get_current_file_relative_path()
	msg.info(string.format("Current file is '%s'", file))
	
	local output_path = create_backup_dir()

	notify("Copying current file...")
	local copy_result, skipped = copy_file(file, output_path)
	msg.info(copy_result)

	if not skipped then
		increment_saved_files()
	end

	msg.info(string.format("Output location is '%s'", output_path))
	notify(string.format("Success! Total: %d", FILES_SAVED))
end

local function get_full_path(output_path, file)
	local filename, _ = file:gsub(".*/(.*)", "%1")
	return output_path .. "/" .. filename
end

local function update_current_file_path_on_playlist_entry(path)
	local pos = mp.get_property_number("time-pos")
	mp.commandv("loadfile", path, "replace", "start=" .. pos)
end

-- Almost identical functions for maintainability
local function move_current_file()
	local file = get_current_file_relative_path()
	msg.info(string.format("Current file is '%s'", file))
	
	local output_path = create_backup_dir()

	notify("Moving current file...")
	move_result, skipped = move_file(file, output_path)
	msg.info(move_result)

	if not skipped then
		local full_path = get_full_path(output_path, file)
		update_current_file_path_on_playlist_entry(full_path)

		increment_saved_files()
	end

	msg.info(string.format("Output location is '%s'", output_path))
	notify(string.format("Success! Total: %d", FILES_SAVED))
end

mp.set_property("keep-open", "yes") -- Prevent mpv from exiting when the video ends
mp.set_property("quiet", "yes") -- Silence terminal.

mp.add_key_binding('Ctrl+m', "move_current_file", move_current_file)
mp.add_key_binding('Ctrl+d', "copy_current_file", copy_current_file)
