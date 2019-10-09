ALL:=Coord.lua.ok CyroDoor.lua.ok
.PHONY: all
all:  ${ALL}

.PHONY: install
install: all
	@rsync -aR ${ALL:.ok=} icons/*.dds *.xml CyroDoor.txt  '/smb/c/Users/cgf/Documents/Elder Scrolls Online/live/AddOns'/Cyrodoor/
	@touch '/smb/c/Users/cgf/Documents/Elder Scrolls Online/live/AddOns'/POC/POC.txt

%.lua.ok: %.lua
	@unexpand -a -I $?
	esolua $?
	@touch $@
