$PythonVersion = $($args[0])

function ClearPath() {
	$x = $env:Path
	$sparr = $x.Split(';')
	$final = @()
	for ($i = 0; $i -lt $sparr.length; $i++) {
		if (!($sparr[$i] -match '\\Python')) {
			$final += $sparr[$i]
		}
	}
	$x1 = $final -join ';'
	$env:Path = $x1
	$x = [Environment]::GetEnvironmentVariable("Path","User")
	$sparr = $x.Split(';')
	$final = @()
	for ($i = 0; $i -lt $sparr.length; $i++) {
		if (!($sparr[$i] -match '\\Python')) {
			$final += $sparr[$i]
		}
	}
	$x2 = $final -join ';'
	[Environment]::SetEnvironmentVariable("Path", $x2, "User")
	$x = [Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
	$sparr = $x.Split(';')
	$final = @()
	for ($i = 0; $i -lt $sparr.length; $i++) {
		if (!($sparr[$i] -match '\\Python')) {
			$final += $sparr[$i]
		}
	}
	$x3 = $final -join ';'
	[Environment]::SetEnvironmentVariable("Path", $x3, [System.EnvironmentVariableTarget]::Machine)
}

function InstallPython()
{
	if ($PythonVersion -eq 2.7)
	{
		$output = Join-Path (pwd) "python-2.7.10.amd64.msi"
	}
	else
	{
		$output = Join-Path (pwd) "python-3.4.3.amd64.msi"
	}
  echo "Installing Python..."
  Start-Process -FilePath $output -ArgumentList "/quiet" -Wait
  if ($PythonVersion -eq 2.7) {
  	$Ppath = ";" + "C:\Python27\"
  }
  else {
  	$Ppath = ";" + "C:\Python34\"
  }
  ClearPath
  $Pscripts = $Ppath + $Ppath + "Scripts\"
  $Pscripts | Out-File pathfile.txt -Append
  $env:Path += $Pscripts
  [Environment]::SetEnvironmentVariable("Path", $env:Path + $Pscripts, [System.EnvironmentVariableTarget]::Machine)
}

function MSVCR100()
{
	
	$VCPath = 'C:\Windows\SysWOW64\msvcr100.dll'
	$test = Test-Path $VCPath
	if (!($test)) {
		echo "Copying msvcr100.dll"
		$p = Join-Path (pwd) "msvcr100.dll"
		Copy-Item $p 'C:\Windows\SysWOW64'
	}
}

function InstallPip()
{
  echo "Installing pip"
  $url = "https://raw.github.com/pypa/pip/master/contrib/get-pip.py"
  $output = Join-Path (pwd) "get-pip.py"
  Download $url $output
  python $output
}

function PathPython([string]$Ppath)
{
  if (-Not($Ppath.EndsWith("\")))
    {
        $Ppath += "\"
    }
    $p_exe = $Ppath + "python.exe"
    $testP = Test-Path $p_exe
    if ($testP)
    {
		ClearPath
        $Ppath = ";" + $Ppath + ";" + $Ppath + "Scripts\"
        $env:Path += $Ppath
		$Ppath | Out-File pathfile.txt -Append
        [Environment]::SetEnvironmentVariable("Path", $env:Path + $Ppath, [System.EnvironmentVariableTarget]::Machine)
    }
    else
    {
        InstallPython
    }
}

MSVCR100
if (-Not(Get-Command python -errorAction SilentlyContinue)) {
	if ($PythonVersion) {
		[decimal]$PythonVersion = $PythonVersion
	}
	else {
		$PythonVersion = 2.7
	}
	echo "Checking python"
	$k1 = "HKCU:\Software\Python\PythonCore\2.7\InstallPath"
	$k2 = "HKCU:\Software\Python\PythonCore\3.4\InstallPath"
	$k3 = "HKLM:\SOFTWARE\Python\PythonCore\2.7\InstallPath"
	$k4 = "HKLM:\SOFTWARE\Python\PythonCore\3.4\InstallPath"
	$P27 = Test-Path $k1
	$P34 = Test-Path $k2
	$P2 = Test-Path $k3
	$P3 = Test-Path $k4
	if (!($P27) -and !($P34) -and !($P2) -and !($P3)) {
		InstallPython
	}
	else
	{
		if ($P27) {
			$x = (Get-ItemProperty -Path $k1).'(default)'
			PathPython $x
		}
		ElseIf ($P34) {
			$x = (Get-ItemProperty -Path $k2).'(default)'
			PathPython $x
		}
		ElseIf ($P2) {
			$x = (Get-ItemProperty -Path $k3).'(default)'
			PathPython $x
		}
		ElseIf ($P3) {
			$x = (Get-ItemProperty -Path $k4).'(default)'
			PathPython $x
		}
	}
}

$PYTHON_VERSION = (python --version) 2>&1

if ($PYTHON_VERSION -match "[0-9]+.[0-9]+") {
    $PYTHON_VERSION = $matches[0]
    if (-Not (($PYTHON_VERSION -eq "2.7") -Or ($PYTHON_VERSION -eq "3.4"))) {
        InstallPython
    }
}

if (-Not(Get-Command pip -errorAction SilentlyContinue)) {
  echo "Installing pip"
  InstallPip
}

$PIP_VERSION = (pip -V)

$x = "$PIP_VERSION" -match "[0-9]+\.[0-9]+"
if ([double]$matches[0] -le 1.4) {
  echo "Upgrading pip"
  & pip -q install --upgrade pip
  echo ""
}
if (-Not(Get-Command virtualenv -errorAction SilentlyContinue)) {
  echo "Installing virtualenv"
  $ptow = Join-Path (pwd) "virtualenv-13.1.2-py2.py3-none-any.whl"
  & pip -q install $ptow
  echo ""
}

$VIRTUAL_ENV_VERSION = (virtualenv --version)

$x = $VIRTUAL_ENV_VERSION  -match "[0-9]+"

if ($matches[0] -lt 12) {
  echo "Upgrading virtualenv."
  $ptow = Join-Path (pwd) "virtualenv-13.1.2-py2.py3-none-any.whl"
  & pip -q install $ptow --upgrade
  echo ""
  }