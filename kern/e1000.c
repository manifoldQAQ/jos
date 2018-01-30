#include <kern/e1000.h>
#include <kern/pci.h>
#include <kern/pmap.h>
#include <inc/string.h>
#include <inc/error.h>

physaddr_t e1000_addr;
volatile uint32_t *e1000; // Declare as volatile to prevent reordering.

/* Transmission descriptor ring */
struct e1000_tx_desc tx_descs[N_TX_DESCS] __attribute__((aligned (16)));
uint8_t tx_bufs[N_TX_DESCS][ETH_PKT_SIZE];

// LAB 6: Your driver code here
int
pci_e1000_attach(struct pci_func *pcif)
{
    pci_func_enable(pcif);

    // Create a direct mapping for net driver registers.
    // Set up base address register 0 (BAR0).
    e1000_addr = pcif->reg_base[0];
    e1000 = mmio_map_region(pcif->reg_base[0], pcif->reg_size[0]);
    check_e1000_mmio();

    // Initialize network transmission.
    e1000_tx_init();
    return 0;
}

int
e1000_transmit(uint8_t data[], int len)
{
    int tail = e1000[E1000_TDT>>2];

    // No buffer left.
    if (!(tx_descs[tail].upper.data & E1000_TXD_STAT_DD))
        return -E_NO_TX_BUF;

    assert(len < ETH_PKT_SIZE);
    memset(tx_bufs[tail], 0, ETH_PKT_SIZE);
    memcpy(tx_bufs[tail], data, len);
    tx_descs[tail].lower.flags.length = len;
    tx_descs[tail].lower.data |= E1000_TXD_CMD_RS;
    tx_descs[tail].lower.data |= E1000_TXD_CMD_EOP;
    tx_descs[tail].upper.data &= ~E1000_TXD_STAT_DD;
    e1000[E1000_TDT>>2] = (tail + 1) % N_TX_DESCS;
    return 0;
}

static void
e1000_tx_init()
{
    assert(sizeof(tx_descs) % 128 == 0);
    memset(tx_descs, 0, sizeof(tx_descs));
    for (int i = 0; i < N_TX_DESCS; i++) {
        tx_descs[i].buffer_addr = PADDR(&tx_bufs[i]);
        tx_descs[i].lower.data |= E1000_TXD_CMD_RS;
        tx_descs[i].upper.data |= E1000_TXD_STAT_DD;
    }
    e1000[E1000_TDBAL>>2] = PADDR(tx_descs);
    e1000[E1000_TDLEN>>2] = sizeof(tx_descs);
    e1000[E1000_TDH>>2]   = 0;
    e1000[E1000_TDT>>2]   = 0;
    e1000[E1000_TCTL>>2] |= E1000_TCTL_EN;
    e1000[E1000_TCTL>>2] |= E1000_TCTL_PSP;
    e1000[E1000_TCTL>>2] &= ~E1000_TCTL_CT;
    e1000[E1000_TCTL>>2] |= 0x100;
    e1000[E1000_TCTL>>2] &= ~E1000_TCTL_COLD;
    e1000[E1000_TCTL>>2] |= 0x40<<12;
    e1000[E1000_TIPG>>2]  = (6<<20) | (4<<10) | 10;
}



static void
check_e1000_mmio()
{
    assert(e1000[E1000_STATUS>>2] == 0x80080783);
    cprintf("check_e1000_mmio() succeeded!\n");
}
