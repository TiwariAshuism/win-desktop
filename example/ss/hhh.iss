; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "Flutter jsu"
#define MyAppVersion "1.5"
#define MyAppPublisher "FlutterJcu"
#define MyAppExeName "Q-neuro.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{82187DD1-7AF6-4A92-943D-038A512A6A91}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
; Remove the following line to run in administrative install mode (install for all users.)
PrivilegesRequired=lowest
OutputDir=C:\Users\ashut\StudioProjects\win_ble\example\ss
OutputBaseFilename=mysetup
SetupIconFile=C:\Users\ashut\StudioProjects\win_ble\example\windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "C:\Users\ashut\StudioProjects\win_ble\example\build\windows\x64\runner\Debug\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\ashut\StudioProjects\win_ble\example\build\windows\x64\runner\Debug\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\ashut\StudioProjects\win_ble\example\build\windows\x64\runner\Debug\Q-neuro.pdb"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\ashut\StudioProjects\win_ble\example\build\windows\x64\runner\Debug\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

