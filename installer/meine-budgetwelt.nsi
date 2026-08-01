Unicode True

!ifndef APP_VERSION
  !error "APP_VERSION fehlt."
!endif
!ifndef APP_EXE
  !error "APP_EXE fehlt."
!endif
!ifndef OUTPUT_FILE
  !error "OUTPUT_FILE fehlt."
!endif

!include "MUI2.nsh"
!include "WordFunc.nsh"

Name "Meine Budgetwelt"
OutFile "${OUTPUT_FILE}"
InstallDir "$LOCALAPPDATA\Programs\Meine Budgetwelt"
InstallDirRegKey HKCU "Software\Meine Budgetwelt" "InstallDir"
RequestExecutionLevel user
SetCompressor /SOLID lzma
SetCompressorDictSize 32
CRCCheck on
ShowInstDetails nevershow
ShowUninstDetails nevershow

VIProductVersion "${APP_VERSION}.0"
VIAddVersionKey /LANG=1031 "ProductName" "Meine Budgetwelt"
VIAddVersionKey /LANG=1031 "FileDescription" "Meine Budgetwelt Setup"
VIAddVersionKey /LANG=1031 "FileVersion" "${APP_VERSION}"
VIAddVersionKey /LANG=1031 "ProductVersion" "${APP_VERSION}"
VIAddVersionKey /LANG=1031 "LegalCopyright" "Copyright 2026"

!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\Meine-Budgetwelt.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Meine Budgetwelt starten"
!define MUI_FINISHPAGE_NOAUTOCLOSE

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "German"

Var ExistingVersion
Var PreviousExecutable

Function .onInit
  ReadRegStr $ExistingVersion HKCU \
    "Software\Microsoft\Windows\CurrentVersion\Uninstall\MeineBudgetwelt" \
    "DisplayVersion"
  StrCmp $ExistingVersion "" init_done
  StrCmp $ExistingVersion "${APP_VERSION}" repair_prompt compare_versions

compare_versions:
  ${VersionCompare} "$ExistingVersion" "${APP_VERSION}" $0
  StrCmp $0 "1" downgrade_prompt update_prompt

repair_prompt:
  MessageBox MB_YESNO|MB_ICONQUESTION \
    "Meine Budgetwelt ${APP_VERSION} ist bereits installiert.$\r$\n$\r$\nMöchten Sie die Installation jetzt reparieren? Ihre persönlichen Daten bleiben erhalten." \
    /SD IDYES IDYES init_done
  SetErrorLevel 1
  Abort

downgrade_prompt:
  MessageBox MB_YESNO|MB_ICONEXCLAMATION \
    "Eine neuere Version ($ExistingVersion) ist bereits installiert.$\r$\n$\r$\nMöchten Sie wirklich die ältere Version ${APP_VERSION} installieren?" \
    /SD IDNO IDYES init_done
  SetErrorLevel 1
  Abort

update_prompt:
  MessageBox MB_OKCANCEL|MB_ICONINFORMATION \
    "Meine Budgetwelt $ExistingVersion wird auf Version ${APP_VERSION} aktualisiert.$\r$\n$\r$\nIhre persönlichen Daten bleiben erhalten. Die bisherige Programmdatei wird bis zum erfolgreichen Abschluss als Rückfallkopie gesichert." \
    /SD IDOK IDOK init_done
  SetErrorLevel 1
  Abort

init_done:
FunctionEnd

Section "Meine Budgetwelt" CoreSection
  SectionIn RO
  SetShellVarContext current
  SetOutPath "$INSTDIR"

  StrCpy $PreviousExecutable "$INSTDIR\Meine-Budgetwelt.exe.previous"
  Delete "$PreviousExecutable"
  IfFileExists "$INSTDIR\Meine-Budgetwelt.exe" 0 install_new_executable
  ClearErrors
  Rename "$INSTDIR\Meine-Budgetwelt.exe" "$PreviousExecutable"
  IfErrors 0 install_new_executable
  MessageBox MB_OK|MB_ICONSTOP \
    "Die laufende Anwendung konnte nicht für das Update geschlossen werden.$\r$\n$\r$\nBitte schließen Sie Meine Budgetwelt und starten Sie das Setup erneut." \
    /SD IDOK
  SetErrorLevel 1
  Abort

install_new_executable:
  ClearErrors
!ifdef TEST_FORCE_INSTALL_FAILURE
  SetErrors
!else
  File "/oname=Meine-Budgetwelt.exe" "${APP_EXE}"
!endif
  IfErrors 0 executable_installed
  Delete "$INSTDIR\Meine-Budgetwelt.exe"
  IfFileExists "$PreviousExecutable" 0 rollback_finished
  Rename "$PreviousExecutable" "$INSTDIR\Meine-Budgetwelt.exe"

rollback_finished:
  MessageBox MB_OK|MB_ICONSTOP \
    "Die neue Programmversion konnte nicht installiert werden. Die bisherige Version wurde soweit möglich wiederhergestellt." \
    /SD IDOK
  SetErrorLevel 1
  Abort

executable_installed:

  WriteUninstaller "$INSTDIR\Meine-Budgetwelt-deinstallieren.exe"
  CreateDirectory "$SMPROGRAMS\Meine Budgetwelt"
  CreateShortcut "$SMPROGRAMS\Meine Budgetwelt\Meine Budgetwelt.lnk" \
    "$INSTDIR\Meine-Budgetwelt.exe"
  CreateShortcut "$SMPROGRAMS\Meine Budgetwelt\Meine Budgetwelt deinstallieren.lnk" \
    "$INSTDIR\Meine-Budgetwelt-deinstallieren.exe"

  WriteRegStr HKCU "Software\Meine Budgetwelt" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU \
    "Software\Microsoft\Windows\CurrentVersion\Uninstall\MeineBudgetwelt" \
    "DisplayName" "Meine Budgetwelt"
  WriteRegStr HKCU \
    "Software\Microsoft\Windows\CurrentVersion\Uninstall\MeineBudgetwelt" \
    "DisplayVersion" "${APP_VERSION}"
  WriteRegStr HKCU \
    "Software\Microsoft\Windows\CurrentVersion\Uninstall\MeineBudgetwelt" \
    "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU \
    "Software\Microsoft\Windows\CurrentVersion\Uninstall\MeineBudgetwelt" \
    "DisplayIcon" "$INSTDIR\Meine-Budgetwelt.exe"
  WriteRegStr HKCU \
    "Software\Microsoft\Windows\CurrentVersion\Uninstall\MeineBudgetwelt" \
    "UninstallString" "$\"$INSTDIR\Meine-Budgetwelt-deinstallieren.exe$\""
  WriteRegDWORD HKCU \
    "Software\Microsoft\Windows\CurrentVersion\Uninstall\MeineBudgetwelt" \
    "NoModify" 1
  WriteRegDWORD HKCU \
    "Software\Microsoft\Windows\CurrentVersion\Uninstall\MeineBudgetwelt" \
    "NoRepair" 1
  Delete "$PreviousExecutable"
SectionEnd

Section /o "Desktopverknüpfung" DesktopSection
  SetShellVarContext current
  CreateShortcut "$DESKTOP\Meine Budgetwelt.lnk" "$INSTDIR\Meine-Budgetwelt.exe"
SectionEnd

LangString DESC_CoreSection ${LANG_GERMAN} \
  "Installiert Meine Budgetwelt für das aktuelle Windows-Benutzerkonto."
LangString DESC_DesktopSection ${LANG_GERMAN} \
  "Legt zusätzlich eine Verknüpfung auf dem Desktop an."

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${CoreSection} $(DESC_CoreSection)
  !insertmacro MUI_DESCRIPTION_TEXT ${DesktopSection} $(DESC_DesktopSection)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

Section "Uninstall"
  SetShellVarContext current
  Delete "$DESKTOP\Meine Budgetwelt.lnk"
  Delete "$SMPROGRAMS\Meine Budgetwelt\Meine Budgetwelt.lnk"
  Delete "$SMPROGRAMS\Meine Budgetwelt\Meine Budgetwelt deinstallieren.lnk"
  RMDir "$SMPROGRAMS\Meine Budgetwelt"

  Delete "$INSTDIR\Meine-Budgetwelt.exe"
  Delete "$INSTDIR\Meine-Budgetwelt.exe.previous"
  Delete "$INSTDIR\Meine-Budgetwelt-deinstallieren.exe"
  RMDir "$INSTDIR"

  DeleteRegKey HKCU \
    "Software\Microsoft\Windows\CurrentVersion\Uninstall\MeineBudgetwelt"
  DeleteRegKey HKCU "Software\Meine Budgetwelt"

  MessageBox MB_OK|MB_ICONINFORMATION \
    "Meine Budgetwelt wurde deinstalliert.$\r$\n$\r$\nIhre persönlichen Budgetdaten und Sicherungen wurden nicht gelöscht." \
    /SD IDOK
SectionEnd
