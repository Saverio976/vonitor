module monitor

pub struct ProcessWatcher {
pub mut:
	id      int @[primary; sql: serial]
	pid     int
	program string
	command string
	user    string
	memory  int
	cpu     int
}
