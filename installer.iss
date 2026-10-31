#define MyAppName "撷签"
#define MyAppVersion "1.0.6"
#define MyAppPublisher "XieQian"
#define MyAppExeName "XieQian.exe"

[Setup]
AppId={{16AD439B-0142-4C04-85FC-28C98CC55920}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\XieQian
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=installer-output
OutputBaseFilename=XieQian-Setup-{#MyAppVersion}
SetupIconFile=assets\app.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务："

[Files]
Source: "deploy\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
Name: "{group}\卸载 {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "运行 {#MyAppName}"; Flags: nowait postinstall skipifsilent

[Code]
var
  DataDirPage: TInputDirWizardPage;

procedure InitializeWizard;
begin
  // 在“选择目标位置”页之后，新增“选择数据目录”页
  DataDirPage := CreateInputDirPage(wpSelectDir,
    '选择数据存储位置', '您希望将名单和历史记录保存在哪里？',
    '如果您在学校机房使用（带有还原卡），请务必选择非系统盘（如 D:\ 或 E:\），否则重启后数据会丢失。',
    False, '');
  DataDirPage.Add('数据存储目录:');
  // 默认路径设为目标安装目录下的 Data 文件夹，或者默认的 AppData
  DataDirPage.Values[0] := ExpandConstant('{localappdata}\XieQian');
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // 安装完成后，将用户选择的路径写入当前用户的注册表
    RegWriteStringValue(HKCU, 'Software\XieQian', 'DataPath', DataDirPage.Values[0]);
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
  begin
    // 卸载时清理注册表，但不删除用户的数据文件（保护数据）
    RegDeleteKeyIfEmpty(HKCU, 'Software\XieQian');
  end;
end;
