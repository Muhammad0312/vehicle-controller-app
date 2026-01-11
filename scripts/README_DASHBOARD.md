# Vehicle Control Dashboard

A beautiful, real-time terminal dashboard for visualizing and monitoring data from the Vehicle Controller Flutter app. The dashboard provides a comprehensive view of all vehicle control inputs with live updates at 50 Hz.

## Overview

The dashboard acts as a TCP server that receives JSON data from the Flutter app and displays it in an organized, easy-to-read terminal interface. It's perfect for:
- **Development & Testing**: Monitor app behavior and data transmission
- **Debugging**: Verify control inputs and connection status
- **Demonstration**: Show real-time vehicle control data
- **Integration**: Understand data format for custom integrations

## Installation

### Prerequisites

- **Python 3.7 or higher** (Python 3.8+ recommended)
- **pip** (Python package manager)

### Setup

1. **Navigate to the project root directory**:
   ```bash
   cd /path/to/vehicle_controller
   ```

2. **Install required dependencies**:
   ```bash
   pip install -r requirements.txt
   ```
   
   Or install manually:
   ```bash
   pip install rich>=13.0.0
   ```

3. **Verify installation**:
   ```bash
   python scripts/dashboard.py --help
   ```

## Usage

### Basic Usage

Start the dashboard with default settings (listens on `0.0.0.0:8080`):
```bash
python scripts/dashboard.py
```

### Custom Configuration

Specify custom host and port:
```bash
python scripts/dashboard.py --host 0.0.0.0 --port 8080
```

**Command-line Arguments:**
- `--host`: Host address to bind to (default: `0.0.0.0` - listens on all interfaces)
- `--port`: Port number to listen on (default: `8080`)

### Network Setup

**Important**: Ensure your phone and PC are on the same Wi-Fi network.

1. **Find your PC's IP address**:
   - **Windows**: Run `ipconfig` and look for "IPv4 Address"
   - **Linux/Mac**: Run `ifconfig` or `ip addr` and look for "inet" address
   - Example: `192.168.1.100`

2. **Configure firewall** (if needed):
   - Allow incoming connections on the specified port
   - Windows: Add exception in Windows Firewall
   - Linux: Use `ufw` or `iptables` to allow the port
   - Mac: Configure in System Preferences > Security & Privacy > Firewall

3. **Configure the Flutter app**:
   - Open the app settings
   - Enter your PC's IP address
   - Enter the port number (must match dashboard port)
   - Save settings

## Features

### Real-time Data Display

- **Update Rate**: 50 Hz (20ms intervals)
- **Live Updates**: Dashboard refreshes automatically as data arrives
- **Connection Status**: Visual indicator shows connection state

### Control Visualization

**Gas & Brake Pedals**:
- Progress bars showing 0-100% (0.0 to 1.0)
- Color-coded (green for gas, red for brake)
- Raw value display with 6 decimal precision

**Steering Control**:
- Visual steering bar with center marker
- Numerical value display (-1.0 to +1.0)
- Direction indicator (LEFT/CENTER/RIGHT)
- Color-coded based on direction

**Gear Selection**:
- Current gear display (P, D, N, R)
- Color highlighting for active gears

**Auto Mode**:
- ON/OFF status indicator
- Visual state display

**Blinkers**:
- Left and right blinker indicators
- Visual arrows when active

### Status Monitoring

- **Connection Status**: Real-time connection state
- **Update Frequency**: Shows if data is being received actively
- **Last Update Time**: Time since last data packet
- **Client Information**: IP address and port of connected device
- **Timestamp**: Precise timestamp from app data

## Dashboard Layout

```
┌─────────────────────────────────────────────────────────┐
│  ● CONNECTED    VEHICLE CONTROL DASHBOARD    Port: 8080 │
├──────────────────┬──────────────────────────────────────┤
│ Controls         │ Steering                             │
│ Gas:    ████░░░  │ Steering: ◄────────●─────────►      │
│        45.23%    │ Value:    +0.750000                  │
│                  │ Direction: RIGHT                      │
│ Brake:  ░░░░░░░  │                                       │
│        0.00%     │                                       │
│                  │                                       │
│ Gear:   D        │                                       │
│                  │                                       │
│ Auto Mode: OFF   │                                       │
│                  │                                       │
│         ◄ Blinkers ►                                     │
├──────────────────┼──────────────────────────────────────┤
│ Status           │ Connection Info                       │
│ Update: ACTIVE   │ Client IP: 192.168.1.50              │
│ Last: 0.02s ago  │ Client Port: 54321                    │
│ Timestamp: 14:23:45.123                                  │
└──────────────────┴──────────────────────────────────────┘
```

## Data Format

The dashboard receives JSON data in the following format:

```json
{
  "steering": {
    "x": -0.75,
    "y": 0.0
  },
  "gas": 0.45,
  "brake": 0.0,
  "gear": "D",
  "autoMode": false,
  "leftBlinker": false,
  "rightBlinker": true,
  "timestamp": 1234567890123
}
```

### Data Ranges

- **`steering.x`**: `-1.0` (full left) to `+1.0` (full right)
- **`steering.y`**: Always `0.0` (horizontal-only steering)
- **`gas`**: `0.0` (released) to `1.0` (fully pressed) = 0% to 100%
- **`brake`**: `0.0` (released) to `1.0` (fully pressed) = 0% to 100%
- **`gear`**: `"P"`, `"D"`, `"N"`, or `"R"`
- **`autoMode`**: `true` or `false`
- **`leftBlinker`**: `true` or `false`
- **`rightBlinker`**: `true` or `false`
- **`timestamp`**: Milliseconds since Unix epoch

### Data Display

- **Raw Values**: All values are displayed exactly as received (no scaling)
- **Precision**: Steering values shown with 6 decimal places
- **Percentages**: Gas and brake shown as both progress bars and percentages

## Troubleshooting

### Connection Issues

**Problem**: Dashboard shows "○ DISCONNECTED"

**Solutions**:
1. ✅ Verify phone and PC are on the same Wi-Fi network
2. ✅ Check that the IP address in the app matches your PC's IP
3. ✅ Ensure the port number matches in both app and dashboard
4. ✅ Check firewall settings - allow incoming connections on the port
5. ✅ Verify the dashboard is running and listening:
   ```bash
   # Check if port is in use
   netstat -an | grep 8080  # Linux/Mac
   netstat -an | findstr 8080  # Windows
   ```
6. ✅ Try restarting both the app and dashboard
7. ✅ Check router settings - some routers block device-to-device communication

**Problem**: "Address already in use" error

**Solutions**:
1. ✅ Another process is using the port - change the port:
   ```bash
   python scripts/dashboard.py --port 8081
   ```
2. ✅ Kill the process using the port:
   ```bash
   # Linux/Mac
   lsof -ti:8080 | xargs kill
   
   # Windows
   netstat -ano | findstr :8080
   taskkill /PID <PID> /F
   ```

### Data Display Issues

**Problem**: Values not updating or showing as 0

**Solutions**:
1. ✅ Check connection status - should show "● CONNECTED"
2. ✅ Verify data is being sent from the app (check app connection status)
3. ✅ Check if "Last Update" time is recent
4. ✅ Restart the dashboard

**Problem**: Dashboard shows incorrect values

**Solutions**:
1. ✅ Verify app is sending correct data format
2. ✅ Check for JSON parsing errors in terminal output
3. ✅ Ensure app and dashboard are using the same data format version

### Performance Issues

**Problem**: Dashboard is slow or laggy

**Solutions**:
1. ✅ Close other terminal applications
2. ✅ Use a terminal that supports Rich library properly
3. ✅ Reduce terminal window size if very large
4. ✅ Check system resources (CPU/memory)

## Advanced Usage

### Running in Background

**Linux/Mac**:
```bash
nohup python scripts/dashboard.py > dashboard.log 2>&1 &
```

**Windows** (using PowerShell):
```powershell
Start-Process python -ArgumentList "scripts/dashboard.py" -WindowStyle Hidden
```

### Custom Integration

The dashboard can be used as a reference for building custom integrations. The data format is well-documented, and you can:

1. **Modify the dashboard**: Edit `scripts/dashboard.py` to add custom visualizations
2. **Create custom clients**: Use the data format to build your own monitoring tools
3. **Log data**: Add logging functionality to save data to files
4. **Export data**: Add CSV/JSON export capabilities

### Data Logging Example

To add logging to the dashboard, you can modify the `handle_client` method in `dashboard.py`:

```python
import json
from datetime import datetime

# In handle_client method, after parsing data:
with open('vehicle_data.log', 'a') as f:
    log_entry = {
        'timestamp': datetime.now().isoformat(),
        'data': parsed_data
    }
    f.write(json.dumps(log_entry) + '\n')
```

## Notes

- The dashboard automatically handles client disconnections and reconnections
- Press `Ctrl+C` to exit gracefully
- The dashboard supports only one client connection at a time
- Data is displayed in real-time with no buffering
- All values are shown exactly as received from the app (no scaling or transformation)
- The dashboard updates at 10 Hz for smooth visualization (data arrives at 50 Hz)

## See Also

- [Main README](../README.md) - Complete project documentation
- [Scripts README](README.md) - Overview of all utility scripts
