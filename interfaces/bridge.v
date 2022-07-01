module interfaces

import os

pub struct Bridge {
	ns_device string
	ns_previous_device string
	ns_ip []string

	host_device string
	host_bridge string
}

pub fn (i Bridge) create(pid int) {
	os.execute_or_exit("ip link add name $i.host_device type veth peer name $i.ns_previous_device")
	os.execute_or_exit("ip link set $i.ns_previous_device netns $pid")
	os.execute_or_exit("ip link set $i.host_bridge up")
	os.execute_or_exit("ip link set $i.host_device up")
	os.execute_or_exit("ip link set $i.host_device master $i.host_bridge")
}

pub fn new_bridge(name string) (Interface, bool) {
	bridge := os.getenv_opt("NETNS_" + name + "_BRIDGE") or {
		return Bridge{}, false
	}

	return Bridge{
		ns_device: name,
		ns_previous_device: tmp_veth(),
		ns_ip: os.getenv("NETNS_" + name + "_IP").split(" "),
		host_bridge: bridge,
		host_device: os.getenv_opt("NETNS_" + name + "_BRIDGE_INT") or {tmp_veth()},
	}, true
}