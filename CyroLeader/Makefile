g:='/smb/c/Users/cgf/Documents/Elder Scrolls Online/live/AddOns'
gp:=$(subst live,pts,$g)
e:='/home/cgf/.local/share/Steam/steamapps/compatdata/306130/pfx/drive_c/users/steamuser/My Documents/Elder Scrolls Online/live/AddOns'
n:=$(notdir ${CURDIR})
txt:=$($n.txt)
ALL:=$(shell { echo $n.txt; egrep -v '^[        ]*(;|\#|$$)' $n.txt; ls textures/* 2>/dev/null;} | sed -e 's/\.lua$$/\.lua.ok/' | sort)
touch:=touch $e/POC/POC.txt $g/POC/POC.txt

export LUAIGNORE=
P=@

r:=rRlD
.PHONY: all
all:  ${ALL}

.PHONY: install
install: all
	$Prsync -$r ${ALL:.ok=} ${txt}  $g/$n/
	$Prsync -$r ${ALL:.ok=} ${txt}  ${gp}/$n/
	$Prsync -$r ${ALL:.ok=} ${txt}  $e/$n/
	$P${touch}

%.lua.ok: %.lua
	@unexpand -a -I $?
	esolua $?
	@touch $@
