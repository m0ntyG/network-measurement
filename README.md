# Network Performance Measurement Script

A cross-platform script for measuring network performance to multiple targets (URLs and IPs).

**Available for:**
- Windows 10/11 (PowerShell script)
- MacOS (Bash script)
- Linux (Bash script)

## Features

- ✅ **DNS Resolution Time** - Measures time to resolve hostname to IP address
- ✅ **Packet Loss** - Measures packet loss percentage
- ✅ **Latency** - Measures latency (Average, Min, Max)
- ✅ **Jitter** - Measures latency variations
- ✅ **Port Connectivity** - Tests port reachability
- ✅ **Protocol Selection** - Choose between TCP and ICMP per target
- ✅ **Continuous Monitoring** - Continuous monitoring with configurable interval
- ✅ **CSV Export** - Exports results to CSV file (append mode for continuous monitoring)
- ✅ **Performance Optimized** - Reduced ping count and timeouts for minimal system load
- ✅ **No Admin Rights Required** - No administrator privileges required
- ✅ **Built-in Windows Tools Only** - Uses only built-in Windows tools
- ✅ **Endpoint Security Friendly** - Delays between tests to respect security policies

## Requirements

### Windows
- Windows 10 or Windows 11
- PowerShell (already installed)
- No administrator privileges required

### MacOS / Linux
- MacOS 10.x+ or any modern Linux distribution
- Bash shell (already installed)
- Standard Unix tools: `ping`, `dig` or `host`, `date`, `awk`, `sed`, `bc`
- Python 3 (for MacOS millisecond timestamps - typically pre-installed on MacOS 10.15+)
- No administrator/root privileges required

## Usage

### 1. Configuration

#### Windows (PowerShell)

Open the file `measure-network.ps1` and edit the target list at the beginning:

```powershell
$Targets = @(
    @{Name="Google DNS"; Host="8.8.8.8"; Port=443; Protocol="ICMP"},
    @{Name="Cloudflare DNS"; Host="1.1.1.1"; Port=443; Protocol="ICMP"},
    @{Name="Google"; Host="www.google.com"; Port=443; Protocol="TCP"},
    @{Name="Microsoft"; Host="www.microsoft.com"; Port=443; Protocol="TCP"},
    @{Name="GitHub"; Host="github.com"; Port=443; Protocol="ICMP"}
)

# Measurement settings
$PingCount = 4           # Number of pings to send (reduced for performance)
$TcpTimeout = 2000       # TCP connection timeout in milliseconds
$OutputFile = "network_measurement_results.csv"
$ContinuousMode = $true  # Run continuously
$TestInterval = 300      # Interval between test cycles in seconds (5 minutes)
```

#### MacOS / Linux (Bash)

Open the file `measure-network.sh` and edit the target list at the beginning:

```bash
TARGETS=(
    "Google DNS|8.8.8.8|443|ICMP"
    "Cloudflare DNS|1.1.1.1|443|ICMP"
    "Google|www.google.com|443|TCP"
    "Microsoft|www.microsoft.com|443|TCP"
    "GitHub|github.com|443|ICMP"
)

# Measurement settings
PING_COUNT=4                    # Number of pings to send
TCP_TIMEOUT=2                   # TCP connection timeout in seconds
OUTPUT_FILE="network_measurement_results.csv"
CONTINUOUS_MODE=true            # Run continuously
TEST_INTERVAL=300               # Interval between test cycles in seconds (5 minutes)
```

Each entry requires:
- **Name**: Descriptive name for the target
- **Host**: URL or IP address
- **Port**: Port number to test
- **Protocol**: "ICMP" for ping or "TCP" for TCP connections

**Continuous Mode:**
- `$ContinuousMode = $true` - Runs continuously
- `$ContinuousMode = $false` - Single run
- `$TestInterval` - Seconds between tests (300 = 5 minutes)

### 2. Execution

#### Windows - Run PowerShell Script:

```powershell
cd path\to\network-measurement
.\measure-network.ps1
```

If you get an execution policy error:

```powershell
powershell -ExecutionPolicy Bypass -File .\measure-network.ps1
```

#### MacOS / Linux - Run Bash Script:

```bash
cd /path/to/network-measurement
chmod +x measure-network.sh
./measure-network.sh
```

Or run directly with bash:

```bash
bash measure-network.sh
```

### 3. Results

The script creates a CSV file named `network_measurement_results.csv` in the same directory.

#### CSV Fields:

- **Timestamp** - Timestamp of measurement
- **TargetName** - Target name
- **Hostname** - Hostname or IP
- **Port** - Tested port
- **Protocol** - Protocol used (ICMP/TCP)
- **ResolvedIP** - Resolved IP address
- **DnsResolutionTime_ms** - DNS resolution time in milliseconds
- **AvgLatency_ms** - Average latency in ms
- **MinLatency_ms** - Minimum latency in ms
- **MaxLatency_ms** - Maximum latency in ms
- **Jitter_ms** - Jitter in ms
- **PacketLoss_percent** - Packet loss in percent
- **PacketsSent** - Number of packets sent
- **PacketsReceived** - Number of packets received
- **PortOpen** - Port reachable (True/False)
- **TcpConnectionTime_ms** - TCP connection time in ms

## Connection Quality Reference

You can interpret the values yourself using common benchmarks:

| Quality | Packet Loss | Avg Latency | Jitter |
|---------|-------------|-------------|--------|
| Excellent | < 1% | < 50 ms | < 15 ms |
| Good | < 3% | < 100 ms | < 30 ms |
| Fair | < 5% | < 200 ms | < 50 ms |
| Poor | ≥ 5% | ≥ 200 ms | ≥ 50 ms |

## Customization

### Windows (PowerShell)

You can change the number of pings (reduced for better performance):

```powershell
$PingCount = 4           # Number of pings
```

You can change the TCP timeout (reduced for better performance):

```powershell
$TcpTimeout = 2000       # TCP timeout in milliseconds
```

You can enable/disable continuous mode:

```powershell
$ContinuousMode = $true  # true for continuous
$TestInterval = 300      # Seconds between tests
```

You can change the output file name:

```powershell
$OutputFile = "network_measurement_results.csv"
```

### MacOS / Linux (Bash)

You can change the number of pings:

```bash
PING_COUNT=4                    # Number of pings to send
```

You can change the TCP timeout:

```bash
TCP_TIMEOUT=2                   # TCP timeout in seconds
```

You can enable/disable continuous mode:

```bash
CONTINUOUS_MODE=true            # true for continuous
TEST_INTERVAL=300               # Seconds between tests
```

You can change the output file name:

```bash
OUTPUT_FILE="network_measurement_results.csv"
```

## Protocol Selection

**ICMP (Ping):**
- Uses standard ICMP echo requests
- Faster and less resource-intensive
- May be blocked by firewalls
- Good for general network connectivity

**TCP:**
- Measures TCP connection time to specified port
- More realistic for application latencies
- Works through most firewalls
- Slightly slower than ICMP

## Example Output

Console:
```
======================================
  Network Performance Measurement
======================================

Configuration:
  Continuous Mode: True
  Test Interval: 300 seconds (5.0 minutes)
  Ping Count: 4
  Targets: 5
  Output File: network_measurement_results.csv

======================================
  Test Cycle #1 - 2026-01-19 10:30:00
======================================

Testing: Google DNS (8.8.8.8:443) [Protocol: ICMP]
============================================================
  Resolved IP: 8.8.8.8
  DNS Resolution Time: 0 ms
  Protocol: ICMP
  Testing connectivity with 4 pings...
  Average Latency: 15.5 ms
  Min/Max Latency: 14 / 18 ms
  Jitter: 1.2 ms
  Packet Loss: 0% (4/4)
  Port 443: Open
  TCP Connection Time: 16 ms

Testing: Google (www.google.com:443) [Protocol: TCP]
============================================================
  Resolved IP: 142.250.185.68
  DNS Resolution Time: 23 ms
  Protocol: TCP
  Testing TCP connectivity to port 443 with 4 attempts...
  Average Latency: 18.7 ms
  Min/Max Latency: 16 / 24 ms
  Jitter: 2.3 ms
  Packet Loss: 0% (4/4)

Summary:
TargetName    Protocol AvgLatency_ms Jitter_ms PacketLoss_percent
----------    -------- ------------- --------- ------------------
Google DNS    ICMP              15.5       1.2                  0
Google        TCP               18.7       2.3                  0

Next test in 300 seconds (10:30:00 -> 10:35:00)
Press Ctrl+C to stop continuous monitoring...
```

## Technical Details

### Windows (PowerShell)

The script uses the following built-in Windows tools and APIs:

- `Test-Connection` - For ICMP pings
- `System.Net.Dns` - For DNS resolution
- `System.Net.Sockets.TcpClient` - For port testing and TCP latency
- `Export-Csv` - For CSV export

### MacOS / Linux (Bash)

The script uses the following standard Unix tools:

- `ping` - For ICMP echo requests (compatible with both MacOS and Linux)
- `dig` or `host` - For DNS resolution timing
- `/dev/tcp` - For TCP connection testing (Bash built-in)
- `timeout` - For connection timeouts
- `date`, `awk`, `sed`, `bc` - For calculations and data processing

All measurements are performed without external tools or dependencies.

### Performance & Security

**Performance Optimizations:**
- Reduced ping count (4 instead of 10) for faster tests
- Reduced timeouts for efficient resource usage
- Delays between TCP tests (100ms) to avoid aggressive scanning
- Configurable test intervals for continuous operation

**Endpoint Security Compliance:**
- Minimal network activity per test
- Delays between connection attempts
- No parallel connections
- Respects standard timeouts
- No aggressive scan patterns

## License

MIT