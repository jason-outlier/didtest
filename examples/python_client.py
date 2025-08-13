#!/usr/bin/env python3
"""
Simple Python socket client to connect to the Flutter socket server

Usage:
1. Start the Flutter socket server app
2. Note the IP address and port displayed
3. Update the SERVER_IP variable below
4. Run: python examples/python_client.py
"""

import socket
import sys
import threading

# ⚠️ CHANGE THIS TO YOUR SERVER'S IP FROM THE FLUTTER APP
SERVER_IP = '192.168.1.100'
SERVER_PORT = 8080

def listen_for_messages(sock):
    """Listen for incoming messages from the server"""
    try:
        while True:
            data = sock.recv(1024)
            if not data:
                break
            message = data.decode('utf-8').strip()
            if message:
                print(f"\n📨 Server: {message}")
                print("> ", end="", flush=True)
    except Exception as e:
        print(f"\n💥 Error receiving: {e}")

def main():
    try:
        print(f"🔄 Connecting to {SERVER_IP}:{SERVER_PORT}...")
        
        # Create socket and connect
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect((SERVER_IP, SERVER_PORT))
        
        print("✅ Connected to server!")
        print("📱 You can now see this connection in your Flutter app")
        print("")
        print("💬 Type messages to send to server (type 'quit' to exit):")
        print("   Messages will be echoed back to all connected clients")
        print("")
        
        # Start listening thread
        listen_thread = threading.Thread(target=listen_for_messages, args=(sock,))
        listen_thread.daemon = True
        listen_thread.start()
        
        # Send messages
        while True:
            try:
                message = input("> ")
                
                if message.lower() == 'quit':
                    print("👋 Goodbye!")
                    break
                
                if message.strip():
                    sock.send((message + '\n').encode('utf-8'))
                    
            except KeyboardInterrupt:
                print("\n👋 Goodbye!")
                break
        
        sock.close()
        print("🔌 Disconnected from server")
        
    except ConnectionRefused:
        print("❌ Connection refused")
        print("💡 Make sure the Flutter server app is running")
    except Exception as e:
        print(f"❌ Failed to connect: {e}")
        print("")
        print("💡 Troubleshooting:")
        print("   1. Make sure the Flutter server app is running")
        print("   2. Check that both devices are on the same WiFi")
        print("   3. Update the SERVER_IP variable above")
        print("   4. Try disabling firewall temporarily")

if __name__ == "__main__":
    main()