;
; AutoHotkey Version: 1.x
; Language:       English
; Platform:       Win10
; Author:         Chimstaz <ChimstazElComa@gmail.com>
;
; Script Function:
;	Reading touchpad status from Elantech Device Information program.
;

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#NoTrayIcon
#SingleInstance, Force

global TapDelay := 200		;Max time between taps to count as next tap in row
global PressDelay := 100	;Time to recognize tap as press

FingersDetectionDelay := 100	;Time to wait for fingers

global NoSwipeDistance := 60	;Distance that isn't interpreted as move

DetectHiddenWindows, On

IfWinNotExist ETDDeviceInformation
{
	Run , "C:\Program Files\Elantech\ETDDeviceInformation.exe"
	WinWait , ETDDeviceInformation, , 3
	if ErrorLevel
	{
		Traytip,TouchpadStatus, Filed to start ETDDeviceInformation.exe , , 16
		return
	}
}
WinGet , ETDID, ID

OnExit , ExitSub	;ETDDeviceInformation window exist so make sure to close it when script is done

FingerID := Object()

ControlGet , cid, Hwnd,, Static4, ahk_id %ETDID%
FingerID[1] := cid
ControlGet , cid, Hwnd,, Static19, ahk_id %ETDID%
FingerID[2] := cid
ControlGet , cid, Hwnd,, Static21, ahk_id %ETDID%
FingerID[3] := cid
ControlGet , cid, Hwnd,, Static23, ahk_id %ETDID%
FingerID[4] := cid
ControlGet , cid, Hwnd,, Static25, ahk_id %ETDID%
FingerID[5] := cid

ControlGet , NumberOfFingersID, Hwnd,, Static11, ahk_id %ETDID%
ControlGet , ButtonID, Hwnd,, Static6, ahk_id %ETDID%


WinHide , ahk_id %ETDID%

ControlIDs := Object()
ControlIDs.Finger := FingerID
ControlIDs.NumberOfFingers := NumberOfFingersID
ControlIDs.Button := ButtonID

GeastureInfo := Object()

while (1)
{
    TouchPadStat := ReadTouchPadStatus(ControlIDs)

	if (TouchPadStat.NumberOfFingers = 0 )
	{
		TouchTime := 0
		NoTouchTime := NoTouchTime + 10
		GeastureInfo.FingersNum := 0
		GeastureInfo.FingersNumMismatch := false
	}
	else
	{
		TouchTime := TouchTime + 10
		NoTouchTime := 0
	}

	if (TouchTime > FingersDetectionDelay and GeastureInfo.FingersNum = 0 )
		GeastureInfo.FingersNum := TouchPadStat.NumberOfFingers

	GeastureInfo.MoveDirection := DetectFingerMove(TouchPadStat)

	GeastureInfo.tap := DetectTap(TouchPadStat, GeastureInfo.MoveDirection, TouchTime, NoTouchTime)

	;DetectedFingers := DetectFingersInSpot(GeastureInfo, TouchPadStat, 3000 , 1900 , 3260 , 2119 )
	;for i, f in DetectedFingers
	;{
	;	GeastureInfo.MoveDirection[f].exist := false
	;}
	;GeastureInfo.UpperRightCorner := DetectedFingers.Length()

	GeastureInfo.SwipeRight := DetectSwipe(GeastureInfo, 0 , 0.6 , 150 )	;GeastureInfo with move direction, direction, accepted eps of dir, min distance
	GeastureInfo.SwipeLeft  := DetectSwipe(GeastureInfo, 3.1416 , 0.6 , 150 )
	GeastureInfo.SwipeUp    := DetectSwipe(GeastureInfo, 1.5708 , 0.6 , 150 )
	GeastureInfo.SwipeDown  := DetectSwipe(GeastureInfo, 4.7124 , 0.6 , 150 )

	;GeastureInfo.ModKey := GetKeyState("AppsKey")

	if (GeastureInfo.FingersNum <> TouchPadStat.NumberOfFingers and GeastureInfo.FingersNum <> 0 )
		GeastureInfo.FingersNumMismatch := true

	;message := "No. fingers: " . GeastureInfo.FingersNum
	;for index, m in GeastureInfo.MoveDirection
	;{
	;	message := message . "`nFinger " . index . " exist: " . m.exist . " noMove: " . m.noMove . " angle: " . m.angle . " distance: " . m.distance
	;}
	;
	;message := message . "`nSwipe right: " . GeastureInfo.SwipeRight . "`nSwipe left:  " . GeastureInfo.SwipeLeft . "`nSwipe up:    " . GeastureInfo.SwipeUp . "`nSwipe down:  " . GeastureInfo.SwipeDown . "`nUpperRight: " . GeastureInfo.UpperRightCorner
	;ToolTip %message%

	ifWinActive , Widok zada ahk_class MultitaskingViewFrame
	{
		swdBlock( true )
		SwitchWindowsDesktops(GeastureInfo, TouchPadStat)
	}
	else
		swdBlock( false )

	if (GeastureInfo.FingersNum = 4 and GeastureInfo.SwipeRight )
	{
		ClearNotifications()
		GeastureInfo := Object()
	}

	if (GeastureInfo.FingersNum = 4 and GeastureInfo.SwipeUp )
	{
		send #{Tab}
		GeastureInfo := Object()
	}

	if (GeastureInfo.FingersNum = 3 and GeastureInfo.SwipeRight )
	{
		fromVM := false
	  ifWinActive , ahk_class VMPlayerFrame
		{
			fromVM := true
		  WinActivate , ahk_class Shell_TrayWnd ahk_exe explorer.exe
			MouseGetPos , xpos, ypos
			MouseMove , 0 , 0 , 0
		}
		send ^#{Right}
		if(fromVM)
		{
			MouseMove , %xpos%, %ypos%, 0
		}
		PostMessage, 0x2000, , , , C:\Users\Tom\Documents\AutoHotkey\skrypty\GitHub\windows10DesktopManager\windows10.ahk ahk_class AutoHotkey
		GeastureInfo := Object()
	}

	if (GeastureInfo.FingersNum = 3 and GeastureInfo.SwipeLeft )
	{
		fromVM := false
	  ifWinActive , ahk_class VMPlayerFrame
		{
			fromVM := true
		  WinActivate , ahk_class Shell_TrayWnd ahk_exe explorer.exe
			MouseGetPos , xpos, ypos
			MouseMove , 0 , 0 , 0
		}
		send ^#{Left}
		if(fromVM)
		{
			MouseMove , %xpos%, %ypos%, 0
		}
		PostMessage , 0x2000, , , , C:\Users\Tom\Documents\AutoHotkey\skrypty\GitHub\windows10DesktopManager\windows10.ahk ahk_class AutoHotkey
		GeastureInfo := Object()
	}

	if(GeastureInfo.tap.exist and GeastureInfo.tap.fingers = 4 and GeastureInfo.tap.num = 1)
	{
		send #a
	}

	;if (GeastureInfo.UpperRightCorner = 1 )
	;{
	;	BlockInput MouseMove
	;	if (TouchPadStat.NumberOfFingers = 2 )
	;	{
	;		if (GeastureInfo.SwipeRight)
	;		{
	;			SwitchWindow( 1 )
	;			GeastureInfo.FingersNum := 0
	;			TouchTime := 0
	;			DetectFingerMove( TouchPadStat, 1 )
	;		}
	;		else if (GeastureInfo.SwipeLeft)
	;		{
	;			SwitchWindow( -1 )
	;			GeastureInfo.FingersNum := 0
	;			TouchTime := 0
	;			DetectFingerMove( TouchPadStat, 1 )
	;		}
	;	}
	;}
	;else
	;{
	;	BlockInput MouseMoveOff
	;	SwitchWindow( 0 )
	;}

	Sleep , 10
}
ToolTip
return

ExitSub:
	;close ETDDeviceInformation window
	;WinClose
	WinShow , ahk_id %ETDID%
	ExitApp

SendEnter:
	Send {Enter}
	return

SendEsc:
	Send {Esc}
	return

SendAppsKey:
	Send {AppsKey}
	return


swdBlock( switch )
{
	static blockStatus := false
	static oldx
	static oldy
	if (switch and not blockStatus)
	{
		hotkey , LButton, SendEnter, On
		hotkey , MButton, SendEsc, On
		hotkey , RButton, SendAppsKey, On
		cm := A_CoordModeMouse
		CoordMode , Mouse , Screen
		MouseGetPos , oldx, oldy
		MouseMove , %A_ScreenWidth% , 0 , 0
		BlockInput MouseMove
		blockStatus := true
		CoordMode , Mouse , %cm%
	}
	else if (not switch and blockStatus)
	{
		hotkey , LButton, Off
		hotkey , MButton, Off
		hotkey , RButton, Off
		cm := A_CoordModeMouse
		CoordMode , Mouse , Screen
		BlockInput MouseMoveOff
		MouseMove , %oldx%, %oldy%, 0
		blockStatus := false
		CoordMode , Mouse , %cm%
		PostMessage, 0x2000, , , , C:\Users\Tom\Documents\AutoHotkey\skrypty\GitHub\windows10DesktopManager\windows10.ahk ahk_class AutoHotkey
	}
}

SwitchWindowsDesktops(GeastureInfo, Status)
{
	static menuActive := false

	if (GeastureInfo.FingersNum = 1 and GeastureInfo.FingersNumMismatch = false )
	{
		if ( GeastureInfo.SwipeDown )
		{
			send {Down}
			DetectFingerMove( Status, 1 )
		}
		if ( GeastureInfo.SwipeUp )
		{
			send {Up}
			DetectFingerMove( Status, 1 )
		}
		if ( GeastureInfo.SwipeRight )
		{
			send {Right}
			DetectFingerMove( Status, 1 )
		}
		if ( GeastureInfo.SwipeLeft )
		{
			send {Left}
			DetectFingerMove( Status, 1 )
		}
	}
	if (GeastureInfo.FingersNum = 2 and GeastureInfo.FingersNumMismatch = false )
	{
		if ( GeastureInfo.SwipeLeft )
		{
			send ^#{Left}
			DetectFingerMove( Status, 1 )
		}
		if ( GeastureInfo.SwipeRight )
		{
			send ^#{Right}
			DetectFingerMove( Status, 1 )
		}
	}
}

DetectFingersInSpot(GeastureInfo, TouchPadStatus, xmin, ymin, xmax, ymax)
{
	indexes := []
	for i, m in GeastureInfo.MoveDirection
	{
		if ( m.exist = true and m.noMove = true
			and TouchPadStatus.FingerPosition[i].x > xmin and TouchPadStatus.FingerPosition[i].x < xmax
			and TouchPadStatus.FingerPosition[i].y > ymin and TouchPadStatus.FingerPosition[i].y < ymax )
		{
			indexes.Push(i)
		}
	}
	return indexes
}

SwitchWindow(n)		;n = 0 -- stop alt tabing; 1 -- next; -1 -- pervious
{
	static AltState := false
	if (n = 0 )
	{
		if (AltState)
		{
			Send {Alt Up}
			AltState := false
		}
	}
	else
	{
		if (AltState = false )
		{
			Send {Alt Down}
			AltState := true
		}
		if (n = 1)
		{
			Send {Tab}
		}
		else if (n = -1)
		{
			Send +{Tab}
		}
	}
}

DetectSwipe(GeastureInfo, direction, directionEps, minDistance)
{
	anyFinger := false
	for i, m in GeastureInfo.MoveDirection
	{
		anyFinger := anyFinger or m.exist
		nDir := Abs(m.angle - direction)
		if ( m.exist = true and (( 6.2831853 - nDir > directionEps and nDir > directionEps) or m.distance < minDistance ) )
			return false
	}
	return anyFinger
}


ClearNotifications()
{
	;dirty hack. Move mouse and click clear notifications. Move mouse to piervious position
	IfWinActive , Centrum akcji
	{
		MouseGetPos , xpos, ypos
		MouseClick , Left, 1281 , 27 , 1 , 0
		MouseMove , %xpos%, %ypos%, 0
	}
}

DetectFingerMove(Status, Reset := 0 )
{
	static StartStatus := [ {x: 0, y: 0}, {x: 0, y: 0}, {x: 0, y: 0}, {x: 0, y: 0}, {x: 0, y: 0} ]	;start status
	if (Reset = 1 )
	{
		for i, fs in Status.FingerPosition
		{
			StartStatus[i].x := fs.x
			StartStatus[i].y := fs.y
		}
	}

	FingerDirection := [{},{},{},{},{}]
	for i, fs in Status.FingerPosition
	{
		os := StartStatus[i]
		if ((os.x = 0 and os.y = 0 ) or (fs.x = 0 and fs.y = 0 ))
		{
			StartStatus[i].x := fs.x
			StartStatus[i].y := fs.y
			FingerDirection[i].exist := false
		}
		else
		{
			FingerDirection[i].exist := true
			distance := Sqrt((os.x - fs.x)**2 + (os.y - fs.y)**2)
			FingerDirection[i].distance := distance
			if (NoSwipeDistance > distance)
			{
				FingerDirection[i].noMove := true
			}
			else
			{
				FingerDirection[i].noMove := false
				FingerDirection[i].angle := ACos((fs.x - os.x)/distance )
				if (os.y > fs.y)
					FingerDirection[i].angle := 6.2831853 - FingerDirection[i].angle
			}
		}
	}
	return FingerDirection
}

ReadTouchPadStatus(ControlIDs)
{
	Status := Object()
	Status.FingerPosition := Object()
	NOFID := ControlIDs.NumberOfFingers
	BID := ControlIDs.Button
	ControlGetText , NumberOfFingers, , ahk_id %NOFID%
	ControlGetText , ButtonStat, , ahk_id %BID%
	Status.NumberOfFingers := NumberOfFingers
	Status.Button := ParseButtonStatus(ButtonStat)
	for index, cid in ControlIDs.Finger
	{
		ControlGetText , fingerStat, , ahk_id %cid%
		Status.FingerPosition[index] := ParseFingerStatus(fingerStat)
	}
	return Status
}

ParseButtonStatus(bt)
{
	If (bt = "Down")
		return true
	else
		return false
}

ParseFingerStatus(fs) ; [1323,443] [12] [3]
{
	fields := StrSplit(fs , ["," , "[" ] , "] ")
	fp := Object()
	fp.x := fields[2]
	fp.y := fields[3]
	fp.h := fields[4]
	fp.mk := fields[5]
	return fp
}

DetectTap(TouchPadStat, MoveDirection, TouchTime, NoTouchTime)
{
	static maxFingers := 0
	static correctNumOfFingers := false
	static LastTouchTime := 0
	static LastNoTouchTime := 0
	static TapNum := 0

	;message := message . "TapDelay: " . TapDelay . "`nmaxFingers: " . maxFingers . "`nLastTouch:  " . LastTouchTime . "`nLastNoTouch: " . LastNoTouchTime . "`nNoTouch: " . NoTouchTime . "`nTapNum:  " . TapNum . "`ncorrect: " . correctNumOfFingers
	;ToolTip %message%

	tap := Object()
	tap.exist := false

	anyMove := false
	for i, fs in MoveDirection
	{
		anyMove := anyMove or (fs.exist and !fs.noMove)
	}
	if(anyMove)
	{
		TapNum := 0
		maxFingers := 0
		correctNumOfFingers := false
	}
	else if(TouchTime > TapDelay)
	{
		TapNum := 0
		maxFingers := 0
		correctNumOfFingers := false
	}
	else if(NoTouchTime >= TapDelay and LastNoTouchTime < TapDelay and correctNumOfFingers)
	{
		;message := message . "SEND" . "`nmaxFingers: " . maxFingers . "`nLastTouch:  " . LastTouchTime . "`nLastNoTouch: " . LastNoTouchTime . "`nNoTouch: " . NoTouchTime . "`nTapNum:  " . TapNum . "`ncorrect: " . correctNumOfFingers
		;ToolTip %message%
		tap.exist := true
		tap.num := TapNum
		tap.fingers := maxFingers
		TapNum := 0
		maxFingers := 0
	}
	else if(TouchTime > 0)
	{
		if(TapNum = 0 and maxFingers < TouchPadStat.NumberOfFingers)
		{
			maxFingers := TouchPadStat.NumberOfFingers
			correctNumOfFingers := true
		}
		if(TapNum > 0)
		{
			if(TouchPadStat.NumberOfFingers == maxFingers){
				correctNumOfFingers := true
			}
			if(TouchPadStat.NumberOfFingers > maxFingers){
				correctNumOfFingers := false
				maxFingers := 6
			}
		}
	}
	else if(LastNoTouchTime > TapDelay)
	{
		TapNum := 0
		maxFingers := 0
		correctNumOfFingers := false
	}
	else if(LastNoTouchTime == 0 and NoTouchTime > 0)
	{
		TapNum += 1
	}
	LastNoTouchTime := NoTouchTime
	LastTouchTime := TouchTime

	return tap
}
