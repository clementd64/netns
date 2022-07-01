module interfaces

import os

pub struct Veth {
	ns_device string
	ns_previous_device string
	ns_ip []string

	host_device string
	host_ip []string
}

pub fn (i Veth) create(pid int) {
	os.execute_or_exit("ip link add name $i.host_device type veth peer name $i.ns_previous_device")
	os.execute_or_exit("ip link set $i.ns_previous_device netns $pid")
	for ip in i.host_ip {
		os.execute_or_exit("ip addr add dev $i.host_device $ip")
	}
	os.execute_or_exit("ip link set $i.host_device up")
}

pub fn new_veth(name string) (Interface, bool) {
	veth := os.getenv_opt("NETNS_" + name + "_VETH") or {
		return Veth{}, false
	}

	return Veth{
		ns_device: name,
		ns_previous_device: tmp_veth(),
		ns_ip: os.getenv("NETNS_" + name + "_IP").split(" "),
		host_device: veth,
		host_ip: os.getenv("NETNS_" + name + "_VETH_IP").split(" "),
	}, true
}