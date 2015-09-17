;runhidden
;SW_HIDE
; X32
[Setup]
AppName=DCOS-CLI
AppVersion=0.1.13
AppId=dcos-cli
CreateAppDir=yes
DefaultDirName={pf}\dcos-cli
DisableProgramGroupPage=yes
DefaultGroupName=DCOS-CLI
WizardSmallImageFile="..\data\mesosphere.bmp"
WizardImageFile="..\data\mesosphere_side.bmp"
PrivilegesRequired=admin
ChangesEnvironment=yes
SetupIconFile="..\data\Setupicon.ico"

[Files]
Source: "PythonConf.exe"; DestDir: "{tmp}"
Source: "GitConf.exe"; DestDir: "{tmp}"
Source: "Installer.exe"; DestDir: "{tmp}"
Source: "DcosConf.exe"; DestDir: "{tmp}"
Source: "python-3.4.3.msi"; DestDir: "{tmp}"
Source: "python-2.7.10.msi"; DestDir: "{tmp}"
Source: "Git-2.5.1-32-bit.exe"; DestDir: "{tmp}"
Source: "dcoscli-0.1.13-py2.py3-none-any.whl"; DestDir: "{tmp}"
Source: "virtualenv-13.1.2-py2.py3-none-any.whl"; DestDir: "{tmp}"
Source: "pywin32-219.win32-py2.7.exe"; DestDir: "{tmp}"
Source: "pywin32-219.win32-py3.4.exe"; DestDir: "{tmp}"
Source: "msvcr100.dll"; DestDir: "{tmp}"

[Dirs]
Name: "{app}\bin"

[Icons]
Name: "{group}\Uninstall dcos-cli"; Filename: "{uninstallexe}"

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
Type: filesandordirs; Name: "{%USERPROFILE}\.dcos"

[Registry]
Root: HKCU; Subkey: "Software\dcos"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\dcos\Settings"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}";

[Code]
const
  cCheckBox = false;

var
  Page1: TInputQueryWizardPage;
  Page2: TInputQueryWizardPage;
  Page3: TInputQueryWizardPage;
  ProgressPage: TOutputProgressWizardPage;
  ProgressConf: TOutputProgressWizardPage;
  IsRegisteredUser: Boolean;
  PythonVersion: string;
  WasHere: boolean;
  WasConf: boolean;
  ConfigAgain: boolean;

procedure ExitProcess(exitCode:integer);
  external 'ExitProcess@kernel32.dll stdcall';

function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
  PathPr: String;
begin
  Result := RegkeyExists(HKCU, 'Software\dcos\Settings')
  if Result then
  begin
    RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\dcos-cli_is1', 'UninstallString', PathPr)
    if MsgBox('DCOS-CLI is already installed. Do you want to uninstall it?', mbConfirmation, MB_YESNO or MB_DEFBUTTON2) = IDYES then
    begin
      Exec(RemoveQuotes(PathPr), '', '', SW_SHOW, ewWaitUntilTerminated, ResultCode)    
      Result := False
    end
    else
      Result := False
  end
  else
  begin
    Result := True
  end;
end;

function IsPythonInstalled: boolean;
var
  test1: boolean;
  test2: boolean;
  test3: boolean;
  test4: boolean;
begin
  test1 := RegKeyExists(HKCU, 'Software\Python\PythonCore\2.7\InstallPath');
  test2 := RegKeyExists(HKCU, 'Software\Python\PythonCore\3.4\InstallPath');
  test3 := RegKeyExists(HKLM32, 'SOFTWARE\Python\PythonCore\2.7\InstallPath');
  test4 := RegKeyExists(HKLM32, 'SOFTWARE\Python\PythonCore\3.4\InstallPath');
  result := test1 or test2 or test3 or test4
end;

function IsGitInstalled: boolean;
var
  test: boolean;
begin
  test := RegKeyExists(HKLM32, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1');
  result := test
end;

function DcosConf: boolean;
var
  ResultCode: integer;
begin
  ExtractTemporaryFile('DcosConf.exe')
  Exec(ExpandConstant('{tmp}\DcosConf.exe'), ExpandConstant('"{code:Token}" "{code:Email}" "{app}\bin\Scripts"'), '', SW_HIDE, ewWaitUntilTerminated, ResultCode)
  if ResultCode = 1 then
    result := True
  else
    result := False;
end;

procedure CurPageChanged(CurPageID: Integer);
var
  I: Integer;
  ResultCode: Integer;
  Ptest: boolean;
  Gtest: boolean;
begin
   if CurPageID = 105 then
   begin
      Ptest := IsPythonInstalled
      Gtest := IsGitInstalled
      WizardForm.NextButton.Enabled := Ptest and Gtest
   end
   else if (CurPageID = 103) and (not WasHere) then
   begin
      ExtractTemporaryFile('PythonConf.exe')
      ExtractTemporaryFile('GitConf.exe')
      ExtractTemporaryFile('Installer.exe')
      WasHere := True
      ProgressPage.SetText('Starting Installation', '')
      ProgressPage.SetProgress(0, 0)
      ProgressPage.Show
      ProgressPage.SetText('Configuring Python', '')
      ProgressPage.SetProgress(3, 10)
      Exec(ExpandConstant('{tmp}\PythonConf.exe'), ExpandConstant('"{code:GetPythonV}"'), '', SW_HIDE, ewWaitUntilTerminated, ResultCode)
      ProgressPage.SetText('Configuring Git', '')
      ProgressPage.SetProgress(6, 10)
      Exec(ExpandConstant('{tmp}\GitConf.exe'), '', '', SW_HIDE, ewWaitUntilTerminated, ResultCode)
      try
        begin
          ProgressPage.SetText('Installing DCOS-CLI', '')
          ProgressPage.SetProgress(10, 10)
          Exec(ExpandConstant('{tmp}\Installer.exe'), ExpandConstant('"{app}\bin"  {code:GetParams} -wait'), '', SW_SHOW, ewWaitUntilTerminated, ResultCode)
        end;
      finally
        ProgressPage.Hide
      end
   end
   else if (CurPageID = 14) and (not WasConf) and (not ConfigAgain) then
   begin
      WasConf := True
      ProgressConf.SetText('Configuring DCOS-CLI', '')
      ProgressConf.SetProgress(0, 0)
      ProgressConf.Show
      ProgressConf.SetProgress(I, 10)
      DcosConf
      try
        while I <= 10 do 
        begin
          ProgressConf.SetProgress(I, 10)
          Sleep(50)
          I := I + 2;
        end;
      finally
        ProgressConf.Hide
   end
end;
end;

function ValidateEmail(strEmail : String) : boolean;
var
    strTemp  : String;
    nSpace   : Integer;
    nAt      : Integer;
    nDot     : Integer;
begin
    strEmail := Trim(strEmail);
    nSpace := Pos(' ', strEmail);
    nAt := Pos('@', strEmail);
    strTemp := Copy(strEmail, nAt + 1, Length(strEmail) - nAt + 1);
    nDot := Pos('.', strTemp) + nAt;
    Result := ((nSpace = 0) and (1 < nAt) and (nAt + 1 < nDot) and (nDot < Length(strEmail)));
end;



function NextButtonClick(CurPageID: Integer): Boolean;
var
  I: integer;
  isempty: boolean;
  email: boolean;
  IfToken: boolean;
 begin
   I := CurPageID
   if I = 102 then
   begin
     if Page1.Values[0] = '' then
     begin
        MsgBox('You must enter dcos_url!', mbError, MB_OK)
        Result := False
     end
     else
        Result := True;
   end
   else if I = 103 then
   begin
       isempty := Page2.Values[1] = ''
       if not isempty then
       begin
          IfToken := DcosConf
          if IfToken then
          begin
            ConfigAgain := True
            Result := True
          end
          else
          begin
            MsgBox('Verification code is wrong. Please try again.', mbError, MB_OK)
            Result := False
          end;
       end
       else
          Result := True;
   end
   else if I = 104 then
   begin
      isempty := Page3.Values[0] = ''
      if not isempty then
      begin
        email := ValidateEmail(Page3.Values[0])
        if not email then
        begin
          MsgBox('Email must be entered correctly', mbError, MB_OK)
          Result := False
        end
        else
        begin
          Result := True
        end;
      end
      else
      begin
        Result := True
      end;
   end
   else
      Result := True;
 end;

function ShouldSkipPage(PageID: Integer): Boolean;
var
  ifEmpty: boolean;
begin
  Result := False;
  if PageID = 103 then
  begin
    ifEmpty := Page2.Values[1] = ''
    Result := not ifEmpty
  end;
end;

procedure CheckBoxClick(Sender: TObject);
begin
  if TNewCheckListBox(Sender).ItemEnabled[0] then
  begin
    if TNewCheckListBox(Sender).Checked[1] then
      PythonVersion := '2.7'
    else
      PythonVersion := '3.4'
  end;
  WizardForm.NextButton.Enabled := TNewCheckListBox(Sender).Checked[0] and TNewCheckListBox(Sender).Checked[3]
end;

function GetParams(Value: string): string;
begin
  Result := Page1.Values[0];
end;

function Token(Value: string): string;
begin
  Result := Page2.Values[1];
end;

function Email(Value: string): string;
begin
  Result := Page3.Values[0];
end;

function GetPythonV(Value: string): string;
begin
  Result := PythonVersion;
end;

procedure CreateTheWizardPages;
var
  Page: TWizardPage;
  CheckListBox: TNewCheckListBox;
  FolderTreeView: TCustomFolderTreeView;
  CheckBox, CheckBoxG: TNewCheckBox;
  Ptest: boolean;
  Gtest: boolean;   
begin
  WasHere := False;
  WasConf := False;
  ConfigAgain := False;

  ProgressPage := CreateOutputProgressPage('DCOS-CLI','');

  ProgressConf := CreateOutputProgressPage('Configuring DCOS-CLI','');

  Page1 := CreateInputQueryPage(wpWelcome, 'DCOS url', '', 'Please specify DCOS url.');
  Page1.Add('dcos-url:', False);
  
  Page2 := CreateInputQueryPage(wpInfoAfter, 'DCOS verification', '', 'Please go to that url and enter verification code. You can skip verification.');
  Page2.Add('url: ', False)
  Page2.Add('verification code:', False);
  Page2.Values[0] := 'https://accounts.mesosphere.com/oauth/authorize?scope=&redirect_uri=urn%3Aie%20tf%3Awg%3Aoauth%3A2.0%3Aoob&response_type=code&client_id=6a552732-ab9b-410d-9b7d%20-d8c6523b09a1&access_type=offline#' 

  Page3 := CreateInputQueryPage (Page2.ID, 'DCOS email adress', '', 'Please type your email. You can skip this step.')
  Page3.Add('email: ', False)

  Page := CreateCustomPage(wpWelcome, 'Software prerequisites', 'Choose wisely');

  Ptest := IsPythonInstalled;
  Gtest := IsGitInstalled;

  CheckListBox := TNewCheckListBox.Create(Page);
  CheckListBox.Width := Page.SurfaceWidth;
  CheckListBox.Height := ScaleY(97);
  CheckListBox.Flat := True;
  CheckListBox.Parent := Page.Surface;
  CheckListBox.AddCheckBox('Python', '', 0, Ptest, not Ptest, False, True, nil);
  CheckListBox.AddRadioButton('2.7', '', 1, True, not Ptest, nil);
  CheckListBox.AddRadioButton('3.4', '', 1, True, not Ptest, nil);
  CheckListBox.AddCheckBox('Git', '', 0, Gtest, not Gtest, False, True, nil);
  CheckListBox.Onclick := @CheckBoxClick;

end;

 procedure InitializeWizard();
var
  BackgroundBitmapText: TNewStaticText;
  s: string;
begin
  CreateTheWizardPages;

  BackgroundBitmapText := TNewStaticText.Create(MainForm);
  BackgroundBitmapText.Left := 50
  BackgroundBitmapText.Top := 90 + ScaleY(8);
  BackgroundBitmapText.Caption := 'Installation DCOS-CLI';
  BackgroundBitmapText.Font.Color := clWhite;
  BackgroundBitmapText.Parent := MainForm;
end;