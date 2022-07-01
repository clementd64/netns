module interfaces

import os

pub struct Generic {
	ns_device string
	ns_tmp_device string
	ns_ip []string
}

pub fn (i Generic) create(pid int) {
	os.execute_or_exit("ip link set $i.ns_tmp_device netns $pid")
}

pub fn new_generic(name string) (Interface, bool) {
	i := os.getenv_opt("NETNS_" + name + "_GENERIC") or {
		return Veth{}, false
	}

	return Generic{
		ns_device: name,
		ns_tmp_device: i,
		ns_ip: os.getenv("NETNS_" + name + "_IP").split(" "),
	}, true
}