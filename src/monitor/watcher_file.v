module monitor

import db.sqlite
import os

struct ConfigFileWatcher {
	uniq_id          string
	path             string
	interval_seconds int
}

pub struct FileWatcher {
pub mut:
	id               int @[primary; sql: serial]
	active           bool
	size             u64
	content          string
	uniq_id          string @[required]
	path             string @[required]
	interval_seconds int    @[required]
}

fn FileWatcher.from_config(conf ConfigFileWatcher) FileWatcher {
	return FileWatcher{
		active:           true
		uniq_id:          conf.uniq_id
		path:             conf.path
		interval_seconds: conf.interval_seconds
	}
}

fn (mut item FileWatcher) from_config(conf ConfigFileWatcher) {
	item.uniq_id = conf.uniq_id
	item.path = conf.path
	item.interval_seconds = conf.interval_seconds
}

fn (mut item FileWatcher) watch(mut db sqlite.DB) {
	content := os.read_file(item.path) or {
		eprintln(err.msg())
		return
	}
	item.content = content
	item.size = os.file_size(item.path)
	sql db {
		update FileWatcher set content = item.content where uniq_id == item.uniq_id
		update FileWatcher set size = item.size where uniq_id == item.uniq_id
	} or {
		eprintln(err.msg())
		return
	}
}
