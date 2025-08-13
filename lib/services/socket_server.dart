import 'dart:io';
import 'dart:convert';
import 'dart:async';

class SocketServer {
  ServerSocket? _server;
  final List<Socket> _clients = [];
  final StreamController<String> _messagesController = StreamController<String>.broadcast();
  final StreamController<String> _statusController = StreamController<String>.broadcast();

  bool get isRunning => _server != null;
  Stream<String> get messages => _messagesController.stream;
  Stream<String> get status => _statusController.stream;

  Future<String> start({int port = 8080}) async {
    try {
      if (_server != null) {
        throw Exception('Server is already running');
      }

      // Start the server
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _statusController.add('Server started on port $port');

      // Listen for client connections
      _server!.listen((Socket client) {
        _handleClient(client);
      });

      // Get local IP address
      final localIP = await _getLocalIPAddress();
      final serverInfo = 'Server running on $localIP:$port';
      _statusController.add(serverInfo);

      return serverInfo;
    } catch (e) {
      _statusController.add('Error starting server: $e');
      throw Exception('Failed to start server: $e');
    }
  }

  Future<void> stop() async {
    try {
      // Close all client connections
      for (final client in _clients) {
        await client.close();
      }
      _clients.clear();

      // Close the server
      await _server?.close();
      _server = null;

      _statusController.add('Server stopped');
    } catch (e) {
      _statusController.add('Error stopping server: $e');
    }
  }

  void _handleClient(Socket client) {
    final clientAddress = '${client.remoteAddress.address}:${client.remotePort}';
    _clients.add(client);
    _statusController.add('Client connected: $clientAddress');

    client.listen(
      (data) {
        final message = utf8.decode(data).trim();
        _messagesController.add('[$clientAddress]: $message');

        // Echo the message back to all clients
        broadcastMessage('Echo: $message');
      },
      onDone: () {
        _clients.remove(client);
        _statusController.add('Client disconnected: $clientAddress');
      },
      onError: (error) {
        _clients.remove(client);
        _statusController.add('Client error: $clientAddress - $error');
      },
    );

    // Send welcome message
    client.add(utf8.encode('Welcome to the socket server!\n'));
  }

  void broadcastMessage(String message) {
    final data = utf8.encode('$message\n');
    for (final client in _clients) {
      try {
        client.add(data);
      } catch (e) {
        _statusController.add('Error sending to client: $e');
      }
    }
  }

  Future<String> _getLocalIPAddress() async {
    try {
      final interfaces = await NetworkInterface.list();

      // Look for WiFi interface first
      for (final interface in interfaces) {
        if (interface.name.toLowerCase().contains('wlan') || interface.name.toLowerCase().contains('wifi') || interface.name.toLowerCase().contains('wi-fi')) {
          for (final addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
              return addr.address;
            }
          }
        }
      }

      // Fallback to any non-loopback IPv4 address
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }

      return 'localhost';
    } catch (e) {
      return 'localhost';
    }
  }

  void dispose() {
    stop();
    _messagesController.close();
    _statusController.close();
  }
}
