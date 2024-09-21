// // ESP32 - MQTT
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
const char* ssid = "AndroidAP8382";
const char* password = "mohamed2004";
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
const int flamePin = 12;
const int buzzerPin = 27;
const int mq4Pin = 14;
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
// Queue for keypad events
QueueHandle_t keypadQueue;

// Flags to track shutdown state
bool mallClosed = false; // Add a flag to indicate if mall is closed
bool doorOpen = false;  // State for door position
bool manualControl = false;  // Flag to disable automatic door control when manually controlled
bool fireDetected = false;  // Flag for fire detection
bool gasDetected = false;  // Flag for gas detection
bool safe = true;  // State for safety

// Prices and cart
String cart[10];
int cartIndex = 0;
float totalPrice = 0.0;
float prices[] = {5, 10, 30, 25, 50, 80, 400, 10, 5};

// Functions Declaration
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
  pinMode(flamePin, INPUT);
  pinMode(mq4Pin, INPUT);
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

  // Handle MQTT messages
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
  String message = "";
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }

  if (String(topic) == "mall/door/control") {
    manualControl = true;  // Disable PIR-based control
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
  } else if (String(topic) == "mall/door/auto") {
    manualControl = false;  // enable PIR-based control
    client.publish("mall/door/control", "Door be Auto");
  } else if (String(topic) == "mall/end/day") {
    mallClosed = true;  // Set flag to indicate mall is closed
    doorOpen = false;
    manualControl = false;  // Disable manual control
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Mall Closed");
    doorServo.write(0);  // Close door
    digitalWrite(greenLedPin, LOW);  // Turn off green LED
    client.publish("mall/status", "Mall closed and systems shut down");
    delay(5000);
    lcd.noDisplay();
    lcd.setBacklight(LOW);
  } else if (String(topic) == "mall/buy/online") {
    if (message >= "1" && message <= "9") {
      // Add item to cart
      if (cartIndex < 10) {
        cart[cartIndex++] = message;
        client.publish("mall/online/added", (getItemName(message[0]) + String(" Added")).c_str());
      } else {
        client.publish("mall/online/error", "Cart is Full");
      }
    } else if (message == "A") {
      // Confirm order
      if (cartIndex > 0) {
        String orderDetails = "Order Confirmed: ";
        client.publish("mall/online/buy", "Order Confirmed");
        cartIndex = 0;  // Clear the cart after order confirmation
      } else {
        client.publish("mall/online/error", "Cart is Empty");
      }
    } else if (message == "B") {
      // Remove the last item from the cart
      if (cartIndex > 0) {
        String lastItem = cart[--cartIndex];
        client.publish("mall/online/removed", (getItemName(lastItem[0]) + String(" Removed")).c_str());
      } else {
        client.publish("mall/online/error", "Cart is Empty");
      }
    } else if (message == "0") {
      // Cancel order
      if (cartIndex > 0) {
        cartIndex = 0;  // Clear the cart
        client.publish("mall/online/canceled", "Order Canceled");
      } else {
        client.publish("mall/online/error", "Cart is Empty");
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
        client.publish("mall/online/summary", summary.c_str());
      } else {
        client.publish("mall/online/error", "Cart is Empty");
      }
    }
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");

    if (client.connect("ESP32Client", mqtt_username, mqtt_password)) {
      Serial.println("connected");
      client.subscribe("mall/door/control");
      client.subscribe("mall/door/auto");
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

void handlePIR(void *pvParameters) {
  unsigned long lastMotionTime = 0;
  const unsigned long motionDelay = 3000;
  while (true) {
    int pirValue = digitalRead(pirPin);
    int flameValue = digitalRead(flamePin);
    int mq4Value = digitalRead(mq4Pin);

    if(!mallClosed && !manualControl){
      if (pirValue == HIGH && !doorOpen) {
            doorServo.write(90);  // Open door
            doorOpen = true;
            client.publish("mall/enter", "Person Entered");

        if (flameValue == LOW && mq4Value == LOW) {
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Danger Alert");
          lcd.setCursor(0, 1);
          lcd.print("Fire & GAS Detected!");
        } else if (flameValue == LOW) {
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Danger Alert");
          lcd.setCursor(0, 1);
          lcd.print("Fire Detected!");
        } else if (mq4Value == LOW) {
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Danger Alert");
          lcd.setCursor(0, 1);
          lcd.print("Gas Detected!");
        } else {
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Welcome to Mall!");
          lcd.setCursor(0, 1);
          lcd.print("Person Detected");
        }
        lastMotionTime = millis();  // Reset motion timer
      }
      // Check if door needs to be closed
      if (millis() - lastMotionTime >= motionDelay && doorOpen) {
        doorServo.write(0);  // Close door
        doorOpen = false;
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Welcome to Mall");
      }
    }
    vTaskDelay(1000 / portTICK_PERIOD_MS);  // Delay for 1 second
  }
}

void handleLDR(void *pvParameters) {
  bool lightState = false;
  while (true) {
    if(!mallClosed){
      int ldrValue = analogRead(ldrPin);

      if (ldrValue < 500 && !lightState) {
        digitalWrite(greenLedPin, HIGH);
        client.publish("mall/light", "Light turn on");
        lightState = true;
      } else if (ldrValue >= 500 && lightState) {
        digitalWrite(greenLedPin, LOW);
        client.publish("mall/light", "Light turn off");
        lightState = false;
      }
    }
    vTaskDelay(1000 / portTICK_PERIOD_MS);  // Delay for 1 second
  }
}

void handleDangerous(void *pvParameters) {
  bool wasSafe = true; // Track previous safety state
  while (true) {
    int flameValue = digitalRead(flamePin);
    int mq4Value = digitalRead(mq4Pin);

    if (flameValue == LOW && mq4Value == LOW) {
      safe = false;
      fireDetected = true;
      gasDetected = true;
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Danger Alert");
      lcd.setCursor(0, 1);
      lcd.print("Fire & GAS Detected!");
      digitalWrite(redLedPin, HIGH);
      digitalWrite(buzzerPin, HIGH);
      if (wasSafe) {
        client.publish("mall/status", "Fire & GAS Detected");
        wasSafe = false; // Update state to not safe
      }
    } else if (flameValue == LOW) {
      safe = false;
      fireDetected = true;
      gasDetected = false; // Clear gas detection
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Danger Alert");
      lcd.setCursor(0, 1);
      lcd.print("Fire Detected!");
      digitalWrite(redLedPin, HIGH);
      digitalWrite(buzzerPin, HIGH);
      if (wasSafe) {
        client.publish("mall/status", "Fire Detected");
        wasSafe = false; // Update state to not safe
      }
    } else if (mq4Value == LOW) {
      safe = false;
      gasDetected = true;
      fireDetected = false; // Clear fire detection
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Danger Alert");
      lcd.setCursor(0, 1);
      lcd.print("Gas Detected!");
      digitalWrite(redLedPin, HIGH);
      digitalWrite(buzzerPin, HIGH);
      if (wasSafe) {
        client.publish("mall/status", "Gas Detected");
        wasSafe = false; // Update state to not safe
      }
    } else { // No danger detected
      safe = true;
      fireDetected = false;
      gasDetected = false;
      digitalWrite(redLedPin, LOW);
      digitalWrite(buzzerPin, LOW);
      if (!wasSafe) {
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Welcome to Mall");
        lcd.setCursor(0, 1);
        lcd.print("Mall is Safe");
        client.publish("mall/status", "Mall is Safe");
        wasSafe = true; // Update state to safe
      }
    }
    vTaskDelay(3000 / portTICK_PERIOD_MS);  // Delay for 3 second
    lcd.setCursor(0, 1);
    lcd.print("                ");
  }
}

void handleKeypad(void *pvParameters) {
  char key;
  while (true) {
    if(!mallClosed){
      key = keypad.getKey();
      if (key) {

        if (key >= '1' && key <= '9') {
          // Add item to cart and publish item added message
          if (cartIndex < 10) {
            cart[cartIndex++] = String(key);
            client.publish("mall/item/added", (getItemName(key) + String(" Added")).c_str());
          } else {
            client.publish("mall/item/error", "Cart is Full");
          }
        } else if (key == 'B') {
          // Remove the last item from the cart and publish item removed message
          if (cartIndex > 0) {
            String lastItem = cart[--cartIndex];
            client.publish("mall/item/removed", (getItemName(lastItem[0]) + String(" Removed")).c_str());
          } else {
            client.publish("mall/item/error", "Cart is Empty");
          }
        } else if (key == '0') {
          // Cancel order, clear cart, and publish order canceled message
          if (cartIndex == 0) {
            client.publish("mall/item/error", "Cart is Empty");
          } else {
            cartIndex = 0;
            client.publish("mall/items/canceled", "Order Canceled");
          }
        } else if (key == 'C') {
          // Publish cart summary with total price
          if (cartIndex == 0) {
            client.publish("mall/item/error", "Cart is Empty");
          } else {
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
          }
        } else if (key == 'D') {
          // Apply a 10% discount and publish the new total price
          if (cartIndex == 0) {
            client.publish("mall/item/error", "Cart is Empty");
          } else {
            float total = 0.0;
            for (int i = 0; i < cartIndex; i++) {
              int itemIndex = cart[i].toInt() - 1;
              if (itemIndex >= 0 && itemIndex < 9) {
                total += prices[itemIndex];
              }
            }
            float discountedTotal = total * 0.9;  // Apply 10% discount
            String discountSummary = "Discounted Total = $" + String(discountedTotal);
            client.publish("mall/items/discount", "10% Discount Applied");
            client.publish("mall/items/summary", discountSummary.c_str());
          }
        } else if (key == 'A') {
          // Confirm order, clear cart, and publish order confirmed message
          if (cartIndex == 0) {
            client.publish("mall/item/error", "Cart is Empty");
          } else {
          cartIndex = 0;
          client.publish("mall/items/buy", "Order Confirmed");
          }
        }
      }
    }
    vTaskDelay(100 / portTICK_PERIOD_MS);  // Delay for 100 milliseconds
  }
}

String getItemName(char key) {
  switch (key - '0') {
    case 1: return "Chips";
    case 2: return "Soda cans";
    case 3: return "Coffee";
    case 4: return "Vegetables";
    case 5: return "Fruits";
    case 6: return "Fish";
    case 7: return "Meat";
    case 8: return "Noodles";
    case 9: return "Bakery";
    default: return "Unknown";
  }
}