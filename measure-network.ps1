# Network Performance Measurement Script
# This script measures network performance to multiple targets using built-in Windows tools
# Compatible with Windows 10/11, requires no admin privileges

#region Configuration - Edit targets here
$Targets = @(
    # For ICMP: Port=$null (not applicable for ICMP ping)
    # For TCP: Port=number (required for TCP connection testing)
    @{Name = "Google DNS"; Host = "8.8.8.8"; Port = $null; Protocol = "ICMP" },
    @{Name = "Cloudflare DNS"; Host = "1.1.1.1"; Port = $null; Protocol = "ICMP" },
    @{Name = "Google"; Host = "www.google.com"; Port = 443; Protocol = "TCP" },
    @{Name = "Microsoft"; Host = "www.microsoft.com"; Port = 443; Protocol = "TCP" },
    @{Name = "GitHub"; Host = "github.com"; Port = 443; Protocol = "TCP" }
)

# Measurement settings
$PingCount = 4           # Number of pings to send (reduced for performance)
$TcpTimeout = 2000       # TCP connection timeout in milliseconds (reduced for performance)
$OutputFile = "network_measurement_results.csv"
$ContinuousMode = $true  # Run continuously
$TestInterval = 300      # Interval between test cycles in seconds (5 minutes)
$EnableTraceroute = $false  # Enable hop-by-hop traceroute (optional, increases test time)
$TracerouteMaxHops = 30  # Maximum number of hops for traceroute
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
        
        # Filter to only include successful pings for accurate statistics
        $successfulPings = $pingResults | Where-Object { $_.StatusCode -eq 0 }
        $responseTimes = $successfulPings | ForEach-Object { $_.ResponseTime }
        $successCount = $successfulPings.Count
        
        if ($successCount -gt 0) {
            $avgLatency = ($responseTimes | Measure-Object -Average).Average
            $minLatency = ($responseTimes | Measure-Object -Minimum).Minimum
            $maxLatency = ($responseTimes | Measure-Object -Maximum).Maximum
            
            # Calculate jitter (average deviation from mean)
            $jitter = 0
            if ($responseTimes.Count -gt 1) {
                $deviations = $responseTimes | ForEach-Object { [Math]::Abs($_ - $avgLatency) }
                $jitter = ($deviations | Measure-Object -Average).Average
            }
        }
        else {
            # No successful pings
            $avgLatency = 0
            $minLatency = 0
            $maxLatency = 0
            $jitter = 0
        }
        
        # Calculate packet loss percentage
        $packetLoss = (($Count - $successCount) / $Count) * 100
        
        return @{
            Success         = $true
            AvgLatency      = [Math]::Round($avgLatency, 2)
            MinLatency      = $minLatency
            MaxLatency      = $maxLatency
            Jitter          = [Math]::Round($jitter, 2)
            PacketLoss      = [Math]::Round($packetLoss, 2)
            PacketsSent     = $Count
            PacketsReceived = $successCount
        }
    }
    catch {
        Write-Host "  Failed to ping $Target" -ForegroundColor Red
        return @{
            Success         = $false
            AvgLatency      = 0
            MinLatency      = 0
            MaxLatency      = 0
            Jitter          = 0
            PacketLoss      = 100
            PacketsSent     = $Count
            PacketsReceived = 0
        }
    }
}

function Measure-TcpLatency {
    param(
        [string]$Target,
        [int]$Port,
        [int]$Count,
        [int]$TimeoutMs = $script:TcpTimeout
    )
    
    Write-Host "  Testing TCP connectivity to port $Port with $Count attempts..." -ForegroundColor Cyan
    
    $responseTimes = @()
    $successCount = 0
    
    for ($i = 0; $i -lt $Count; $i++) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $connect = $tcpClient.BeginConnect($Target, $Port, $null, $null)
            $wait = $connect.AsyncWaitHandle.WaitOne($TimeoutMs, $false)
            $stopwatch.Stop()
            
            if ($wait) {
                $tcpClient.EndConnect($connect)
                $responseTimes += $stopwatch.ElapsedMilliseconds
                $successCount++
            }
            $connect.AsyncWaitHandle.Close()
            $tcpClient.Close()
            $tcpClient.Dispose()
        }
        catch {
            # Connection failed
        }
        
        # Small delay between attempts
        if ($i -lt ($Count - 1)) {
            Start-Sleep -Milliseconds 100
        }
    }
    
    if ($successCount -eq 0) {
        return @{
            Success         = $false
            AvgLatency      = 0
            MinLatency      = 0
            MaxLatency      = 0
            Jitter          = 0
            PacketLoss      = 100
            PacketsSent     = $Count
            PacketsReceived = 0
        }
    }
    
    $avgLatency = ($responseTimes | Measure-Object -Average).Average
    $minLatency = ($responseTimes | Measure-Object -Minimum).Minimum
    $maxLatency = ($responseTimes | Measure-Object -Maximum).Maximum
    
    # Calculate jitter (average deviation from mean)
    $jitter = 0
    if ($responseTimes.Count -gt 1) {
        $deviations = $responseTimes | ForEach-Object { [Math]::Abs($_ - $avgLatency) }
        $jitter = ($deviations | Measure-Object -Average).Average
    }
    
    $packetLoss = (($Count - $successCount) / $Count) * 100
    
    return @{
        Success         = $true
        AvgLatency      = [Math]::Round($avgLatency, 2)
        MinLatency      = [Math]::Round($minLatency, 2)
        MaxLatency      = [Math]::Round($maxLatency, 2)
        Jitter          = [Math]::Round($jitter, 2)
        PacketLoss      = [Math]::Round($packetLoss, 2)
        PacketsSent     = $Count
        PacketsReceived = $successCount
    }
}

function Measure-DnsResolution {
    param([string]$Hostname)
    
    # Check if it's an IP address using proper validation
    try {
        $null = [System.Net.IPAddress]::Parse($Hostname)
        # It's a valid IP address
        return @{
            ResolvedIP = $Hostname
            DnsTime    = 0
        }
    }
    catch {
        # Not an IP, continue with DNS resolution
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
            DnsTime    = $dnsTime
        }
    }
    catch {
        Write-Host "  DNS resolution failed" -ForegroundColor Red
        return @{
            ResolvedIP = "Failed"
            DnsTime    = -1
        }
    }
}

function Measure-TcpLatency {
    param(
        [string]$Target,
        [int]$Port,
        [int]$Count,
        [int]$TimeoutMs = $script:TcpTimeout
    )
    
    Write-Host "  Testing TCP connectivity to port $Port with $Count attempts..." -ForegroundColor Cyan
    
    $responseTimes = @()
    $successCount = 0
    
    for ($i = 0; $i -lt $Count; $i++) {
        $tcpClient = $null
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $connect = $tcpClient.BeginConnect($Target, $Port, $null, $null)
            $wait = $connect.AsyncWaitHandle.WaitOne($TimeoutMs, $false)
            $stopwatch.Stop()
            
            if ($wait) {
                try {
                    $tcpClient.EndConnect($connect)
                    $responseTimes += $stopwatch.ElapsedMilliseconds
                    $successCount++
                }
                catch {
                    # Connection failed
                }
            }
            
            # Explicitly close the wait handle to prevent resource leaks
            $connect.AsyncWaitHandle.Close()
        }
        catch {
            # Connection attempt failed
        }
        finally {
            if ($null -ne $tcpClient) {
                $tcpClient.Close()
                $tcpClient.Dispose()
            }
        }
        
        # Small delay between attempts to avoid being flagged as aggressive scanning
        if ($i -lt ($Count - 1)) {
            Start-Sleep -Milliseconds 100
        }
    }
    
    if ($successCount -gt 0) {
        $avgLatency = ($responseTimes | Measure-Object -Average).Average
        $minLatency = ($responseTimes | Measure-Object -Minimum).Minimum
        $maxLatency = ($responseTimes | Measure-Object -Maximum).Maximum
        
        # Calculate jitter
        $jitter = 0
        if ($responseTimes.Count -gt 1) {
            $deviations = $responseTimes | ForEach-Object { [Math]::Abs($_ - $avgLatency) }
            $jitter = ($deviations | Measure-Object -Average).Average
        }
        
        $packetLoss = (($Count - $successCount) / $Count) * 100
        
        return @{
            Success         = $true
            AvgLatency      = [Math]::Round($avgLatency, 2)
            MinLatency      = $minLatency
            MaxLatency      = $maxLatency
            Jitter          = [Math]::Round($jitter, 2)
            PacketLoss      = [Math]::Round($packetLoss, 2)
            PacketsSent     = $Count
            PacketsReceived = $successCount
        }
    }
    else {
        return @{
            Success         = $false
            AvgLatency      = 0
            MinLatency      = 0
            MaxLatency      = 0
            Jitter          = 0
            PacketLoss      = 100
            PacketsSent     = $Count
            PacketsReceived = 0
        }
    }
}

function Test-PortConnectivity {
    param(
        [string]$Target,
        [int]$Port,
        [int]$TimeoutMs = $script:TcpTimeout
    )
    
    Write-Host "  Testing port $Port connectivity..." -ForegroundColor Cyan
    
    $tcpClient = $null
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $connect = $tcpClient.BeginConnect($Target, $Port, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne($TimeoutMs, $false)
        $stopwatch.Stop()
        
        if (!$wait) {
            # Explicitly close the wait handle to prevent resource leaks
            $connect.AsyncWaitHandle.Close()
            return @{
                PortOpen       = $false
                ConnectionTime = -1
            }
        }
        else {
            try {
                $tcpClient.EndConnect($connect)
                # Explicitly close the wait handle to prevent resource leaks
                $connect.AsyncWaitHandle.Close()
                return @{
                    PortOpen       = $true
                    ConnectionTime = $stopwatch.ElapsedMilliseconds
                }
            }
            catch {
                # Explicitly close the wait handle to prevent resource leaks
                $connect.AsyncWaitHandle.Close()
                return @{
                    PortOpen       = $false
                    ConnectionTime = -1
                }
            }
        }
    }
    catch {
        return @{
            PortOpen       = $false
            ConnectionTime = -1
        }
    }
    finally {
        if ($null -ne $tcpClient) {
            $tcpClient.Close()
            $tcpClient.Dispose()
        }
    }
}

function Measure-Traceroute {
    param(
        [string]$Target,
        [int]$MaxHops = 30
    )
    
    Write-Host "  Performing traceroute (max $MaxHops hops)..." -ForegroundColor Cyan
    
    # Create a script block to run with timeout protection
    $tracerouteScript = {
        param($Target, $MaxHops)
        
        # Try Test-NetConnection first (Windows 8.1/Server 2012 R2 and later)
        if (Get-Command Test-NetConnection -ErrorAction SilentlyContinue) {
            try {
                $traceResult = Test-NetConnection -ComputerName $Target -TraceRoute -Hops $MaxHops -WarningAction SilentlyContinue -ErrorAction Stop
                
                if ($traceResult.TraceRoute) {
                    $hopCount = $traceResult.TraceRoute.Count
                    $hopDetails = ""
                    
                    for ($i = 0; $i -lt $traceResult.TraceRoute.Count; $i++) {
                        $hopNum = $i + 1
                        $hopIp = $traceResult.TraceRoute[$i]
                        $hopHost = $hopIp
                        
                        # NOTE: Test-NetConnection -TraceRoute does not provide per-hop latency.
                        # To get approximate latency, we ping each hop once.
                        $hopLatencyMs = $null
                        try {
                            $pingResult = Test-Connection -ComputerName $hopIp -Count 1 -ErrorAction SilentlyContinue
                            if ($pingResult -and $pingResult.ResponseTime) {
                                $hopLatencyMs = [math]::Round($pingResult.ResponseTime, 2)
                            }
                        }
                        catch {
                            # If ping fails, leave latency as null
                        }
                        
                        $latencyDisplay = if ($null -ne $hopLatencyMs) { "$hopLatencyMs ms" } else { "* ms" }
                        $hopDetails += "Hop$hopNum`:$hopHost($hopIp)=$latencyDisplay;"
                    }
                    
                    $hopDetails = $hopDetails.TrimEnd(';')
                    
                    return @{
                        Status  = "Success"
                        Hops    = $hopCount
                        Details = $hopDetails
                    }
                }
            }
            catch {
                # Fall through to tracert.exe
            }
        }
        
        # Fallback to tracert.exe (native Windows tool, available on all versions)
        $tracertOutput = & tracert -h $MaxHops -w 2000 $Target 2>&1
        
        if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            return @{
                Status  = "Failed"
                Hops    = 0
                Details = ""
            }
        }
        
        # Parse tracert output
        $hopCount = 0
        $hopDetails = ""
        
        foreach ($line in $tracertOutput) {
            # Match lines like: "  1    <1 ms    <1 ms    <1 ms  router.local [192.168.1.1]"
            # Match with hostname and IP in brackets
            if ($line -match '^\s+(\d+)\s+(?:\*|<?\d+\s+ms)\s+(?:\*|<?\d+\s+ms)\s+(?:\*|<?\d+\s+ms)\s+(\S+)\s+\[([0-9\.]+)\]') {
                $hopNum = $matches[1]
                $hopHost = $matches[2]
                $hopIp = $matches[3]
                $hopCount++
                
                # Extract first valid latency
                $latency = "*"
                if ($line -match '<?\s*(\d+)\s+ms') {
                    $latency = $matches[1]
                }
                
                $hopDetails += "Hop$hopNum`:$hopHost($hopIp)=$latency ms;"
            }
            # Match with just IP (no hostname, reverse DNS failed)
            elseif ($line -match '^\s+(\d+)\s+(?:\*|<?\d+\s+ms)\s+(?:\*|<?\d+\s+ms)\s+(?:\*|<?\d+\s+ms)\s+([0-9\.]+)\s*$') {
                $hopNum = $matches[1]
                $hopIp = $matches[2]
                $hopCount++
                
                # Extract first valid latency
                $latency = "*"
                if ($line -match '<?\s*(\d+)\s+ms') {
                    $latency = $matches[1]
                }
                
                $hopHost = $hopIp
                $hopDetails += "Hop$hopNum`:$hopHost($hopIp)=$latency ms;"
            }
            # Match timeout hops: "  2     *        *        *     Request timed out."
            elseif ($line -match '^\s+(\d+)\s+\*\s+\*\s+\*') {
                $hopNum = $matches[1]
                $hopCount++
                $hopDetails += "Hop$hopNum`:*(*):* ms;"
            }
        }
        
        $hopDetails = $hopDetails.TrimEnd(';')
        
        if ($hopCount -eq 0) {
            return @{
                Status  = "Failed"
                Hops    = 0
                Details = ""
            }
        }
        
        return @{
            Status  = "Success"
            Hops    = $hopCount
            Details = $hopDetails
        }
    }
    
    try {
        # Run traceroute with 60-second timeout
        $job = Start-Job -ScriptBlock $tracerouteScript -ArgumentList $Target, $MaxHops
        $result = Wait-Job -Job $job -Timeout 60
        
        if ($null -eq $result) {
            # Timeout occurred
            Stop-Job -Job $job
            Remove-Job -Job $job
            Write-Host "  Traceroute timed out after 60 seconds" -ForegroundColor Red
            return @{
                Status  = "Failed"
                Hops    = 0
                Details = ""
            }
        }
        
        $output = Receive-Job -Job $job
        Remove-Job -Job $job
        
        if ($null -ne $output) {
            return $output
        }
        
        return @{
            Status  = "Failed"
            Hops    = 0
            Details = ""
        }
    }
    catch {
        Write-Host "  Traceroute failed: $($_.Exception.Message)" -ForegroundColor Red
        return @{
            Status  = "Failed"
            Hops    = 0
            Details = ""
        }
    }
}
#endregion

#region Main Script
Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "  Network Performance Measurement" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Continuous Mode: $ContinuousMode" -ForegroundColor White
if ($ContinuousMode) {
    Write-Host "  Test Interval: $TestInterval seconds ($([Math]::Round($TestInterval/60, 1)) minutes)" -ForegroundColor White
}
Write-Host "  Ping Count: $PingCount" -ForegroundColor White
Write-Host "  Targets: $($Targets.Count)" -ForegroundColor White
Write-Host "  Output File: $OutputFile" -ForegroundColor White
if ($EnableTraceroute) {
    Write-Host "  Traceroute: Enabled (max $TracerouteMaxHops hops)" -ForegroundColor White
}
else {
    Write-Host "  Traceroute: Disabled" -ForegroundColor White
}
Write-Host ""

# CSV file initialization - append mode for continuous operation
$csvExists = Test-Path $OutputFile

$testCycle = 0
do {
    $testCycle++
    
    if ($ContinuousMode) {
        Write-Host ""
        Write-Host "======================================" -ForegroundColor Cyan
        Write-Host "  Test Cycle #$testCycle - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
        Write-Host "======================================" -ForegroundColor Cyan
        Write-Host ""
    }
    
    $results = @()
    
    foreach ($target in $Targets) {
        $protocol = if ($target.Protocol) { $target.Protocol.ToUpper() } else { "ICMP" }
        
        # Validate protocol
        if ($protocol -ne "ICMP" -and $protocol -ne "TCP") {
            Write-Host "Warning: Invalid protocol '$($target.Protocol)' for target '$($target.Name)'. Defaulting to ICMP." -ForegroundColor Yellow
            $protocol = "ICMP"
        }
        
        # Validate TCP targets have a port
        if ($protocol -eq "TCP" -and ($null -eq $target.Port -or $target.Port -eq "")) {
            Write-Host "Error: TCP protocol requires a port number for target '$($target.Name)'. Skipping." -ForegroundColor Red
            Write-Host ""
            continue
        }
        
        # Display target info (with or without port depending on protocol)
        if ($protocol -eq "ICMP") {
            Write-Host "Testing: $($target.Name) ($($target.Host)) [Protocol: $protocol]" -ForegroundColor Green
        }
        else {
            Write-Host "Testing: $($target.Name) ($($target.Host):$($target.Port)) [Protocol: $protocol]" -ForegroundColor Green
        }
        Write-Host ("=" * 60) -ForegroundColor Gray
        
        # DNS Resolution
        $dnsResult = Measure-DnsResolution -Hostname $target.Host
        Write-Host "  Resolved IP: $($dnsResult.ResolvedIP)" -ForegroundColor White
        if ($dnsResult.DnsTime -ge 0) {
            Write-Host "  DNS Resolution Time: $($dnsResult.DnsTime) ms" -ForegroundColor White
        }
        
        # Latency, Jitter, Packet Loss based on protocol
        if ($protocol -eq "TCP") {
            Write-Host "  Protocol: TCP" -ForegroundColor Cyan
            $latencyResult = Measure-TcpLatency -Target $target.Host -Port $target.Port -Count $PingCount
        }
        else {
            Write-Host "  Protocol: ICMP" -ForegroundColor Cyan
            $latencyResult = Measure-Latency -Target $target.Host -Count $PingCount
        }
        
        if ($latencyResult.Success) {
            Write-Host "  Average Latency: $($latencyResult.AvgLatency) ms" -ForegroundColor White
            Write-Host "  Min/Max Latency: $($latencyResult.MinLatency) / $($latencyResult.MaxLatency) ms" -ForegroundColor White
            Write-Host "  Jitter: $($latencyResult.Jitter) ms" -ForegroundColor White
            Write-Host "  Packet Loss: $($latencyResult.PacketLoss)% ($($latencyResult.PacketsReceived)/$($latencyResult.PacketsSent))" -ForegroundColor White
        }
        
        # Port Connectivity (only for TCP protocol)
        if ($protocol -eq "TCP") {
            # For TCP protocol, port is implicitly tested via latency measurement
            $portResult = @{
                PortOpen       = $latencyResult.Success
                ConnectionTime = $latencyResult.AvgLatency
            }
        }
        else {
            # For ICMP protocol, port testing is not applicable
            $portResult = @{
                PortOpen       = "N/A"
                ConnectionTime = -1
            }
        }
        
        # Traceroute (optional)
        if ($EnableTraceroute) {
            $tracerouteResult = Measure-Traceroute -Target $target.Host -MaxHops $TracerouteMaxHops
            
            Write-Host "  Traceroute Status: $($tracerouteResult.Status)" -ForegroundColor White
            if ($tracerouteResult.Status -eq "Success") {
                Write-Host "  Traceroute Hops: $($tracerouteResult.Hops)" -ForegroundColor White
            }
        }
        else {
            $tracerouteResult = @{
                Status  = "Disabled"
                Hops    = 0
                Details = ""
            }
        }
        
        # Store results
        if ($EnableTraceroute) {
            $results += [PSCustomObject]@{
                Timestamp            = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                TargetName           = $target.Name
                Hostname             = $target.Host
                Port                 = if ($protocol -eq "ICMP") { "N/A" } else { $target.Port }
                Protocol             = $protocol
                ResolvedIP           = $dnsResult.ResolvedIP
                DnsResolutionTime_ms = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:F0}", $dnsResult.DnsTime)
                AvgLatency_ms        = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:F2}", $latencyResult.AvgLatency)
                MinLatency_ms        = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:F0}", $latencyResult.MinLatency)
                MaxLatency_ms        = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:F0}", $latencyResult.MaxLatency)
                Jitter_ms            = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:F2}", $latencyResult.Jitter)
                PacketLoss_percent   = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:F2}", $latencyResult.PacketLoss)
                PacketsSent          = $latencyResult.PacketsSent
                PacketsReceived      = $latencyResult.PacketsReceived
                PortOpen             = $portResult.PortOpen
                TcpConnectionTime_ms = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:F0}", $portResult.ConnectionTime)
                TracerouteStatus     = $tracerouteResult.Status
                TracerouteHops       = $tracerouteResult.Hops
                TracerouteDetails    = $tracerouteResult.Details
            }
        }
        else {
            $results += [PSCustomObject]@{
                Timestamp            = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                TargetName           = $target.Name
                Hostname             = $target.Host
                Port                 = if ($protocol -eq "ICMP") { "N/A" } else { $target.Port }
                Protocol             = $protocol
                ResolvedIP           = $dnsResult.ResolvedIP
                DnsResolutionTime_ms = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:F0}", $dnsResult.DnsTime)
                AvgLatency_ms        = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:F2}", $latencyResult.AvgLatency)
                MinLatency_ms        = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:F0}", $latencyResult.MinLatency)
                MaxLatency_ms        = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:F0}", $latencyResult.MaxLatency)
                Jitter_ms            = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:F2}", $latencyResult.Jitter)
                PacketLoss_percent   = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:F2}", $latencyResult.PacketLoss)
                PacketsSent          = $latencyResult.PacketsSent
                PacketsReceived      = $latencyResult.PacketsReceived
                PortOpen             = $portResult.PortOpen
                TcpConnectionTime_ms = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:F0}", $portResult.ConnectionTime)
            }
        }
        
        Write-Host ""
    }
    
    # Export to CSV (append mode in continuous operation, overwrite in single-run mode)
    Write-Host "Exporting results to: $OutputFile" -ForegroundColor Green
    
    # Validate that we have results to export
    if ($null -eq $results -or $results.Count -eq 0) {
        Write-Host "  Warning: No results to export. Skipping CSV export." -ForegroundColor Yellow
    }
    elseif ($csvExists -and $ContinuousMode) {
        # Append to existing CSV in continuous mode (preserves historical data)
        # Read existing CSV to get column names and ensure compatibility
        try {
            $existingData = Import-Csv -Path $OutputFile -ErrorAction Stop
            $existingColumns = @()
            if ($existingData.Count -gt 0) {
                # Get all property names from the first row
                $existingColumns = $existingData[0].PSObject.Properties.Name
            }
            else {
                # If CSV is empty (only headers), parse headers using a CSV-aware parser
                $headerLine = Get-Content -Path $OutputFile -First 1 -ErrorAction SilentlyContinue
                if ($null -ne $headerLine -and $headerLine.Length -gt 0) {
                    $stringReader = $null
                    $parser = $null
                    try {
                        # Use TextFieldParser to correctly handle quoted CSV headers (including commas in quotes)
                        Add-Type -AssemblyName Microsoft.VisualBasic -ErrorAction Stop
                        $stringReader = New-Object System.IO.StringReader($headerLine)
                        $parser = New-Object Microsoft.VisualBasic.FileIO.TextFieldParser($stringReader)
                        $parser.TextFieldType = [Microsoft.VisualBasic.FileIO.FieldType]::Delimited
                        $parser.SetDelimiters(',')
                        $parser.HasFieldsEnclosedInQuotes = $true
                        $fields = $parser.ReadFields()
                        if ($fields) {
                            $existingColumns = $fields
                        }
                    }
                    catch {
                        # Fallback: use simple split if TextFieldParser fails or is unavailable
                        $existingColumns = $headerLine -replace '"', '' -split ','
                    }
                    finally {
                        # Ensure proper resource cleanup
                        if ($null -ne $parser) { $parser.Close() }
                        if ($null -ne $stringReader) { $stringReader.Close() }
                    }
                }
            }
            
            # Get new data columns (safe to access since we validated results.Count > 0 above)
            $newColumns = $results[0].PSObject.Properties.Name
            
            # Find columns that exist in CSV but not in new data
            $missingColumns = $existingColumns | Where-Object { $_ -notin $newColumns }
            
            # Add missing columns to new results with empty/default values
            if ($missingColumns.Count -gt 0) {
                foreach ($result in $results) {
                    foreach ($column in $missingColumns) {
                        $result | Add-Member -MemberType NoteProperty -Name $column -Value "" -Force
                    }
                }
            }
            
            # Find columns in new data that don't exist in CSV (these will be appended)
            $extraColumns = $newColumns | Where-Object { $_ -notin $existingColumns }
            
            # Reorder properties to match existing CSV column order, then append any extra columns
            if ($existingColumns.Count -gt 0) {
                $orderedResults = $results | Select-Object -Property (@($existingColumns) + @($extraColumns))
                $orderedResults | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8 -Append
            }
            else {
                $results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8 -Append
            }
        }
        catch {
            Write-Host "  Warning: Could not read existing CSV structure. Creating new file." -ForegroundColor Yellow
            $results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8
        }
    }
    else {
        # Create new CSV or overwrite in single-run mode (fresh start each run)
        $results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8
        $csvExists = $true
    }
    
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "  Measurement Complete!" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    Write-Host ""
    
    # Display summary table
    Write-Host "Summary:" -ForegroundColor Green
    $results | Format-Table TargetName, Protocol, AvgLatency_ms, Jitter_ms, PacketLoss_percent -AutoSize
    
    # If continuous mode, wait for next cycle
    if ($ContinuousMode) {
        Write-Host ""
        Write-Host "Next test in $TestInterval seconds ($(Get-Date -Format 'HH:mm:ss') -> $($(Get-Date).AddSeconds($TestInterval).ToString('HH:mm:ss')))" -ForegroundColor Yellow
        Write-Host "Press Ctrl+C to stop continuous monitoring..." -ForegroundColor Gray
        Write-Host ""
        
        Start-Sleep -Seconds $TestInterval
    }
    
} while ($ContinuousMode)

#endregion
