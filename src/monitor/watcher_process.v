module monitor

import db.pg
import os
import strconv

struct ConfigProcessWatcher {
	interval_seconds int
	proc_path string
}

pub struct ProcessWatcher {
pub mut:
	id      int @[primary; sql: serial]
	pid     int
	program string
	command string
	user    string
	memory  int
	threads int
	cpu     u64
}

fn set_statm(statm_path string, mut process ProcessWatcher) ! {
	content := os.read_file(statm_path)!
	split := content.split(' ')
	if split.len > 1 {
		memory := strconv.atoi(split[1])!
		process.memory = memory * os.page_size()
		return
	}
	return error("Can't parse ${statm_path}")
}

fn set_stat(stat_path string, mut process ProcessWatcher) ! {
	content := os.read_file(stat_path)!
	split := content.split(' ')
	if split.len > 19 {
		process.threads = strconv.atoi(split[19])!
		cpu, cpu_ok := strconv.common_parse_uint2(split[13], 10, 0)
		if cpu_ok != 0 {
			return error("Can't parse ${stat_path} cpu")
		}
		process.cpu = cpu / u64(get_tick_per_second())
		return
	}
	return error("Can't parse ${stat_path}")
}

fn ProcessWatcher.watch(proc_path string, mut db pg.DB) {
	sql db {
		delete from ProcessWatcher where 1 == 1
	} or {
		//
	}
	for pid in os.ls(proc_path) or { [] } {
		pid_int := strconv.atoi(pid) or { continue }
		pid_path := os.join_path(proc_path, pid)
		mut process := ProcessWatcher{
			pid:     pid_int
			program: os.real_path(os.join_path(pid_path, 'exe'))
			command: os.read_file(os.join_path(pid_path, 'cmdline')) or { continue }
			user:    os.read_file(os.join_path(pid_path, 'loginuid')) or { continue }
		}
		set_statm(os.join_path(pid_path, 'statm'), mut process) or { continue }
		set_stat(os.join_path(pid_path, 'stat'), mut process) or { continue }
		sql db {
			insert process into ProcessWatcher
		} or {
			eprintln(err.msg())
			continue
		}
	}
}
