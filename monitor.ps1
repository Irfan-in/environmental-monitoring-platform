$port = New-Object System.IO.Ports.SerialPort "COM11", 115200, "None", 8, "One"
$port.ReadTimeout = 1000
$port.DtrEnable = $false
$port.RtsEnable = $false
try {
    $port.Open()
    Write-Host "Monitoring COM11 (no reset)..."
    $start = Get-Date
    while (((Get-Date) - $start).TotalSeconds -lt 10) {
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
