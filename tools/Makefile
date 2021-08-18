#TARGETS = $(shell find ./log/ -name '*.dstat.log')
TARGET_DIRS = $(wildcard ./log/*)
DSTAT_TARGETS = $(addsuffix /_all.dstat.log, $(TARGET_DIRS))
NGINX_TARGETS = $(addsuffix /_all.nginxalp.txt, $(TARGET_DIRS))
JOURNALCTL_TARGETS = $(addsuffix /_all.journalctl.txt, $(TARGET_DIRS))
MYSQL_TARGETS = $(addsuffix /_all.mysqldumpslow.txt, $(TARGET_DIRS))
PTQUERYDIGEST_TARGETS = $(addsuffix /_all.ptquerydigest.txt, $(TARGET_DIRS))
SUMMARY_TARGETS = $(addsuffix /__all.txt, $(TARGET_DIRS))

TARGETS = $(DSTAT_TARGETS) $(NGINX_TARGETS) $(JOURNALCTL_TARGETS) $(MYSQL_TARGETS) $(PTQUERYDIGEST_TARGETS) $(SUMMARY_TARGETS)
SUMMARIES = .dstat.txt .mysqldumpslow.txt .ptquerydigest.txt .nginxalp.txt .journalctl.txt

.PHONY: all clean

all: $(TARGETS)

define concat
	for i in $^; do echo "########## $$i ##########" >> $@; cat $$i >> $@; echo >>$@; echo >>$@; done
endef

.SECONDEXPANSION:
./log/%/_all.dstat.log: $$(wildcard ./log/%/[!_]*.dstat.log)
	$(concat)

./log/%/_all.dstat.txt: $$(wildcard ./log/%/_all.dstat.log)
	ansi2txt < $^ > $@

./log/%/_all.nginxalp.txt: $$(wildcard ./log/%/[!_]*.nginxalp.txt)
	$(concat)

./log/%/_all.journalctl.txt: $$(wildcard ./log/%/[!_]*.journalctl.txt)
	$(concat)

./log/%/_all.mysqldumpslow.txt: $$(wildcard ./log/%/[!_]*.mysqldumpslow.txt)
	$(concat)

./log/%/_all.ptquerydigest.txt: $$(wildcard ./log/%/[!_]*.mysql-slow.log)
	for i in $^; do echo "########## $$i ##########" >> $@; pt-query-digest $$i >> $@; echo >>$@; echo >>$@; done
./log/%/__all.txt: $$(addprefix ./log/%/_all, $(SUMMARIES))
	cat $^ >> $@ || true # ignore error




clean:
	rm -rf $(TARGETS)

