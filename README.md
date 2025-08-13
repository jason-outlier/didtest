# Digital Information Display (DID) System

A Flutter-based Digital Information Display system that manages order numbers through socket communication. The system displays waiting and completed orders in a modern, Toss-style interface.

## Features

- **Real-time Order Management**: Display waiting and completed order numbers
- **Socket Communication**: Receive order updates via TCP socket
- **Modern UI**: Clean, card-based design following Toss app design language
- **Cross-platform**: Works on Windows, macOS, Linux, Android, and iOS
- **Real-time Updates**: Orders update instantly when received through socket

## Order Message Format

The system accepts the following message formats through socket:

- `*1W0000*` - Add order 0000 to the waiting list
- `*1A0000*` - Add order 0000 to the completed list (removes from waiting if present)
- `*1D0000*` - Remove order 0000 from both waiting and completed lists
- `*1C0000*` - Clear all orders

Where:

- `*` - Delimiter (asterisk)
- `1` - Fixed prefix
- `W` - Action (W = Wait/Add to waiting, A = Complete/Add to completed, D = Delete from both, C = Clear All)
- `0000` - 4-digit order number (ignored for clear command)

## Usage

### Starting the DID System

1. Run the Flutter app
2. The system will automatically detect your device's IP address
3. Enter a port number (default: 4040)
4. Click "Start Server" to begin listening for connections

### Sending Order Updates

Use any TCP client to send messages to the system:

#### Python Client

```bash
python examples/did_client.py <host> <port>
```

#### Windows Batch Script

```cmd
examples\did_client.bat <host> <port>
```

#### Manual Testing with netcat

```bash
echo "*1W0001*" | nc <host> <port>
echo "*1A0001*" | nc <host> <port>
echo "*1W0002*" | nc <host> <port>
echo "*1D0001*" | nc <host> <port>
echo "*1C0000*" | nc <host> <port>
```

### Example Workflow

1. **Add to Waiting**: Send `*1W0001*` to add order 0001 to waiting list
2. **Complete Order**: Send `*1A0001*` to move order 0001 to completed list (removes from waiting)
3. **Add Another Order**: Send `*1W0002*` to add order 0002 to waiting list
4. **Delete Order**: Send `*1D0001*` to remove order 0001 from both lists
5. **Clear All Orders**: Send `*1C0000*` to clear all orders from both lists

## Architecture

- **Main Screen**: `DIDDisplayScreen` - Main interface with order lists
- **Socket Server**: Built-in TCP server for receiving order updates
- **Order Management**: Separate lists for waiting and completed orders
- **Real-time Updates**: Orders update immediately when socket messages are received

## Development

### Prerequisites

- Flutter SDK
- Dart SDK
- Platform-specific development tools

### Running the App

```bash
flutter run
```

### Building for Production

```bash
flutter build web
flutter build apk
flutter build ios
```

## Network Configuration

- **Default Port**: 4040
- **Protocol**: TCP
- **IP Detection**: Automatically detects WiFi/LAN IP address
- **Access**: Accepts connections from any device on the network

## UI Design

The interface follows Toss app design principles:

- Clean, card-based layout
- Consistent spacing and typography
- Color-coded order status (orange for waiting, green for completed)
- Modern icons and visual feedback
- Responsive design for different screen sizes

## Troubleshooting

- **Port Already in Use**: Change the port number in the app
- **Connection Refused**: Ensure the server is running and firewall allows connections
- **IP Detection Issues**: Check network interface configuration
- **Order Not Updating**: Verify message format and socket connection

## License

This project is open source and available under the MIT License.
