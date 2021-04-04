g:='/smb/c/Users/cgf/Documents/Elder Scrolls Online/live/AddOns'
gp:=$(subst live,pts,$g)
e:='/home/cgf/.local/share/Steam/steamapps/compatdata/306130/pfx/drive_c/users/steamuser/My Documents/Elder Scrolls Online/live/AddOns'
n:=$(notdir ${CURDIR})
txt:=$($n.txt)
ALL:=$(shell { echo $n.txt; egrep -v '^[        ]*(;|\#|$$)' $n.txt; ls textures/* 2>/dev/null;} | sed -e 's/\.lua$$/\.lua.ok/' | sort)

MODULES:=$(patsubst %/,%,$(shell echo Cyro*/))
r:=rRlD
.PHONY: all
all:  ${ALL}

.PHONY: install
install: all ${MODULES}
	@rsync -$r ${ALL:.ok=} ${txt} $g/$n/
	@rsync -$r ${ALL:.ok=} ${txt} ${gp}/$n/
	@rsync -$r ${ALL:.ok=} ${txt} $e/$n/
	@touch $e/POC/POC.txt $g/POC/POC.txt

.PHONY: ${MODULES}
${MODULES}:
	@make -s -C $@ install touch=

.PHONY: 

%.lua.ok: %.lua
	@unexpand -a -I $?
	esolua $?
	@touch $@
