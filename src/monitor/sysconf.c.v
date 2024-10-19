module monitor

#include <unistd.h>

fn C.sysconf(int name) i64

fn get_tick_per_second() i64 {
	return C.sysconf(C._SC_CLK_TCK)
}
