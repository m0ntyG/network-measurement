# Network Performance Measurement Script
# This script measures network performance to multiple targets using built-in Windows tools
# Compatible with Windows 10/11, requires no admin privileges

#region Configuration - Edit targets here
$Targets = @(
    @{Name="Google DNS"; Host="8.8.8.8"; Port=443},
    @{Name="Cloudflare DNS"; Host="1.1.1.1"; Port=443},
    @{Name="Google"; Host="www.google.com"; Port=443},
    @{Name="Microsoft"; Host="www.microsoft.com"; Port=443},
    @{Name="GitHub"; Host="github.com"; Port=443}
)

# Measurement settings
$PingCount = 10          # Number of pings to send
$OutputFile = "network_measurement_results.csv"
#endregion

#region Helper Functions
function Measure-Latency {
    param(
        [string]$Target,
        [int]$Count
    )
    
    Write-Host "  Testing connectivity with $Count pings..." -ForegroundColor Cyan
    
    try {
        $pingResults = Test-Connection -ComputerName $Target -Count $Count -ErrorAction Stop
        
        $responseTimes = $pingResults | ForEach-Object { $_.ResponseTime }
        $successCount = ($pingResults | Where-Object { $_.StatusCode -eq 0 }).Count
        
        $avgLatency = ($responseTimes | Measure-Object -Average).Average
        $minLatency = ($responseTimes | Measure-Object -Minimum).Minimum
        $maxLatency = ($responseTimes | Measure-Object -Maximum).Maximum
        
        # Calculate jitter (average deviation from mean)
        $jitter = 0
        if ($responseTimes.Count -gt 1) {
            $deviations = $responseTimes | ForEach-Object { [Math]::Abs($_ - $avgLatency) }
            $jitter = ($deviations | Measure-Object -Average).Average
        }
        
        # Calculate packet loss percentage
        $packetLoss = (($Count - $successCount) / $Count) * 100
        
        return @{
            Success = $true
            AvgLatency = [Math]::Round($avgLatency, 2)
            MinLatency = $minLatency
            MaxLatency = $maxLatency
            Jitter = [Math]::Round($jitter, 2)
            PacketLoss = [Math]::Round($packetLoss, 2)
            PacketsSent = $Count
            PacketsReceived = $successCount
        }
    }
    catch {
        Write-Host "  Failed to ping $Target" -ForegroundColor Red
        return @{
            Success = $false
            AvgLatency = 0
            MinLatency = 0
            MaxLatency = 0
            Jitter = 0
            PacketLoss = 100
            PacketsSent = $Count
            PacketsReceived = 0
        }
    }
}

function Measure-DnsResolution {
    param([string]$Hostname)
    
    if ($Hostname -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
        # It's already an IP address
        return @{
            ResolvedIP = $Hostname
            DnsTime = 0
        }
    }
    
    Write-Host "  Resolving DNS..." -ForegroundColor Cyan
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $resolved = [System.Net.Dns]::GetHostAddresses($Hostname)
        $stopwatch.Stop()
        
        $firstIP = $resolved[0].IPAddressToString
        $dnsTime = $stopwatch.ElapsedMilliseconds
        
        return @{
            ResolvedIP = $firstIP
            DnsTime = $dnsTime
        }
    }
    catch {
        Write-Host "  DNS resolution failed" -ForegroundColor Red
        return @{
            ResolvedIP = "Failed"
            DnsTime = -1
        }
    }
}

function Test-PortConnectivity {
    param(
        [string]$Target,
        [int]$Port
    )
    
    Write-Host "  Testing port $Port connectivity..." -ForegroundColor Cyan
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $connect = $tcpClient.BeginConnect($Target, $Port, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne(3000, $false)
        $stopwatch.Stop()
        
        if (!$wait) {
            $tcpClient.Close()
            return @{
                PortOpen = $false
                ConnectionTime = -1
            }
        }
        else {
            try {
                $tcpClient.EndConnect($connect)
                $tcpClient.Close()
                return @{
                    PortOpen = $true
                    ConnectionTime = $stopwatch.ElapsedMilliseconds
                }
            }
            catch {
                return @{
                    PortOpen = $false
                    ConnectionTime = -1
                }
            }
        }
    }
    catch {
        return @{
            PortOpen = $false
            ConnectionTime = -1
        }
    }
}

function Get-ConnectionQuality {
    param($LatencyResult)
    
    $avgLatency = $LatencyResult.AvgLatency
    $jitter = $LatencyResult.Jitter
    $packetLoss = $LatencyResult.PacketLoss
    
    # Simple quality assessment
    if ($packetLoss -gt 5 -or $avgLatency -gt 200 -or $jitter -gt 50) {
        return "Poor"
    }
    elseif ($packetLoss -gt 1 -or $avgLatency -gt 100 -or $jitter -gt 30) {
        return "Fair"
    }
    elseif ($avgLatency -gt 50 -or $jitter -gt 15) {
        return "Good"
    }
    else {
        return "Excellent"
    }
}
#endregion

#region Main Script
Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "  Network Performance Measurement" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host "Ping Count: $PingCount" -ForegroundColor Yellow
Write-Host "Targets: $($Targets.Count)" -ForegroundColor Yellow
Write-Host ""

$results = @()

foreach ($target in $Targets) {
    Write-Host "Testing: $($target.Name) ($($target.Host):$($target.Port))" -ForegroundColor Green
    Write-Host ("=" * 60) -ForegroundColor Gray
    
    # DNS Resolution
    $dnsResult = Measure-DnsResolution -Hostname $target.Host
    Write-Host "  Resolved IP: $($dnsResult.ResolvedIP)" -ForegroundColor White
    if ($dnsResult.DnsTime -ge 0) {
        Write-Host "  DNS Resolution Time: $($dnsResult.DnsTime) ms" -ForegroundColor White
    }
    
    # Latency, Jitter, Packet Loss
    $latencyResult = Measure-Latency -Target $target.Host -Count $PingCount
    
    if ($latencyResult.Success) {
        Write-Host "  Average Latency: $($latencyResult.AvgLatency) ms" -ForegroundColor White
        Write-Host "  Min/Max Latency: $($latencyResult.MinLatency) / $($latencyResult.MaxLatency) ms" -ForegroundColor White
        Write-Host "  Jitter: $($latencyResult.Jitter) ms" -ForegroundColor White
        Write-Host "  Packet Loss: $($latencyResult.PacketLoss)% ($($latencyResult.PacketsReceived)/$($latencyResult.PacketsSent))" -ForegroundColor White
    }
    
    # Port Connectivity
    $portResult = Test-PortConnectivity -Target $target.Host -Port $target.Port
    Write-Host "  Port $($target.Port): $(if($portResult.PortOpen){'Open'}else{'Closed/Filtered'})" -ForegroundColor White
    if ($portResult.PortOpen -and $portResult.ConnectionTime -ge 0) {
        Write-Host "  TCP Connection Time: $($portResult.ConnectionTime) ms" -ForegroundColor White
    }
    
    # Connection Quality Assessment
    $quality = Get-ConnectionQuality -LatencyResult $latencyResult
    $qualityColor = switch ($quality) {
        "Excellent" { "Green" }
        "Good" { "Cyan" }
        "Fair" { "Yellow" }
        "Poor" { "Red" }
    }
    Write-Host "  Connection Quality: $quality" -ForegroundColor $qualityColor
    
    # Store results
    $results += [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        TargetName = $target.Name
        Hostname = $target.Host
        Port = $target.Port
        ResolvedIP = $dnsResult.ResolvedIP
        DnsResolutionTime_ms = $dnsResult.DnsTime
        AvgLatency_ms = $latencyResult.AvgLatency
        MinLatency_ms = $latencyResult.MinLatency
        MaxLatency_ms = $latencyResult.MaxLatency
        Jitter_ms = $latencyResult.Jitter
        PacketLoss_percent = $latencyResult.PacketLoss
        PacketsSent = $latencyResult.PacketsSent
        PacketsReceived = $latencyResult.PacketsReceived
        PortOpen = $portResult.PortOpen
        TcpConnectionTime_ms = $portResult.ConnectionTime
        ConnectionQuality = $quality
    }
    
    Write-Host ""
}

# Export to CSV
Write-Host "Exporting results to: $OutputFile" -ForegroundColor Green
$results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "  Measurement Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Results saved to: $(Resolve-Path $OutputFile)" -ForegroundColor Yellow
Write-Host ""

# Display summary table
Write-Host "Summary:" -ForegroundColor Green
$results | Format-Table TargetName, AvgLatency_ms, Jitter_ms, PacketLoss_percent, ConnectionQuality -AutoSize

#endregion
