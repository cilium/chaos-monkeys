SUBDIRS := $(wildcard monkeys/*)

all:
	@for i in $(SUBDIRS); do $(MAKE) -C $$i all; done

clean:
	@for i in $(SUBDIRS); do $(MAKE) -C $$i clean; done
