module main

import toml
import os
import veb
import db.pg
import veb.auth
import monitor
import flag

@[xdoc: 'Monitor a machine with a web interface']
@[footer: 'https://github.com/Saverio976/vonitor']
@[name: 'vonitor']
@[version: '0.0.0']
struct Config {
	daemon_config_file string @[long: dconfig; xdoc: 'config file for the monitor daemon']
	web_config_file    string @[long: wconfig; xdoc: 'config file for the web interface']
}

struct ConfigFile {
mut:
	postgres_uri string
}

pub struct User {
	id            int @[primary; sql: serial]
	name          string
	password_hash string
	salt          string
}

pub struct Context {
	veb.Context
pub mut:
	user ?User
}

pub struct App {
	veb.StaticHandler
pub mut:
	db     pg.DB
	auth   auth.Auth[pg.DB]
}

fn new_config_file(config_path string) !ConfigFile {
	doc := toml.parse_file(config_path)!
	mut config := ConfigFile{}
	postgres_uri := doc.value('postgres_uri').string()
	if postgres_uri != '' {
		config.postgres_uri = postgres_uri
	}
	return config
}

fn main() {
	config, no_matches := flag.to_struct[Config](os.args, skip: 1)!
	if no_matches.len > 0 {
		println('The following flags could not be mapped to any fields on the struct: ${no_matches}')
	}
	config_file := new_config_file(config.web_config_file)!
	data_folder_path := os.join_path(os.dir(os.executable()), '.data')
	mut db := pg.connect_with_conninfo(config_file.postgres_uri) or { panic(err) }
	defer {
		db.close()
	}
	monitor_path := os.join_path(data_folder_path, 'monitor.db')
	mut app := &App{
		db:     db
	}
	app.auth = auth.new(app.db)
	sql app.db {
		create table User
	}!
	app.mount_static_folder_at('static', '/static') or { panic('Failed to find static folder') }
	spawn monitor.monitor(config.daemon_config_file, monitor_path)
	veb.run[App, Context](mut app, 8080)
}
