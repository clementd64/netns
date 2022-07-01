import os

import interfaces

#include <unistd.h>
fn C.kill(int, int) int
fn C.waitpid(int, &int, int) int
fn C.sethostname(&char, int) int

#define _GNU_SOURCE
#include <sched.h>
fn C.unshare(int) int

fn invalid_config(name string) (interfaces.Interface, bool) {
	println("Invalid configuration for interface $name")
	exit(1)
	// Unreachable. only for typechecking.
	return interfaces.Generic{}, false
}

struct Config {
	hostname string
	route []string
mut:
	interfaces []interfaces.Interface
}

fn main() {
	if os.args.len < 2 {
		println("usage: netns COMMAND")
		exit(1)
	}

	mut config := Config{
		hostname: os.getenv("NETNS_HOSTNAME"),
		route: os.getenv("NETNS_ROUTE").split("\n"),
	}

	for name in os.getenv("NETNS_INTERFACES").split(" ") {
		for new in [
			interfaces.new_veth,
			interfaces.new_bridge,
			interfaces.new_generic,
			invalid_config,
		] {
			i, ok := new(name)
			if ok {
				config.interfaces << i
				break
			}
		}
	}

	pid := os.fork()

	if pid == -1 {
		println("fork failed")
		exit(1)
	} else if pid == 0 {
		C.kill(os.getpid(), 19) // SIGSTOP

		ppid := os.getppid()
		for i in config.interfaces {
			i.create(ppid)
		}
	} else {
		status := C.unshare(0x44000000) // CLONE_NEWNET | CLONE_NEWUTS
		if status != 0 {
			C.kill(pid, 9) // SIGKILL
			println("unshare failed")
			exit(1)
		}

		os.execute_or_exit("ip addr add dev lo 127.0.0.1/8")
		os.execute_or_exit("ip addr add dev lo ::1/128")
		os.execute_or_exit("ip link set dev lo up")

		if config.hostname != "" {
			if C.sethostname(&char(config.hostname.str), config.hostname.len) != 0 {
				println("sethostname failed")
				exit(1)
			}
		}

		C.kill(pid, 18) // SIGCONT
		C.waitpid(pid, &status, 0)
		if status != 0 {
			exit(1)
		}

		for i in config.interfaces {
			i.setup_ns()
		}

		for route in config.route {
			if route.trim(" \t\n\r") == "" {
				continue
			}
			os.execute_or_exit("ip route add $route")
		}

		os.execvp(os.args[1], os.args[2..])?
	}
}