module monitor

import toml

struct ConfigFile {
mut:
	file_watcher    []ConfigFileWatcher
	command_watcher []ConfigCommandWatcher
}

fn parse_config(config_path string) !ConfigFile {
	doc := toml.parse_file(config_path)!
	mut config := ConfigFile{}
	for item in doc.value('file_watcher').array() {
		c := item.reflect[ConfigFileWatcher]()
		if c.path != '' && c.interval_seconds != 0 {
			config.file_watcher << c
		}
	}
	for item in doc.value('command_watcher').array() {
		c := item.reflect[ConfigCommandWatcher]()
		if c.exe != '' && c.interval_seconds != 0 {
			config.command_watcher << c
		}
	}
	println('${config}')
	return config
}
