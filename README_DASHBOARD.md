# Vehicle Control Dashboard

A beautiful terminal dashboard to visualize data from the Flutter Vehicle Control app.

## Installation

1. Install Python 3.7 or higher
2. Install required dependencies:
```bash
pip install -r requirements.txt
```

## Usage

Run the dashboard:
```bash
python dashboard.py
```

Or with custom host/port:
```bash
python dashboard.py --host 0.0.0.0 --port 8080
```

## Features

- **Real-time Updates**: Displays data as it's received from the app
- **Beautiful UI**: Uses Rich library for a modern terminal interface
- **Connection Status**: Shows connection state and client information
- **Control Display**: 
  - Gas and Brake pedals with progress bars
  - Current gear selection
  - Auto mode status
  - Blinker indicators
- **Steering Visualization**: 
  - Visual steering bar showing left/right position
  - Numerical steering value
  - Direction indicator
- **Status Monitoring**: 
  - Update frequency indicator
  - Last update timestamp
  - Connection info

## Dashboard Layout

```
┌─────────────────────────────────────────────────────────┐
│  ● CONNECTED    VEHICLE CONTROL DASHBOARD    Port: 8080 │
├──────────────────┬──────────────────────────────────────┤
│ Controls         │ Steering                             │
│ Gas:    ████░░░  │ Steering: ◄────────●─────────►      │
│ Brake:  ░░░░░░░  │ Value:    +0.234                    │
│ Gear:   D        │ Direction: RIGHT                     │
│ Auto Mode: ON    │                                       │
│         ◄ Blinkers ►                                     │
├──────────────────┼──────────────────────────────────────┤
│ Status           │ Connection Info                       │
│ Update: ACTIVE   │ Client IP: 192.168.1.100             │
│ Last: 0.05s ago  │ Client Port: 54321                    │
│ Timestamp: 14:23:45.123                                  │
└──────────────────┴──────────────────────────────────────┘
```

## Notes

- The dashboard automatically reconnects when a client disconnects
- Press Ctrl+C to exit
- Make sure the port matches the one configured in your Flutter app
