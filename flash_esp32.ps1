$esptool = "C:\Users\Irfan\AppData\Local\Arduino15\packages\esp32\tools\esptool_py\5.3.1\esptool.exe"
$bootloader = "C:\Users\Irfan\AppData\Local\arduino\sketches\9408366B1291098E6B9DB2695285AB95\esp32_sensor_node.ino.bootloader.bin"
$partitions = "C:\Users\Irfan\AppData\Local\arduino\sketches\9408366B1291098E6B9DB2695285AB95\esp32_sensor_node.ino.partitions.bin"
$bootApp0 = "C:\Users\Irfan\AppData\Local\Arduino15\packages\esp32\hardware\esp32\3.3.12\tools\partitions\boot_app0.bin"
$app = "C:\Users\Irfan\AppData\Local\arduino\sketches\9408366B1291098E6B9DB2695285AB95\esp32_sensor_node.ino.bin"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " ESP32 Firmware Flasher (Direct High-Speed esptool) " -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Port: COM11 | Baud: 921600 | Attempts: 30"
Write-Host ""
Write-Host ">>> WAITING FOR ESP32 TO CONNECT... PLEASE HOLD THE 'BOOT' BUTTON! <<<" -ForegroundColor Magenta
Write-Host ""

& $esptool --chip esp32 --port COM11 --baud 921600 --before default-reset --after hard-reset --connect-attempts 30 write-flash -z --flash_mode dio --flash_freq 80m --flash_size 4MB 0x1000 $bootloader 0x8000 $partitions 0xe000 $bootApp0 0x10000 $app

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " >>> SUCCESS! ESP32 FIRMWARE FLASHED AND RUNNING! <<<" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host " Flashing failed. Please make sure the BOOT button was held." -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    exit 1
}
