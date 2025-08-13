#!/bin/bash

# Simple shell script to test connection to the Flutter socket server
# 
# Usage:
# 1. Start the Flutter socket server app
# 2. Note the IP address and port displayed
# 3. Update the SERVER_IP variable below
# 4. Run: bash examples/test_connection.sh

# ⚠️ CHANGE THIS TO YOUR SERVER'S IP FROM THE FLUTTER APP
SERVER_IP="192.168.1.100"
SERVER_PORT="8080"

echo "🔄 Testing connection to $SERVER_IP:$SERVER_PORT..."
echo ""

# Test 1: Check if port is open using netcat
echo "📡 Test 1: Checking if port is open..."
if command -v nc >/dev/null 2>&1; then
    if nc -z -v -w5 "$SERVER_IP" "$SERVER_PORT" 2>/dev/null; then
        echo "✅ Port is open and accepting connections"
    else
        echo "❌ Port is not accessible"
        echo ""
        echo "💡 Troubleshooting:"
        echo "   1. Make sure the Flutter server app is running"
        echo "   2. Check that both devices are on the same WiFi"
        echo "   3. Update the SERVER_IP variable above"
        echo "   4. Try disabling firewall temporarily"
        exit 1
    fi
else
    echo "⚠️  netcat (nc) not found, skipping port test"
fi

echo ""

# Test 2: Send a test message
echo "📨 Test 2: Sending test message..."
if command -v nc >/dev/null 2>&1; then
    echo "Hello from shell script!" | nc "$SERVER_IP" "$SERVER_PORT"
    echo "✅ Test message sent successfully"
    echo "📱 Check your Flutter app to see the message"
else
    echo "⚠️  netcat (nc) not found, skipping message test"
fi

echo ""

# Test 3: Interactive session
echo "💬 Test 3: Starting interactive session..."
echo "   Type messages and press Enter (Ctrl+C to exit)"
echo ""

if command -v nc >/dev/null 2>&1; then
    nc "$SERVER_IP" "$SERVER_PORT"
elif command -v telnet >/dev/null 2>&1; then
    telnet "$SERVER_IP" "$SERVER_PORT"
else
    echo "❌ Neither netcat (nc) nor telnet found"
    echo "💡 Install netcat or telnet to test interactively"
    echo ""
    echo "📋 Alternative test commands:"
    echo "   nc $SERVER_IP $SERVER_PORT"
    echo "   telnet $SERVER_IP $SERVER_PORT"
    echo "   echo 'test message' | nc $SERVER_IP $SERVER_PORT"
fi

echo ""
echo "🏁 Test completed!"