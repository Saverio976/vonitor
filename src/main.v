module main

import os
import x.templating.dtm
import veb
import db.sqlite
import veb.auth
import monitor
import flag

@[xdoc: 'Monitor a machine with a web interface']
@[footer: 'https://github.com/Saverio976/vonitor']
@[version: '0.0.0']
@[name: 'vonitor']
struct Config {
	daemon_config_file string @[long: dconfig; xdoc: 'config file for the monitor daemon']
	web_config_file string @[long: wconfig; xdoc: 'config file for the web interface']
}

pub struct User {
	id int @[primary; sql: serial]
	name string
	password_hash string
	salt string
}

pub struct Context {
	veb.Context
pub mut:
	user ?User
}

pub struct App {
	veb.StaticHandler
pub mut:
	dtmi &dtm.DynamicTemplateManager = unsafe { nil }
	db sqlite.DB
	auth auth.Auth[sqlite.DB]
}

fn main() {
	config, no_matches := flag.to_struct[Config](os.args, skip: 1)!

	if no_matches.len > 0 {
		println('The following flags could not be mapped to any fields on the struct: ${no_matches}')
	}

	cache_folder_path := os.join_path(os.dir(os.executable()), '.vcache_dtm')
	data_folder_path := os.join_path(os.dir(os.executable()), '.data')
	mut db := sqlite.connect(os.join_path(data_folder_path, 'vonitor.db')) or {
		panic(err)
	}
	defer {
		db.close() or {}
	}
	mut app := &App{
		db: db
		dtmi: dtm.initialize(def_cache_path: cache_folder_path)
	}
	app.auth = auth.new(app.db)
	sql app.db {
		create table User
	}!
	defer {
		app.dtmi.stop_cache_handler()
	}
	app.mount_static_folder_at('static', '/static') or {
		panic('Failed to find static folder')
	}
	spawn monitor.monitor(config.daemon_config_file, os.join_path(data_folder_path, 'monitor.db'))
	veb.run[App, Context](mut app, 8080)
}
