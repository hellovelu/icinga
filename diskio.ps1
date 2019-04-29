
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
[Int]$LastExitCode = 0


if ($Debug) {
	Set-PSDebug -Trace 2
}

function diskio {

$ErrorOccured = $false

try 
{ 
 $ErrorActionPreference = 'Stop'

$outfile1 = ".\outputdiskio1.txt"
$outfile2 = ".\outputdiskio2.txt"
$outfile3 = ".\outputdiskio3.txt"
$Counteridle = "\PhysicalDisk(*)\% Idle Time"

Get-Counter -ComputerName $Hostname $Counteridle > $outfile1
$Total = (Get-Counter -ComputerName $Hostname "\PhysicalDisk(_total)\% Idle Time").countersamples.cookedvalue
$Total = [math]::Round((100 - $Total),1)

Get-Content $outfile1 | Select-String -Pattern 'idle', 'Timestamp', '-' -NotMatch > $outfile2
Get-Content $outfile2 | Where-Object { $_.Trim() -ne '' } > $outfile3

$contentdiskio1 = Get-Content $outfile1 | Where-Object { $_.Trim() -ne '' }
$contentdiskio2 = Get-Content $outfile3 
$diskiovalue = New-Object 'string[,]' 3,3
[Int]$x = 0
[Int]$y = 0

Clear-Content $outfile2

Foreach ($lines1 in $contentdiskio1) {
    
    [String]$line1 = "$lines1".Split("(")[1]
    $line1 = "$line1".Split(")")[0] | foreach {"$_".Trim(":").split(" ")[1]}
    
    if ($line1) {
        $line1 = "$line1".Trim()
        Write-Output $line1 | Out-File $outfile2 -Append
        $diskiovalue[$x,$y] = $line1
        $x = $x + 1
    }
    $arrvalue = $x - 1
    
}

$x = 0
$y = 1

Foreach ($lines2 in $contentdiskio2) {
    $lines2 = $lines2.Trim()
    $lines2 = [math]::Round((100 - $lines2),1)
    $diskiovalue[$x,$y] = $lines2
    $x = $x + 1
}

[String]$outputline = ""
$x = 0 
$y = 0

for ($i=0; $i -le $arrvalue; $i++) {
    
    $outputline = $outputline + $diskiovalue[$x,0] + ":io=" + $diskiovalue[$x,1] + "% "
    $diskiovalue[$x,1]

    if ($Severity -ne 'CRITICAL') {

        if ($Total -ge $Critical -or $diskiovalue[$x,1] -ge $Critical) {
            $Severity = 'CRITICAL';
            $LastExitCode = 1;
        } elseif ($Total -ge $Warning -or $diskiovalue[$x,1] -ge $Warning) {
            $Severity = 'WARNING';
            $LastExitCode = 2;
        }
    }
    $x = $x + 1
}



}

catch
{
   "Error occured"
   $ErrorOccured=$true
}

if ($ErrorOccured) { 
    $Severity = 'Error';
     }

Write-Host ([String]::Format('Disk IO: {0} | Average={1}% {2}',
            $Severity,
            $Total,
            $outputline))

}

exit diskio -H $Hostname -Warning $Warning -c $Critical; 