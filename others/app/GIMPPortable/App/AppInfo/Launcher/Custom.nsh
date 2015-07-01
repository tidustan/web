${SegmentFile}

!addincludedir "${PACKAGE}\App\AppInfo\Launcher"
!include ReadINIStrWithDefault.nsh

Var EXISTSTHUMBNAILS
Var EXISTSFONTSCACHE
Var EXISTSGTKBOOKMARKS
Var EXISTSFONTCONFIG
Var EXISTSFILECHOOSER
Var EXISTSGEGL
Var USERPROFILE
Var RENAMEDINCOMPATIBLEFILES
Var AUTOFIXINCOMPATIBLEFILES
Var GTKDIRECTORY
Var CustomBits
Var GSMode
Var GSDirectory
Var GSRegExists
Var GSExecutable

Function _Ghostscript_ValidateInstall
	${If} $Bits = 64
		${If} ${FileExists} $GSDirectory\bin\gswin64c.exe
			StrCpy $GSExecutable $GSDirectory\bin\gswin64c.exe
			;${DebugMsg} "Found valid 64-bit Ghostscript install at $GSDirectory."
			StrCpy $R8 "Found valid 64-bit Ghostscript install at $GSDirectory."
			Push true
			Goto End
		${Else}
			;${DebugMsg} "64-bit Windows but gswin64c.exe not found; trying gswin32c.exe instead."
			StrCpy $R8 "64-bit Windows but gswin64c.exe not found; trying gswin32c.exe instead.$\r$\n"
		${EndIf}
	${EndIf}

	${IfNot} ${FileExists} $GSDirectory\bin\gswin32c.exe
		StrCpy $GSDirectory ""
		StrCpy $GSExecutable ""
		;${DebugMsg} "No valid Ghostscript install found at $GSDirectory."
		StrCpy $R8 "$R8No valid Ghostscript install found at $GSDirectory."
		Push false
		Goto End
	${EndIf}

	StrCpy $GSExecutable $GSDirectory\bin\gswin32c.exe
	;${DebugMsg} "Found valid 32-bit Ghostscript install at $GSDirectory."
	StrCpy $R8 "$R8Found valid 32-bit Ghostscript install at $GSDirectory."
	Push true
	Goto End

	End:
FunctionEnd
!macro _Ghostscript_ValidateInstall _a _b _t _f
	!insertmacro _LOGICLIB_TEMP
	;${DebugMsg} "Checking for Ghostscript in $GSDirectory..."
	;${DebugMsg} `$R8`
	Call _Ghostscript_ValidateInstall
	Pop $_LOGICLIB_TEMP
	!insertmacro _== $_LOGICLIB_TEMP true `${_t}` `${_f}`
!macroend
!define IsValidGhostscriptInstall `"" Ghostscript_ValidateInstall ""`

${Segment.OnInit}
	; Borrowed the following from PAL 2.2, Remove on release of PAL 2.2
		; Work out if it's 64-bit or 32-bit
	System::Call kernel32::GetCurrentProcess()i.s
	System::Call kernel32::IsWow64Process(is,*i.r0)
	${If} $0 == 0
		StrCpy $Bits 32
	${Else}
		StrCpy $Bits 64
	${EndIf}
	
	StrCpy $0 $Bits
	${SetEnvironmentVariable} CustomBits $0
!macroend

${SegmentInit}

	${ReadINIStrWithDefault} $AUTOFIXINCOMPATIBLEFILES "%PAL:DataDir%\settings\GIMPPortableTestSettings" "GIMPPortableTestSettings" "AutofixIncompatibleFiles" "false"
	
	IfFileExists "$PAL:AppDir\GIMP\bin\libgtk-win32*.*" "" GTKSeparate
		StrCpy $GTKDIRECTORY "NONE"
			Goto EndINI

	GTKSeparate:
		IfFileExists "$PAL:AppDir\gtk\bin\*.*" "" GTKCommonFiles
			StrCpy $GTKDIRECTORY "$PAL:AppDir\gtk"
			Goto EndINI

	GTKCommonFiles:
			StrCpy $GTKDIRECTORY "$PortableAppsDirectory\CommonFiles\GTK"
			GoTo EndINI
	
	EndINI:


	;=== Check for incompatible files and fix, if desired
	IfFileExists "$WINDIR\system32\xmlparse.dll" IncompatibleFilesFound
	IfFileExists "$WINDIR\system32\xmltok.dll" IncompatibleFilesFound
	IfFileExists "$WINDIR\system\xmlparse.dll" IncompatibleFilesFound
	IfFileExists "$WINDIR\system\xmltok.dll" IncompatibleFilesFound
	Goto IncompatibleFilesHandled
		
	IncompatibleFilesFound:
		StrCmp $AUTOFIXINCOMPATIBLEFILES "true" FixIncompatibleFiles
		MessageBox MB_YESNO|MB_ICONQUESTION `Some files (xmlparse.dll, xmltok.dll) were found on this PC that are incompatible with GIMP Portable (Test).  Would you like to temporariliy disable these files while GIMP Portable (Test) is running?` IDYES FixIncompatibleFiles
		MessageBox MB_YESNO|MB_ICONQUESTION `Without disabling these files, GIMP Portable (Test) may fail to work correctly.  Would you like to continue using GIMP Portable (Test) anyway?` IDYES IncompatibleFilesHandled
		Abort
		
	FixIncompatibleFiles:
		Rename "$WINDIR\system32\xmlparse.dll" "$WINDIR\system32\xmlparse.dll.disabled"
		Rename "$WINDIR\system32\xmltok.dll" "$WINDIR\system32\xmltok.dll.disabled"
		Rename "$WINDIR\system\xmlparse.dll" "$WINDIR\system\xmlparse.dll.disabled"
		Rename "$WINDIR\system\xmltok.dll" "$WINDIR\system\xmltok.dll.disabled"
		StrCpy $RENAMEDINCOMPATIBLEFILES "true"

	IncompatibleFilesHandled:
	
	;Check for extraneous files
	CheckForUserProfileFolders:
		IfFileExists "$DOCUMENTS\gegl-0.0" 0 +2
			StrCpy $EXISTSGEGL "true"
		ReadEnvStr $USERPROFILE "USERPROFILE"
		IfFileExists "$USERPROFILE\.fonts.cache-1" 0 +2
			StrCpy $EXISTSFONTSCACHE "true"
		IfFileExists "$USERPROFILE\.gtk-bookmarks" 0 +2
			StrCpy $EXISTSGTKBOOKMARKS "true"
		IfFileExists "$USERPROFILE\.thumbnails\*.*" 0 +2
			StrCpy $EXISTSTHUMBNAILS "true"
		;IfFileExists "$TEMP\fontconfig\*.*" 0 CopyFontConfigLocally
		;	StrCpy $EXISTSFONTCONFIG "true"
		;	Goto CheckForFileChooser

		;CopyFontConfigLocally:
		;	CreateDirectory "$TEMP\fontconfig\cache\"
		;	CopyFiles /SILENT "$PAL:DataDir\.gimp\fontconfig\cache\*.*" "$TEMP\fontconfig\cache"

		CheckForFileChooser:
		IfFileExists "$APPDATA\gtk-2.0\gtkfilechooser.ini" 0 +2
			StrCpy $EXISTSFILECHOOSER "true"
!macroend

${SegmentPre}	
	; If [Activate]:Ghostscript=find|require, search for Ghostscript in the
	; following locations (in order):
	;
	;  - PortableApps.com CommonFiles (..\CommonFiles\Ghostscript)
	;  - GS_PROG (which will be $GSDirectory\bin\gswin(32|64)c.exe)
	;  - Anywhere in %PATH% (with SearchPath)
	;
	; If it's in none of those, give up. [Activate]:Ghostscript=require will
	; then abort, [Activate]:Ghostscript=find will not set it.
	ClearErrors
	${ReadLauncherConfig} $GSMode Activate Ghostscript
	${If} $GSMode == find
	${OrIf} $GSMode == require
		StrCpy $GSDirectory $PortableAppsDirectory\CommonFiles\Ghostscript
		${IfNot} ${IsValidGhostscriptInstall}
			ReadEnvStr $GSDirectory GS_PROG
			${GetParent} $GSDirectory $GSDirectory
			${GetParent} $GSDirectory $GSDirectory
			${IfNot} ${IsValidGhostscriptInstall}
				ClearErrors
				SearchPath $GSDirectory gswin32c.exe
				${GetParent} $GSDirectory $GSDirectory
				${GetParent} $GSDirectory $GSDirectory
				${IfNot} ${IsValidGhostscriptInstall}
					; If not valid, ${IsValidGhostscriptInstall} will clear
					; $GSDirectory for us.
					Nop
				${EndIf}
			${EndIf}
		${EndIf}

		; If Ghostscript is required and not found, quit
		${If} $GSMode == require
		${AndIf} $GSDirectory == ""
			MessageBox MB_OK|MB_ICONSTOP `$(LauncherNoGhostscript)`
			Quit
		${EndIf}

		; This may be created; check if it exists before: 0 = exists
		${registry::KeyExists} "HKCU\Software\GPL Ghostscript" $GSRegExists

		;${DebugMsg} "Selected Ghostscript path: $GSDirectory"
		;${DebugMsg} "Selected Ghostscript executable: $GSExecutable"
		ReadEnvStr $0 PATH
		StrCpy $0 "$0;$GSDirectory\bin"
		${SetEnvironmentVariablesPath} PATH $0
		${SetEnvironmentVariablesPath} GS_PROG $GSExecutable
	${ElseIfNot} ${Errors}
		${InvalidValueError} [Activate]:Ghostscript $GSMode
	${EndIf}
!macroend

${SegmentPost}
	; Ghostscript section
	${If} $GSRegExists != 0  ; Didn't exist before
	${AndIf} ${RegistryKeyExists} "HKCU\Software\GPL Ghostscript"
		${registry::DeleteKey} "HKCU\Software\GPL Ghostscript" $R9
	${EndIf}
	
	; Revert Incompatible Files
	StrCmp $RENAMEDINCOMPATIBLEFILES "true" "" SkipRename
	Rename "$WINDIR\system32\xmlparse.dll.disabled" "$WINDIR\system32\xmlparse.dll"
	Rename "$WINDIR\system32\xmltok.dll.disabled" "$WINDIR\system32\xmltok.dll"
	Rename "$WINDIR\system\xmlparse.dll.disabled" "$WINDIR\system\xmlparse.dll"
	Rename "$WINDIR\system\xmltok.dll.disabled" "$WINDIR\system\xmltok.dll"

	SkipRename:
	
    ; Delete existing extraneous files
	StrCmp $EXISTSFONTSCACHE "true" +2
		Delete "$USERPROFILE\.fonts.cache-1"
	StrCmp $EXISTSGTKBOOKMARKS "true" +2
		Delete "$USERPROFILE\.gtk-bookmarks"
	;StrCmp $EXISTSFONTCONFIG "true" +5
	;	Delete $PAL:DataDir\.gimp\fontconfig\cache\*.*
	;	CreateDirectory $PAL:DataDir\.gimp\fontconfig\cache
	;	CopyFiles /SILENT "$TEMP\fontconfig\cache\*.*" "$PAL:DataDir\.gimp\fontconfig\cache"
	;	RMDir /r "$TEMP\fontconfig\"
	StrCmp $EXISTSFILECHOOSER "true" TheRealEnd
		Delete "$APPDATA\gtk-2.0\gtkfilechooser.ini"
		RMDir "$APPDATA\gtk-2.0\"		

	TheRealEnd:
!macroend