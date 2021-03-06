$filename = $($args[0])
$version = $($args[1])
$Output = $($args[2])

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


$ps2exed = Join-Path (pwd) "ps2exe"
if (!(Test-Path $ps2exed)) {
	echo "Installing PS2EXE"
	InstallPS2EXE
}

if (!(Test-Path $filename)) {
	echo "Filename $filename not found"
    "##teamcity[buildStatus status='FAILURE' text='Setup source not found']" 
	exit 1
}

if ($Output) {
	$Output = "/O " + $Output
}

if ($version -eq "86") {
	$folder = "x86\"
}
else {
	$folder = "x64\"
}
$inputPy = Join-Path (pwd) ($folder + "PythonConf.ps1")
$outPy = Join-Path (pwd) ($folder + "PythonConf.exe")
$inputGi = Join-Path (pwd) ($folder + "GitConf.ps1")
$outGi = Join-Path (pwd) ($folder + "GitConf.exe")
$inputIn = Join-Path (pwd) ($folder + "Installer.ps1")
$outIn = Join-Path (pwd) ($folder + "Installer.exe")
$inputDc = Join-Path (pwd) ($folder + "DcosConf.ps1")
$outDc = Join-Path (pwd) ($folder + "DcosConf.exe")

if (Test-Path $inputPy) {
    "##teamcity[buildStatus status='FAILURE' text='Powershell scripts not found']"    
}

& .\ps2exe\ps2exe.ps1 -inputFile $inputPy $outPy
cd ..\
& .\ps2exe\ps2exe.ps1 -inputFile $inputGi $outGi
cd ..\
& .\ps2exe\ps2exe.ps1 -inputFile $inputIn $outIn
cd ..\
& .\ps2exe\ps2exe.ps1 -inputFile $inputDc $outDc
cd ..\
echo "Building..."
& .\InnoSetup5\ISCC.exe "/Q" "/F ""setup$version""" $Output $filename
echo "Finished"
"##teamcity[buildStatus status='SUCCESS' text='Build Finished']"