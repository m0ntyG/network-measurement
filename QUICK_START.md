# Quick Start Guide

## How to run the script:

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

### Connection Quality:

- **Excellent**: Perfect for gaming, VoIP, video streaming
- **Good**: Good for most applications
- **Fair**: Acceptable, but may have issues with real-time applications
- **Poor**: Bad, likely network problems

## Example

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
  Connection Quality: Excellent

Summary:
TargetName Protocol AvgLatency_ms Jitter_ms PacketLoss_percent ConnectionQuality
---------- -------- ------------- --------- ------------------ -----------------
Google DNS ICMP              15.5       1.2                  0 Excellent

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
