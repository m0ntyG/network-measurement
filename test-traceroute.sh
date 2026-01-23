#!/usr/bin/env bash
# Quick test of traceroute function

# Source the main script functions
OS_TYPE=$(uname -s)

# Test tracepath
echo "Testing tracepath availability:"
which tracepath
echo ""

echo "Testing tracepath to 8.8.8.8 (max 10 hops):"
timeout 30 tracepath -m 10 8.8.8.8 2>&1 | head -20
