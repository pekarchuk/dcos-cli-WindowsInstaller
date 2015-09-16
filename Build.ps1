param(
  [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
  [string]$filename,
  [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
  [string]$version,
  [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
  [AllowEmptyString()]
  [string]$Output
  )

$client = new-object System.Net.WebClient

function Download([string]$url, [string]$output)
{
  While (!(Test-Connection -computer 8.8.8.8 -count 1 -quiet)) {
        Write-Host -ForegroundColor Red "Cannot connect to the server"
        Start-Sleep -Seconds 3
        }
  if(!(Test-Path $output -pathType leaf)) {
    echo "Downloading..."
    $client.DownloadFile($url, $output)
  }
  else {
    echo "File already exists. Installing from file..."
  }
}

function unzip($file, $destination)
{
	$shell = new-object -com shell.application
	$zip = $shell.NameSpace($file)
	foreach($item in $zip.items()) {
		$shell.Namespace($destination).copyhere($item)
	}
}

function InstallPS2EXE()
{
	$url = "https://gallery.technet.microsoft.com/PS2EXE-Convert-PowerShell-9e4e07f1/file/134627/1/PS2EXE-v0.5.0.0.zip"
	$output = Join-Path (pwd) "PS2EXE.zip"
	Download $url $output
	$dest = Join-Path (pwd) "ps2exe"
	mkdir $dest
	unzip $output $dest
	Remove-Item $output	
}

function InstallInno()
{
	$url = "http://www.jrsoftware.org/download.php/is.exe"
	$outputd = Join-Path (pwd) "InnoSetup.exe"
	Download $url $outputd
	echo "Installing Inno Setup"
	Start-Process -FilePath $outputd -ArgumentList "/verysilent" -Wait
  	Remove-Item $outputd
	$dir64 = "C:\Program Files (x86)\Inno Setup 5"
	$dir86 = "C:\Program Files\Inno Setup 5"
	$DtoEnv = ""
	if (Test-Path $dir64) {
		$DtoEnv = ";" + $dir64
	}
	ElseIf (Test-Path $dir86) {
		$DtoEnv = ";" + $dir86
	}
	if (!($DtoEnv)) {
		echo "Unexpected error. Aborting..."
		exit 1
	}
	$env:Path += $DtoEnv
   	[Environment]::SetEnvironmentVariable("Path", $env:Path + $Ppath, "User")
}
$ps2exed = Join-Path (pwd) "ps2exe"
if (!(Test-Path $ps2exed)) {
	echo "Installing PS2EXE"
	InstallPS2EXE
}

$dir64 = "C:\Program Files (x86)\Inno Setup 5"
$dir86 = "C:\Program Files\Inno Setup 5"
$DtoEnv = ""
if (Test-Path $dir64) {
	$DtoEnv = ";" + $dir64
}
ElseIf (Test-Path $dir86) {
	$DtoEnv = ";" + $dir86
}
if (-Not(Get-Command iscc.exe -errorAction SilentlyContinue)) {
	if (!($DtoEnv)) {
		InstallInno
	}
	else {
		$env:Path += $DtoEnv
		[Environment]::SetEnvironmentVariable("Path", $env:Path + $Ppath, "User")
	}
}

if (!(Test-Path $filename)) {
	echo "Filename $filename not found"
	exit 1
}

if ($Output) {
	$Output = "/O " + $Output
}

if ($version -eq "86") {
	$inputPy = Join-Path (pwd) "x86\PythonConf.ps1"
	$outPy = Join-Path (pwd) "x86\PythonConf.exe"
	$inputGi = Join-Path (pwd) "x86\GitConf.ps1"
	$outGi = Join-Path (pwd) "x86\GitConf.exe"
	$inputIn = Join-Path (pwd) "x86\Installer.ps1"
	$outIn = Join-Path (pwd) "x86\Installer.exe"
	$inputDc = Join-Path (pwd) "x86\DcosConf.ps1"
	$outDc = Join-Path (pwd) "x86\DcosConf.exe"
}
else {
	$inputPy = Join-Path (pwd) "x86-64\PythonConf.ps1"
	$outPy = Join-Path (pwd) "x86-64\PythonConf.exe"
	$inputGi = Join-Path (pwd) "x86-64\GitConf.ps1"
	$outGi = Join-Path (pwd) "x86-64\GitConf.exe"
	$inputIn = Join-Path (pwd) "x86-64\Installer.ps1"
	$outIn = Join-Path (pwd) "x86-64\Installer.exe"
	$inputDc = Join-Path (pwd) "x86-64\DcosConf.ps1"
	$outDc = Join-Path (pwd) "x86-64\DcosConf.exe"
}
& .\ps2exe\ps2exe.ps1 -inputFile $inputPy $outPy
cd ..\
& .\ps2exe\ps2exe.ps1 -inputFile $inputGi $outGi
cd ..\
& .\ps2exe\ps2exe.ps1 -inputFile $inputIn $outIn
cd ..\
& .\ps2exe\ps2exe.ps1 -inputFile $inputDc $outDc
cd ..\
# exit 1
echo "Building..."
& iscc.exe "/Q" "/F ""setup$version""" $Output $filename
echo "Finished"