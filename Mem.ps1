
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

function mem {

$ErrorOccured = $false

try 
{ 
 $ErrorActionPreference = 'Stop'


$totalMemory = (Get-CimInstance -class "cim_physicalmemory" | % {$_.Capacity}) / 1MB
   <#Invoke-Command -ComputerName $Hostname -ScriptBlock {Get-WmiObject -Class win32_physicalmemory -Property Capacity | 
    Measure-Object -Property Capacity -Sum | 
    Select-Object -ExpandProperty Sum } 
) / 1MB #>

#$availMemory = Invoke-Command -ComputerName $Hostname -ScriptBlock {(Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue}
#$poolpage = Invoke-Command -ComputerName $Hostname -ScriptBlock {(Get-Counter '\Memory\Pool Paged Bytes').CounterSamples.CookedValue}
#$nonpagedpool = Invoke-Command -ComputerName $Hostname -ScriptBlock {(Get-Counter '\Memory\Pool Nonpaged Bytes').CounterSamples.CookedValue}
$availMemory =  (Get-Counter -ComputerName $Hostname '\Memory\Available MBytes').CounterSamples.CookedValue
$poolpage = (Get-Counter -ComputerName $Hostname '\Memory\Pool Paged Bytes').CounterSamples.CookedValue
$nonpagedpool = (Get-Counter -ComputerName $Hostname '\Memory\Pool Nonpaged Bytes').CounterSamples.CookedValue
$poolpage = [math]::Round(($poolpage/1024)/1024,2)
$nonpagedpool = [math]::Round(($nonpagedpool/1024)/1024,2)
$usedMemory = [math]::Round((($totalMemory - $availMemory) / $totalMemory * 100),2)

}

catch
{
   "Error occured"
   $ErrorOccured=$true
}

if ($usedMemory -ge $Critical) {

    $Severity = 'CRITICAL';
    $ExitCode = 2;
} elseif ($usedMemory -ge $Warning) {

    $Severity = 'WARNING';
	$ExitCode = 1;
} elseif ($ErrorOccured) { 
    $Severity = 'Error';
    $ExitCode = 3; }

Write-Host ([String]::Format('Mem {0} | Used={1}%, Total={2}MB, PagedPool={3}MB, Nonpagedpool={4}MB',
		$Severity,
		$usedMemory,
        $totalMemory,
        $poolpage,
        $nonpagedpool))

}


exit mem -H $Hostname -Warning $Warning -c $Critical; 



