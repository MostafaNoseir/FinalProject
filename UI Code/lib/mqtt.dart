import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:io';

class MQTTClientWrapper {
  MqttServerClient? client;
  Function(String)? onMessageReceived;
  MqttCurrentConnectionState connectionState = MqttCurrentConnectionState.IDLE;

  Future<void> prepareMqttClient() async {
    try {
      _setupMqttClient();
      await _connectClient();
    } catch (e) {
      print('Error preparing MQTT client: $e');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
    }
  }

  Future<void> _connectClient() async {
    if (client == null) {
      throw Exception('MQTT client is not initialized');
    }
    try {
      print('Client connecting....');
      connectionState = MqttCurrentConnectionState.CONNECTING;
      await client!.connect('Mostafa', 'Mostafa2004');
    } on Exception catch (e) {
      print('Client exception - $e');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client!.disconnect();
    }

    if (client!.connectionStatus?.state == MqttConnectionState.connected) {
      connectionState = MqttCurrentConnectionState.CONNECTED;
      print('Client connected');
    } else {
      print(
          'ERROR: Client connection failed - disconnecting, status is ${client!.connectionStatus}');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client!.disconnect();
    }
  }

  void _setupMqttClient() {
    client = MqttServerClient.withPort(
        '69ae36b9ae8d4f0db383227010867309.s1.eu.hivemq.cloud', // HiveMQ cloud URL
        'Mostafa', // Unique client ID
        8883); // MQTT over SSL port
    client!.secure = true;
    client!.securityContext = SecurityContext.defaultContext;
    client!.keepAlivePeriod = 20;
    client!.onDisconnected = _onDisconnected;
    client!.onConnected = _onConnected;
    client!.onSubscribed = _onSubscribed;
  }

  void subscribeToTopic(String topicName) {
    if (client == null) {
      print('Client is not initialized');
      return;
    }
    if (connectionState == MqttCurrentConnectionState.CONNECTED) {
      print('Subscribing to the $topicName topic');
      client!.subscribe(topicName, MqttQos.atLeastOnce);
      client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        var message =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        print('YOU GOT A NEW MESSAGE: $message');
        if (onMessageReceived != null) {
          onMessageReceived!(message);
        }
      });
    } else {
      print(
          'Cannot subscribe: MQTT client not connected. State: $connectionState');
    }
  }

  void publishMessage(String topic, String message) {
    if (client == null) {
      print('Client is not initialized');
      return;
    }
    if (connectionState == MqttCurrentConnectionState.CONNECTED) {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addString(message);
      print('Publishing message "$message" to topic $topic');
      client!.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
    } else {
      print(
          'Cannot publish: MQTT client not connected. State: $connectionState');
    }
  }

  void _onSubscribed(String topic) {
    print('Subscription confirmed for topic $topic');
  }

  void _onDisconnected() {
    print('OnDisconnected client callback - Client disconnection');
    connectionState = MqttCurrentConnectionState.DISCONNECTED;
  }

  void _onConnected() {
    connectionState = MqttCurrentConnectionState.CONNECTED;
    print('OnConnected client callback - Client connection was successful');
  }

  void disconnect() {
    if (client != null) {
      client!.disconnect();
      connectionState = MqttCurrentConnectionState.DISCONNECTED;
    }
  }
}

enum MqttCurrentConnectionState {
  IDLE,
  CONNECTING,
  CONNECTED,
  DISCONNECTED,
  ERROR_WHEN_CONNECTING
}
