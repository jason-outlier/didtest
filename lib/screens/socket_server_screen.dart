import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SocketServerScreen extends StatefulWidget {
  const SocketServerScreen({super.key});

  @override
  State<SocketServerScreen> createState() => _SocketServerScreenState();
}

class _SocketServerScreenState extends State<SocketServerScreen> {
  final TextEditingController _portController = TextEditingController(text: '4040');
  final List<String> _messages = [];
  final ScrollController _scrollController = ScrollController();

  ServerSocket? _server;
  bool _isServerRunning = false;
  String _serverIp = '';
  String _serverPort = '';

  @override
  void initState() {
    super.initState();
    _getDeviceIP();
  }

  @override
  void dispose() {
    _portController.dispose();
    _scrollController.dispose();
    _stopServer();
    super.dispose();
  }

  Future<void> _getDeviceIP() async {
    try {
      final interfaces = await NetworkInterface.list();

      // Look for WiFi interface first
      for (final interface in interfaces) {
        if (interface.name.toLowerCase().contains('wlan') || interface.name.toLowerCase().contains('wifi') || interface.name.toLowerCase().contains('wi-fi')) {
          for (final addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
              setState(() {
                _serverIp = addr.address;
              });
              return;
            }
          }
        }
      }

      // Fallback to any non-loopback IPv4 address
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            setState(() {
              _serverIp = addr.address;
            });
            return;
          }
        }
      }

      setState(() {
        _serverIp = 'localhost';
      });
    } catch (e) {
      setState(() {
        _serverIp = 'Unable to detect IP';
      });
    }
  }

  Future<void> _startServer() async {
    try {
      final port = int.parse(_portController.text.trim());

      _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);

      setState(() {
        _isServerRunning = true;
        _serverPort = port.toString();
      });

      _addMessage('🚀 Server started on $_serverIp:$port');
      _addMessage('📡 Listening for connections from any device');

      _server!.listen((Socket client) {
        _handleClient(client);
      });
    } catch (e) {
      _showSnackBar('Failed to start server: $e', isError: true);
    }
  }

  void _handleClient(Socket client) {
    final clientIp = client.remoteAddress.address;
    _addMessage('🔔 Incoming connection from $clientIp');
    _addMessage('✅ Client connected: $clientIp');

    client.listen(
      (data) {
        final message = String.fromCharCodes(data).trim();
        if (message.isNotEmpty) {
          _addMessage('📨 [$clientIp]: $message');
          client.write('Echo: $message\n');
        }
      },
      onDone: () {
        _addMessage('👋 Client disconnected: $clientIp');
        client.close();
      },
      onError: (error) {
        _addMessage('❌ Client error [$clientIp]: $error');
        client.close();
      },
    );
  }

  Future<void> _stopServer() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      setState(() {
        _isServerRunning = false;
        _serverPort = '';
      });
      _addMessage('🛑 Server stopped');
    }
  }

  void _addMessage(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _messages.add('[$timestamp] $message');
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  void _clearMessages() {
    setState(() {
      _messages.clear();
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Socket Server',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_buildServerControlCard(), const SizedBox(height: 16), if (_isServerRunning) _buildServerStatusCard(), if (_isServerRunning) const SizedBox(height: 16), _buildMessageLogCard()],
        ),
      ),
    );
  }

  Widget _buildServerControlCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Socket Server', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),

            // Current IP Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi, color: Colors.blue.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Device IP',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _serverIp.isNotEmpty ? _serverIp : 'Detecting...',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Courier New'),
                        ),
                      ],
                    ),
                  ),
                  if (_serverIp.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _serverIp));
                        _showSnackBar('IP address copied to clipboard');
                      },
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'Copy IP',
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Port Input
            const Text(
              'Port Number',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                hintText: 'Enter port number',
                prefixIcon: Icon(Icons.router, color: Color(0xFF007AFF)),
              ),
              keyboardType: TextInputType.number,
              enabled: !_isServerRunning,
            ),

            const SizedBox(height: 24),

            // Start/Stop Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isServerRunning ? _stopServer : _startServer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isServerRunning ? Colors.red.shade400 : const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isServerRunning ? Icons.stop : Icons.play_arrow),
                    const SizedBox(width: 8),
                    Text(_isServerRunning ? 'Stop Server' : 'Start Server', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerStatusCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade200),
      ),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: Colors.green.shade400, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                const Text('Server Active', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.computer, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Server Address: $_serverIp:$_serverPort',
                          style: const TextStyle(fontFamily: 'Courier New', fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: '$_serverIp:$_serverPort'));
                          _showSnackBar('Server address copied to clipboard');
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        tooltip: 'Copy Address',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.public, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text('Accepting connections from any device', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageLogCard() {
    return Card(
      elevation: 0,
      borderOnForeground: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Message Log', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                if (_messages.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearMessages,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 400,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.message_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No messages yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text('Start the server to see incoming connections', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(_messages[index], style: const TextStyle(fontFamily: 'Courier New', fontSize: 13, height: 1.4)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
