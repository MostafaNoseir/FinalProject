// ESP32 - MQTT
#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <ESP32Servo.h>
#include <Keypad.h>
#include <freertos/task.h>
#include <freertos/queue.h>

// WiFi and MQTT settings
const char* ssid = "Wokwi-GUEST";
const char* password = "";
const char* mqtt_server = "69ae36b9ae8d4f0db383227010867309.s1.eu.hivemq.cloud";
const int mqtt_port = 8883;
const char* mqtt_username = "Mostafa";
const char* mqtt_password = "Mostafa2004";

// MQTT client
WiFiClientSecure ESP_Client;
PubSubClient client(ESP_Client);

// LCD setup
LiquidCrystal_I2C lcd(0x27, 16, 2);

// Servo setup
Servo doorServo;

// Pin definitions
const int servoPin = 2;
const int pirPin = 13;
const int flamepotPin = 12;
const int buzzerPin = 27;
const int mq4potPin = 14;
const int greenLedPin = 26;
const int redLedPin = 25;
const int ldrPin = 33;

// Keypad setup
const byte ROWS = 4;
const byte COLS = 4;
char keys[ROWS][COLS] = {
  {'1', '2', '3', 'A'},
  {'4', '5', '6', 'B'},
  {'7', '8', '9', 'C'},
  {'*', '0', '#', 'D'}
};
byte rowPins[ROWS] = {15, 4, 16, 5};
byte colPins[COLS] = {18, 19, 23, 32};
Keypad keypad = Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);

// Flags to track shutdown state
bool endOfDay = false;  // State for end of day
bool doorOpen = false;  // State for door position
bool fireDetected = false;  // Flag for fire detection
bool gasDetected = false;   // Flag for gas detection
bool safe = true;  // State for safety

// Prices and cart
String cart[10];
int cartIndex = 0;
float totalPrice = 0.0;
float prices[] = {1.5, 2.0, 1.0, 2.5, 1.0, 2.0, 1.0, 1.0, 1.5};

// Queue for keypad events
QueueHandle_t keypadQueue;

void setup_wifi();
void callback(char* topic, byte* payload, unsigned int length);
void reconnect();
void handlePIR(void *pvParameters);
void handleLDR(void *pvParameters);
void handleDangerous(void *pvParameters);
void handleKeypad(void *pvParameters);
String getItemName(char key);

void setup() {
  // Initialize serial communication
  Serial.begin(115200);

  // Initialize WiFi and MQTT
  setup_wifi();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  ESP_Client.setInsecure();  // For secure MQTT connection without certificate

  // Initialize LCD
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Welcome to Mall!");

  // Initialize Servo
  doorServo.attach(servoPin);
  doorServo.write(0);  // Start with the door closed

  // Initialize sensors and actuators
  pinMode(pirPin, INPUT);
  pinMode(ldrPin, INPUT);
  pinMode(flamepotPin, INPUT);
  pinMode(mq4potPin, INPUT);
  pinMode(buzzerPin, OUTPUT);
  pinMode(greenLedPin, OUTPUT);
  pinMode(redLedPin, OUTPUT);

  // Initial state
  digitalWrite(greenLedPin, LOW);  // Green LED off
  digitalWrite(redLedPin, LOW);    // Red LED off
  digitalWrite(buzzerPin, LOW);    // Buzzer off

  // Create tasks
  xTaskCreatePinnedToCore(handlePIR, "PIR Task", 2048, NULL, 2, NULL, 1);
  xTaskCreatePinnedToCore(handleLDR, "LDR Task", 2048, NULL, 2, NULL, 1);
  xTaskCreatePinnedToCore(handleDangerous, "Dangerous Task", 2048, NULL, 2, NULL, 1);
  xTaskCreatePinnedToCore(handleKeypad, "Keypad Task", 2048, NULL, 2, NULL, 1);
  
  // Create queue for keypad events
  keypadQueue = xQueueCreate(10, sizeof(char));
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();   
  vTaskDelay(1000 / portTICK_PERIOD_MS);
}

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}

void callback(char* topic, byte* payload, unsigned int length) {
  String message;
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }

  if (String(topic) == "mall/door/control") {
    if (message == "1") {
      doorOpen = true;  // Set the door open state
      doorServo.write(90);  // Open door
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Welcome to Mall!");
      client.publish("mall/door/control", "Door opened");
    } else if (message == "0") {
      doorOpen = false;  // Set the door closed state
      doorServo.write(0);   // Close door
      client.publish("mall/door/control", "Door closed");
    }
  } else if (String(topic) == "mall/end/day") {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Mall Closed");
    doorServo.write(0);  // Close door
    digitalWrite(greenLedPin, LOW);  // Turn off green LED
    client.publish("mall/status", "Mall closed and systems shut down");
    delay(5000);
    lcd.noDisplay();
  
    return;
  } else if (String(topic) == "mall/buy/online") {
    if (message >= "1" && message <= "9") {
      // Add item to cart
      if (cartIndex < 10) {
        cart[cartIndex++] = message;
        client.publish("mall/item/added", (getItemName(message[0]) + String(" Added")).c_str());
      } else {
        client.publish("mall/item/error", "Cart is Full");
      }
    } else if (message == "A") {
      // Confirm order
      if (cartIndex > 0) {
        String orderDetails = "Order Confirmed: ";
        client.publish("mall/items/buy", "Order Confirmed");
        cartIndex = 0;  // Clear the cart after order confirmation
      } else {
        client.publish("mall/item/error", "Cart is Empty");
      }
    } else if (message == "B") {
      // Remove the last item from the cart
      if (cartIndex > 0) {
        String lastItem = cart[--cartIndex];
        client.publish("mall/item/removed", (getItemName(lastItem[0]) + String(" Removed")).c_str());
      } else {
        client.publish("mall/item/error", "Cart is Empty");
      }
    } else if (message == "0") {
      // Cancel order
      if (cartIndex > 0) {
        cartIndex = 0;  // Clear the cart
        client.publish("mall/items/canceled", "Order Canceled");
      } else {
        client.publish("mall/item/error", "Cart is Empty");
      }
    } else if (message == "C") {
      // Send summary and total price
      if (cartIndex > 0) {
        String summary = "Items: ";
        float total = 0.0;
        for (int i = 0; i < cartIndex; i++) {
          int itemIndex = cart[i].toInt() - 1;
          if (itemIndex >= 0 && itemIndex < 9) {
            summary += getItemName(cart[i][0]) + " , ";
            total += prices[itemIndex];
          }
        }
        summary += "Total = $" + String(total);
        client.publish("mall/items/summary", summary.c_str());
      } else {
        client.publish("mall/item/error", "Cart is Empty");
      }
    }
  }
}

void handlePIR(void *pvParameters) {
  while (1) {
    int motionDetected = digitalRead(pirPin);
    if (motionDetected) {
      if (!doorOpen) {
        client.publish("mall/pir", "Motion detected, opening door");
        doorServo.write(90);  // Open the door
        delay(5000);
        doorServo.write(0);  // Close the door after 5 seconds
      }
    }
    vTaskDelay(1000 / portTICK_PERIOD_MS);
  }
}

void handleLDR(void *pvParameters) {
  while (1) {
    int lightIntensity = analogRead(ldrPin);
    if (lightIntensity < 500) {
      digitalWrite(greenLedPin, HIGH);  // Turn on green LED if it's dark
    } else {
      digitalWrite(greenLedPin, LOW);   // Turn off green LED if it's bright
    }
    vTaskDelay(1000 / portTICK_PERIOD_MS);
  }
}

void handleDangerous(void *pvParameters) {
  while (1) {
    int flameValue = analogRead(flamepotPin);
    int gasValue = analogRead(mq4potPin);

    if (flameValue > 500 || gasValue > 500) {
      fireDetected = flameValue > 500;
      gasDetected = gasValue > 500;
      safe = false;

      digitalWrite(redLedPin, HIGH);   // Turn on red LED
      digitalWrite(buzzerPin, HIGH);   // Sound the buzzer
      client.publish("mall/alarm", "Fire or Gas Detected!");
    } else {
      fireDetected = false;
      gasDetected = false;
      safe = true;

      digitalWrite(redLedPin, LOW);   // Turn off red LED
      digitalWrite(buzzerPin, LOW);   // Turn off buzzer
    }
    vTaskDelay(1000 / portTICK_PERIOD_MS);
  }
}

void handleKeypad(void *pvParameters) {
  char key;
  while (1) {
    key = keypad.getKey();
    if (key) {
      xQueueSend(keypadQueue, &key, portMAX_DELAY);
    }
    vTaskDelay(100 / portTICK_PERIOD_MS);
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    if (client.connect("ESP32Client", mqtt_username, mqtt_password)) {
      Serial.println("connected");
      client.subscribe("mall/door/control");
      client.subscribe("mall/end/day");
      client.subscribe("mall/buy/online");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

String getItemName(char key) {
  switch (key) {
    case '1': return "Apple";
    case '2': return "Banana";
    case '3': return "Milk";
    case '4': return "Bread";
    case '5': return "Cheese";
    case '6': return "Yogurt";
    case '7': return "Water";
    case '8': return "Juice";
    case '9': return "Coffee";
    default: return "Unknown";
  }
}
