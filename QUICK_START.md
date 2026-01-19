# Quick Start Guide

## Choose Your Platform

- [Windows](#windows) - PowerShell script
- [MacOS / Linux](#macos--linux) - Bash script

---

## Windows

### How to run the script:

1. **Easiest method**: Right-click on `measure-network.ps1`
   - Choose "Run with PowerShell"
   - The script will run automatically
   - Wait for all tests to complete
   - Results are saved to `network_measurement_results.csv`

2. **PowerShell command line**:
   - Open PowerShell and type:
     ```powershell
     cd path\to\folder
     .\measure-network.ps1
     ```

3. **If you get an Execution Policy error**:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\measure-network.ps1
   ```

### Customize targets:

1. Open `measure-network.ps1` with a text editor (Notepad++)
2. Find the section with `$Targets = @(`
3. Add new lines or modify existing ones:
   ```powershell
   @{Name="My Server"; Host="192.168.1.100"; Port=80; Protocol="ICMP"},
   @{Name="Web Server"; Host="example.com"; Port=443; Protocol="TCP"},
   ```

### Continuous Mode:

The script runs continuously by default and tests every 5 minutes:
- `$ContinuousMode = $true` - Run continuously
- `$ContinuousMode = $false` - Run once
- `$TestInterval = 300` - Seconds between tests (300 = 5 minutes)

To stop the script: Press **Ctrl+C**

### What is measured?

- **DNS Resolution Time**: Time to resolve hostname to IP address
- **Latency**: Time for a data packet to make a round trip
- **Jitter**: Variations in latency (important for VoIP/gaming)
- **Packet Loss**: Percentage of lost data packets
- **Port Status**: Whether the specified port is reachable
- **Protocol**: ICMP (Ping) or TCP (Connection test)

### Protocol Selection:

- **ICMP**: Fast, standard ping, may be blocked by firewalls
- **TCP**: Tests actual connection to port, works through firewalls

### Connection Quality Reference:

You can interpret the values yourself using common benchmarks:

- **Excellent**: < 1% packet loss, < 50ms latency, < 15ms jitter (Perfect for gaming, VoIP, video streaming)
- **Good**: < 3% packet loss, < 100ms latency, < 30ms jitter (Good for most applications)
- **Fair**: < 5% packet loss, < 200ms latency, < 50ms jitter (Acceptable, but may have issues with real-time applications)
- **Poor**: ≥ 5% packet loss, ≥ 200ms latency, ≥ 50ms jitter (Bad, likely network problems)

## Example Output (Both Platforms)

```
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
  

Summary:
TargetName Protocol AvgLatency_ms Jitter_ms PacketLoss_percent
---------- -------- ------------- --------- ------------------
Google DNS ICMP              15.5       1.2                  0

Next test in 300 seconds (10:30:00 -> 10:35:00)
Press Ctrl+C to stop continuous monitoring...
```

## Troubleshooting

**Problem**: Script cannot be executed (Execution Policy)
**Solution**: Run:
```powershell
powershell -ExecutionPolicy Bypass -File .\measure-network.ps1
```

**Problem**: "Test-Connection" error
**Solution**: Make sure ICMP is not blocked by your firewall

**Problem**: All ports show "Closed"
**Solution**: Normal if a firewall restricts outgoing connections

---

## MacOS / Linux

### How to run the script:

1. **From Terminal**:
   ```bash
   cd /path/to/network-measurement
   chmod +x measure-network.sh
   ./measure-network.sh
   ```

2. **Or run with bash directly**:
   ```bash
   cd /path/to/network-measurement
   bash measure-network.sh
   ```

### Customize targets:

1. Open `measure-network.sh` with a text editor (nano, vim, or any editor)
2. Find the section with `TARGETS=(`
3. Add new lines or modify existing ones:
   ```bash
   "My Server|192.168.1.100|80|ICMP"
   "Web Server|example.com|443|TCP"
   ```

   Format: `"Name|Host|Port|Protocol"`

### Continuous Mode:

The script runs continuously by default and tests every 5 minutes:
- `CONTINUOUS_MODE=true` - Run continuously
- `CONTINUOUS_MODE=false` - Run once
- `TEST_INTERVAL=300` - Seconds between tests (300 = 5 minutes)

To stop the script: Press **Ctrl+C**

### What is measured?

- **DNS Resolution Time**: Time to resolve hostname to IP address
- **Latency**: Time for a data packet to make a round trip
- **Jitter**: Variations in latency (important for VoIP/gaming)
- **Packet Loss**: Percentage of lost data packets
- **Port Status**: Whether the specified port is reachable
- **Protocol**: ICMP (Ping) or TCP (Connection test)

### Protocol Selection:

- **ICMP**: Fast, standard ping, may be blocked by firewalls
- **TCP**: Tests actual connection to port, works through firewalls

### Connection Quality:

- **Excellent**: < 1% packet loss, < 50ms latency, < 15ms jitter (Perfect for gaming, VoIP, video streaming)
- **Good**: < 3% packet loss, < 100ms latency, < 30ms jitter (Good for most applications)
- **Fair**: < 5% packet loss, < 200ms latency, < 50ms jitter (Acceptable, but may have issues with real-time applications)
- **Poor**: ≥ 5% packet loss, ≥ 200ms latency, ≥ 50ms jitter (Bad, likely network problems)

## Example Output (Both Platforms)

```
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
  

Summary:
TargetName Protocol AvgLatency_ms Jitter_ms PacketLoss_percent
---------- -------- ------------- --------- ------------------
Google DNS ICMP              15.5       1.2                  0

Next test in 300 seconds (10:30:00 -> 10:35:00)
Press Ctrl+C to stop continuous monitoring...
```

## Troubleshooting

### Windows

**Problem**: Script cannot be executed (Execution Policy)
**Solution**: Run:
```powershell
powershell -ExecutionPolicy Bypass -File .\measure-network.ps1
```

**Problem**: "Test-Connection" error
**Solution**: Make sure ICMP is not blocked by your firewall

**Problem**: All ports show "Closed"
**Solution**: Normal if a firewall restricts outgoing connections

### MacOS / Linux

**Problem**: Permission denied when running script
**Solution**: Make sure the script is executable:
```bash
chmod +x measure-network.sh
```

**Problem**: "ping: command not found" or similar tool errors
**Solution**: Install missing tools:
- Ubuntu/Debian: `sudo apt-get install iputils-ping dnsutils bc`
- CentOS/RHEL: `sudo yum install iputils bind-utils bc`
- MacOS: Tools are pre-installed, ensure you're using bash shell

**Problem**: All ICMP pings fail (100% packet loss)
**Solution**: 
- Normal if ICMP is blocked by firewall
- Try using TCP protocol instead for those targets
- Some networks block ICMP for security reasons

**Problem**: "timeout: command not found"
**Solution**: Install coreutils:
- Ubuntu/Debian: `sudo apt-get install coreutils`
- MacOS: `brew install coreutils` (requires Homebrew)
