local mp = require "mp"
local msg = require "mp.msg"

table.unpack = table.unpack or unpack -- Workaround for Lua 5.1

local OUTPUT_LOCATION = mp.get_property("working-directory")
						or os.getenv("MPV_SEPARATOR_OUTPUT")

local BACKUP_LOCATION = ""
local FILES_SAVED = 0

-- Actions
local ACTION_COPY = 0
local ACTION_MOVE = 1
---------

local MARKS = {} 

local function notify(duration, ...)
	local args = {...}
	local text = ""

	for i, v in ipairs(args) do
		text = text .. tostring(v)
	end

	msg.info(text)
	mp.command(string.format("show-text \"%s\" %d 1", text, duration))
end

local function table_size(t)
	count = 0
	for _ in pairs(t) do count = count + 1 end
	return count
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

local function operate_file(op, source, destination)
	result = execute_command('%s -nv "%s" "%s"', op, source, destination)
	
	skipped, _ = result:find('^skipped')

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
	file = get_current_file_relative_path()
	msg.info(string.format("Current file is '%s'", file))
	
	output_path = create_backup_dir()

	notify(2000, "Copying current file...")
	copy_result, skipped = copy_file(file, output_path)
	msg.info(copy_result)

	if not skipped then
		increment_saved_files()
	end

	msg.info(string.format("Output location is '%s'", output_path))
	notify(2000, string.format("Success! Total: %d", FILES_SAVED))
end

local function get_current_file_id()
	pos = mp.get_property("playlist-pos")
	return mp.get_property(string.format("playlist/%d/id", pos))
end

local function mark_current_file(action)
	current_id = get_current_file_id()
	current_mark = MARKS[current_id]

	if not current_mark or current_mark.action ~= action then
		MARKS[current_id] = {
			count = 1,
			action = action,
		}
	else
		MARKS[current_id].count = MARKS[current_id].count + 1
	end

	if MARKS[current_id].count >= 2 then
		MARKS[current_id].count = 0
		return true
	end

	return false
end

local function reset_current_file_mark()
	current_id = get_current_file_id()
	current_mark = MARKS[current_id]

	if not current_mark or current_mark.count == 0 then
		notify(2000, "Current file is not marked")
	else
		MARKS[current_id].count = 0
		notify(2000, "Current file unmarked")
	end
end

local function summary()
end

-- Almost identical functions for maintainability
local function move_current_file()
	file = get_current_file_relative_path()
	msg.info(string.format("Current file is '%s'", file))
	
	output_path = create_backup_dir()

	notify(2000, "Moving current file...")
	move_result, skipped = move_file(file, output_path)
	msg.info(move_result)

	if not skipped then
		increment_saved_files()
	end

	msg.info(string.format("Output location is '%s'", output_path))
	notify(2000, string.format("Success! Total: %d", FILES_SAVED))
end

local function mark_or_operate_file(action)
end

local function op_copy_current_file()
	if mark_current_file(ACTION_COPY) then
		copy_current_file()
	else
		notify(2000, "File marked for copying")
	end
end

local function op_move_current_file()
	if mark_current_file(ACTION_MOVE) then
		move_current_file()
	else
		notify(2000, "File marked for moving")
	end
end

--local function operate_marked_files()
--	for _, v in pairs(MARKS) do
--		if v.action == ACTION_COPY then
--			copy_current_file()
--		elseif v.action == ACTION_MOVE then
--			move_current_file()
--		else
--			notify(2000, "Error: unknown action")
--		end
--	end
--end


mp.set_property("quiet", "yes") -- Silence terminal.

mp.add_key_binding('Ctrl+d', "copy_current_file", op_copy_current_file)
mp.add_key_binding('Ctrl+s', "move_current_file", op_move_current_file)
mp.add_key_binding('Ctrl+r', "reset_current_file_mark", reset_current_file_mark)
--mp.add_key_binding('Ctrl+e', "operate_marked_files", operate_marked_files)
