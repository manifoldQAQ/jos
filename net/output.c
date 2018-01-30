#include "ns.h"

extern union Nsipc nsipcbuf;

void
output(envid_t ns_envid)
{
	binaryname = "ns_output";

	// LAB 6: Your code here:
	// 	- read a packet from the network server
	//	- send the packet to the device driver
    int r;
    envid_t from_env;
    int perm;

    while (1) {
        if ((r = ipc_recv(&from_env, (void *) &nsipcbuf.pkt, &perm)) < 0)
            continue;
        if (from_env != ns_envid || !(perm & PTE_U))
            continue;
        while ((r = sys_net_try_send(nsipcbuf.pkt.jp_data, nsipcbuf.pkt.jp_len)) == -E_NO_TX_BUF)
            ;
    }
    panic("output: control flow should not arrive here.");
}
