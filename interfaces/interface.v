module interfaces

import os
import encoding.base58
import rand

fn tmp_veth() string {
	return "veth" + base58.encode_int(rand.int31()) or {""}
}

pub interface Interface {
	ns_device string
	ns_tmp_device string
	ns_ip []string

	create(pid int)
}

pub fn (i Interface) setup_ns() {
	os.execute_or_exit("ip link set dev $i.ns_tmp_device name $i.ns_device")
	for ip in i.ns_ip {
		os.execute_or_exit("ip addr add dev $i.ns_device $ip")
	}
	os.execute_or_exit("ip link set $i.ns_device up")
}