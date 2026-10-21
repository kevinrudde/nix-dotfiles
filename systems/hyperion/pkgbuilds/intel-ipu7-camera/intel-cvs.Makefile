# SPDX-License-Identifier: GPL-2.0-only
ifneq ($(KBUILD_EXTMOD),)
intel_cvs-y := core.o v4l2.o
obj-m += intel_cvs.o
else
KERNEL_SRC ?= /lib/modules/$(shell uname -r)/build

all:
	$(MAKE) -C $(KERNEL_SRC) M=$(CURDIR) modules

clean:
	$(MAKE) -C $(KERNEL_SRC) M=$(CURDIR) clean
endif
