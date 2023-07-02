local mp = require "mp"
local msg = require "mp.msg"

table.unpack = table.unpack or unpack -- Workaround for Lua 5.1

local OUTPUT_LOCATION = mp.get_property("working-directory")
						or os.getenv("MPV_SEPARATOR_OUTPUT")

local BACKUP_LOCATION = ""
local FILES_SAVED = 0

local function notify(duration, ...)
	local args = {...}
	local text = ""

	for i, v in ipairs(args) do
		text = text .. tostring(v)
	end

	msg.info(text)
	mp.command(string.format("show-text \"%s\" %d 1", text, duration))
end

local function get_current_file_relative_path()
	return mp.get_property("path")
end

local function execute_command(cmd, ...)
	args = {...}
	prepared_cmd = string.format(cmd, table.unpack(args))

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

local function copy_file(source, destination)
	result = execute_command('cp -nv "%s" "%s"', source, destination)
	
	skipped, _ = result:find('^skipped')

	return result, skipped == 1
end

local function increment_saved_files()
	FILES_SAVED = FILES_SAVED + 1
end

local function backup_current_file()
	file = get_current_file_relative_path()
	msg.info(string.format("Current file is '%s'", file))
	
	output_path = create_backup_dir()

	notify(2000, "Backing up current file...")
	copy_result, skipped = copy_file(file, output_path)
	msg.info(copy_result)

	if not skipped then
		increment_saved_files()
	end

	msg.info(string.format("Output location is '%s'", output_path))
	notify(2000, string.format("Success! Total: %d", FILES_SAVED))
end

mp.set_property("quiet", "yes") -- Silence terminal.

mp.add_key_binding('Ctrl+s', "backup_current_file", backup_current_file)
