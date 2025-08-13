import 'dart:io';
import 'dart:convert';

/// Simple socket client to connect to the Flutter socket server
///
/// Usage:
/// 1. Start the Flutter socket server app
/// 2. Note the IP address and port displayed
/// 3. Update the serverIP variable below
/// 4. Run: dart examples/dart_client.dart
void main() async {
  // Replace with your server's IP address from the Flutter app
  const serverIP = '192.168.1.100'; // ⚠️ CHANGE THIS TO YOUR SERVER'S IP
  const port = 8080;

  try {
    print('🔄 Connecting to $serverIP:$port...');
    final socket = await Socket.connect(serverIP, port);
    print('✅ Connected to server!');
    print('📱 You can now see this connection in your Flutter app');
    print('');

    // Listen for messages from server
    socket.listen(
      (data) {
        final message = utf8.decode(data).trim();
        if (message.isNotEmpty) {
          print('📨 Server: $message');
        }
      },
      onDone: () {
        print('❌ Server disconnected');
        exit(0);
      },
      onError: (error) {
        print('💥 Error: $error');
        exit(1);
      },
    );

    // Send messages to server
    print('💬 Type messages to send to server (type "quit" to exit):');
    print('   Messages will be echoed back to all connected clients');
    print('');

    while (true) {
      stdout.write('> ');
      final input = stdin.readLineSync();

      if (input == null || input.toLowerCase() == 'quit') {
        print('👋 Goodbye!');
        break;
      }

      if (input.trim().isEmpty) {
        continue;
      }

      // Send message to server
      socket.add(utf8.encode('$input\n'));
    }

    await socket.close();
    print('🔌 Disconnected from server');
  } catch (e) {
    print('❌ Failed to connect: $e');
    print('');
    print('💡 Troubleshooting:');
    print('   1. Make sure the Flutter server app is running');
    print('   2. Check that both devices are on the same WiFi');
    print('   3. Update the serverIP variable above');
    print('   4. Try disabling firewall temporarily');
  }
}
