# Network Measurement Project - AI Coding Guidelines

## Project Overview

Cross-platform network performance measurement tool with PowerShell (Windows) and Bash (Mac/Linux) implementations. Measures DNS resolution, latency, jitter, packet loss, and port connectivity using only built-in system tools. No admin privileges required.

## Architecture Patterns

### Dual Implementation Structure

- **measure-network.ps1**: Windows PowerShell implementation
- **measure-network.sh**: Cross-platform Bash implementation
- Identical functionality with platform-specific tool usage (Test-Connection vs ping, .NET DNS vs dig/host)

### Configuration-Driven Design

Edit target lists and settings at script top:

```bash
TARGETS=(
    "Google DNS|8.8.8.8||ICMP"
    "Google|www.google.com|443|TCP"
)
```

### Measurement Pipeline

For each target: DNS resolution → Latency measurement → Port connectivity → CSV export

## Key Code Patterns

### Target Configuration Format

- **Bash**: `"Name|Host|Port|Protocol"` (empty Port for ICMP)
- **PowerShell**: `@{Name="Name"; Host="host"; Port=$null; Protocol="ICMP"}`

### Cross-Platform Compatibility

- Detect OS with `uname -s` (Bash) or runtime environment (PowerShell)
- Handle ping output differences (MacOS "round-trip" vs Linux "rtt min/avg/max")
- Fallback DNS tools: `dig` → `host` → fail
- TCP testing: `nc` → `/dev/tcp` → fail

### CSV Export with Backward Compatibility

- Append mode for continuous monitoring
- Auto-add missing columns when schema evolves
- Headers: `Timestamp,TargetName,Hostname,Port,Protocol,ResolvedIP,DnsResolutionTime_ms,...`

### Error Handling

- Graceful degradation: failed measurements return 0/-1 values
- Continue processing other targets on individual failures
- Color-coded console output for status indication

## Development Workflow

### Testing Changes

1. Edit configuration section at script top
2. Run script: `.\measure-network.ps1` (Windows) or `./measure-network.sh` (Mac/Linux)
3. Check `network_measurement_results.csv` output
4. Verify CSV format matches existing data

### Adding New Metrics

1. Add measurement function (e.g., `measure_new_metric()`)
2. Update result object/hashtable with new fields
3. Modify CSV header logic to include new column
4. Ensure backward compatibility with existing CSVs

### Cross-Platform Testing

- Test on both Windows (PowerShell) and Mac/Linux (Bash)
- Verify ping syntax differences handled
- Confirm DNS resolution fallbacks work
- Validate TCP connection methods

## Common Patterns to Follow

### Function Organization

- Helper functions for each measurement type
- Consistent parameter order: target, count, timeout
- Return formatted strings or hashtables with all metrics

### Continuous Mode Implementation

- `$ContinuousMode = $true` with `$TestInterval` seconds
- Infinite loop with sleep between cycles
- Ctrl+C to exit gracefully

### Performance Optimizations

- Reduced ping count (default 4) for minimal system load
- Shortened timeouts (2s TCP, 1s ping) for responsiveness
- Built-in tool preference over external dependencies
