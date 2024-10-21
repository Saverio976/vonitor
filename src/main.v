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

struct UserConfigFile {
	name string
	password_env_var string
}

struct ConfigFile {
mut:
	postgres_uri string
	users_create []UserConfigFile
	enable_register bool
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
pub:
	enable_register bool
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
	for item in doc.value('users').array() {
		user := item.reflect[UserConfigFile]()
		if user.name != '' && user.password_env_var != '' {
			config.users_create << user
		}
	}
	enable_register := doc.value('enable_register').bool()
	config.enable_register = enable_register
	return config
}

fn main() {
	eprintln('------------------ VONITOR -----------------------')
	config, no_matches := flag.to_struct[Config](os.args, skip: 1)!
	if no_matches.len > 0 {
		println('The following flags could not be mapped to any fields on the struct: ${no_matches}')
	}
	config_file := new_config_file(config.web_config_file)!
	mut db := pg.connect_with_conninfo(config_file.postgres_uri) or {
		eprintln('While connecting to pg in main: ${err.msg()}')
		os.exit(1)
	}
	defer {
		db.close()
	}
	mut app := &App{
		db:     db
		enable_register: config_file.enable_register
	}
	app.auth = auth.new(app.db)
	sql app.db {
		create table User
	}!
	for user in config_file.users_create {
		res := sql app.db {
			select from User where name == user.name limit 1
		} or {
			eprintln(err.msg())
			continue
		}
		if res.len == 0 {
			app.create_user(user.name, os.getenv(user.password_env_var)) or {
				eprintln('While creating users specified in config: ${err.msg()}')
				os.exit(1)
			}
		}
	}
	eprintln('${config}\n${config_file}')
	spawn monitor.monitor(config.daemon_config_file, config_file.postgres_uri)
	veb.run[App, Context](mut app, 8080)
}
