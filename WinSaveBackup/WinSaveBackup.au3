#NoTrayIcon
#RequireAdmin
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <ProgressConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <Array.au3>
#include <File.au3>

; --- Configuration ---
Global $BackupPath = @ScriptDir & "\WinSaveBackup"
Global $SevenZip = @TempDir & "\7z_internal.exe"

; Create storage folder
If Not FileExists($BackupPath) Then DirCreate($BackupPath)

; Bundle 7z.exe into the EXE
FileInstall("7z.exe", $SevenZip, 1)

; --- Create GUI ---
Global $hGUI = GUICreate("WinSaveBackup", 420, 330, -1, -1)
GUISetBkColor(0xFDFDFD)

GUICtrlCreateLabel("WinSaveBackup Utility", 10, 15, 400, 30, $SS_CENTER)
GUICtrlSetFont(-1, 14, 800, 0, "Segoe UI")
GUICtrlSetColor(-1, 0x2A52BE) 

; Developer Credit
GUICtrlCreateLabel("Developer: Ajay9634", 10, 42, 400, 20, $SS_CENTER)
GUICtrlSetFont(-1, 8, 600, 0, "Segoe UI")
GUICtrlSetColor(-1, 0x888888)

; Options
Global $chkDate = GUICtrlCreateCheckbox(" Create Date-Wise Backup (Unique folder)", 40, 75, 340, 20)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

; Buttons
Global $btnBackup = GUICtrlCreateButton("RUN BACKUP", 40, 110, 160, 50)
GUICtrlSetFont(-1, 10, 800)

Global $btnRestore = GUICtrlCreateButton("RUN RESTORE", 220, 110, 160, 50)
GUICtrlSetFont(-1, 10, 800)

Global $btnOpen = GUICtrlCreateButton("Open Backup Folder", 140, 170, 140, 30)
GUICtrlSetFont(-1, 8, 400)

; Progress Area
Global $lblStatus = GUICtrlCreateLabel("System Ready", 10, 215, 400, 20, $SS_CENTER)
Global $progressBar = GUICtrlCreateProgress(25, 240, 370, 22)

Global $lblPath = GUICtrlCreateLabel("Storage: " & $BackupPath, 10, 285, 400, 20, $SS_CENTER)
GUICtrlSetFont(-1, 8, 400, 2, "Segoe UI")
GUICtrlSetColor(-1, 0x666666)

GUISetState(@SW_SHOW)

; --- Init Check ---
CheckAjayPrefix()

; --- Main Loop ---
While 1
    Switch GUIGetMsg()
        Case $GUI_EVENT_CLOSE
            Exit
        Case $btnOpen
            Run('explorer.exe "' & $BackupPath & '"')
            
        Case $btnBackup
            ToggleButtons(0)
            BackupProcess()
            ToggleButtons(1)
            
        Case $btnRestore
            ToggleButtons(0)
            RestoreProcess()
            ToggleButtons(1)
    EndSwitch
WEnd

; --- Core Functions ---

Func ToggleButtons($iState)
    Local $val = ($iState = 1) ? $GUI_ENABLE : $GUI_DISABLE
    GUICtrlSetState($btnBackup, $val)
    GUICtrlSetState($btnRestore, $val)
    GUICtrlSetState($btnOpen, $val)
EndFunc

Func CheckAjayPrefix()
    Local $personal = RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders", "Personal")
    If StringInStr($personal, "Ajay_prefix") Then
        MsgBox(16, "WinSaveBackup - Error", "Ajay_prefix detected. Operation blocked.")
        Exit
    EndIf
EndFunc

Func BackupProcess()
    Local $FolderName = "Default_Backup"
    If GUICtrlRead($chkDate) = $GUI_CHECKED Then 
        $FolderName = @YEAR & "-" & @MON & "-" & @MDAY & "_" & @HOUR & @MIN
    EndIf
    
    Local $TargetSubDir = $BackupPath & "\" & $FolderName
    If Not FileExists($TargetSubDir) Then DirCreate($TargetSubDir)

    UpdateUI("Archiving User Profile...", 20)
    RunWait($SevenZip & ' a -t7z -y -bsp0 -bso0 "' & $TargetSubDir & '\Backup_User.7z" "C:\Users\' & @UserName & '\*" -mx0 -xr!Desktop -xr!Music -xr!"Start Menu" -xr!Microsoft -xr!Videos -xr!Temp -xr!Links -xr!Pictures -xr!Searches -xr!Downloads -xr!Contacts', "", @SW_HIDE)

    UpdateUI("Archiving Public Profile...", 50)
    RunWait($SevenZip & ' a -t7z -y -bsp0 -bso0 "' & $TargetSubDir & '\Backup_Public.7z" "C:\Users\Public\*" -mx0 -xr!Desktop -xr!Music -xr!"Start Menu" -xr!Microsoft -xr!Videos -xr!Temp -xr!Links -xr!Pictures -xr!Searches -xr!Downloads -xr!Contacts', "", @SW_HIDE)

    UpdateUI("Archiving ProgramData...", 85)
    RunWait($SevenZip & ' a -t7z -y -bsp0 -bso0 "' & $TargetSubDir & '\Backup_ProgData.7z" "C:\ProgramData\*" -mx0 -xr!Desktop -xr!Music -xr!"Start Menu" -xr!Microsoft -xr!"Package Cache" -xr!Videos -xr!Temp -xr!Links -xr!Pictures -xr!Searches -xr!Downloads -xr!Contacts', "", @SW_HIDE)

    UpdateUI("Backup Successful!", 100)
    MsgBox(64, "WinSaveBackup", "Backup completed in: " & $FolderName & @CRLF & "By Ajay9634")
    UpdateUI("System Ready", 0)
EndFunc

Func RestoreProcess()
    Local $aList = _FileListToArray($BackupPath, "*", 2) 
    If @error Then
        MsgBox(16, "WinSaveBackup", "No backups found.")
        Return
    EndIf

    Local $sFolders = ""
    For $i = 1 To $aList[0]
        $sFolders &= $aList[$i] & "|"
    Next
    
    Local $hSelect = GUICreate("Restore Point - Ajay9634", 320, 160, -1, -1, -1, $WS_EX_TOPMOST)
    GUICtrlCreateLabel("Select the backup folder to restore:", 15, 15, 290, 20)
    Local $cCombo = GUICtrlCreateCombo("", 15, 45, 290, 20)
    GUICtrlSetData($cCombo, StringTrimRight($sFolders, 1), $aList[1])
    Local $btnDoRestore = GUICtrlCreateButton("RESTORE NOW", 85, 95, 150, 35)
    GUISetState(@SW_SHOW)

    Local $sSelected = ""
    While 1
        Switch GUIGetMsg()
            Case $btnDoRestore
                $sSelected = GUICtrlRead($cCombo)
                ExitLoop
            Case $GUI_EVENT_CLOSE
                GUIDelete($hSelect)
                Return
            Case Else
                ; Idle
        EndSwitch
    WEnd
    GUIDelete($hSelect)

    Local $Source = $BackupPath & "\" & $sSelected
    UpdateUI("Restoring User Data...", 30)
    RunWait($SevenZip & ' x -y -bsp0 -bso0 "' & $Source & '\Backup_User.7z" -o"C:\Users\' & @UserName & '"', "", @SW_HIDE)
    
    UpdateUI("Restoring Public Data...", 60)
    RunWait($SevenZip & ' x -y -bsp0 -bso0 "' & $Source & '\Backup_Public.7z" -o"C:\Users\Public"', "", @SW_HIDE)
    
    UpdateUI("Restoring ProgramData...", 90)
    RunWait($SevenZip & ' x -y -bsp0 -bso0 "' & $Source & '\Backup_ProgData.7z" -o"C:\ProgramData"', "", @SW_HIDE)

    UpdateUI("Restore Finished!", 100)
    MsgBox(64, "WinSaveBackup", "Data from [" & $sSelected & "] restored successfully!")
    UpdateUI("System Ready", 0)
EndFunc

Func UpdateUI($text, $percent)
    GUICtrlSetData($lblStatus, $text)
    GUICtrlSetData($progressBar, $percent)
EndFunc
