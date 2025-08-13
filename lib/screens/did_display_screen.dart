import 'dart:io';
import 'package:flutter/material.dart';

class DIDDisplayScreen extends StatefulWidget {
  const DIDDisplayScreen({super.key});

  @override
  State<DIDDisplayScreen> createState() => _DIDDisplayScreenState();
}

class _DIDDisplayScreenState extends State<DIDDisplayScreen> with TickerProviderStateMixin {
  final TextEditingController _portController = TextEditingController(text: '4040');
  final ScrollController _waitingScrollController = ScrollController();
  final ScrollController _completedScrollController = ScrollController();

  ServerSocket? _server;

  // Order management
  final List<String> _waitingOrders = [];
  final List<String> _completedOrders = [];
  final Map<String, DateTime> _orderTimestamps = {};
  String? _latestCalledNumber;

  // Animation for blinking latest called number
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize blink animation
    _blinkController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut));

    _getDeviceIP();
    // Auto-start server on port 4040
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _portController.text = '4040';
      _startServer();
    });
  }

  @override
  void dispose() {
    _portController.dispose();
    _waitingScrollController.dispose();
    _completedScrollController.dispose();
    _blinkController.dispose();
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
              return;
            }
          }
        }
      }

      // Fallback to any non-loopback IPv4 address
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return;
          }
        }
      }
    } catch (e) {}
  }

  Future<void> _startServer() async {
    try {
      final port = int.parse(_portController.text.trim());
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _server!.listen((Socket client) {
        _handleClient(client);
      });
    } catch (e) {
      _showSnackBar('Failed to start server: $e', isError: true);
    }
  }

  void _handleClient(Socket client) {
    final clientIp = client.remoteAddress.address;
    print('🔌 New client connected from: $clientIp');

    client.listen(
      (data) {
        final message = String.fromCharCodes(data).trim();
        print('📨 Received socket data from $clientIp: "$message"');

        if (message.isNotEmpty) {
          print('🔄 Processing order message: $message');
          _processOrderMessage(message);
          client.write('Order processed: $message\n');
          print('✅ Response sent to client: Order processed: $message');
        } else {
          print('⚠️ Empty message received, ignoring');
        }
      },
      onDone: () {
        print('👋 Client disconnected: $clientIp');
        client.close();
      },
      onError: (error) {
        print('❌ Client error [$clientIp]: $error');
        client.close();
      },
    );
  }

  void _processOrderMessage(String message) {
    print('🔍 Parsing order message: "$message"');

    // Parse order message format: "*1W0000*" (wait), "*1A0000*" (complete), "*1D0000*" (delete), or "*1C0000*" (clear all)
    // Remove asterisk delimiters if present
    String cleanMessage = message;
    if (message.startsWith('*') && message.endsWith('*')) {
      cleanMessage = message.substring(1, message.length - 1);
      print('🔧 Removed asterisk delimiters, clean message: "$cleanMessage"');
    }

    if (cleanMessage.length == 6 && cleanMessage.startsWith('1')) {
      final action = cleanMessage[1];
      final orderNo = cleanMessage.substring(2);

      print('📋 Action: $action, Order Number: $orderNo');

      if (action == 'W') {
        print('⏳ WAIT command detected for order: $orderNo');
        if (orderNo.isNotEmpty) {
          _addToWaitList(orderNo);
        } else {
          print('⚠️ Empty order number in WAIT command');
        }
      } else if (action == 'A') {
        print('✅ COMPLETE command detected for order: $orderNo');
        if (orderNo.isNotEmpty) {
          _addToCompleteList(orderNo);
        } else {
          print('⚠️ Empty order number in COMPLETE command');
        }
      } else if (action == 'D') {
        print('🗑️ DELETE command detected for order: $orderNo');
        if (orderNo.isNotEmpty) {
          _deleteOrder(orderNo);
        } else {
          print('⚠️ Empty order number in DELETE command');
        }
      } else if (action == 'C') {
        print('🧹 CLEAR ALL command detected');
        _clearAllOrders();
      } else {
        print('❌ Unknown action: $action');
        print('💡 Expected actions: W (wait), A (complete), D (delete), C (clear all)');
      }
    } else {
      print('❌ Invalid message format: "$message"');
      print('💡 Expected format: *1W0000* (wait), *1A0000* (complete), *1D0000* (delete), or *1C0000* (clear all)');
      print('💡 Where * = delimiter, W=wait, A=complete, D=delete, C=clear all, last 4 digits=order number');
    }
  }

  void _addToWaitList(String orderNo) {
    print('🔄 Processing wait command for order: $orderNo');

    // Remove from completed list if it exists there
    if (_completedOrders.contains(orderNo)) {
      print('📤 Removing order $orderNo from completed list');
      setState(() {
        _completedOrders.remove(orderNo);
      });
      print('✅ Order $orderNo removed from completed list');

      // Check if this was the latest called number and remove it if so
      if (_latestCalledNumber == orderNo) {
        print('🔄 Removing $orderNo from latest called number (no longer in completed list)');
        setState(() {
          _latestCalledNumber = null;
        });
        print('✅ Latest called number cleared');
      }
    }

    // Add to waiting list if not already there
    if (!_waitingOrders.contains(orderNo)) {
      print('📝 Adding order $orderNo to waiting list');
      setState(() {
        _waitingOrders.add(orderNo);
        _orderTimestamps[orderNo] = DateTime.now();
      });
      print('✅ Order $orderNo added to waiting list. Total waiting: ${_waitingOrders.length}');
    } else {
      print('⚠️ Order $orderNo already exists in waiting list');
    }
  }

  void _addToCompleteList(String orderNo) {
    if (_waitingOrders.contains(orderNo)) {
      print('📤 Removing order $orderNo from waiting list');
      setState(() {
        _waitingOrders.remove(orderNo);
        _orderTimestamps.remove(orderNo);
      });
      print('✅ Order $orderNo removed from waiting list');
    }
    if (!_completedOrders.contains(orderNo)) {
      setState(() {
        _completedOrders.add(orderNo);
        _latestCalledNumber = orderNo; // Set as latest called number
      });
      _startBlinkingAnimation();
    } else {
      print('⚠️ Order $orderNo already exists in completed list');
    }

    // Validate latest called number after any completed list changes
    _validateLatestCalledNumber();
  }

  void _deleteOrder(String orderNo) {
    print('🗑️ Processing delete command for order: $orderNo');

    // Remove from waiting list if it exists there
    if (_waitingOrders.contains(orderNo)) {
      print('📤 Removing order $orderNo from waiting list');
      setState(() {
        _waitingOrders.remove(orderNo);
        _orderTimestamps.remove(orderNo);
      });
      print('✅ Order $orderNo removed from waiting list');
    }

    // Remove from completed list if it exists there
    if (_completedOrders.contains(orderNo)) {
      print('📤 Removing order $orderNo from completed list');
      setState(() {
        _completedOrders.remove(orderNo);
      });
      print('✅ Order $orderNo removed from completed list');

      // Check if this was the latest called number and remove it if so
      if (_latestCalledNumber == orderNo) {
        print('🔄 Removing $orderNo from latest called number (no longer in completed list)');
        setState(() {
          _latestCalledNumber = null;
        });
        print('✅ Latest called number cleared');
      }
    }

    print('✅ Delete operation completed for order $orderNo');
  }

  Future<void> _stopServer() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
    } else {}
  }

  void _clearAllOrders() {
    setState(() {
      _waitingOrders.clear();
      _completedOrders.clear();
      _orderTimestamps.clear();
      _latestCalledNumber = null; // Reset latest called number
    });
  }

  void _validateLatestCalledNumber() {
    // Check if the latest called number is still in the completed list
    if (_latestCalledNumber != null && !_completedOrders.contains(_latestCalledNumber)) {
      setState(() {
        _latestCalledNumber = null;
      });
    }
  }

  void _startBlinkingAnimation() {
    _blinkController.reset();
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 1000), () {
        if (mounted) {
          _blinkController.forward().then((_) {
            if (mounted) {
              _blinkController.reverse();
            }
          });
        }
      });
    }
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
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLatestCalledNumber(),
                Expanded(
                  child: _buildOrderList(
                    title: '완료 목록',
                    orders: _completedOrders,
                    scrollController: _completedScrollController,
                    backgroundColor: Colors.green.shade50,
                    borderColor: Colors.green.shade200,
                    icon: Icons.check_circle,
                    iconColor: Colors.green.shade600,
                    emptyMessage: '완료 목록이 비어있습니다.',
                    showTimestamp: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _buildOrderList(
              title: '대기 목록',
              orders: _waitingOrders,
              scrollController: _waitingScrollController,
              backgroundColor: Colors.orange.shade50,
              borderColor: Colors.orange.shade200,
              icon: Icons.pending,
              iconColor: Colors.orange.shade600,
              emptyMessage: '대기 목록이 비어있습니다.',
              showTimestamp: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList({
    required String title,
    required List<String> orders,
    required ScrollController scrollController,
    required Color backgroundColor,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
    required String emptyMessage,
    required bool showTimestamp,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    '${orders.length}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: iconColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              emptyMessage,
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        controller: scrollController,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 100),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final orderNo = orders[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: backgroundColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor.withOpacity(0.5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  orderNo,
                                  style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestCalledNumber() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            if (_latestCalledNumber != null)
              AnimatedBuilder(
                animation: _blinkAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _blinkAnimation.value,
                    child: Text(
                      _latestCalledNumber!,
                      style: const TextStyle(fontSize: 100, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
