#!/usr/bin/env python3
"""
Vehicle Control Dashboard
Receives TCP data from Flutter app and displays it in a nice terminal dashboard
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
    def __init__(self, host='0.0.0.0', port=8080):
        self.host = host
        self.port = port
        self.console = Console()
        self.data = {
            'steering': {'x': 0.0, 'y': 0.0},
            'gas': 0.0,
            'brake': 0.0,
            'gear': 'P',
            'autoMode': False,
            'leftBlinker': False,
            'rightBlinker': False,
            'timestamp': 0,
        }
        self.connected = False
        self.last_update = None
        self.socket = None
        self.client_socket = None
        self.running = True
        
    def create_layout(self):
        """Create the dashboard layout"""
        layout = Layout()
        
        layout.split_column(
            Layout(name="header", size=3),
            Layout(name="main"),
            Layout(name="footer", size=3)
        )
        
        layout["main"].split_row(
            Layout(name="left"),
            Layout(name="right")
        )
        
        layout["left"].split_column(
            Layout(name="controls", ratio=2),
            Layout(name="status")
        )
        
        layout["right"].split_column(
            Layout(name="steering", ratio=2),
            Layout(name="info")
        )
        
        return layout
    
    def create_header(self):
        """Create header panel"""
        status_color = "green" if self.connected else "red"
        status_text = "● CONNECTED" if self.connected else "○ DISCONNECTED"
        
        header = Table.grid(padding=1)
        header.add_column(style="bold white", justify="left")
        header.add_column(style="bold white", justify="center", ratio=2)
        header.add_column(style="bold white", justify="right")
        
        header.add_row(
            f"[{status_color}]{status_text}[/{status_color}]",
            "[bold cyan]VEHICLE CONTROL DASHBOARD[/bold cyan]",
            f"Port: {self.port}"
        )
        
        return Panel(header, box=box.ROUNDED, border_style="cyan")
    
    def create_controls_panel(self):
        """Create controls display panel"""
        table = Table.grid(padding=(0, 2))
        table.add_column(style="cyan", width=12)
        table.add_column(style="white")
        
        # Gas
        gas_bar = self.create_bar(self.data['gas'], "green")
        table.add_row("Gas:", gas_bar)
        
        # Brake
        brake_bar = self.create_bar(self.data['brake'], "red")
        table.add_row("Brake:", brake_bar)
        
        # Gear
        gear_color = "yellow" if self.data['gear'] in ['D', 'R'] else "white"
        table.add_row("Gear:", f"[{gear_color}]{self.data['gear']}[/{gear_color}]")
        
        # Auto Mode
        auto_color = "green" if self.data['autoMode'] else "dim white"
        auto_text = "ON" if self.data['autoMode'] else "OFF"
        table.add_row("Auto Mode:", f"[{auto_color}]{auto_text}[/{auto_color}]")
        
        # Blinkers
        left_blink = "◄" if self.data['leftBlinker'] else " "
        right_blink = "►" if self.data['rightBlinker'] else " "
        blinker_text = f"[yellow]{left_blink}[/yellow] Blinkers [yellow]{right_blink}[/yellow]"
        table.add_row("", blinker_text)
        
        return Panel(table, title="[bold]Controls[/bold]", border_style="blue", box=box.ROUNDED)
    
    def create_steering_panel(self):
        """Create steering display panel"""
        # Display raw steering value as received from app (no scaling)
        steering_x = self.data['steering']['x']
        
        # Create steering bar - map raw value to visual position
        bar_width = 50
        center = bar_width // 2
        
        # Map raw steering value to bar position (no scaling, just visual mapping)
        # Handle any value range - show raw data
        # For visualization, allow wider range but show actual raw value
        display_x = max(-2.0, min(2.0, steering_x))  # Clamp only for bar visualization
        position = int(center + (display_x * center / 2.0))  # Scale for wider range in bar
        position = max(0, min(bar_width - 1, position))
        
        bar = ['─'] * bar_width
        bar[center] = '│'  # Center marker
        bar[position] = '●'  # Current position
        
        # Add range markers
        bar_text = ''.join(bar)
        
        # Color based on direction
        if steering_x > 0.01:
            bar_text = f"[green]{bar_text}[/green]"
        elif steering_x < -0.01:
            bar_text = f"[red]{bar_text}[/red]"
        else:
            bar_text = f"[white]{bar_text}[/white]"
        
        table = Table.grid(padding=(0, 1))
        table.add_column(style="cyan", width=12)
        table.add_column()
        
        # Show raw value exactly as received (no scaling)
        # Also show if it's at the limits
        value_text = f"[bold]{steering_x:+.6f}[/bold]"
        if abs(steering_x) >= 0.999:
            value_text += " [green](MAX)[/green]"
        elif abs(steering_x) <= 0.001:
            value_text += " [dim](CENTER)[/dim]"
        table.add_row("Raw Value:", value_text)
        table.add_row("Steering:", bar_text)
        
        # Visual indicator using raw value
        if abs(steering_x) > 0.001:
            direction = "RIGHT" if steering_x > 0 else "LEFT"
            direction_color = "green" if steering_x > 0 else "red"
            table.add_row("Direction:", f"[{direction_color}]{direction}[/{direction_color}]")
        else:
            table.add_row("Direction:", "[dim]CENTER[/dim]")
        
        # Show Y value if present (raw)
        steering_y = self.data['steering'].get('y', 0.0)
        if abs(steering_y) > 0.001:
            table.add_row("Y Value:", f"{steering_y:+.6f}")
        
        return Panel(table, title="[bold]Steering (Raw Data)[/bold]", border_style="magenta", box=box.ROUNDED)
    
    def create_status_panel(self):
        """Create status panel"""
        table = Table.grid(padding=(0, 1))
        table.add_column(style="cyan", width=14)
        table.add_column(style="white")
        
        if self.last_update:
            time_diff = time.time() - self.last_update
            if time_diff < 1.0:
                status = "[green]ACTIVE[/green]"
            elif time_diff < 3.0:
                status = "[yellow]SLOW[/yellow]"
            else:
                status = "[red]STALE[/red]"
            
            table.add_row("Update Status:", status)
            table.add_row("Last Update:", f"{time_diff:.2f}s ago")
        else:
            table.add_row("Update Status:", "[dim]WAITING[/dim]")
            table.add_row("Last Update:", "[dim]Never[/dim]")
        
        if self.data['timestamp']:
            dt = datetime.fromtimestamp(self.data['timestamp'] / 1000)
            table.add_row("Timestamp:", dt.strftime("%H:%M:%S.%f")[:-3])
        
        return Panel(table, title="[bold]Status[/bold]", border_style="yellow", box=box.ROUNDED)
    
    def create_info_panel(self):
        """Create info panel"""
        table = Table.grid(padding=(0, 1))
        table.add_column(style="cyan", width=14)
        table.add_column(style="white")
        
        if self.client_socket:
            client_addr = self.client_socket.getpeername()
            table.add_row("Client IP:", client_addr[0])
            table.add_row("Client Port:", str(client_addr[1]))
        else:
            table.add_row("Client IP:", "[dim]None[/dim]")
            table.add_row("Client Port:", "[dim]None[/dim]")
        
        table.add_row("Server Port:", str(self.port))
        table.add_row("", "")
        table.add_row("Press:", "[dim]Ctrl+C to exit[/dim]")
        
        return Panel(table, title="[bold]Connection Info[/bold]", border_style="green", box=box.ROUNDED)
    
    def create_bar(self, value, color):
        """Create a progress bar"""
        bar_width = 30
        # Ensure value is clamped to 0.0-1.0 for display
        clamped_value = max(0.0, min(1.0, value))
        filled = int(clamped_value * bar_width)
        bar = '█' * filled + '░' * (bar_width - filled)
        # Show exact percentage with 2 decimal places for precision
        percentage = f"{clamped_value * 100:.2f}%"
        # Also show raw value for debugging
        raw_value_text = f" (raw: {value:.6f})"
        return f"[{color}]{bar}[/{color}] {percentage}{raw_value_text}"
    
    def create_footer(self):
        """Create footer panel"""
        footer_text = Text()
        footer_text.append("Vehicle Control System | ", style="dim white")
        footer_text.append("TCP Server", style="cyan")
        footer_text.append(f" | {self.host}:{self.port}", style="dim white")
        
        return Panel(footer_text, box=box.ROUNDED, border_style="dim")
    
    def update_dashboard(self, layout):
        """Update all dashboard panels"""
        layout["header"].update(self.create_header())
        layout["left"]["controls"].update(self.create_controls_panel())
        layout["left"]["status"].update(self.create_status_panel())
        layout["right"]["steering"].update(self.create_steering_panel())
        layout["right"]["info"].update(self.create_info_panel())
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
                            self.data.update(parsed_data)
                            self.last_update = time.time()
                        except json.JSONDecodeError as e:
                            self.console.print(f"[red]JSON decode error: {e}[/red]")
                            
        except ConnectionResetError:
            self.console.print(f"[yellow]Client {addr[0]}:{addr[1]} disconnected[/yellow]")
        except Exception as e:
            self.console.print(f"[red]Error handling client: {e}[/red]")
        finally:
            self.connected = False
            self.client_socket = None
            client_socket.close()
            self.console.print(f"[red]Connection closed[/red]")
    
    def start_server(self):
        """Start the TCP server"""
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.socket.bind((self.host, self.port))
        self.socket.listen(1)
        self.socket.settimeout(1.0)  # Non-blocking with timeout
        
        self.console.print(f"[cyan]Server started on {self.host}:{self.port}[/cyan]")
        self.console.print("[yellow]Waiting for connection...[/yellow]")
        
        layout = self.create_layout()
        
        with Live(layout, refresh_per_second=10, screen=True) as live:
            while self.running:
                try:
                    # Try to accept a connection
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
                            pass  # No connection yet, continue
                    
                    # Update dashboard
                    self.update_dashboard(layout)
                    live.update(layout)
                    
                    time.sleep(0.1)  # Update rate
                    
                except KeyboardInterrupt:
                    self.console.print("\n[yellow]Shutting down...[/yellow]")
                    self.running = False
                    break
        
        if self.socket:
            self.socket.close()
        self.console.print("[green]Server stopped[/green]")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Vehicle Control Dashboard')
    parser.add_argument('--host', default='0.0.0.0', help='Host to bind to (default: 0.0.0.0)')
    parser.add_argument('--port', type=int, default=8080, help='Port to listen on (default: 8080)')
    
    args = parser.parse_args()
    
    dashboard = VehicleDashboard(host=args.host, port=args.port)
    dashboard.start_server()

if __name__ == '__main__':
    main()
