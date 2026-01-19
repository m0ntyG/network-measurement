# Schnellstart-Anleitung / Quick Start Guide

## Deutsch

### So führen Sie das Script aus:

1. **Einfachste Methode**: Rechtsklick auf `measure-network.ps1`
   - "Mit PowerShell ausführen" wählen
   - Das Script wird automatisch ausgeführt
   - Warten Sie, bis alle Tests abgeschlossen sind
   - Die Ergebnisse werden in `network_measurement_results.csv` gespeichert

2. **PowerShell Kommandozeile**:
   - PowerShell öffnen und eingeben:
     ```powershell
     cd Pfad\zum\Ordner
     .\measure-network.ps1
     ```
   
3. **Bei Execution Policy Fehler**:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\measure-network.ps1
   ```

### Ziele anpassen:

1. Öffnen Sie `measure-network.ps1` mit einem Texteditor (Notepad++)
2. Suchen Sie nach dem Abschnitt mit `$Targets = @(`
3. Fügen Sie neue Zeilen hinzu oder ändern Sie bestehende:
   ```powershell
   @{Name="Mein Server"; Host="192.168.1.100"; Port=80; Protocol="ICMP"},
   @{Name="Webserver"; Host="example.com"; Port=443; Protocol="TCP"},
   ```

### Kontinuierlicher Modus:

Das Script läuft standardmäßig kontinuierlich und testet alle 5 Minuten:
- `$ContinuousMode = $true` - Kontinuierlich laufen lassen
- `$ContinuousMode = $false` - Nur einmal ausführen
- `$TestInterval = 300` - Sekunden zwischen Tests (300 = 5 Minuten)

Um das Script zu stoppen: **Ctrl+C** drücken

### Was wird gemessen?

- **DNS-Auflösungszeit**: Zeit zur Auflösung des Hostnamens in IP-Adresse
- **Netzwerklatenz**: Zeit, die ein Datenpaket für Hin- und Rückweg benötigt
- **Jitter**: Schwankungen in der Latenz (wichtig für VoIP/Gaming)
- **Packet Loss**: Prozentsatz verlorener Datenpakete
- **Port-Status**: Ob der angegebene Port erreichbar ist
- **Protokoll**: ICMP (Ping) oder TCP (Verbindungstest)

### Protokollauswahl:

- **ICMP**: Schnell, Standard-Ping, kann von Firewalls blockiert werden
- **TCP**: Testet tatsächliche Verbindung zum Port, funktioniert durch Firewalls

### Verbindungsqualität:

- **Excellent**: Perfekt für Gaming, VoIP, Video-Streaming
- **Good**: Gut für die meisten Anwendungen
- **Fair**: Akzeptabel, aber möglicherweise Probleme bei Echtzeit-Anwendungen
- **Poor**: Schlecht, wahrscheinlich Netzwerkprobleme

---

## English

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
- **Network Latency**: Time for a data packet to make a round trip
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

---

## Beispiel / Example

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

## Fehlerbehebung / Troubleshooting

**Problem**: Script kann nicht ausgeführt werden (Execution Policy)
**Lösung**: Führen Sie aus:
```powershell
powershell -ExecutionPolicy Bypass -File .\measure-network.ps1
```

**Problem**: "Test-Connection" Fehler
**Lösung**: Stellen Sie sicher, dass ICMP nicht von Ihrer Firewall blockiert wird

**Problem**: Alle Ports zeigen "Closed"
**Lösung**: Normal, wenn eine Firewall ausgehende Verbindungen einschränkt
