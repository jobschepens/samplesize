#!/usr/bin/env pwsh
# Run Prior Predictive Simulation in Docker Container
# Date: February 4, 2026

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Prior Predictive Simulation - Docker" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$containerName = "brms-workshop"
$scriptPath = "C:\GitHub\temp\random"
$outputPath = "C:\GitHub\temp\random\simulation_output"

# Create output directory if it doesn't exist
if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
    Write-Host "✓ Created output directory: $outputPath" -ForegroundColor Green
}

# Check if container is running
$containerStatus = docker ps --filter "name=$containerName" --format "{{.Status}}"
if (-not $containerStatus) {
    Write-Host "✗ Container '$containerName' is not running!" -ForegroundColor Red
    Write-Host "Please start the container first." -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Container '$containerName' is running" -ForegroundColor Green

Write-Host "`nCopying R script to container..." -ForegroundColor Yellow
Get-Content "$scriptPath\run_simulation_scenarios.R" | docker exec -i $containerName bash -c "cat > /home/rstudio/run_simulation_scenarios.R"
Write-Host "✓ Script copied" -ForegroundColor Green

Write-Host "`nStarting simulation..." -ForegroundColor Yellow
Write-Host "This will take approximately 45-90 minutes`n" -ForegroundColor Yellow

# Run the simulation in the existing container
docker exec -w /home/rstudio $containerName Rscript run_simulation_scenarios.R

# Check if successful
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✓ Simulation completed successfully!" -ForegroundColor Green
    
    # Copy results from container
    Write-Host "`nCopying results from container..." -ForegroundColor Yellow
    docker exec $containerName bash -c "cd /home/rstudio && tar czf simulation_results.tar.gz simulation_results_*.csv simulation_results_*.rds scenario_comparison.csv all_scenarios_*.rds 2>/dev/null || true"
    docker cp ${containerName}:/home/rstudio/simulation_results.tar.gz "$scriptPath\simulation_results.tar.gz"
    
    if (Test-Path "$scriptPath\simulation_results.tar.gz") {
        Write-Host "✓ Results copied to: $scriptPath\simulation_results.tar.gz" -ForegroundColor Green
        
        # Extract the archive
        tar -xzf "$scriptPath\simulation_results.tar.gz" -C $scriptPath
        Write-Host "✓ Results extracted" -ForegroundColor Green
        
        # List output files
        Write-Host "`nGenerated files:" -ForegroundColor Yellow
        Get-ChildItem -Path $scriptPath -Filter "simulation_*.csv" | ForEach-Object {
            Write-Host "  - $($_.Name)" -ForegroundColor White
        }
        Get-ChildItem -Path $scriptPath -Filter "*.rds" | Where-Object { $_.Name -match "scenario" } | ForEach-Object {
            Write-Host "  - $($_.Name)" -ForegroundColor White
        }
    }
    
} else {
    Write-Host "`n✗ Simulation failed with exit code: $LASTEXITCODE" -ForegroundColor Red
}

Write-Host "`n========================================`n" -ForegroundColor Cyan
