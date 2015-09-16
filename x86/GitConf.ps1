function InstallGit()
{
    $output = Join-Path (pwd) "Git-2.5.1-32-bit.exe"
    echo "Installing 'git'"
    Start-Process -FilePath $output -ArgumentList "/verysilent" -Wait
    $Gpath = ";" + "C:\Program Files\Git\bin\"
    $env:Path += $Gpath
	$Gpath | Out-File pathfile.txt -Append
    [Environment]::SetEnvironmentVariable("Path", $env:Path + $Gpath, "User")
}

function PathGit([string]$GPath)
{
  if (-Not($Gpath.EndsWith("\")))
    {
        $Gpath += "\"
    }
	if (-Not($Gpath.EndsWith("bin\")))
    {
        $Gpath += "bin\"
    }
    $p_exe = $Gpath + "git.exe"
    $testP = Test-Path $p_exe
    if ($testP)
    {
        $Gpath = ";" + $Gpath
        $env:Path += $Gpath
		$Gpath | Out-File pathfile.txt -Append
        [Environment]::SetEnvironmentVariable("Path", $env:Path + $Gpath, "User")
    }
    else
    {
        InstallGit
    }
}

if (-Not(Get-Command git -errorAction SilentlyContinue)) {
	$Registry = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1"
	$GTest = Test-Path $Registry
	if ($GTest) {
		$x =  (Get-ItemProperty -Path $Registry).InstallLocation
		PathGit $x
	}
	else {
		InstallGit
	}
}