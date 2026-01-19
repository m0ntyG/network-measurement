# Network Performance Measurement Script

Ein PowerShell-Script für Windows 10/11 zur Messung der Netzwerkperformance zu mehreren Zielen (URLs und IPs).

A PowerShell script for Windows 10/11 to measure network performance to multiple targets (URLs and IPs).

## Features / Funktionen

- ✅ **Packet Loss** - Paketverlust messen
- ✅ **Latency** - Latenz (Durchschnitt, Min, Max)
- ✅ **Jitter** - Schwankungen in der Latenz
- ✅ **DNS Resolution Time** - DNS-Auflösungszeit
- ✅ **Port Connectivity** - Port-Erreichbarkeit testen
- ✅ **Protocol Selection** - Wählbar zwischen TCP und ICMP pro Ziel
- ✅ **Continuous Monitoring** - Kontinuierliche Überwachung mit konfigurierbarem Intervall
- ✅ **Connection Quality Assessment** - Automatische Bewertung der Verbindungsqualität
- ✅ **CSV Export** - Exportiert Ergebnisse in CSV-Datei (append mode für kontinuierliche Überwachung)
- ✅ **Performance Optimized** - Reduzierte Ping-Anzahl und Timeouts für minimale Systemlast
- ✅ **No Admin Rights Required** - Keine Administratorrechte erforderlich
- ✅ **Built-in Windows Tools Only** - Nur integrierte Windows-Tools
- ✅ **Endpoint Security Friendly** - Verzögerungen zwischen Tests um Sicherheitsrichtlinien zu respektieren

## Requirements / Voraussetzungen

- Windows 10 oder Windows 11
- PowerShell (bereits installiert)
- Keine Administratorrechte erforderlich

## Usage / Verwendung

### 1. Konfiguration / Configuration

Öffnen Sie die Datei `measure-network.ps1` und bearbeiten Sie die Zielliste am Anfang:

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

Jeder Eintrag benötigt:
- **Name**: Beschreibender Name für das Ziel
- **Host**: URL oder IP-Adresse
- **Port**: Port-Nummer zum Testen
- **Protocol**: "ICMP" für Ping oder "TCP" für TCP-Verbindungen

Each entry requires:
- **Name**: Descriptive name for the target
- **Host**: URL or IP address
- **Port**: Port number to test
- **Protocol**: "ICMP" for ping or "TCP" for TCP connections

**Kontinuierlicher Modus / Continuous Mode:**
- `$ContinuousMode = $true` - Läuft kontinuierlich / Runs continuously
- `$ContinuousMode = $false` - Einmaliger Durchlauf / Single run
- `$TestInterval` - Sekunden zwischen Tests / Seconds between tests (300 = 5 Minuten/minutes)

### 2. Ausführung / Execution

#### PowerShell ausführen / Run PowerShell:

```powershell
cd path\to\network-measurement
.\measure-network.ps1
```

Falls Sie eine Fehlermeldung zur Ausführungsrichtlinie erhalten / If you get an execution policy error:

```powershell
powershell -ExecutionPolicy Bypass -File .\measure-network.ps1
```

### 3. Ergebnisse / Results

Das Script erstellt eine CSV-Datei mit dem Namen `network_measurement_results.csv` im gleichen Verzeichnis.

The script creates a CSV file named `network_measurement_results.csv` in the same directory.

#### CSV-Felder / CSV Fields:

- **Timestamp** - Zeitstempel der Messung
- **TargetName** - Name des Ziels
- **Hostname** - Hostname oder IP
- **Port** - Getesteter Port
- **Protocol** - Verwendetes Protokoll (ICMP/TCP)
- **ResolvedIP** - Aufgelöste IP-Adresse
- **DnsResolutionTime_ms** - DNS-Auflösungszeit in Millisekunden
- **AvgLatency_ms** - Durchschnittliche Latenz in ms
- **MinLatency_ms** - Minimale Latenz in ms
- **MaxLatency_ms** - Maximale Latenz in ms
- **Jitter_ms** - Jitter in ms
- **PacketLoss_percent** - Paketverlust in Prozent
- **PacketsSent** - Anzahl gesendeter Pakete
- **PacketsReceived** - Anzahl empfangener Pakete
- **PortOpen** - Port erreichbar (True/False)
- **TcpConnectionTime_ms** - TCP-Verbindungszeit in ms
- **ConnectionQuality** - Verbindungsqualität (Excellent/Good/Fair/Poor)

## Connection Quality Criteria / Verbindungsqualitätskriterien

| Quality | Packet Loss | Avg Latency | Jitter |
|---------|-------------|-------------|--------|
| Excellent | < 1% | < 50 ms | < 15 ms |
| Good | < 1% | < 100 ms | < 30 ms |
| Fair | < 5% | < 200 ms | < 50 ms |
| Poor | ≥ 5% | ≥ 200 ms | ≥ 50 ms |

## Anpassungen / Customization

Sie können die Anzahl der Pings ändern (reduziert für bessere Performance):

You can change the number of pings (reduced for better performance):

```powershell
$PingCount = 4           # Anzahl der Pings / Number of pings
```

Sie können den TCP-Timeout ändern (reduziert für bessere Performance):

You can change the TCP timeout (reduced for better performance):

```powershell
$TcpTimeout = 2000       # TCP timeout in milliseconds
```

Sie können den kontinuierlichen Modus aktivieren/deaktivieren:

You can enable/disable continuous mode:

```powershell
$ContinuousMode = $true  # true für kontinuierlich / true for continuous
$TestInterval = 300      # Sekunden zwischen Tests / Seconds between tests
```

Sie können den Namen der Ausgabedatei ändern:

You can change the output file name:

```powershell
$OutputFile = "network_measurement_results.csv"
```

Sie können die Qualitätsschwellenwerte anpassen:

You can customize the quality thresholds:

```powershell
$QualityThresholds = @{
    Excellent = @{PacketLoss = 1; Latency = 50; Jitter = 15}
    Good = @{PacketLoss = 1; Latency = 100; Jitter = 30}
    Fair = @{PacketLoss = 5; Latency = 200; Jitter = 50}
}
```

## Protocol Selection / Protokollauswahl

**ICMP (Ping):**
- Verwendet Standard-ICMP-Echo-Anfragen
- Schneller und weniger ressourcenintensiv
- Kann von Firewalls blockiert werden
- Gut für allgemeine Netzwerkkonnektivität

**TCP:**
- Misst TCP-Verbindungszeit zum angegebenen Port
- Realistischer für Anwendungslatenzen
- Funktioniert durch die meisten Firewalls
- Etwas langsamer als ICMP

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

## Example Output / Beispielausgabe

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
  Connection Quality: Excellent

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
  Connection Quality: Excellent

Summary:
TargetName    Protocol AvgLatency_ms Jitter_ms PacketLoss_percent ConnectionQuality
----------    -------- ------------- --------- ------------------ -----------------
Google DNS    ICMP              15.5       1.2                  0 Excellent
Google        TCP               18.7       2.3                  0 Excellent

Next test in 300 seconds (10:30:00 -> 10:35:00)
Press Ctrl+C to stop continuous monitoring...
```

## Technical Details / Technische Details

Das Script verwendet folgende integrierte Windows-Tools und APIs:

The script uses the following built-in Windows tools and APIs:

- `Test-Connection` - Für ICMP-Pings / For ICMP pings
- `System.Net.Dns` - Für DNS-Auflösung / For DNS resolution
- `System.Net.Sockets.TcpClient` - Für Port-Tests und TCP-Latenz / For port testing and TCP latency
- `Export-Csv` - Für CSV-Export / For CSV export

Alle Messungen erfolgen ohne externe Tools oder Abhängigkeiten.

All measurements are performed without external tools or dependencies.

### Performance & Security / Performance & Sicherheit

**Performance-Optimierungen:**
- Reduzierte Ping-Anzahl (4 statt 10) für schnellere Tests
- Reduzierte Timeouts für effizientere Ressourcennutzung
- Verzögerungen zwischen TCP-Tests (100ms) um aggressive Scans zu vermeiden
- Konfigurierbare Testintervalle für kontinuierlichen Betrieb

**Endpoint Security Compliance:**
- Minimale Netzwerkaktivität pro Test
- Verzögerungen zwischen Verbindungsversuchen
- Keine parallelen Verbindungen
- Respektiert Standard-Timeouts
- Keine aggressiven Scan-Muster

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