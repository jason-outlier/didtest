#!/usr/bin/env node
/**
 * Simple Node.js socket client to connect to the Flutter socket server
 * 
 * Usage:
 * 1. Start the Flutter socket server app
 * 2. Note the IP address and port displayed
 * 3. Update the SERVER_IP variable below
 * 4. Run: node examples/nodejs_client.js
 */

const net = require('net');
const readline = require('readline');

// ⚠️ CHANGE THIS TO YOUR SERVER'S IP FROM THE FLUTTER APP
const SERVER_IP = '192.168.1.100';
const SERVER_PORT = 8080;

// Create readline interface for user input
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function connectToServer() {
  console.log(`🔄 Connecting to ${SERVER_IP}:${SERVER_PORT}...`);
  
  const client = new net.Socket();
  
  // Connect to server
  client.connect(SERVER_PORT, SERVER_IP, () => {
    console.log('✅ Connected to server!');
    console.log('📱 You can now see this connection in your Flutter app');
    console.log('');
    console.log('💬 Type messages to send to server (type "quit" to exit):');
    console.log('   Messages will be echoed back to all connected clients');
    console.log('');
    
    // Start accepting user input
    promptForMessage();
  });
  
  // Handle incoming data from server
  client.on('data', (data) => {
    const message = data.toString().trim();
    if (message) {
      // Move cursor to new line and show server message
      process.stdout.write('\n📨 Server: ' + message + '\n> ');
    }
  });
  
  // Handle connection closed
  client.on('close', () => {
    console.log('\n❌ Server disconnected');
    process.exit(0);
  });
  
  // Handle connection errors
  client.on('error', (err) => {
    console.log('💥 Connection error:', err.message);
    console.log('');
    console.log('💡 Troubleshooting:');
    console.log('   1. Make sure the Flutter server app is running');
    console.log('   2. Check that both devices are on the same WiFi');
    console.log('   3. Update the SERVER_IP variable above');
    console.log('   4. Try disabling firewall temporarily');
    process.exit(1);
  });
  
  function promptForMessage() {
    rl.question('> ', (input) => {
      if (input.toLowerCase() === 'quit') {
        console.log('👋 Goodbye!');
        client.destroy();
        rl.close();
        return;
      }
      
      if (input.trim()) {
        client.write(input + '\n');
      }
      
      // Continue prompting for more messages
      promptForMessage();
    });
  }
  
  // Handle Ctrl+C
  process.on('SIGINT', () => {
    console.log('\n👋 Goodbye!');
    client.destroy();
    rl.close();
    process.exit(0);
  });
}

// Start the client
connectToServer();