# Network Performance Measurement Script

Ein PowerShell-Script für Windows 10/11 zur Messung der Netzwerkperformance zu mehreren Zielen (URLs und IPs).

A PowerShell script for Windows 10/11 to measure network performance to multiple targets (URLs and IPs).

## Features / Funktionen

- ✅ **Packet Loss** - Paketverlust messen
- ✅ **Latency** - Latenz (Durchschnitt, Min, Max)
- ✅ **Jitter** - Schwankungen in der Latenz
- ✅ **DNS Resolution Time** - DNS-Auflösungszeit
- ✅ **Port Connectivity** - Port-Erreichbarkeit testen
- ✅ **Connection Quality Assessment** - Automatische Bewertung der Verbindungsqualität
- ✅ **CSV Export** - Exportiert Ergebnisse in CSV-Datei
- ✅ **No Admin Rights Required** - Keine Administratorrechte erforderlich
- ✅ **Built-in Windows Tools Only** - Nur integrierte Windows-Tools

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
    @{Name="Google DNS"; Host="8.8.8.8"; Port=443},
    @{Name="Cloudflare DNS"; Host="1.1.1.1"; Port=443},
    @{Name="Google"; Host="www.google.com"; Port=443},
    @{Name="Microsoft"; Host="www.microsoft.com"; Port=443},
    @{Name="GitHub"; Host="github.com"; Port=443}
)
```

Jeder Eintrag benötigt:
- **Name**: Beschreibender Name für das Ziel
- **Host**: URL oder IP-Adresse
- **Port**: Port-Nummer zum Testen

Each entry requires:
- **Name**: Descriptive name for the target
- **Host**: URL or IP address
- **Port**: Port number to test

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

Sie können die Anzahl der Pings ändern:

You can change the number of pings:

```powershell
$PingCount = 10          # Anzahl der Pings / Number of pings
```

Sie können den TCP-Timeout ändern:

You can change the TCP timeout:

```powershell
$TcpTimeout = 3000       # TCP timeout in milliseconds
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

## Example Output / Beispielausgabe

Console:
```
======================================
  Network Performance Measurement
======================================

Timestamp: 2026-01-19 10:30:00
Ping Count: 10
Targets: 5

Testing: Google DNS (8.8.8.8:443)
============================================================
  Resolved IP: 8.8.8.8
  DNS Resolution Time: 0 ms
  Testing connectivity with 10 pings...
  Average Latency: 15.5 ms
  Min/Max Latency: 14 / 18 ms
  Jitter: 1.2 ms
  Packet Loss: 0% (10/10)
  Testing port 443 connectivity...
  Port 443: Open
  TCP Connection Time: 16 ms
  Connection Quality: Excellent
```

## Technical Details / Technische Details

Das Script verwendet folgende integrierte Windows-Tools und APIs:

The script uses the following built-in Windows tools and APIs:

- `Test-Connection` - Für ICMP-Pings / For ICMP pings
- `System.Net.Dns` - Für DNS-Auflösung / For DNS resolution
- `System.Net.Sockets.TcpClient` - Für Port-Tests / For port testing
- `Export-Csv` - Für CSV-Export / For CSV export

Alle Messungen erfolgen ohne externe Tools oder Abhängigkeiten.

All measurements are performed without external tools or dependencies.

## License

MIT