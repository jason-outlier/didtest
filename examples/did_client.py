#!/usr/bin/env python3
"""
DID System Test Client
Sends order messages to the Digital Information Display system
"""

import socket
import time
import sys

def send_order_message(host, port, message):
    """Send a message to the DID system"""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.connect((host, port))
            s.sendall(message.encode('utf-8'))
            response = s.recv(1024).decode('utf-8')
            print(f"Sent: {message}")
            print(f"Response: {response.strip()}")
            return True
    except Exception as e:
        print(f"Error: {e}")
        return False

def main():
    if len(sys.argv) != 3:
        print("Usage: python did_client.py <host> <port>")
        print("Example: python did_client.py 192.168.1.100 4040")
        sys.exit(1)
    
    host = sys.argv[1]
    port = int(sys.argv[2])
    
    print(f"Connecting to DID system at {host}:{port}")
    print("Available commands:")
    print("1. *1W0000* - Add order 0000 to waiting list")
    print("2. *1A0000* - Add order 0000 to completed list (removes from waiting if present)")
    print("3. *1D0000* - Remove order 0000 from both lists")
    print("4. *1C0000* - Clear all orders")
    print("5. quit - Exit client")
    print()
    print("Format: *1W0000* where * = delimiter, W=wait, A=complete, D=delete, C=clear all, last 4 digits=order number")
    print()
    
    while True:
        try:
            command = input("Enter command: ").strip()
            
            if command.lower() == 'quit':
                break
            elif len(command) == 8 and command.startsWith('*') and command.endsWith('*') and command[1] == '1' and command[2] in ['W', 'A', 'D', 'C']:
                send_order_message(host, port, command)
            else:
                print("Invalid command. Use *1W0000* (wait), *1A0000* (complete), *1D0000* (delete), *1C0000* (clear all) or quit")
                
        except KeyboardInterrupt:
            print("\nExiting...")
            break
        except EOFError:
            break

if __name__ == "__main__":
    main()
