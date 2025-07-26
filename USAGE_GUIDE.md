# Even Demo App - iPhone Usage Guide

## Overview
The Even Demo App allows you to connect to G1 smart glasses and test various features including BMP image display, text sending, and Even AI functionality. This guide will help you set up and use the app effectively on your iPhone.

## Prerequisites

### Hardware Requirements
- iPhone running iOS 12.0 or later
- Even G1 Smart Glasses
- Both left and right arms of the glasses must be powered on and in pairing mode

### Software Requirements
- Bluetooth enabled on iPhone
- Location services enabled (required for BLE scanning on iOS)
- App permissions granted (Bluetooth, Speech Recognition)

## Getting Started

### 1. Initial Setup

1. **Enable Bluetooth and Location Services**
   - Go to Settings > Bluetooth and turn on Bluetooth
   - Go to Settings > Privacy & Security > Location Services and ensure it's enabled
   - Grant location permission to the Even Demo App when prompted

2. **Prepare Your Glasses**
   - Ensure both left and right arms of your G1 glasses are charged
   - Power on both arms
   - Put the glasses in pairing mode (refer to your glasses manual)
   - The glasses should broadcast with names like `_XXXX_L_` and `_XXXX_R_` where XXXX is the channel number

### 2. Connecting to Glasses

1. **Launch the App**
   - Open the Even Demo App on your iPhone
   - You'll see the home screen with connection status

2. **Scan for Glasses**
   - If no glasses are connected, tap the connection status area
   - The app will start scanning for nearby glasses (indicated by a spinning progress indicator)
   - Scanning will automatically stop after 15 seconds

3. **Connect to Found Glasses**
   - Found glasses will appear in a list below the connection status
   - Each entry shows the channel number and device names for left and right arms
   - Tap on a glasses entry to connect
   - Wait for the connection to establish (status will change to "Connected")

### 3. Using BMP Image Features

Once connected, you can access the BMP features:

1. **Navigate to Features**
   - Tap the menu icon (☰) in the top-right corner
   - Select "BMP" from the features list

2. **Send Images**
   - **BMP 1**: Tap to send the first test image (image_1.bmp)
   - **BMP 2**: Tap to send the second test image (image_2.bmp)
   - **Exit**: Tap to exit BMP mode and return glasses to dashboard

3. **Monitor Progress**
   - Buttons show loading indicators during transmission
   - Success/error messages appear as snackbars
   - Watch the debug console for detailed transmission progress

## Debugging Features

The app now includes comprehensive debug logging with emoji indicators:

### Debug Message Categories

- 🚀 **App Launch**: Application initialization
- 🔧 **Setup**: Configuration and initialization
- 📱 **Platform**: iOS/Android platform calls
- 🔍 **Scanning**: BLE device scanning
- 🔗 **Connection**: Device connection attempts
- 💓 **Heartbeat**: Keep-alive communications
- 📡 **Data Transmission**: BLE data sending/receiving
- 🖼️ **BMP Operations**: Image loading and transmission
- 📦 **Packet Management**: Data packet handling
- 🏁 **Completion**: Task completion status
- ⚠️ **Warnings**: Non-critical issues
- ❌ **Errors**: Error conditions
- ✅ **Success**: Successful operations

### Viewing Debug Messages

1. **Xcode Console** (Development):
   - Connect your iPhone to Mac with Xcode
   - Run the app through Xcode
   - View detailed logs in the Xcode console

2. **Device Logs** (Production):
   - Use iPhone analytics tools or third-party logging apps
   - Debug messages will appear in system logs

## Troubleshooting

### Connection Issues

**Problem**: Can't find glasses during scan
- **Check**: Ensure both glass arms are powered on
- **Check**: Verify glasses are in pairing mode
- **Check**: Location services are enabled for the app
- **Check**: Bluetooth is enabled
- **Solution**: Move closer to glasses, restart scan

**Problem**: Connection fails after finding glasses
- **Check**: Debug logs for specific error messages
- **Check**: No other devices are connected to the glasses
- **Solution**: Restart glasses, clear Bluetooth cache, retry connection

**Problem**: Connection drops frequently
- **Check**: Battery level of glasses
- **Check**: Distance between phone and glasses
- **Solution**: Ensure glasses are fully charged, stay within range

### BMP Issues

**Problem**: BMP buttons don't respond
- **Check**: Connection status indicator shows "Connected"
- **Check**: Debug logs show "isConnected = true"
- **Solution**: Ensure proper connection before using BMP features

**Problem**: BMP transmission fails
- **Check**: Debug logs for transmission errors
- **Check**: Image file exists in assets/images/
- **Possible causes**:
  - Connection instability
  - Incorrect image format
  - Transmission timeout
- **Solution**: Retry transmission, check connection stability

**Problem**: Images don't display on glasses
- **Check**: CRC check passes in debug logs
- **Check**: All packets transmitted successfully
- **Solution**: Verify image format (1-bit BMP, 576x136 pixels)

### Performance Issues

**Problem**: Slow BMP transmission
- **Normal behavior**: Large images take time to transmit over BLE
- **Check**: Platform-specific delays (iOS: 8ms, Android: 5ms between packets)
- **Solution**: Wait for transmission to complete, avoid interrupting

## Advanced Usage

### Protocol Understanding

The app communicates with glasses using specific BLE protocols:

1. **Dual BLE Architecture**: Separate connections to left and right arms
2. **Command Sequence**: Left side first, then right side after acknowledgment
3. **Heartbeat System**: Regular keep-alive messages every 8 seconds
4. **Packet Management**: Data split into 194-byte packets for transmission

### TouchBar Events

When connected, the glasses can send events to the app:
- **Single Tap**: Page navigation in features
- **Double Tap**: Exit current feature
- **Triple Tap**: Toggle silent mode

### Monitoring Connection Health

Watch for these debug indicators:
- 💓 Regular heartbeat success messages
- 📡 Successful data transmission confirmations
- 🔍 Both sides connection status (isLeftConnected, isRightConnected)

## Technical Specifications

### Supported Image Format
- **Format**: 1-bit BMP
- **Dimensions**: 576 x 136 pixels
- **Color Depth**: Monochrome (1 bit per pixel)
- **Location**: assets/images/ directory

### BLE Characteristics
- **Service UUID**: Custom UART service
- **TX/RX**: Separate characteristics for send/receive
- **Packet Size**: 194 bytes maximum per packet
- **Timeout**: 1.5-3 seconds per command

### Platform-Specific Behavior
- **iOS**: 8ms delay between packets, enhanced error handling
- **Android**: 5ms delay between packets
- **Both**: Automatic retry mechanisms for failed transmissions

## Permissions Required

### iOS Permissions
1. **Bluetooth**: Required for BLE communication
2. **Location**: Required for BLE scanning (iOS requirement)
3. **Speech Recognition**: Required for Even AI features (when implemented)

### Granting Permissions
- Permissions are requested automatically when needed
- If denied, go to Settings > Privacy & Security > [Permission Type] > Even Demo App

## Support and Troubleshooting

### First Steps for Issues
1. Check all prerequisites are met
2. Review debug logs for specific error messages
3. Restart app and glasses
4. Ensure optimal proximity between devices

### Debug Log Keywords to Watch For
- "Connection failed"
- "Timeout"
- "CRC check failed"
- "Invalid response"
- "BMP data is empty"

### When to Seek Help
- Persistent connection failures after following troubleshooting steps
- App crashes or freezes
- Glasses found but connection never establishes
- BMP transmission always fails despite successful connection

## App Architecture

### Key Components
- **BleManager**: Handles all Bluetooth communication
- **BmpUpdateManager**: Manages image transmission
- **Proto**: Implements communication protocols
- **FeaturesServices**: Coordinates feature operations

### Connection Flow
1. App initialization and BLE setup
2. Device scanning and discovery
3. Dual connection establishment (left + right)
4. Heartbeat initiation
5. Feature availability

This comprehensive guide should help you successfully use the Even Demo App with your G1 glasses. The enhanced debug logging will provide detailed information about any issues you encounter. 