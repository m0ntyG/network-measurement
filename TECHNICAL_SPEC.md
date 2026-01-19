# Technical Specification - Network Performance Measurement Script

## Overview

This specification covers both the PowerShell (Windows) and Bash (MacOS/Linux) implementations of the network performance measurement script. Both versions provide comprehensive network performance measurement capabilities using only built-in tools. No administrative privileges are required.

## Platform Support

- **Windows**: PowerShell script (`measure-network.ps1`) for Windows 10/11
- **MacOS**: Bash script (`measure-network.sh`) for MacOS 10.x+
- **Linux**: Bash script (`measure-network.sh`) for modern Linux distributions

## Measured Metrics

### 1. Packet Loss
- **Method**: ICMP Echo Request/Reply (ping)
- **Tool**: 
  - Windows: `Test-Connection` cmdlet
  - MacOS/Linux: `ping` command
- **Calculation**: `((PacketsSent - PacketsReceived) / PacketsSent) * 100`
- **Unit**: Percentage (%)
- **Typical Range**: 0% (excellent) to 100% (complete failure)

### 2. Latency
- **Method**: ICMP Echo Request/Reply round-trip time
- **Tool**: 
  - Windows: `Test-Connection` cmdlet
  - MacOS/Linux: `ping` command
- **Measurements**:
  - Average (mean) latency
  - Minimum latency
  - Maximum latency
- **Unit**: Milliseconds (ms)
- **Typical Range**: 
  - Local network: 1-10 ms
  - National: 10-50 ms
  - International: 50-300 ms

### 3. Jitter
- **Method**: Average absolute deviation from mean latency
- **Calculation**: 
  - Windows: `Average(|ResponseTime - MeanLatency|)` for all samples
  - MacOS/Linux: Standard deviation from `ping` output
- **Unit**: Milliseconds (ms)
- **Significance**: Critical for real-time applications (VoIP, gaming, video conferencing)
- **Typical Range**:
  - Excellent: < 15 ms
  - Good: < 30 ms
  - Problematic: > 50 ms

### 4. DNS Resolution Time
- **Method**: Time to resolve hostname to IP address
- **Tool**: 
  - Windows: `System.Net.Dns.GetHostAddresses()`
  - MacOS/Linux: `dig` or `host` command
- **Unit**: Milliseconds (ms)
- **Note**: Results may be cached by OS, subsequent lookups may be faster
- **Typical Range**: 5-100 ms (first lookup), 0-5 ms (cached)

### 5. Port Connectivity
- **Method**: TCP connection establishment test
- **Tool**: 
  - Windows: `System.Net.Sockets.TcpClient`
  - MacOS/Linux: Bash `/dev/tcp` pseudo-device
- **Measurements**:
  - Port reachability (boolean)
  - TCP connection establishment time
- **Timeout**: Configurable (default 2000 ms for Windows, 2 seconds for MacOS/Linux)
- **Unit**: Milliseconds (ms)

## Connection Quality Assessment

The script automatically classifies connection quality based on three metrics:

| Quality   | Packet Loss | Avg Latency | Jitter  | Use Cases |
|-----------|-------------|-------------|---------|-----------|
| Excellent | ≤ 1%       | ≤ 50 ms    | ≤ 15 ms | Gaming, VoIP, Video conferencing, Real-time trading |
| Good      | ≤ 1%       | ≤ 100 ms   | ≤ 30 ms | Web browsing, Video streaming, Remote desktop |
| Fair      | ≤ 5%       | ≤ 200 ms   | ≤ 50 ms | Email, File downloads, General browsing |
| Poor      | > 5%       | > 200 ms   | > 50 ms | Connection issues, troubleshooting needed |

**Assessment Logic**: Connection is rated by the worst metric (if any metric indicates "Poor", overall quality is "Poor").

## Technical Implementation

### Windows (PowerShell)

#### Functions

#### `Measure-Latency`
- Sends N ICMP echo requests (configurable via `$PingCount`)
- Collects response times and success count
- Calculates average, min, max latency
- Calculates jitter as average deviation
- Computes packet loss percentage

#### `Measure-DnsResolution`
- Validates if input is already an IP address using `IPAddress.Parse()`
- If hostname, measures time to resolve using `System.Net.Dns.GetHostAddresses()`
- Returns resolved IP and resolution time

#### `Test-PortConnectivity`
- Creates asynchronous TCP connection attempt
- Waits up to timeout period (configurable)
- Measures connection establishment time
- Properly disposes resources using try-finally pattern

#### `Get-ConnectionQuality`
- Evaluates all metrics against configurable thresholds
- Returns quality rating (Excellent/Good/Fair/Poor)

### MacOS / Linux (Bash)

#### Functions

##### `measure_dns_resolution`
- Validates if input is already an IP address using regex pattern matching
- If hostname, measures time to resolve using `dig` or `host` command
- Returns resolved IP and resolution time

##### `measure_latency`
- Sends N ICMP echo requests using `ping` command (count configurable)
- Handles differences in MacOS and Linux `ping` output formats
- Collects response times and success count
- Calculates average, min, max latency
- Calculates jitter from standard deviation
- Computes packet loss percentage

##### `measure_tcp_latency`
- Creates N TCP connection attempts using Bash `/dev/tcp` pseudo-device
- Uses `timeout` command to enforce connection timeout
- Waits up to timeout period for each connection
- Measures connection establishment time
- Calculates statistics (avg, min, max, jitter, packet loss)
- Small delays between attempts to avoid aggressive scanning

##### `test_port_connectivity`
- Creates TCP connection attempt using `/dev/tcp`
- Uses `timeout` to enforce timeout period
- Measures connection establishment time
- Returns port status and connection time

##### `get_connection_quality`
- Evaluates all metrics against configurable thresholds
- Returns quality rating (Excellent/Good/Fair/Poor)

### Cross-Platform Differences

| Feature | Windows (PowerShell) | MacOS/Linux (Bash) |
|---------|---------------------|-------------------|
| ICMP Ping | `Test-Connection` cmdlet | `ping` command |
| DNS Resolution | `.NET System.Net.Dns` | `dig` or `host` command |
| TCP Connection | `.NET TcpClient` | Bash `/dev/tcp` pseudo-device |
| Timeout | Built into .NET methods | `timeout` command wrapper |
| Time Measurement | `.NET Stopwatch` | `date +%s%3N` (milliseconds) |
| CSV Export | `Export-Csv` cmdlet | Standard output redirection |

### Data Flow (Both Platforms)

1. **Initialization**: Load configuration and targets
2. **For each target**:
   a. DNS resolution (if hostname)
   b. Latency measurement (4 pings by default)
   c. Port connectivity test
   d. Quality assessment
   e. Store results in object
3. **Export**: Write all results to CSV
4. **Display**: Show summary table in console

### CSV Output Format

All measurements are exported with the following columns:

- `Timestamp`: Date and time of measurement
- `TargetName`: User-defined target name
- `Hostname`: Target hostname or IP
- `Port`: Tested port number
- `Protocol`: Protocol used for testing (ICMP or TCP)
- `ResolvedIP`: IP address (from DNS or original input)
- `DnsResolutionTime_ms`: DNS lookup time
- `AvgLatency_ms`: Average round-trip time
- `MinLatency_ms`: Minimum round-trip time
- `MaxLatency_ms`: Maximum round-trip time
- `Jitter_ms`: Average latency deviation
- `PacketLoss_percent`: Percentage of lost packets
- `PacketsSent`: Total packets sent
- `PacketsReceived`: Total packets received
- `PortOpen`: Port accessibility (True/False)
- `TcpConnectionTime_ms`: Time to establish TCP connection
- `ConnectionQuality`: Overall quality rating

## Configuration Options

### Windows (PowerShell)

All configuration is at the top of the script for easy access:

```powershell
# Target list - each entry requires Name, Host, Port, and Protocol
$Targets = @(
    @{Name="Description"; Host="hostname_or_ip"; Port=port_number; Protocol="ICMP"}
)

# Number of ping packets to send per target
$PingCount = 4

# TCP connection timeout in milliseconds
$TcpTimeout = 2000

# Output CSV filename
$OutputFile = "network_measurement_results.csv"

# Quality assessment thresholds
$QualityThresholds = @{
    Excellent = @{PacketLoss = 1; Latency = 50; Jitter = 15}
    Good = @{PacketLoss = 1; Latency = 100; Jitter = 30}
    Fair = @{PacketLoss = 5; Latency = 200; Jitter = 50}
}
```

### MacOS / Linux (Bash)

All configuration is at the top of the script:

```bash
# Target configuration: Name|Host|Port|Protocol
TARGETS=(
    "Description|hostname_or_ip|port_number|ICMP"
)

# Number of ping packets to send per target
PING_COUNT=4

# TCP connection timeout in seconds
TCP_TIMEOUT=2

# Output CSV filename
OUTPUT_FILE="network_measurement_results.csv"

# Continuous mode settings
CONTINUOUS_MODE=true
TEST_INTERVAL=300

# Quality assessment thresholds
EXCELLENT_PACKET_LOSS=1
EXCELLENT_LATENCY=50
EXCELLENT_JITTER=15

GOOD_PACKET_LOSS=3
GOOD_LATENCY=100
GOOD_JITTER=30

FAIR_PACKET_LOSS=5
FAIR_LATENCY=200
FAIR_JITTER=50
```

## Compatibility

### Windows
- **OS**: Windows 10, Windows 11
- **PowerShell**: Version 5.1+ (included in Windows 10/11)
- **Privileges**: No administrative rights required
- **Firewall**: May require ICMP and outbound TCP to be allowed

### MacOS
- **OS**: MacOS 10.x or later
- **Shell**: Bash 3.2+ (included with MacOS)
- **Tools**: `ping`, `dig`/`host`, `timeout`, `date`, `awk`, `sed`, `bc` (all standard)
- **Privileges**: No root/sudo required
- **Firewall**: May require ICMP and outbound TCP to be allowed

### Linux
- **OS**: Any modern Linux distribution (Ubuntu, Debian, CentOS, Fedora, etc.)
- **Shell**: Bash 4.0+ (typically pre-installed)
- **Tools**: `ping`, `dig`/`host`, `timeout`, `date`, `awk`, `sed`, `bc` (all standard)
- **Privileges**: No root/sudo required
- **Firewall**: May require ICMP and outbound TCP to be allowed

## Limitations

### General (All Platforms)
1. **ICMP Blocking**: Some hosts/networks block ICMP, resulting in 100% packet loss even if connection is working
2. **Firewall**: Corporate firewalls may block port connectivity tests
3. **DNS Caching**: DNS resolution times may not reflect actual DNS server performance after first lookup
4. **TCP Handshake**: Port tests only verify TCP handshake completion, not application-layer connectivity
5. **Single-threaded**: Targets are tested sequentially, not in parallel

### Platform-Specific
- **Windows**: Uses PowerShell which may have execution policy restrictions
- **MacOS**: Different `ping` output format compared to Linux (handled by script)
- **Linux**: Varies by distribution but script uses only POSIX-compliant tools

## Performance

### Windows
Typical execution time:
- Per target: ~0.5-1.5 seconds (with 4 pings)
- Total for 5 targets: ~3-8 seconds
- With slower/unresponsive targets: May take longer (respects timeout values)

### MacOS / Linux
Typical execution time:
- Per target: ~0.5-2 seconds (with 4 pings)
- Total for 5 targets: ~3-10 seconds
- With slower/unresponsive targets: May take longer (respects timeout values)

## Error Handling

- **DNS Failure**: Marks DNS as "Failed", continues with other tests using hostname directly
- **Ping Failure**: Reports 100% packet loss, continues with port test
- **Port Timeout**: Marks port as closed/filtered, doesn't block other measurements
- **CSV Export Failure**: Will display error but continue to show console output

## Security Considerations

- No credentials or sensitive data handling
- No code execution from external sources
- No write operations outside current directory
- Output file can be excluded via .gitignore
- All operations use standard .NET and PowerShell APIs (Windows) or standard Unix tools (MacOS/Linux)
- No elevation or privilege escalation attempts

## Use Cases

1. **Network Troubleshooting**: Identify packet loss, high latency, or connectivity issues
2. **ISP Quality Monitoring**: Regular measurements to document ISP performance
3. **VPN Performance**: Compare connection quality with/without VPN
4. **Site Selection**: Determine best server/CDN for your location
5. **Gaming Server Selection**: Find servers with lowest latency and jitter
6. **Remote Work**: Verify connection quality for video conferencing and remote desktop
7. **Documentation**: Generate reports for IT support or ISP complaints

## Future Enhancement Possibilities

- Parallel target testing for faster execution
- Historical trend analysis
- Graphical output/charts
- Automated scheduling via Task Scheduler
- Email alerts for poor quality
- Multiple protocol support (UDP, HTTP)
- MTR-like path analysis
- Bandwidth testing (requires external tools)
