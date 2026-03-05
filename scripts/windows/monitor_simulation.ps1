# Monitor Prior Predictive Simulation Progress
# Usage: .\monitor_simulation.ps1

$containerName = "brms-workshop"
$logFile = "/home/rstudio/simulation_output.log"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Simulation Progress Monitor" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

while ($true) {
    Clear-Host
    Write-Host "Monitoring simulation in container: $containerName" -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop monitoring (simulation will continue)" -ForegroundColor Gray
    Write-Host ""
    
    # Check if process is still running
    $processCount = docker exec $containerName ps aux | Select-String "Rscript.*run_simulation" | Measure-Object | Select-Object -ExpandProperty Count
    
    if ($processCount -gt 0) {
        Write-Host "[RUNNING] Simulation is actively running" -ForegroundColor Green
    } else {
        Write-Host "[STOPPED] Simulation appears to have finished or stopped" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Show last 40 lines of log
    Write-Host "Last 40 lines of output:" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    docker exec $containerName tail -40 $logFile
    Write-Host ""
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host "Refreshing in 30 seconds..." -ForegroundColor Gray
    
    Start-Sleep -Seconds 30
}
