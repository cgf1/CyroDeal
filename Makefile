ALL:=Coord.lua.ok CyroDoor.lua.ok
all install:  ${ALL}
	@rsync -aR ${ALL:.ok=} icons/*.dds CyroDoor.txt  '/smb/c/Users/cgf/Documents/Elder Scrolls Online/live/AddOns'/Cyrodoor/
	@touch '/smb/c/Users/cgf/Documents/Elder Scrolls Online/live/AddOns'/POC/POC.txt

%.lua.ok: %.lua
	@unexpand -a -I $?
	esolua $?
	@touch $@
