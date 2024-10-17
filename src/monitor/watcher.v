module monitor

fn watcher(mut mon Monitor) {
	for mut item in mon.command_watcher {
		item.watch(mut mon.db)
	}
	for mut item in mon.file_watcher {
		item.watch(mut mon.db)
	}
}
