#$computers = Get-Content -Path "ip_list.txt"
echo "Ping checker. Built 04/07/2024"
function FileName { Read-Host -Prompt "Enter file name" }
$computers = Get-Content -Path $(FileName)
Write-Host "Checking..."
foreach ($computer in $computers)
    {
    $ip = $computer.Split(" - ")[0]
    if (Test-Connection  $ip -Count 1 -ErrorAction SilentlyContinue){
        Write-Host "$ip is up"
        }
    else{
        Write-Host "$ip is down"
        }
    }
$response = read-host "Press C and Enter to Close."
$aborted = $response -eq "C"
