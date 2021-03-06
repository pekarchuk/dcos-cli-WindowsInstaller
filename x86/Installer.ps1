$installation_path = $($args[0])
$dcos_url = $($args[1])

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
}

$Paths = Get-Content pathfile.txt
ClearPath
foreach ($elem in $Paths) {
	$env:Path += $elem
}

echo "Installing DCOS CLI from PyPI..."
echo ""

if (-Not( Test-Path $installation_path)) {
  mkdir  $installation_path
}

& virtualenv $installation_path
& $installation_path\Scripts\activate

$PYTHON_VERSION = (python --version) 2>&1
if ($PYTHON_VERSION -Match "3.4") {
	$pd = Join-Path (pwd) "pywin32-219.win32-py3.4.exe"
	& $installation_path\Scripts\easy_install $pd  2>&1 | out-null
}
else {
	$pd = Join-Path (pwd) "pywin32-219.win32-py2.7.exe"
	& $installation_path\Scripts\easy_install $pd  2>&1 | out-null
}


$ptow = Join-Path (pwd) "dcoscli-0.1.13-py2.py3-none-any.whl"
& $installation_path\Scripts\pip install -q $ptow

$dcos_p =  ";$installation_path\Scripts\"
$env:Path += $dcos_p
[Environment]::SetEnvironmentVariable("Path", $env:Path + $dcos_p, "User")
$DCOS_CONFIG = "$env:USERPROFILE\.dcos\dcos.toml"

if (-Not(Test-Path $DCOS_CONFIG)) {
  mkdir "$env:USERPROFILE\.dcos"
  New-Item $DCOS_CONFIG -type file
}
[Environment]::SetEnvironmentVariable("DCOS_CONFIG", "$DCOS_CONFIG", "User")
$env:DCOS_CONFIG = $DCOS_CONFIG

echo "Finished installing DCOS CLI"