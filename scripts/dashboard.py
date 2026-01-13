#!/usr/bin/env python3
"""
Vehicle Control Dashboard
Receives TCP data from Flutter app and displays it in a nice terminal dashboard
Supports generic ControllerState format: {'type': 'id', 'axes': [...], 'buttons': [...]}
"""

import socket
import json
import threading
import time
from datetime import datetime
from rich.console import Console
from rich.layout import Layout
from rich.panel import Panel
from rich.text import Text
from rich.live import Live
from rich.table import Table
from rich import box

class VehicleDashboard:
    def __init__(self, host='0.0.0.0', port=5000):
        self.host = host
        self.port = port
        self.console = Console()
        # Default empty state
        self.data = {
            'type': 'unknown',
            'axes': [],
            'buttons': [],
            'timestamp': 0,
        }
        self.connected = False
        self.last_update = None
        self.socket = None
        self.client_socket = None
        self.running = True
        
    def get_semantic_data(self):
        """Extract semantic meaning based on controller type"""
        ctype = self.data.get('type', 'unknown')
        axes = self.data.get('axes', [])
        buttons = self.data.get('buttons', [])
        
        semantic = {
            'gas': 0.0,
            'brake': 0.0,
            'steering': 0.0,
            'gear': '?',
            'auto_mode': False,
            'blinkers': (False, False) # Left, Right
        }
        
        try:
            if ctype == 'touch_drive' and len(axes) >= 3 and len(buttons) >= 7:
                # Axes: [Steering, Gas, Brake]
                semantic['steering'] = axes[0]
                semantic['gas'] = axes[1]
                semantic['brake'] = axes[2]
                
                # Buttons: [Left, Right, P, R, N, D, Auto]
                semantic['blinkers'] = (bool(buttons[0]), bool(buttons[1]))
                semantic['auto_mode'] = bool(buttons[6])
                
                if buttons[2]: semantic['gear'] = 'P'
                elif buttons[3]: semantic['gear'] = 'R'
                elif buttons[4]: semantic['gear'] = 'N'
                elif buttons[5]: semantic['gear'] = 'D'
                
            elif ctype == 'ps4' and len(axes) >= 6:
                # Axes: [LX, LY, RX, RY, L2, R2]
                semantic['steering'] = axes[0]
                # Map L2/R2 (-1.0 to 1.0) to 0.0 to 1.0
                semantic['brake'] = (axes[4] + 1.0) / 2.0
                semantic['gas'] = (axes[5] + 1.0) / 2.0
                
                # PS4 doesn't have explicit gear buttons mapped yet in this simple view
                # You could map buttons if desired
                
        except Exception:
            pass
            
        return semantic
        
    def create_layout(self):
        """Create the dashboard layout"""
        layout = Layout()
        
        layout.split_column(
            Layout(name="header", size=3),
            Layout(name="main"),
            Layout(name="raw", size=10),
            Layout(name="footer", size=3)
        )
        
        layout["main"].split_row(
            Layout(name="controls"),
            Layout(name="steering")
        )
        
        return layout
    
    def create_header(self):
        """Create header panel"""
        status_color = "green" if self.connected else "red"
        status_text = "● CONNECTED" if self.connected else "○ DISCONNECTED"
        ctype = self.data.get('type', 'Unknown').upper()
        
        header = Table.grid(padding=1)
        header.add_column(style="bold white", justify="left")
        header.add_column(style="bold white", justify="center", ratio=2)
        header.add_column(style="bold white", justify="right")
        
        header.add_row(
            f"[{status_color}]{status_text}[/{status_color}]",
            f"[bold cyan]CONTROLLER: {ctype}[/bold cyan]",
            f"Port: {self.port}"
        )
        
        return Panel(header, box=box.ROUNDED, border_style="cyan")
    
    def create_controls_panel(self):
        """Create controls display panel based on semantic data"""
        data = self.get_semantic_data()
        
        table = Table.grid(padding=(0, 2))
        table.add_column(style="cyan", width=12)
        table.add_column(style="white")
        
        # Gas
        gas_bar = self.create_bar(data['gas'], "green")
        table.add_row("Gas:", gas_bar)
        
        # Brake
        brake_bar = self.create_bar(data['brake'], "red")
        table.add_row("Brake:", brake_bar)
        
        # Gear
        gear = data['gear']
        gear_color = "yellow" if gear in ['D', 'R'] else "white"
        table.add_row("Gear:", f"[{gear_color}]{gear}[/{gear_color}]")
        
        # Auto Mode
        auto_color = "green" if data['auto_mode'] else "dim white"
        auto_text = "ON" if data['auto_mode'] else "OFF"
        table.add_row("Auto Mode:", f"[{auto_color}]{auto_text}[/{auto_color}]")
        
        # Blinkers
        left, right = data['blinkers']
        left_icon = "◄" if left else " "
        right_icon = "►" if right else " "
        blinker_text = f"[yellow]{left_icon}[/yellow] Blinkers [yellow]{right_icon}[/yellow]"
        table.add_row("", blinker_text)
        
        return Panel(table, title="[bold]Semantic Controls[/bold]", border_style="blue", box=box.ROUNDED)
    
    def create_steering_panel(self):
        """Create steering display panel"""
        data = self.get_semantic_data()
        steering = data['steering']
        
        # Visual Bar
        bar_width = 40
        center = bar_width // 2
        # Clamp -1 to 1
        val = max(-1.0, min(1.0, steering))
        pos = int(center + (val * center))
        pos = max(0, min(bar_width - 1, pos))
        
        bar = ['─'] * bar_width
        bar[center] = '│'
        bar[pos] = '●'
        bar_text = ''.join(bar)
        
        if val > 0.05: bar_text = f"[green]{bar_text}[/green]"
        elif val < -0.05: bar_text = f"[red]{bar_text}[/red]"
        else: bar_text = f"[white]{bar_text}[/white]"
        
        table = Table.grid(padding=(0, 1))
        table.add_column(style="cyan", width=12)
        table.add_column()
        
        table.add_row("Steering:", bar_text)
        table.add_row("Value:", f"{steering:+.4f}")
        
        return Panel(table, title="[bold]Steering[/bold]", border_style="magenta", box=box.ROUNDED)

    def create_raw_panel(self):
        """Create panel showing raw axes and buttons"""
        axes = self.data.get('axes', [])
        buttons = self.data.get('buttons', [])
        
        axes_str = " ".join([f"{x:+.2f}" for x in axes])
        buttons_str = " ".join([str(b) for b in buttons])
        
        content = f"[bold]Axes ({len(axes)}):[/bold]\n{axes_str}\n\n[bold]Buttons ({len(buttons)}):[/bold]\n{buttons_str}"
        
        return Panel(content, title="[bold]Raw Data[/bold]", border_style="white", box=box.ROUNDED)
    
    def create_bar(self, value, color):
        """Create a progress bar"""
        bar_width = 20
        clamped_value = max(0.0, min(1.0, value))
        filled = int(clamped_value * bar_width)
        bar = '█' * filled + '░' * (bar_width - filled)
        percentage = f"{clamped_value * 100:.1f}%"
        return f"[{color}]{bar}[/{color}] {percentage}"
    
    def create_footer(self):
        """Create footer panel"""
        footer_text = Text()
        footer_text.append("Vehicle Control System | ", style="dim white")
        footer_text.append("TCP Server", style="cyan")
        footer_text.append(f" | {self.host}:{self.port}", style="dim white")
        
        # Add latency/update info
        if self.last_update:
            diff = time.time() - self.last_update
            footer_text.append(f" | Last Update: {diff:.3f}s ago", style="green" if diff < 1.0 else "red")
            
        return Panel(footer_text, box=box.ROUNDED, border_style="dim")
    
    def update_dashboard(self, layout):
        """Update all dashboard panels"""
        layout["header"].update(self.create_header())
        layout["main"]["controls"].update(self.create_controls_panel())
        layout["main"]["steering"].update(self.create_steering_panel())
        layout["raw"].update(self.create_raw_panel())
        layout["footer"].update(self.create_footer())
    
    def handle_client(self, client_socket, addr):
        """Handle client connection"""
        self.console.print(f"[green]Client connected from {addr[0]}:{addr[1]}[/green]")
        self.connected = True
        self.client_socket = client_socket
        
        try:
            buffer = ""
            while self.running:
                data = client_socket.recv(1024).decode('utf-8')
                if not data:
                    break
                
                buffer += data
                
                # Process complete JSON messages (newline separated)
                while '\n' in buffer:
                    line, buffer = buffer.split('\n', 1)
                    if line.strip():
                        try:
                            parsed_data = json.loads(line)
                            # Expecting keys: type, axes, buttons
                            if 'type' in parsed_data:
                                self.data = parsed_data
                                self.last_update = time.time()
                        except json.JSONDecodeError:
                            pass
                            
        except Exception:
            pass
        finally:
            self.connected = False
            self.client_socket = None
            client_socket.close()
    
    def start_server(self):
        """Start the TCP server"""
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.socket.bind((self.host, self.port))
        self.socket.listen(1)
        self.socket.settimeout(1.0)
        
        self.console.print(f"[cyan]Server started on {self.host}:{self.port}[/cyan]")
        self.console.print("[yellow]Waiting for connection...[/yellow]")
        
        layout = self.create_layout()
        
        with Live(layout, refresh_per_second=10, screen=True) as live:
            while self.running:
                try:
                    if not self.connected:
                        try:
                            client_socket, addr = self.socket.accept()
                            client_thread = threading.Thread(
                                target=self.handle_client,
                                args=(client_socket, addr),
                                daemon=True
                            )
                            client_thread.start()
                        except socket.timeout:
                            pass
                    
                    self.update_dashboard(layout)
                    time.sleep(0.1)
                    
                except KeyboardInterrupt:
                    self.running = False
                    break
        
        if self.socket:
            self.socket.close()

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Vehicle Control Dashboard')
    parser.add_argument('--host', default='0.0.0.0', help='Host to bind to')
    parser.add_argument('--port', type=int, default=5000, help='Port to listen on')
    
    args = parser.parse_args()
    
    dashboard = VehicleDashboard(host=args.host, port=args.port)
    dashboard.start_server()

if __name__ == '__main__':
    main()

