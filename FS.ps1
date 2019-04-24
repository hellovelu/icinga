
param(
    [Alias('H')]
    [String]$Hostname = "localhost",
    [Alias('w')]
    [float]$Warning = 80,
	[Alias('c')]
	[float]$Critical = 90,
    [Alias('d')]
	[Switch]$Debug = $false
    )


[String]$Severity = 'OK'
[Int]$ExitCode = 0

if ($Debug) {
	Set-PSDebug -Trace 2
}

function fs {

$ErrorOccured = $false

try 
{ 
 $ErrorActionPreference = 'Stop'

$counter = "\LogicalDisk(*)\% Free Space"
$data = get-counter -ComputerName $Hostname $counter
$data.countersamples | format-list -Property InstanceName,CookedValue > test.txt
$PATH = (Resolve-Path .\).Path

$filecontent1 = Get-Content -Path "$PATH\test.txt"


if ( Test-Path "$PATH\EmptyFile.txt") {
    Clear-Content "$PATH\EmptyFile.txt"
} else {
New-Item -Name "EmptyFile.txt" -ItemType File | Out-Null
}

foreach ($list1 in $filecontent1) {
    $list1 = $list1.Split(":")[1] >> EmptyFile.txt
    }

$filecontent2 = Get-Content -Path "$PATH\EmptyFile.txt"


$Line1 = (Get-Content EmptyFile.txt | Measure-Object -Line).Lines

$Num1 = 0
[String]$drivesize = "Used =" 

For ($i=0; $i -lt $Line1; $i++) {
    
    $drive = (Get-Content EmptyFile.txt | select -Index ($Num1) | Measure-Object -Character).Characters
    $drive = $drive - 1
    
    
    if ($drive -eq 1) {
        $Num2 = $Num1 + 1
        $drive1 = Get-Content EmptyFile.txt | select -Index ($Num1)
        $size = Get-Content EmptyFile.txt | select -Index ($Num2)
        $size = [math]::Round(100 - $size,2)


        if ($Severity -ne 'CRITICAL') {
            if ($size -ge $Critical ) {
                $Severity = 'CRITICAL';
                $ExitCode = 2; 
            } elseif ($Severity -ne 'WARNING') {
                    if ($size -ge $Warning) {
                        $Severity = 'WARNING';
	                    $ExitCode = 1;
                    } 
                    }
        } elseif ($Severity -ne 'WARNING') {
            if ($size -ge $Warning) {

                $Severity = 'WARNING';
	            $ExitCode = 1;
            } 
        }

        $drive1 = "$drive1".Trim()
        $size = "$size".Trim()

        $drivesize = $drivesize + " " + $drive1 + ":" + " " + $size + "%,"
        
    }
    $Num1 = $Num1 + 2
    
}


$drivesize = "$drivesize".TrimEnd(",")


if (Test-Path "$PATH\test.txt") {
Remove-Item -Path "$PATH\test.txt";
Remove-Item -Path "$PATH\EmptyFile.txt";
}


}

catch
{
   "Error occured"
   $ErrorOccured=$true
}

if ($ErrorOccured) { 
    $Severity = 'Error';
    $ExitCode = 3; }


    Write-Host ([String]::Format('FileSystem {0} | {1}',
            $Severity,
            $drivesize))
           
}

exit fs -H $Hostname -Warning $Warning -c $Critical; 