# Schnellstart-Anleitung / Quick Start Guide

## Deutsch

### So führen Sie das Script aus:

1. **Einfachste Methode**: Doppelklick auf `run-measurement.bat`
   - Das Script wird automatisch ausgeführt
   - Warten Sie, bis alle Tests abgeschlossen sind
   - Die Ergebnisse werden in `network_measurement_results.csv` gespeichert

2. **PowerShell-Methode**:
   - Rechtsklick auf `measure-network.ps1`
   - "Mit PowerShell ausführen" wählen
   - ODER: PowerShell öffnen und eingeben:
     ```powershell
     cd Pfad\zum\Ordner
     .\measure-network.ps1
     ```

### Ziele anpassen:

1. Öffnen Sie `measure-network.ps1` mit einem Texteditor (Notepad++)
2. Suchen Sie nach dem Abschnitt mit `$Targets = @(`
3. Fügen Sie neue Zeilen hinzu oder ändern Sie bestehende:
   ```powershell
   @{Name="Mein Server"; Host="192.168.1.100"; Port=80},
   ```

### Was wird gemessen?

- **Latenz**: Zeit, die ein Datenpaket für Hin- und Rückweg benötigt
- **Jitter**: Schwankungen in der Latenz (wichtig für VoIP/Gaming)
- **Packet Loss**: Prozentsatz verlorener Datenpakete
- **DNS-Zeit**: Zeit zur Auflösung des Hostnamens
- **Port-Status**: Ob der angegebene Port erreichbar ist

### Verbindungsqualität:

- **Excellent**: Perfekt für Gaming, VoIP, Video-Streaming
- **Good**: Gut für die meisten Anwendungen
- **Fair**: Akzeptabel, aber möglicherweise Probleme bei Echtzeit-Anwendungen
- **Poor**: Schlecht, wahrscheinlich Netzwerkprobleme

---

## English

### How to run the script:

1. **Easiest method**: Double-click `run-measurement.bat`
   - The script will run automatically
   - Wait for all tests to complete
   - Results are saved to `network_measurement_results.csv`

2. **PowerShell method**:
   - Right-click on `measure-network.ps1`
   - Choose "Run with PowerShell"
   - OR: Open PowerShell and type:
     ```powershell
     cd path\to\folder
     .\measure-network.ps1
     ```

### Customize targets:

1. Open `measure-network.ps1` with a text editor (Notepad++)
2. Find the section with `$Targets = @(`
3. Add new lines or modify existing ones:
   ```powershell
   @{Name="My Server"; Host="192.168.1.100"; Port=80},
   ```

### What is measured?

- **Latency**: Time for a data packet to make a round trip
- **Jitter**: Variations in latency (important for VoIP/gaming)
- **Packet Loss**: Percentage of lost data packets
- **DNS Time**: Time to resolve the hostname
- **Port Status**: Whether the specified port is reachable

### Connection Quality:

- **Excellent**: Perfect for gaming, VoIP, video streaming
- **Good**: Good for most applications
- **Fair**: Acceptable, but may have issues with real-time applications
- **Poor**: Bad, likely network problems

---

## Beispiel / Example

```
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

## Fehlerbehebung / Troubleshooting

**Problem**: Script kann nicht ausgeführt werden (Execution Policy)
**Lösung**: Verwenden Sie `run-measurement.bat` oder führen Sie aus:
```powershell
powershell -ExecutionPolicy Bypass -File .\measure-network.ps1
```

**Problem**: "Test-Connection" Fehler
**Lösung**: Stellen Sie sicher, dass ICMP nicht von Ihrer Firewall blockiert wird

**Problem**: Alle Ports zeigen "Closed"
**Lösung**: Normal, wenn eine Firewall ausgehende Verbindungen einschränkt
