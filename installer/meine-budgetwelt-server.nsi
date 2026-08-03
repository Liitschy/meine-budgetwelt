Unicode True

!ifndef SERVER_VERSION
  !error "SERVER_VERSION fehlt."
!endif
!ifndef SERVER_PAYLOAD
  !error "SERVER_PAYLOAD fehlt."
!endif
!ifndef OUTPUT_FILE
  !error "OUTPUT_FILE fehlt."
!endif

!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "nsDialogs.nsh"
!include "WinMessages.nsh"
!include "WordFunc.nsh"
!include "StrFunc.nsh"
${Using:StrFunc} StrStr

!ifndef SERVICE_NAME
  !define SERVICE_NAME "MeineBudgetweltServer"
!endif
!ifndef PRODUCT_KEY
  !define PRODUCT_KEY "Software\Meine Budgetwelt Server"
!endif
!ifndef UNINSTALL_KEY
  !define UNINSTALL_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\MeineBudgetweltServer"
!endif
!ifndef UPDATE_TASK_NAME
  !define UPDATE_TASK_NAME "MeineBudgetweltServerUpdater"
!endif

Name "Meine Budgetwelt Server"
OutFile "${OUTPUT_FILE}"
!ifdef TEST_MODE
  InstallDir "${TEST_INSTALL_DIR}"
!else
  InstallDir "$PROGRAMFILES64\Meine Budgetwelt Server"
!endif
InstallDirRegKey HKLM "${PRODUCT_KEY}" "InstallDir"
RequestExecutionLevel admin
SetCompressor /SOLID lzma
SetCompressorDictSize 32
CRCCheck on
ShowInstDetails show
ShowUninstDetails show

VIProductVersion "${SERVER_VERSION}.0"
VIAddVersionKey /LANG=1031 "ProductName" "Meine Budgetwelt Server"
VIAddVersionKey /LANG=1031 "FileDescription" "Meine Budgetwelt Server Setup"
VIAddVersionKey /LANG=1031 "FileVersion" "${SERVER_VERSION}"
VIAddVersionKey /LANG=1031 "ProductVersion" "${SERVER_VERSION}"
VIAddVersionKey /LANG=1031 "LegalCopyright" "Copyright 2026"

!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_NOAUTOCLOSE
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
Page custom PortPageCreate PortPageLeave
Page custom AdminPageCreate AdminPageLeave
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH
!insertmacro MUI_LANGUAGE "German"

Var DataDir
Var AppDir
Var PreviousAppDir
Var ExistingVersion
Var IsUpdate
Var Port
Var PortControl
Var AdminName
Var AdminNameControl
Var AdminEmail
Var AdminEmailControl
Var AdminPassword
Var AdminPasswordControl
Var ShowPasswordControl

!macro TestLog Message
!ifdef TEST_MODE
  FileOpen $9 "$DataDir\installer-test.log" a
  FileSeek $9 0 END
  FileWriteUTF16LE $9 "${Message}$\r$\n"
  FileClose $9
!endif
!macroend

Function .onInit
  SetRegView 64
!ifdef TEST_MODE
  StrCpy $DataDir "${TEST_DATA_DIR}"
  StrCpy $Port "${TEST_PORT}"
  StrCpy $AdminName "Installer Testadmin"
  StrCpy $AdminEmail "installer-test@example.invalid"
  StrCpy $AdminPassword "Installer-Test-2026!"
  System::Call 'Kernel32::SetEnvironmentVariableW(w "BUDGETWELT_DATA_DIR", w "$DataDir")'
!else
  ReadEnvStr $DataDir "ProgramData"
  StrCpy $DataDir "$DataDir\Meine Budgetwelt Server"
  StrCpy $Port "48732"
  StrCpy $AdminName "Administrator"
!endif
  StrCpy $IsUpdate "0"
  StrCpy $AppDir "$INSTDIR\app"
  StrCpy $PreviousAppDir "$INSTDIR\app.previous"

  ReadRegStr $ExistingVersion HKLM "${UNINSTALL_KEY}" "DisplayVersion"
  StrCmp $ExistingVersion "" check_existing_exe
  ${VersionCompare} "$ExistingVersion" "${SERVER_VERSION}" $0
  StrCmp $0 "1" downgrade_prompt
  StrCpy $IsUpdate "1"
  ReadRegStr $0 HKLM "${PRODUCT_KEY}" "Port"
  StrCmp $0 "" +2
  StrCpy $Port $0
  Goto init_extract_checker

downgrade_prompt:
  MessageBox MB_YESNO|MB_ICONEXCLAMATION \
    "Eine neuere Serverversion ($ExistingVersion) ist bereits installiert.$\r$\n$\r$\nMöchten Sie wirklich die ältere Version ${SERVER_VERSION} installieren?" \
    /SD IDNO IDYES downgrade_accepted
  SetErrorLevel 1
  Abort
downgrade_accepted:
  StrCpy $IsUpdate "1"
  ReadRegStr $0 HKLM "${PRODUCT_KEY}" "Port"
  StrCmp $0 "" +2
  StrCpy $Port $0
  Goto init_extract_checker

check_existing_exe:
  IfFileExists "$AppDir\Meine-Budgetwelt-Server.exe" 0 init_extract_checker
  StrCpy $IsUpdate "1"

init_extract_checker:
  InitPluginsDir
  SetOutPath "$PLUGINSDIR"
  File "/oname=Meine-Budgetwelt-Portpruefung.exe" \
    "${SERVER_PAYLOAD}\Meine-Budgetwelt-Server.exe"
FunctionEnd

Function PortPageCreate
  StrCmp $IsUpdate "1" port_page_skip
  !insertmacro MUI_HEADER_TEXT "Lokaler Serverport" \
    "Der Dienst bleibt ausschließlich auf diesem Server erreichbar."
  nsDialogs::Create 1018
  Pop $0
  ${If} $0 == error
    Abort
  ${EndIf}
  ${NSD_CreateLabel} 0 0 100% 28u \
    "Caddy verbindet sich später intern mit diesem Port. Es wird keine Firewallfreigabe angelegt."
  Pop $0
  ${NSD_CreateLabel} 0 38u 38% 12u "Port (1024 bis 65535):"
  Pop $0
  ${NSD_CreateNumber} 40% 34u 28% 14u "$Port"
  Pop $PortControl
  SendMessage $PortControl ${EM_SETLIMITTEXT} 5 0
  nsDialogs::Show
  Return

port_page_skip:
  Abort
FunctionEnd

Function PortPageLeave
  ${NSD_GetText} $PortControl $Port
  IntCmp $Port 1024 port_minimum_ok port_too_low port_minimum_ok
port_too_low:
  MessageBox MB_OK|MB_ICONEXCLAMATION \
    "Bitte verwenden Sie einen Port zwischen 1024 und 65535." /SD IDOK
  Abort
port_minimum_ok:
  IntCmp $Port 65535 port_range_ok port_range_ok port_too_high
port_too_high:
  MessageBox MB_OK|MB_ICONEXCLAMATION \
    "Bitte verwenden Sie einen Port zwischen 1024 und 65535." /SD IDOK
  Abort
port_range_ok:
  nsExec::ExecToLog \
    '$\"$PLUGINSDIR\Meine-Budgetwelt-Portpruefung.exe$\" check-port --port $Port'
  Pop $0
  StrCmp $0 "0" port_available
  MessageBox MB_OK|MB_ICONSTOP \
    "Der Port $Port ist bereits belegt. Bitte wählen Sie einen anderen Port." /SD IDOK
  Abort
port_available:
FunctionEnd

Function AdminPageCreate
  StrCmp $IsUpdate "1" admin_page_skip
  !insertmacro MUI_HEADER_TEXT "Erstes Administratorkonto" \
    "Dieses Konto verwaltet später Benutzer und gemeinsame Budgetgruppen."
  nsDialogs::Create 1018
  Pop $0
  ${If} $0 == error
    Abort
  ${EndIf}
  ${NSD_CreateLabel} 0 0 28% 12u "Name:"
  Pop $0
  ${NSD_CreateText} 30% -2u 70% 14u "$AdminName"
  Pop $AdminNameControl
  ${NSD_CreateLabel} 0 26u 28% 12u "E-Mail:"
  Pop $0
  ${NSD_CreateText} 30% 24u 70% 14u "$AdminEmail"
  Pop $AdminEmailControl
  ${NSD_CreateLabel} 0 52u 28% 12u "Kennwort:"
  Pop $0
  ${NSD_CreatePassword} 30% 50u 70% 14u "$AdminPassword"
  Pop $AdminPasswordControl
  ${NSD_CreateCheckbox} 30% 72u 70% 12u "Kennwort anzeigen"
  Pop $ShowPasswordControl
  ${NSD_OnClick} $ShowPasswordControl ToggleAdminPassword
  ${NSD_CreateLabel} 30% 90u 70% 26u \
    "Mindestens 8 Zeichen. Das Kennwort erscheint weder im Setup-Protokoll noch in der Befehlszeile."
  Pop $0
  nsDialogs::Show
  Return

admin_page_skip:
  Abort
FunctionEnd

Function ToggleAdminPassword
  ${NSD_GetState} $ShowPasswordControl $0
  ${If} $0 == ${BST_CHECKED}
    SendMessage $AdminPasswordControl ${EM_SETPASSWORDCHAR} 0 0
  ${Else}
    SendMessage $AdminPasswordControl ${EM_SETPASSWORDCHAR} 0x25CF 0
  ${EndIf}
  System::Call 'user32::InvalidateRect(p $AdminPasswordControl, p 0, i 1)'
FunctionEnd

Function AdminPageLeave
  ${NSD_GetText} $AdminNameControl $AdminName
  ${NSD_GetText} $AdminEmailControl $AdminEmail
  ${NSD_GetText} $AdminPasswordControl $AdminPassword
  StrCmp $AdminName "" admin_invalid
  StrCmp $AdminEmail "" admin_invalid
  StrLen $0 $AdminPassword
  IntCmp $0 8 admin_password_ok admin_invalid admin_password_ok
admin_password_ok:
  ${StrStr} $0 $AdminEmail "@"
  StrCmp $0 "" admin_invalid
  ${StrStr} $0 $AdminName '$\"'
  StrCmp $0 "" +2
  Goto admin_unsafe_character
  ${StrStr} $0 $AdminEmail '$\"'
  StrCmp $0 "" admin_valid
admin_unsafe_character:
  MessageBox MB_OK|MB_ICONEXCLAMATION \
    'Name und E-Mail dürfen kein Anführungszeichen enthalten.' /SD IDOK
  Abort
admin_invalid:
  MessageBox MB_OK|MB_ICONEXCLAMATION \
    "Bitte geben Sie Name, eine gültige E-Mail-Adresse und ein Kennwort mit mindestens 8 Zeichen ein." /SD IDOK
  Abort
admin_valid:
FunctionEnd

Function StopInstalledService
  nsExec::ExecToLog '$\"$SYSDIR\sc.exe$\" stop ${SERVICE_NAME}'
  Pop $0
  Sleep 2500
FunctionEnd

Section "Meine Budgetwelt Server" CoreSection
  SectionIn RO
  SetRegView 64
  SetShellVarContext all
  StrCmp $IsUpdate "1" prepare_update install_payload

prepare_update:
  Call StopInstalledService
  IfFileExists "$AppDir\Meine-Budgetwelt-Server.exe" 0 install_payload
  nsExec::ExecToLog '$\"$AppDir\Meine-Budgetwelt-Server.exe$\" backup'
  Pop $0
  StrCmp $0 "0" backup_ok
  MessageBox MB_OK|MB_ICONSTOP \
    "Die Serversicherung vor dem Update ist fehlgeschlagen. Das Setup wurde abgebrochen." /SD IDOK
  SetErrorLevel 1
  Abort
backup_ok:
  RMDir /r "$PreviousAppDir"
  Rename "$AppDir" "$PreviousAppDir"
  IfErrors 0 install_payload
  MessageBox MB_OK|MB_ICONSTOP \
    "Der Serverdienst konnte nicht vollständig beendet werden. Bitte versuchen Sie es erneut." /SD IDOK
  SetErrorLevel 1
  Abort

install_payload:
  SetOutPath "$AppDir"
  File /r "${SERVER_PAYLOAD}\*.*"
  CreateDirectory "$DataDir\data"
  CreateDirectory "$DataDir\backups"
  CreateDirectory "$DataDir\logs"
!ifdef TEST_MODE
  System::Call 'Kernel32::SetEnvironmentVariableW(w "BUDGETWELT_DATA_DIR", w "$DataDir")'
!endif
  nsExec::ExecToLog \
    '$\"$AppDir\Meine-Budgetwelt-Server.exe$\" initialize-config --port $Port'
  Pop $0
  !insertmacro TestLog "Konfiguration: Exitcode $0"
  StrCmp $0 "0" configuration_ready
  MessageBox MB_OK|MB_ICONSTOP \
    "Die Serverkonfiguration konnte nicht sicher angelegt werden." /SD IDOK
  SetErrorLevel 1
  Abort
configuration_ready:

  nsExec::ExecToLog \
    '$\"$SYSDIR\icacls.exe$\" $\"$DataDir$\" /grant *S-1-5-19:(OI)(CI)M /T /C'
  Pop $0
  !insertmacro TestLog "Datenrechte: Exitcode $0"
  StrCmp $0 "0" data_permissions_ok
  MessageBox MB_OK|MB_ICONSTOP \
    "Die Schreibrechte für das Server-Datenverzeichnis konnten nicht gesetzt werden." /SD IDOK
  SetErrorLevel 1
  Abort
data_permissions_ok:

  nsExec::ExecToStack '$\"$SYSDIR\sc.exe$\" query ${SERVICE_NAME}'
  Pop $0
  Pop $1
  StrCmp $0 "0" service_exists
  nsExec::ExecToLog \
    '"$SYSDIR\sc.exe" create ${SERVICE_NAME} binPath= "$AppDir\Meine-Budgetwelt-Server.exe" start= auto obj= "NT AUTHORITY\LocalService" DisplayName= "Meine Budgetwelt Server"'
  Pop $0
  !insertmacro TestLog "Dienstanlage: Exitcode $0"
  StrCmp $0 "0" service_exists
  Goto install_rollback
service_exists:
  WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\${SERVICE_NAME}" "ImagePath" \
    '$\"$AppDir\Meine-Budgetwelt-Server.exe$\"'
!ifdef TEST_MODE
  nsExec::ExecToLog \
    '"$SYSDIR\reg.exe" add "HKLM\SYSTEM\CurrentControlSet\Services\${SERVICE_NAME}" /v Environment /t REG_MULTI_SZ /d "BUDGETWELT_DATA_DIR=$DataDir" /f'
  Pop $0
  !insertmacro TestLog "Dienstumgebung: Exitcode $0"
  StrCmp $0 "0" test_service_environment_ready
  Goto install_rollback
test_service_environment_ready:
!endif
  nsExec::ExecToLog \
    '$\"$SYSDIR\sc.exe$\" description ${SERVICE_NAME} $\"Synchronisiert Meine Budgetwelt sicher zwischen Desktop und PWA.$\"'
  Pop $0
  nsExec::ExecToLog \
    '$\"$SYSDIR\sc.exe$\" failure ${SERVICE_NAME} reset= 86400 actions= restart/5000/restart/15000/$\"$\"/0'
  Pop $0
  nsExec::ExecToLog \
    '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -ExecutionPolicy RemoteSigned -File "$AppDir\updater\Install-ServerUpdateTask.ps1" -UpdaterScript "$AppDir\updater\ServerUpdate.ps1" -TaskName "${UPDATE_TASK_NAME}"'
  Pop $0
  !insertmacro TestLog "Updateaufgabe: Exitcode $0"
  StrCmp $0 "0" update_task_ready
  Goto install_rollback
update_task_ready:
  StrCmp $IsUpdate "1" start_service create_first_admin

create_first_admin:
  System::Call 'Kernel32::SetEnvironmentVariableW(w "BUDGETWELT_BOOTSTRAP_PASSWORD", w "$AdminPassword") i.r0'
  StrCmp $0 "0" bootstrap_failed
  nsExec::ExecToLog \
    '$\"$AppDir\Meine-Budgetwelt-Server.exe$\" bootstrap-admin --name $\"$AdminName$\" --email $\"$AdminEmail$\"'
  Pop $1
  !insertmacro TestLog "Adminanlage: Exitcode $1"
  System::Call 'Kernel32::SetEnvironmentVariableW(w "BUDGETWELT_BOOTSTRAP_PASSWORD", w 0)'
  StrCpy $AdminPassword ""
  StrCmp $1 "0" start_service
bootstrap_failed:
  System::Call 'Kernel32::SetEnvironmentVariableW(w "BUDGETWELT_BOOTSTRAP_PASSWORD", w 0)'
  StrCpy $AdminPassword ""
  Goto install_rollback

start_service:
  nsExec::ExecToLog '$\"$SYSDIR\sc.exe$\" start ${SERVICE_NAME}'
  Pop $0
  !insertmacro TestLog "Dienststart: Exitcode $0"
  StrCpy $2 "0"
health_retry:
  IntOp $2 $2 + 1
  Sleep 1000
  nsExec::ExecToLog \
    '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -Command "& { try { Invoke-WebRequest -UseBasicParsing -Uri http://127.0.0.1:$Port/health -TimeoutSec 3 -ErrorAction Stop | Out-Null; exit 0 } catch { exit 1 } }"'
  Pop $0
  !insertmacro TestLog "Healthcheck $2: Exitcode $0"
  StrCmp $0 "0" install_planning_model
  IntCmp $2 15 install_rollback health_retry install_rollback

install_planning_model:
!ifdef TEST_MODE
  Goto install_success
!else
  DetailPrint "Schnelles kostenloses KI-Planungsmodell wird geprüft ..."
  nsExec::ExecToLog \
    '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -ExecutionPolicy RemoteSigned -File "$AppDir\tools\Install-PlanningModel.ps1" -SkipConfiguration'
  Pop $0
  StrCmp $0 "0" install_success planning_model_warning
planning_model_warning:
  MessageBox MB_OK|MB_ICONEXCLAMATION \
    "Der Server wurde aktualisiert, aber das schnelle KI-Planungsmodell konnte noch nicht installiert werden.$\r$\n$\r$\nStarten Sie das Setup erneut, sobald Ollama erreichbar ist." /SD IDOK
  Goto install_success
!endif

install_rollback:
  nsExec::ExecToLog '$\"$SYSDIR\sc.exe$\" stop ${SERVICE_NAME}'
  Pop $0
  Sleep 1500
  nsExec::ExecToLog \
    '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -ExecutionPolicy RemoteSigned -File "$AppDir\updater\Install-ServerUpdateTask.ps1" -UpdaterScript "$AppDir\updater\ServerUpdate.ps1" -TaskName "${UPDATE_TASK_NAME}" -Uninstall'
  Pop $0
  IfFileExists "$PreviousAppDir\Meine-Budgetwelt-Server.exe" 0 rollback_new_install
  RMDir /r "$AppDir"
  Rename "$PreviousAppDir" "$AppDir"
  WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\${SERVICE_NAME}" "ImagePath" \
    '$\"$AppDir\Meine-Budgetwelt-Server.exe$\"'
  nsExec::ExecToLog \
    '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -ExecutionPolicy RemoteSigned -File "$AppDir\updater\Install-ServerUpdateTask.ps1" -UpdaterScript "$AppDir\updater\ServerUpdate.ps1" -TaskName "${UPDATE_TASK_NAME}"'
  Pop $0
  nsExec::ExecToLog '$\"$SYSDIR\sc.exe$\" start ${SERVICE_NAME}'
  Pop $0
  Goto rollback_message
rollback_new_install:
  nsExec::ExecToLog '$\"$SYSDIR\sc.exe$\" delete ${SERVICE_NAME}'
  Pop $0
  RMDir /r "$AppDir"
rollback_message:
  MessageBox MB_OK|MB_ICONSTOP \
    "Der Server konnte nicht gesund gestartet werden. Eine vorhandene Programmversion wurde soweit möglich wiederhergestellt; persönliche Daten wurden nicht gelöscht." /SD IDOK
  SetErrorLevel 1
  Abort

install_success:
  RMDir /r "$PreviousAppDir"
  WriteUninstaller "$INSTDIR\Meine-Budgetwelt-Server-deinstallieren.exe"
!ifndef TEST_MODE
  CreateDirectory "$SMPROGRAMS\Meine Budgetwelt Server"
  CreateShortcut "$SMPROGRAMS\Meine Budgetwelt Server\Meine Budgetwelt öffnen.lnk" \
    "$SYSDIR\rundll32.exe" "url.dll,FileProtocolHandler http://127.0.0.1:$Port/admin/"
  CreateShortcut "$SMPROGRAMS\Meine Budgetwelt Server\Server deinstallieren.lnk" \
    "$INSTDIR\Meine-Budgetwelt-Server-deinstallieren.exe"
!endif

  WriteRegStr HKLM "${PRODUCT_KEY}" "InstallDir" "$INSTDIR"
  WriteRegStr HKLM "${PRODUCT_KEY}" "DataDir" "$DataDir"
  WriteRegStr HKLM "${PRODUCT_KEY}" "Port" "$Port"
  WriteRegStr HKLM "${UNINSTALL_KEY}" "DisplayName" "Meine Budgetwelt Server"
  WriteRegStr HKLM "${UNINSTALL_KEY}" "DisplayVersion" "${SERVER_VERSION}"
  WriteRegStr HKLM "${UNINSTALL_KEY}" "Publisher" "Meine Budgetwelt"
  WriteRegStr HKLM "${UNINSTALL_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "${UNINSTALL_KEY}" "DisplayIcon" "$AppDir\Meine-Budgetwelt-Server.exe"
  WriteRegStr HKLM "${UNINSTALL_KEY}" "UninstallString" \
    "$\"$INSTDIR\Meine-Budgetwelt-Server-deinstallieren.exe$\""
  WriteRegDWORD HKLM "${UNINSTALL_KEY}" "NoModify" 1
  WriteRegDWORD HKLM "${UNINSTALL_KEY}" "NoRepair" 1
SectionEnd

Section "Uninstall"
  SetRegView 64
  SetShellVarContext all
  StrCpy $AppDir "$INSTDIR\app"
!ifdef TEST_MODE
  StrCpy $DataDir "${TEST_DATA_DIR}"
!else
  ReadEnvStr $DataDir "ProgramData"
  StrCpy $DataDir "$DataDir\Meine Budgetwelt Server"
!endif
  nsExec::ExecToLog \
    '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -ExecutionPolicy RemoteSigned -File "$AppDir\updater\Install-ServerUpdateTask.ps1" -UpdaterScript "$AppDir\updater\ServerUpdate.ps1" -TaskName "${UPDATE_TASK_NAME}" -Uninstall'
  Pop $0
  nsExec::ExecToLog '$\"$SYSDIR\sc.exe$\" stop ${SERVICE_NAME}'
  Pop $0
  Sleep 1500
  nsExec::ExecToLog '$\"$SYSDIR\sc.exe$\" delete ${SERVICE_NAME}'
  Pop $0
!ifndef TEST_MODE
  Delete "$SMPROGRAMS\Meine Budgetwelt Server\Meine Budgetwelt öffnen.lnk"
  Delete "$SMPROGRAMS\Meine Budgetwelt Server\Server deinstallieren.lnk"
  RMDir "$SMPROGRAMS\Meine Budgetwelt Server"
!endif
  RMDir /r "$INSTDIR"
  DeleteRegKey HKLM "${UNINSTALL_KEY}"
  DeleteRegKey HKLM "${PRODUCT_KEY}"
  MessageBox MB_OK|MB_ICONINFORMATION \
    "Der Serverdienst wurde entfernt. Datenbank, Konfiguration und Sicherungen unter $DataDir wurden aus Sicherheitsgründen nicht gelöscht." /SD IDOK
SectionEnd
