$token = $($args[0])
$email = $($args[1])
$installation_path = $($args[2])
function Token()
{
	$psi = New-Object System.Diagnostics.ProcessStartInfo;
	$psi.FileName = "dcos.exe"; #process file
	$psi.UseShellExecute = $false; #start the process from it's own executable file
	$psi.RedirectStandardInput = $true; #enable the process to read from standard input
	$psi.RedirectStandardOutput = $true;
	$p = [System.Diagnostics.Process]::Start($psi);
	$id_n = $p.Id
	Start-Sleep -s 2
	if (!($token)) {
		$p.StandardInput.WriteLine($token);
		Start-Sleep -s 2
		$p.StandardInput.WriteLine($email);
	}
	else {
		$p.StandardInput.WriteLine($token);
		Start-Sleep -s 2
		$p.StandardInput.WriteLine($token);
	}
}

function Trys()
{
	$psi = New-Object System.Diagnostics.ProcessStartInfo;
	$psi.FileName = "dcos.exe"; #process file
	$psi.UseShellExecute = $false; #start the process from it's own executable file
	$psi.RedirectStandardInput = $true; #enable the process to read from standard input
	$psi.RedirectStandardOutput = $true
	$p = [System.Diagnostics.Process]::Start($psi);
	$p.StandardInput.WriteLine($token);
	Start-Sleep -s 2
	$p.StandardInput.WriteLine($email);
	$id_n = $p.Id
	Stop-Process -id $id_n
	$stdout = $p.StandardOutput.ReadToEnd()
	if (!$stdout) {
		exit 0
	}
}
echo "Configurating DCOS-CLI"
$env:Path += ";$installation_path"
$DCOS_CONFIG = "$env:USERPROFILE\.dcos\dcos.toml"

if (-Not(Test-Path $DCOS_CONFIG)) {
  mkdir "$env:USERPROFILE\.dcos"
  New-Item $DCOS_CONFIG -type file
}
$env:DCOS_CONFIG = $DCOS_CONFIG
Token
Trys
dcos config set core.reporting true
dcos config set core.dcos_url $dcos_url
dcos config set core.timeout 5
dcos config set package.cache $env:temp\dcos\package-cache
dcos config set package.sources '[\"https://github.com/mesosphere/universe/archive/version-1.x.zip\"]'

dcos package update

echo "Finished configuring DCOS CLI."
exit 1