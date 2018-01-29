#include <kern/pci.h>

#ifndef JOS_KERN_E1000_H
#define JOS_KERN_E1000_H

#define PCI_VENDOR_E1000 0x8086
#define PCI_DEVICE_E1000 0x100E

int pci_e1000_attach(struct pci_func *pcif);

#endif	// JOS_KERN_E1000_H
