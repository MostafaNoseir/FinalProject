// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'mqtt.dart';

class Sensor_page extends StatefulWidget {
  const Sensor_page({super.key});

  @override
  Sensor_page_state createState() => Sensor_page_state();
}

class Sensor_page_state extends State<Sensor_page> {
  final MQTTClientWrapper _mqttClientWrapper = MQTTClientWrapper();
  String _gasValue = '0';
  String _flameValue = '0';
  String _lightStatus = 'Unknown';
  bool _doorOpen = false;
  bool _dayEnded = false;

  @override
  void initState() {
    super.initState();
    // _initializeMQTT();
  }

  // Future<void> _initializeMQTT() async {
  //   await _mqttClientWrapper.prepareMqttClient();
  //   _mqttClientWrapper.onMessageReceived = (String message) {
  //     setState(() {
  //       // Update the values based on your MQTT setup
  //       if (message == 'Fire & GAS Detected') {
  //         _gasValue = message; // Emergency message
  //         _flameValue = message; // Emergency message
  //       } else if (message == 'Mall is Safe') {
  //         _gasValue = '0'; // Reset to safe state
  //         _flameValue = '0'; // Reset to safe state
  //       } else if (message.contains('Fire Detected')) {
  //         _flameValue = message; // Digital message from flame sensor
  //       } else if (message.contains('Gas Detected')) {
  //         _gasValue = message; // Digital message from gas sensor
  //       } else if (message.contains('Light turn on')) {
  //         _lightStatus = 'Light is ON';
  //       } else if (message.contains('Light turn off')) {
  //         _lightStatus = 'Light is OFF';
  //       } else if (message.contains('Door opened')) {
  //         _doorOpen = true;
  //       } else if (message.contains('Door closed')) {
  //         _doorOpen = true;
  //       } else if (message.contains('Mall closed and systems shut down')) {
  //         _dayEnded = true;
  //       }
  //     });
  //   };
  //   // Subscribe to relevant topics
  //   _mqttClientWrapper.subscribeToTopic('mall/status'); // Digital sensors
  //   _mqttClientWrapper.subscribeToTopic('mall/light'); // LDR readings
  //   _mqttClientWrapper.subscribeToTopic('mall/door/control'); // Door control
  //   _mqttClientWrapper.subscribeToTopic('mall/end/day'); // End day
  //   _mqttClientWrapper.subscribeToTopic('mall/door/auto');
  // }

  void open_door(String command) {
    if (_doorOpen) {
      // _mqttClientWrapper.publishMessage(
      //     'mall/door/control', command); // Updated topic
    } else {
      alert_message('Door is already open');
    }
  }

  void close_door(String command) {
    if (!_doorOpen) {
      // _mqttClientWrapper.publishMessage(
      //     'mall/door/control', command); // Updated topic
    } else {
      alert_message('Door is already closed');
    }
  }

  void the_end() {
    if (!_dayEnded) {
      // _mqttClientWrapper.publishMessage('mall/end/day', '1'); // Updated topic
    } else {
      alert_message('Day already ended');
    }
  }

  @override
  // void dispose() {
  //   _mqttClientWrapper.disconnect();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supermarket Sensors'),
        backgroundColor: Colors.teal, // Mint green color
      ),
      body: Container(
        color: Colors.grey[200], // Light grey color
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                children: [
                  sensor_layout(
                    'Gas Sensor',
                    _gasValue,
                    _gasValue == 'Fire & GAS Detected'
                        ? Colors.red
                        : _gasValue == 'Mall is Safe'
                            ? Colors.black
                            : _gasValue.contains('Gas Detected')
                                ? Colors.red
                                : Colors.black,
                  ),
                  sensor_layout(
                    'Flame Sensor',
                    _flameValue,
                    _flameValue == 'Fire & GAS Detected'
                        ? Colors.red
                        : _flameValue == 'Mall is Safe'
                            ? Colors.black
                            : _flameValue.contains('Fire Detected')
                                ? Colors.red
                                : Colors.black,
                  ),
                  sensor_layout('Light Status', _lightStatus, Colors.black),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Package Door',
                          style: TextStyle(
                              fontSize: 18.0, fontWeight: FontWeight.bold)),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              open_door('1'); // Open door
                              _doorOpen = true;
                            },
                            child: const Text(
                              'Open door',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          const SizedBox(width: 15),
                          ElevatedButton(
                            onPressed: () {
                              close_door('0'); // Close door
                              _doorOpen = false;
                            },
                            child: const Text(
                              'Close door',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          const SizedBox(width: 15),
                          ElevatedButton(
                            onPressed: () {
                              _mqttClientWrapper.publishMessage(
                                  'mall/door/auto', '1');
                              _doorOpen = false;
                            },
                            child: const Text(
                              'auto open door',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: the_end,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 12.0),
              ),
              child:
                  const Text('End Day', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget sensor_layout(String title, String value, Color textColor) {
    return Card(
      elevation: 4.0,
      child: Container(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18.0, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            Text(value, style: TextStyle(fontSize: 24.0, color: textColor)),
          ],
        ),
      ),
    );
  }

  void alert_message(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ERROR'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
