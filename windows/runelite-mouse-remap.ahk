#Requires AutoHotkey v2.0

; Remap mouse 5 (front side button) -> middle click, only while RuneLite is focused.
; Workaround for a broken middle mouse button when playing OSRS.

#HotIf WinActive("ahk_exe RuneLite.exe")
XButton2::MButton
#HotIf
