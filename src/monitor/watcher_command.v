module monitor

import db.sqlite
import os
import time

struct ConfigCommandWatcher {
	uniq_id          string
	exe              string
	args             string
	interval_seconds int
}

pub struct CommandWatcher {
pub mut:
	id               int @[primary; sql: serial]
	content          string
	active           bool
	uniq_id          string @[required]
	exe              string @[required]
	args             string @[required]
	interval_seconds int    @[required]
}

fn CommandWatcher.from_config(conf ConfigCommandWatcher) CommandWatcher {
	return CommandWatcher{
		active:           true
		uniq_id:          conf.uniq_id
		exe:              conf.exe
		args:             conf.args
		interval_seconds: conf.interval_seconds
	}
}

fn (mut item CommandWatcher) from_config(conf ConfigCommandWatcher) {
	item.uniq_id = conf.uniq_id
	item.exe = conf.exe
	item.args = conf.args
	item.interval_seconds = conf.interval_seconds
}

fn (mut item CommandWatcher) watch(mut db sqlite.DB) {
	command := '${item.exe} ${item.args}'
	res := os.execute(command)
	item.content += '\n\n${time.now()}${command}\n'
	item.content += res.output
	sql db {
		update CommandWatcher set content = item.content where uniq_id == item.uniq_id
	} or {
		eprintln(err.msg())
		return
	}
}
