#!/usr/bin/env bash
# Network Performance Measurement Script
# This script measures network performance to multiple targets using built-in Unix tools
# Compatible with MacOS and Linux, requires no admin privileges

#region Configuration - Edit targets here
# Target configuration: Name|Host|Port|Protocol
# Protocol can be ICMP or TCP
# For ICMP: Port can be empty or set to "N/A" (not used for ICMP ping)
# For TCP: Port is required and used for TCP connection testing
TARGETS=(
    "Google DNS|8.8.8.8||ICMP"
    "Cloudflare DNS|1.1.1.1||ICMP"
    "Google|www.google.com|443|TCP"
    "Microsoft|www.microsoft.com|443|TCP"
    "GitHub|github.com|443|TCP"
)

# Measurement settings
PING_COUNT=4                    # Number of pings to send
TCP_TIMEOUT=2                   # TCP connection timeout in seconds
OUTPUT_FILE="network_measurement_results.csv"
CONTINUOUS_MODE=true            # Run continuously
TEST_INTERVAL=300               # Interval between test cycles in seconds (5 minutes)

#endregion

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Detect OS for ping command differences
OS_TYPE=$(uname -s)

# Function to get milliseconds timestamp (cross-platform)
get_milliseconds() {
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        # MacOS: Use Python for millisecond precision
        python3 -c 'import time; print(int(time.time() * 1000))' 2>/dev/null || echo $(($(date +%s) * 1000))
    else
        # Linux: Use date with milliseconds
        date +%s%3N
    fi
}

#region Helper Functions

# Function to measure DNS resolution time
measure_dns_resolution() {
    local hostname="$1"
    local resolved_ip=""
    local dns_time=0
    
    # Check if it's already an IP address
    if [[ $hostname =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$hostname|0"
        return 0
    fi
    
    echo -e "${CYAN}  Resolving DNS...${NC}" >&2
    
    # Use dig for DNS resolution timing
    if command -v dig &> /dev/null; then
        local start_time=$(get_milliseconds)
        local dig_output=$(dig +short "$hostname" A 2>/dev/null | awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ {print; exit}')
        local end_time=$(get_milliseconds)
        
        if [[ -n "$dig_output" ]]; then
            resolved_ip="$dig_output"
            dns_time=$((end_time - start_time))
        else
            resolved_ip="Failed"
            dns_time=-1
        fi
    # Fallback to host command
    elif command -v host &> /dev/null; then
        local start_time=$(get_milliseconds)
        local host_output=$(host "$hostname" 2>/dev/null | grep "has address" | head -1 | awk '{print $NF}')
        local end_time=$(get_milliseconds)
        
        if [[ -n "$host_output" ]]; then
            resolved_ip="$host_output"
            dns_time=$((end_time - start_time))
        else
            resolved_ip="Failed"
            dns_time=-1
        fi
    else
        resolved_ip="Failed"
        dns_time=-1
    fi
    
    echo "$resolved_ip|$dns_time"
}

# Function to measure latency using ICMP ping
measure_latency() {
    local target="$1"
    local count="$2"
    
    echo -e "${CYAN}  Testing connectivity with $count pings...${NC}" >&2
    
    # Different ping syntax for Linux vs MacOS
    local ping_output
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        # MacOS ping syntax
        ping_output=$(ping -c "$count" -W 1000 "$target" 2>/dev/null)
    else
        # Linux ping syntax
        ping_output=$(ping -c "$count" -W 1 "$target" 2>/dev/null)
    fi
    
    if [[ $? -ne 0 ]]; then
        # Ping failed completely
        echo "0|0|0|0|100|$count|0"
        return 1
    fi
    
    # Extract statistics
    local packets_received=$(echo "$ping_output" | awk '/received/ {for(i=1;i<=NF;i++) if($(i+1)=="received") print $i}' || echo "0")
    local packet_loss=$(echo "$ping_output" | awk '/packet loss/ {for(i=1;i<=NF;i++) if($i ~ /%/) {sub(/%/,"",$i); print $i}}' || echo "100")
    
    # MacOS and Linux have different output formats
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        # MacOS: round-trip min/avg/max/stddev = 14.123/15.456/18.789/1.234 ms
        local stats=$(echo "$ping_output" | grep "round-trip" | awk -F'[=/]' '{print $2"|"$3"|"$4"|"$5}')
    else
        # Linux: rtt min/avg/max/mdev = 14.123/15.456/18.789/1.234 ms
        local stats=$(echo "$ping_output" | grep "rtt min/avg/max/mdev" | awk -F'[=/]' '{print $2"|"$3"|"$4"|"$5}')
    fi
    
    if [[ -z "$stats" ]]; then
        echo "0|0|0|0|100|$count|0"
        return 1
    fi
    
    IFS='|' read -r min_latency avg_latency max_latency mdev <<< "$stats"
    
    # Calculate jitter (approximated by standard deviation/mdev)
    local jitter=$(echo "$mdev" | awk '{printf "%.2f", $1}')
    
    # Round values
    avg_latency=$(echo "$avg_latency" | awk '{printf "%.2f", $1}')
    min_latency=$(echo "$min_latency" | awk '{printf "%.0f", $1}')
    max_latency=$(echo "$max_latency" | awk '{printf "%.0f", $1}')
    packet_loss=$(echo "$packet_loss" | awk '{printf "%.2f", $1}')
    
    echo "$avg_latency|$min_latency|$max_latency|$jitter|$packet_loss|$count|$packets_received"
}

# Function to measure TCP latency
measure_tcp_latency() {
    local target="$1"
    local port="$2"
    local count="$3"
    local timeout="$4"
    
    echo -e "${CYAN}  Testing TCP connectivity to port $port with $count attempts...${NC}" >&2
    
    local response_times=()
    local success_count=0
    
    for ((i=0; i<count; i++)); do
        local start_time=$(get_milliseconds)
        
        # Try TCP connection using timeout and /dev/tcp
        if timeout "$timeout" bash -c "echo >/dev/tcp/$target/$port" 2>/dev/null; then
            local end_time=$(get_milliseconds)
            local response_time=$((end_time - start_time))
            response_times+=("$response_time")
            ((success_count++))
        fi
        
        # Small delay between attempts
        if [[ $i -lt $((count - 1)) ]]; then
            sleep 0.1
        fi
    done
    
    if [[ $success_count -eq 0 ]]; then
        echo "0|0|0|0|100|$count|0"
        return 1
    fi
    
    # Calculate statistics
    local sum=0
    local min=999999
    local max=0
    
    for time in "${response_times[@]}"; do
        sum=$((sum + time))
        if [[ $time -lt $min ]]; then
            min=$time
        fi
        if [[ $time -gt $max ]]; then
            max=$time
        fi
    done
    
    local avg=$(echo "scale=2; $sum / $success_count" | bc)
    
    # Calculate jitter (average deviation)
    local jitter_sum=0
    for time in "${response_times[@]}"; do
        local deviation=$(echo "$time - ($avg)" | bc | awk '{if ($1 < 0) print -$1; else print $1}')
        jitter_sum=$(echo "scale=2; $jitter_sum + $deviation" | bc)
    done
    local jitter=$(echo "scale=2; $jitter_sum / $success_count" | bc)
    
    local packet_loss=$(echo "scale=2; (($count - $success_count) / $count) * 100" | bc)
    
    echo "$avg|$min|$max|$jitter|$packet_loss|$count|$success_count"
}

# Function to test port connectivity
test_port_connectivity() {
    local target="$1"
    local port="$2"
    local timeout="$3"
    
    echo -e "${CYAN}  Testing port $port connectivity...${NC}" >&2
    
    local start_time=$(get_milliseconds)
    
    if timeout "$timeout" bash -c "echo >/dev/tcp/$target/$port" 2>/dev/null; then
        local end_time=$(get_milliseconds)
        local connection_time=$((end_time - start_time))
        echo "true|$connection_time"
        return 0
    else
        echo "false|-1"
        return 1
    fi
}

#endregion

#region Main Script

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  Network Performance Measurement${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo -e "${WHITE}  Continuous Mode: $CONTINUOUS_MODE${NC}"
if [[ "$CONTINUOUS_MODE" == "true" ]]; then
    interval_minutes=$(echo "scale=1; $TEST_INTERVAL / 60" | bc)
    echo -e "${WHITE}  Test Interval: $TEST_INTERVAL seconds ($interval_minutes minutes)${NC}"
fi
echo -e "${WHITE}  Ping Count: $PING_COUNT${NC}"
echo -e "${WHITE}  Targets: ${#TARGETS[@]}${NC}"
echo -e "${WHITE}  Output File: $OUTPUT_FILE${NC}"
echo ""

# CSV file initialization
csv_exists=false
if [[ -f "$OUTPUT_FILE" ]]; then
    csv_exists=true
fi

test_cycle=0

while true; do
    ((test_cycle++))
    
    if [[ "$CONTINUOUS_MODE" == "true" ]]; then
        echo ""
        echo -e "${CYAN}======================================${NC}"
        echo -e "${CYAN}  Test Cycle #$test_cycle - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
        echo -e "${CYAN}======================================${NC}"
        echo ""
    fi
    
    # Temporary file for results
    temp_results=$(mktemp)
    
    # Add CSV header if file doesn't exist
    if [[ "$csv_exists" == "false" ]]; then
        echo "Timestamp,TargetName,Hostname,Port,Protocol,ResolvedIP,DnsResolutionTime_ms,AvgLatency_ms,MinLatency_ms,MaxLatency_ms,Jitter_ms,PacketLoss_percent,PacketsSent,PacketsReceived,PortOpen,TcpConnectionTime_ms" > "$OUTPUT_FILE"
        csv_exists=true
    fi
    
    # Process each target
    for target_line in "${TARGETS[@]}"; do
        IFS='|' read -r name host port protocol <<< "$target_line"
        
        # Validate and normalize protocol
        protocol=$(echo "$protocol" | tr '[:lower:]' '[:upper:]')
        if [[ "$protocol" != "ICMP" && "$protocol" != "TCP" ]]; then
            echo -e "${YELLOW}Warning: Invalid protocol '$protocol' for target '$name'. Defaulting to ICMP.${NC}"
            protocol="ICMP"
        fi
        
        # Display target info (with or without port depending on protocol)
        if [[ "$protocol" == "ICMP" ]]; then
            echo -e "${GREEN}Testing: $name ($host) [Protocol: $protocol]${NC}"
        else
            echo -e "${GREEN}Testing: $name ($host:$port) [Protocol: $protocol]${NC}"
        fi
        echo -e "${GRAY}$(printf '=%.0s' {1..60})${NC}"
        
        # DNS Resolution
        dns_result=$(measure_dns_resolution "$host")
        IFS='|' read -r resolved_ip dns_time <<< "$dns_result"
        
        echo -e "${WHITE}  Resolved IP: $resolved_ip${NC}"
        if [[ $dns_time -ge 0 ]]; then
            echo -e "${WHITE}  DNS Resolution Time: $dns_time ms${NC}"
        fi
        
        # Latency, Jitter, Packet Loss based on protocol
        if [[ "$protocol" == "TCP" ]]; then
            echo -e "${CYAN}  Protocol: TCP${NC}"
            latency_result=$(measure_tcp_latency "$host" "$port" "$PING_COUNT" "$TCP_TIMEOUT")
        else
            echo -e "${CYAN}  Protocol: ICMP${NC}"
            latency_result=$(measure_latency "$host" "$PING_COUNT")
        fi
        
        IFS='|' read -r avg_latency min_latency max_latency jitter packet_loss packets_sent packets_received <<< "$latency_result"
        
        echo -e "${WHITE}  Average Latency: $avg_latency ms${NC}"
        echo -e "${WHITE}  Min/Max Latency: $min_latency / $max_latency ms${NC}"
        echo -e "${WHITE}  Jitter: $jitter ms${NC}"
        echo -e "${WHITE}  Packet Loss: $packet_loss% ($packets_received/$packets_sent)${NC}"
        
        # Port Connectivity (only for TCP protocol)
        if [[ "$protocol" == "TCP" ]]; then
            # For TCP protocol, port is implicitly tested via latency measurement
            if (( $(echo "$packet_loss < 100" | bc -l) )); then
                port_open="true"
                connection_time="$avg_latency"
            else
                port_open="false"
                connection_time="-1"
            fi
            csv_port="$port"
        else
            # For ICMP protocol, port testing is not applicable
            port_open="N/A"
            connection_time="-1"
            csv_port="N/A"
        fi
        
        # Store results
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "$timestamp,$name,$host,$csv_port,$protocol,$resolved_ip,$dns_time,$avg_latency,$min_latency,$max_latency,$jitter,$packet_loss,$packets_sent,$packets_received,$port_open,$connection_time" >> "$temp_results"
        
        echo ""
    done
    
    # Append results to CSV
    cat "$temp_results" >> "$OUTPUT_FILE"
    
    echo -e "${GREEN}Exporting results to: $OUTPUT_FILE${NC}"
    echo ""
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}  Measurement Complete!${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo ""
    
    # Display summary table
    echo -e "${GREEN}Summary:${NC}"
    printf "%-20s %-8s %-13s %-9s %-18s\n" "TargetName" "Protocol" "AvgLatency_ms" "Jitter_ms" "PacketLoss_percent"
    printf "%-20s %-8s %-13s %-9s %-18s\n" "----------" "--------" "-------------" "---------" "------------------"
    
    while IFS=',' read -r timestamp name host port protocol resolved_ip dns_time avg_latency min_latency max_latency jitter packet_loss packets_sent packets_received port_open connection_time; do
        printf "%-20s %-8s %-13s %-9s %-18s\n" "$name" "$protocol" "$avg_latency" "$jitter" "$packet_loss"
    done < "$temp_results"
    
    # Clean up temp file
    rm -f "$temp_results"
    
    # If continuous mode, wait for next cycle
    if [[ "$CONTINUOUS_MODE" == "true" ]]; then
        echo ""
        # Calculate next test time in a cross-platform way
        current_time=$(date '+%H:%M:%S')
        next_time=""
        if [[ "$OS_TYPE" == "Darwin" ]]; then
            # MacOS uses -v for date arithmetic
            next_time=$(date -v +${TEST_INTERVAL}S '+%H:%M:%S' 2>/dev/null || echo "N/A")
        else
            # Linux uses -d for date arithmetic
            next_time=$(date -d "+$TEST_INTERVAL seconds" '+%H:%M:%S' 2>/dev/null || echo "N/A")
        fi
        echo -e "${YELLOW}Next test in $TEST_INTERVAL seconds ($current_time -> $next_time)${NC}"
        echo -e "${GRAY}Press Ctrl+C to stop continuous monitoring...${NC}"
        echo ""
        
        sleep "$TEST_INTERVAL"
    else
        break
    fi
done

#endregion
