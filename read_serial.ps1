$port = New-Object System.IO.Ports.SerialPort "COM11", 115200, "None", 8, "One"
$port.ReadTimeout = 1000
$port.DtrEnable = $true
$port.RtsEnable = $false
try {
    $port.Open()
    $port.DtrEnable = $false
    $port.RtsEnable = $true
    Start-Sleep -Milliseconds 200
    $port.RtsEnable = $false
    $port.DtrEnable = $true
    
    $start = Get-Date
    while (((Get-Date) - $start).TotalSeconds -lt 14) {
        try {
            $line = $port.ReadLine()
            Write-Host $line
        } catch [System.TimeoutException] {
        }
    }
    $port.Close()
} catch {
    Write-Host "Serial Error: $_"
}
