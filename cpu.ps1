
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


if ($Debug) {
	Set-PSDebug -Trace 2
}

[String]$Severity = 'OK'
[Int]$ExitCode = 0

function proc {

$ErrorOccured = $false

try 
{ 
 $ErrorActionPreference = 'Stop'

#[float]$proc = Invoke-Command -ComputerName $Hostname -ScriptBlock {(Get-Counter -Counter "\Processor(_Total)\% Processor Time" | select -ExpandProperty countersamples | select -ExpandProperty cookedvalue)}
[float]$proc = (Get-Counter -ComputerName $Hostname -Counter "\Processor(_Total)\% Processor Time" | select -ExpandProperty countersamples | select -ExpandProperty cookedvalue)

$proc = [math]::Round($proc,2)

}

catch
{
   "Error occured"
   $ErrorOccured=$true
}


if ($proc -ge $Critical) {

    $Severity = 'CRITICAL';
    $ExitCode = 2;
} elseif ($proc -ge $Warning) {

    $Severity = 'WARNING';
	$ExitCode = 1;
} elseif ($ErrorOccured) { 
    $Severity = 'Error';
    $ExitCode = 3; }

Write-Host ([String]::Format('LOAD {0} | load={1}%',
		$Severity,
		$proc))

}

exit proc -H $Hostname -Warning $Warning -c $Critical; 