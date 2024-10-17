module monitor

import db.sqlite

fn config_to_db_file_watcher(config ConfigFile, mut db sqlite.DB) []FileWatcher {
	mut all_file_watcher := sql db {
		select from FileWatcher
	} or { [] }
	mut file_watcher_active := []FileWatcher{}
	mut file_watcher_create := []FileWatcher{}
	mut file_watcher_passive := []FileWatcher{}
	for item in config.file_watcher {
		mut found := false
		for mut obj in all_file_watcher {
			if obj.uniq_id == item.uniq_id {
				obj.from_config(item)
				file_watcher_active << obj
				found = true
				break
			}
		}
		if !found {
			file_watcher_create << FileWatcher.from_config(item)
		}
	}
	for item in all_file_watcher {
		mut found := false
		for obj in file_watcher_active {
			if item.uniq_id == obj.uniq_id {
				found = true
				break
			}
		}
		if !found {
			file_watcher_passive << item
		}
	}
	for item in file_watcher_passive {
		sql db {
			update FileWatcher set active = false where uniq_id == item.uniq_id
		} or {}
	}
	for item in file_watcher_create {
		sql db {
			insert item into FileWatcher
		} or {}
	}
	for item in file_watcher_active {
		sql db {
			update FileWatcher set path = item.path where uniq_id == item.uniq_id
			update FileWatcher set interval_seconds = item.interval_seconds where uniq_id == item.uniq_id
			update FileWatcher set active = true where uniq_id == item.uniq_id
		} or {}
	}
	result := sql db {
		select from FileWatcher where active == true
	} or { [] }
	return result
}

fn config_to_db_command_watcher(config ConfigFile, mut db sqlite.DB) []CommandWatcher {
	mut all_command_watcher := sql db {
		select from CommandWatcher
	} or { [] }
	mut command_watcher_active := []CommandWatcher{}
	mut command_watcher_create := []CommandWatcher{}
	mut command_watcher_passive := []CommandWatcher{}
	for item in config.command_watcher {
		mut found := false
		for mut obj in all_command_watcher {
			if obj.uniq_id == item.uniq_id {
				obj.from_config(item)
				command_watcher_active << obj
				found = true
				break
			}
		}
		if !found {
			command_watcher_create << CommandWatcher.from_config(item)
		}
	}
	for item in all_command_watcher {
		mut found := false
		for obj in command_watcher_active {
			if item.uniq_id == obj.uniq_id {
				found = true
				break
			}
		}
		if !found {
			command_watcher_passive << item
		}
	}
	for item in command_watcher_passive {
		sql db {
			update CommandWatcher set active = false where uniq_id == item.uniq_id
		} or {}
	}
	for item in command_watcher_create {
		sql db {
			insert item into CommandWatcher
		} or {}
	}
	for item in command_watcher_active {
		sql db {
			update CommandWatcher set exe = item.exe where uniq_id == item.uniq_id
			update CommandWatcher set args = item.args where uniq_id == item.uniq_id
			update CommandWatcher set interval_seconds = item.interval_seconds where uniq_id == item.uniq_id
			update CommandWatcher set active = true where uniq_id == item.uniq_id
		} or {}
	}
	result := sql db {
		select from CommandWatcher where active == true
	} or { [] }
	return result
}

fn config_to_db(config ConfigFile, mut mon Monitor) {
	command_watcher := config_to_db_command_watcher(config, mut mon.db)
	mon.command_watcher << command_watcher
	file_watcher := config_to_db_file_watcher(config, mut mon.db)
	mon.file_watcher << file_watcher
}
