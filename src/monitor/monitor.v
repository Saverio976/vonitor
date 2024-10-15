module monitor

import db.sqlite

pub struct ConfigFile {
pub mut:
	file_watcher []string
}

pub struct ProcessWatcher {
pub mut:
	id int @[primary; sql: serial]
	pid int
	program string
	command string
	user string
	memory int
	cpu int
}

pub struct FileWatcher {
pub mut:
	id int @[primary; sql: serial]
	path string
	content []string
	reader_cursor int
}

// todo: get exit value
pub fn monitor(config_file string, internal_db_path string) {
	mut db := sqlite.connect(internal_db_path) or {
		return
	}
	defer {
		db.close() or {}
	}
	sql db {
		create table ProcessWatcher
		create table FileWatcher
	} or {
		// todo
	}
}
