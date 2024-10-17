module monitor

import db.sqlite
import math
import time

struct Monitor {
pub mut:
	db                   sqlite.DB
	command_watcher      []CommandWatcher
	command_watcher_time map[string]int
	file_watcher         []FileWatcher
	file_watcher_time    map[string]int
}

fn Monitor.new(config_file string, internal_db_path string) !Monitor {
	config := parse_config(config_file) or { return error('${@LOCATION} :: ${err.msg()}') }
	mut db := sqlite.connect(internal_db_path) or { return error('${@LOCATION} :: ${err.msg()}') }
	mut mon := Monitor{
		db: db
	}
	sql mon.db {
		create table ProcessWatcher
		create table CommandWatcher
		create table FileWatcher
	} or {
		mon.db.close() or {}
		return error('${@LOCATION} :: ${err.msg()}')
	}
	config_to_db(config, mut mon)
	for item in mon.command_watcher {
		mon.command_watcher_time[item.uniq_id] = 0
	}
	for item in mon.file_watcher {
		mon.file_watcher_time[item.uniq_id] = 0
	}
	return mon
}

fn (mut mon Monitor) watch(delta int) {
	for mut item in mon.command_watcher {
		mon.command_watcher_time[item.uniq_id] -= delta
		if mon.command_watcher_time[item.uniq_id] <= 0 {
			item.watch(mut mon.db)
			mon.command_watcher_time[item.uniq_id] = item.interval_seconds
		}
	}
	for mut item in mon.file_watcher {
		mon.file_watcher_time[item.uniq_id] -= delta
		if mon.file_watcher_time[item.uniq_id] <= 0 {
			item.watch(mut mon.db)
			mon.file_watcher_time[item.uniq_id] = item.interval_seconds
		}
	}
}

fn (mut mon Monitor) wait() int {
	mut min_wait_second := math.maxof[int]()
	for _, value in mon.command_watcher_time {
		if min_wait_second > value {
			min_wait_second = value
		}
	}
	time.sleep(time.second * min_wait_second)
	return min_wait_second
}

// todo: get exit value
pub fn monitor(config_file string, internal_db_path string) {
	mut mon := Monitor.new(config_file, internal_db_path) or {
		eprintln(err.msg())
		return
	}
	defer {
		mon.db.close() or {}
	}
	for {
		delta := mon.wait()
		mon.watch(delta)
	}
}
