module monitor

import db.pg
import math
import time

struct Monitor {
pub mut:
	db                   pg.DB
	command_watcher      []CommandWatcher
	command_watcher_time map[string]int
	file_watcher         []FileWatcher
	file_watcher_time    map[string]int
	process_watcher ConfigProcessWatcher
	process_watcher_time int
}

fn Monitor.new(config_file string, postgres_uri string) !Monitor {
	config := parse_config(config_file) or { return error('parse_config :: ${err.msg()}') }
	mut db := pg.connect_with_conninfo(postgres_uri) or { return error('connect_with_conninfo :: ${err.msg()}') }
	mut mon := Monitor{
		db: db
	}
	sql mon.db {
		create table ProcessWatcher
		create table CommandWatcher
		create table FileWatcher
	} or {
		mon.db.close()
		return error('mon.db create table monitor :: ${err.msg()}')
	}
	config_to_db(config, mut mon)
	for item in mon.command_watcher {
		mon.command_watcher_time[item.uniq_id] = 0
	}
	for item in mon.file_watcher {
		mon.file_watcher_time[item.uniq_id] = 0
	}
	mon.process_watcher_time = 0
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
	ProcessWatcher.watch(mon.process_watcher.proc_path, mut mon.db)
}

fn (mut mon Monitor) wait() int {
	mut min_wait_second := math.maxof[int]()
	for _, value in mon.command_watcher_time {
		if min_wait_second > value {
			min_wait_second = value
		}
	}
	for _, value in mon.file_watcher_time {
		if min_wait_second > value {
			min_wait_second = value
		}
	}
	if min_wait_second > mon.process_watcher_time {
		min_wait_second = mon.process_watcher_time
	}
	time.sleep(time.second * min_wait_second)
	return min_wait_second
}

// todo: get exit value
pub fn monitor(config_file string, postgres_uri string) {
	mut mon := Monitor.new(config_file, postgres_uri) or {
		eprintln(err.msg())
		return
	}
	defer {
		mon.db.close()
	}
	for {
		delta := mon.wait()
		mon.watch(delta)
	}
}
