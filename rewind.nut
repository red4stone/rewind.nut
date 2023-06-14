// GNU General Public License v3.0
printl("[@Citg] Rewind ACTIVE")
snaps_pos <- []
snaps_angles <- []
snapshot_timer <- ""
rewind_timer <- ""
frame <- 0
target <- null

const MAX_MEMORY_ALLOWANCE = 100000000 // In bytes. Default: 100,000,000 (100mb)

const MAX_SIZE = MAX_MEMORY_ALLOWANCE / (4 * 6) //4 Bytes in a float, 6 floats per frame
const TRACKER_NAME = "citg_eye_angle_tracker"

speedmod <- Entities.CreateByClassname("player_speedmod")
//viewcontrol <- null

logic_mm <- Entities.CreateByClassname("logic_measure_movement")
info_target <- Entities.FindByName(null, TRACKER_NAME)
if(info_target == null) {
	info_target = Entities.CreateByClassname("info_target")
	info_target.__KeyValueFromString("targetname", TRACKER_NAME)
}
logic_mm.__KeyValueFromInt("MeasureType", 1)
logic_mm.__KeyValueFromString("MeasureTarget", "!player")
logic_mm.__KeyValueFromString("MeasureReference", TRACKER_NAME)
logic_mm.__KeyValueFromString("TargetReference", TRACKER_NAME)
logic_mm.__KeyValueFromString("Target", TRACKER_NAME)

function AcquireTarget(targetname) {
	if(targetname == "!player") {
		target <- GetPlayer()
	} else {
		target <- Entities.FindByName(null, targetname)
	}
	printl("Acquired target " + targetname + " on " + self.GetName())
}

function StartSnapshot(delay) {
	if(target == null) {
		target = GetPlayer()
		printl("Snapshotting player")
	} else {
		printl("Snapshotting " + target.GetName() + " on " + self.GetName())
	}
	snapshot_timer = Entities.CreateByClassname("logic_timer")
	snapshot_timer.__KeyValueFromFloat("RefireTime", delay)

	EntFireByHandle(snapshot_timer, "AddOutput", "OnTimer " + self.GetName() + ":RunScriptCode:Snapshot():0:-1", 0, null, null)
	EntFireByHandle(snapshot_timer, "Enable", "", 0, null, null)
}

// Do not call this function!
function Snapshot() {
	if(snaps_pos.len() < MAX_SIZE) {
		if(target == GetPlayer()) {
			snaps_angles.append(info_target.GetAngles())
		} else {
			snaps_angles.append(target.GetAngles())
		}
		snaps_pos.append(target.GetOrigin())

		//printl("Creating frame " + snaps_pos.len())
		//printl("Frame data: x" + snaps_angles[snaps_pos.len() - 1].x + " y" + snaps_angles[snaps_pos.len() - 1].y + " z" + snaps_angles[snaps_pos.len() - 1].z)
	} else {
		printl("Too many frames! Skipping recorded frame.")
	}
}

function PauseSnapshot() {
	if(snapshot_timer != null) {
		snapshot_timer.Destroy()
		snapshot_timer = null
		printl("Snapshot paused on " + self.GetName())
	}
}

function WipeSnapshot() {
	snaps_pos.clear()
	snaps_angles.clear()
	printl("Snapshot cleared on " + self.GetName())
}

function PauseRewind() {
	if(rewind_timer != null) {
		rewind_timer.Destroy()
		rewind_timer = null
		printl("Rewind paused on " + self.GetName())
	}
	/*if(viewcontrol != null) {
		EntFireByHandle(viewcontrol, "Disable", "", 0, null, null)
	}*/
}

function StartRewind(delay) {
	PauseSnapshot()

	frame = snaps_pos.len() - 1
	if(frame <= 0) {
		printl("No frame data to rewind on " + self.GetName())
		return
	}
	printl("Now playing back " + frame + " frames on " + self.GetName())
	rewind_timer = Entities.CreateByClassname("logic_timer")
	rewind_timer.__KeyValueFromFloat("RefireTime", delay)

	EntFireByHandle(rewind_timer, "AddOutput", "OnTimer " + self.GetName() + ":RunScriptCode:Rewind():0:-1", 0, null, null)
	DisableMotion()
	EntFireByHandle(rewind_timer, "Enable", "", 0, null, null)
}

function UpdateViewcontrol() {
	viewcontrol.SetAbsOrigin(target.EyePosition())
	viewcontrol.SetAngles(snaps_angles[frame].x, snaps_angles[frame].y, snaps_angles[frame].z)
}

// Do not call this function!
function Rewind() {
	target.SetAbsOrigin(snaps_pos[frame])
	snaps_pos.remove(frame)
	target.SetAngles(snaps_angles[frame].x, snaps_angles[frame].y, snaps_angles[frame].z)
	/*if(viewcontrol != null) {
		//UpdateViewcontrol()
	}*/

	snaps_angles.remove(frame)

	frame = frame - 1
	if(frame == 0) {
		WipeSnapshot()
		PauseRewind()
		EnableMotion()
	}
}

function DisableMotion() {
	if(target == GetPlayer()) {
		EntFireByHandle(speedmod, "ModifySpeed", "0.0", 0, null, null)
		/*viewcontrol = Entities.CreateByClassname("point_viewcontrol")
		viewcontrol.__KeyValueFromInt("spawnflags", 12)
		UpdateViewcontrol()
		EntFireByHandle(viewcontrol, "Enable", "", 0, null, null)*/
	}
	EntFireByHandle(target, "DisableMotion", "0.0", 0, null, null)
}

function EnableMotion() {
	if(target == GetPlayer()) {
		EntFireByHandle(speedmod, "ModifySpeed", "1.0", 0, null, null)
	}
	EntFireByHandle(target, "EnableMotion", "0.0", 0, null, null)
	/*if(viewcontrol != null) {
		viewcontrol.Destroy()
		viewcontrol = null
	}*/
}