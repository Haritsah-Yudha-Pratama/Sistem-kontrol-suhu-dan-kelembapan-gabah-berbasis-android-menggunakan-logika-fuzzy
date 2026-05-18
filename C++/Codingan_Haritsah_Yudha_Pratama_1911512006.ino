#include <Esp32WifiManager.h>
#include <Firebase_ESP_Client.h>
#include <Adafruit_Sensor.h>
#include <DHT.h>
#include <Fuzzy.h>

// Provide the token generation process info.
#include <addons/TokenHelper.h>

// Provide the RTDB payload printing info and other helper functions.
#include <addons/RTDBHelper.h>

/* 1. Define the WiFi credentials */
#define WIFI_SSID ""
#define WIFI_PASSWORD ""

/* 2. Define the API Key */
#define API_KEY "AIzaSyC5nqM9pBwFnuDd3Hcqv9oouXKoCVY94gA"

/* 3. Define the user Email and password that already registered or added in your project */
#define USER_EMAIL "yudhaharitsah@gmail.com"
#define USER_PASSWORD "yudha160101"

FirebaseData fbdo;
FirebaseData stream;

FirebaseAuth auth;
FirebaseConfig config;

/* 4. Define the RTDB URL */
#define DATABASE_URL "test-contrapp-default-rtdb.asia-southeast1.firebasedatabase.app"

#define DHTPIN 15          // Pin sensor DHT (sesuaikan dengan expansion board)
#define IN1_PIN 16         // Pin untuk motor IN1
#define IN2_PIN 17         // Pin untuk motor IN2
#define IN3_PIN 18         // Pin untuk motor IN3
#define IN4_PIN 19         // Pin untuk motor IN4
#define FAN_ENA_PIN 21     // Pin untuk enA kipas (L298N)
#define FAN_ENB_PIN 22     // Pin untuk enB kipas (L298N)
#define HEATER_PWM_PIN 23  // Pin untuk PWM heater (MOSFET)
#define DHTTYPE DHT22

DHT dht(DHTPIN, DHTTYPE);

// Deklarasi objek Fuzzy
Fuzzy *fuzzy = new Fuzzy();

// Variabel global untuk menyimpan hasil pembacaan sensor
float temperature, humidity;

bool isDrying;
bool dataChanged;

// Deklarasi Input dan Output Fuzzy
FuzzyInput *fuzzyTemperature = new FuzzyInput(1);
FuzzyInput *fuzzyHumidity = new FuzzyInput(2);
FuzzyOutput *fuzzyFan = new FuzzyOutput(1);
FuzzyOutput *fuzzyHeater = new FuzzyOutput(2);

// Variabel untuk mode
enum Mode { DRYING,
            STORAGE };
Mode currentMode = STORAGE;  // Mode awal

// Variabel untuk menghitung lama penyimpanan
unsigned long startTime;
bool storageStarted = false;

//handle stream dari Firebase
void streamCallback(FirebaseStream data) {
  Serial.printf("sream path, %s\nevent path, %s\ndata type, %s\nevent type, %s\n\n",
                data.streamPath().c_str(),
                data.dataPath().c_str(),
                data.dataType().c_str(),
                data.eventType().c_str());
  printResult(data);  // see addons/RTDBHelper.h
  Serial.println();

  if (data.stringData() == "drying") {
    isDrying = true;
  } else {
    isDrying = false;
  }

  Serial.printf("Received stream payload size: %d (Max. %d)\n\n", data.payloadLength(), data.maxPayloadLength());

  dataChanged = true;
}

void streamTimeoutCallback(bool timeout) {
  if (timeout)
    Serial.println("stream timed out, resuming...\n");

  if (!stream.httpConnected())
    Serial.printf("error code: %d, reason: %s\n\n", stream.httpCode(), stream.errorReason().c_str());
}

// Fungsi untuk inisialisasi fuzzy logic
void setupFuzzyLogic() {
  // Deklarasi Fuzzy Sets
  FuzzySet *cold = new FuzzySet(20, 20, 25, 30);  // Suhu dingin (20°C - 30°C)
  FuzzySet *hot = new FuzzySet(30, 35, 50, 50);   // Suhu panas (30°C - 50°C)

  FuzzySet *lowHumidity = new FuzzySet(0, 0, 30, 40);       // Kelembapan rendah (< 40%)
  FuzzySet *normalHumidity = new FuzzySet(40, 45, 55, 60);  // Kelembapan normal (40% - 60%)
  FuzzySet *highHumidity = new FuzzySet(60, 65, 100, 100);  // Kelembapan tinggi (> 60%)

  FuzzySet *slowFan = new FuzzySet(0, 0, 85, 85);         // Kipas lambat (85 PWM)
  FuzzySet *mediumFan = new FuzzySet(85, 170, 170, 170);  // Kipas sedang (170 PWM)
  FuzzySet *fastFan = new FuzzySet(170, 255, 255, 255);   // Kipas cepat (255 PWM)

  FuzzySet *heaterOff = new FuzzySet(0, 0, 127.5, 127.5);   // Heater off (0 - 127.5 PWM)
  FuzzySet *heaterOn = new FuzzySet(127.6, 255, 255, 255);  // Heater on (127.6 - 255 PWM)
  FuzzySet *heaterCut = new FuzzySet(0, 0, 0, 0);           // Heater benar-benar mati (PWM = 0)


  // Menambahkan FuzzySet ke FuzzyInput Temperature
  fuzzyTemperature->addFuzzySet(cold);
  fuzzyTemperature->addFuzzySet(hot);
  fuzzy->addFuzzyInput(fuzzyTemperature);

  // Menambahkan FuzzySet ke FuzzyInput Humidity
  fuzzyHumidity->addFuzzySet(lowHumidity);
  fuzzyHumidity->addFuzzySet(normalHumidity);
  fuzzyHumidity->addFuzzySet(highHumidity);
  fuzzy->addFuzzyInput(fuzzyHumidity);

  // Menambahkan FuzzySet ke FuzzyOutput Fan
  fuzzyFan->addFuzzySet(slowFan);
  fuzzyFan->addFuzzySet(mediumFan);
  fuzzyFan->addFuzzySet(fastFan);
  fuzzy->addFuzzyOutput(fuzzyFan);

  // Menambahkan FuzzySet ke FuzzyOutput Heater
  fuzzyHeater->addFuzzySet(heaterOff);
  fuzzyHeater->addFuzzySet(heaterOn);
  fuzzyHeater->addFuzzySet(heaterCut);
  fuzzy->addFuzzyOutput(fuzzyHeater);

  // Aturan fuzzy
  FuzzyRuleAntecedent *ifColdAndLowHumidity = new FuzzyRuleAntecedent();
  ifColdAndLowHumidity->joinWithAND(cold, lowHumidity);
  FuzzyRuleConsequent *fanSlowHeaterOn = new FuzzyRuleConsequent();  // Output dari Rule 3
  fanSlowHeaterOn->addOutput(slowFan);
  fanSlowHeaterOn->addOutput(heaterOn);
  FuzzyRule *rule1 = new FuzzyRule(1, ifColdAndLowHumidity, fanSlowHeaterOn);
  fuzzy->addFuzzyRule(rule1);

  FuzzyRuleAntecedent *ifColdAndNormalHumidity = new FuzzyRuleAntecedent();
  ifColdAndNormalHumidity->joinWithAND(cold, normalHumidity);
  FuzzyRuleConsequent *fanMediumHeaterOn = new FuzzyRuleConsequent();
  fanMediumHeaterOn->addOutput(mediumFan);
  fanMediumHeaterOn->addOutput(heaterOn);
  FuzzyRule *rule2 = new FuzzyRule(2, ifColdAndNormalHumidity, fanMediumHeaterOn);
  fuzzy->addFuzzyRule(rule2);

  FuzzyRuleAntecedent *ifColdAndHighHumidity = new FuzzyRuleAntecedent();
  ifColdAndHighHumidity->joinWithAND(cold, highHumidity);
  FuzzyRuleConsequent *fanFastHeaterOn = new FuzzyRuleConsequent();  // Output dari Rule 1
  fanFastHeaterOn->addOutput(fastFan);
  fanFastHeaterOn->addOutput(heaterOn);
  FuzzyRule *rule3 = new FuzzyRule(3, ifColdAndHighHumidity, fanFastHeaterOn);
  fuzzy->addFuzzyRule(rule3);

  FuzzyRuleAntecedent *ifHotAndLowHumidity = new FuzzyRuleAntecedent();
  ifHotAndLowHumidity->joinWithAND(hot, lowHumidity);
  FuzzyRuleConsequent *fanFastHeaterCut = new FuzzyRuleConsequent();
  fanFastHeaterCut->addOutput(fastFan);
  fanFastHeaterCut->addOutput(heaterCut);
  FuzzyRule *rule4 = new FuzzyRule(4, ifHotAndLowHumidity, fanFastHeaterCut);
  fuzzy->addFuzzyRule(rule4);

  FuzzyRuleAntecedent *ifHotAndNormalHumidity = new FuzzyRuleAntecedent();
  ifHotAndNormalHumidity->joinWithAND(hot, normalHumidity);
  FuzzyRuleConsequent *fanMediumHeaterOff = new FuzzyRuleConsequent();
  fanMediumHeaterOff->addOutput(mediumFan);
  fanMediumHeaterOff->addOutput(heaterOff);
  FuzzyRule *rule5 = new FuzzyRule(5, ifHotAndNormalHumidity, fanMediumHeaterOff);
  fuzzy->addFuzzyRule(rule5);

  FuzzyRuleAntecedent *ifHotAndHighHumidity = new FuzzyRuleAntecedent();
  ifHotAndHighHumidity->joinWithAND(hot, highHumidity);
  FuzzyRuleConsequent *fanSlowHeaterOff = new FuzzyRuleConsequent();
  fanSlowHeaterOff->addOutput(slowFan);
  fanSlowHeaterOff->addOutput(heaterOff);
  FuzzyRule *rule6 = new FuzzyRule(6, ifHotAndHighHumidity, fanSlowHeaterOff);
  fuzzy->addFuzzyRule(rule6);
}

void readDHT22() {
  temperature = dht.readTemperature();  // Membaca suhu dari sensor
  humidity = dht.readHumidity();        // Membaca kelembaban dari sensor

  // Memeriksa apakah pembacaan berhasil
  if (isnan(temperature) || isnan(humidity)) {
    Serial.print("Gagal membaca dari DHT sensor!");
    return;
  }
}

// Fungsi untuk menampilkan kondisi kipas dan heater berdasarkan nilai PWM
void displayFanHeaterStatus(int fanPWM, int heaterPWM, unsigned long elapsedTime) {
  // Menentukan kondisi kipas berdasarkan nilai PWM
  String fanStatus;
  if (fanPWM >= 170) {
    fanStatus = "Kipas: Cepat";
  } else if (fanPWM >= 85) {
    fanStatus = "Kipas: Sedang";
  } else {
    fanStatus = "Kipas: Lambat";
  }
  Firebase.RTDB.setString(&fbdo, "/defuzzy/fan", fanStatus);

  // Menentukan kondisi heater berdasarkan nilai PWM
  String heaterStatus;
  if (heaterPWM > 127.5) {
    heaterStatus = "Heater: ON";
  } else {
    heaterStatus = "Heater: OFF";
  }
  Firebase.RTDB.setString(&fbdo, "/defuzzy/heater", heaterStatus);
  Firebase.RTDB.setFloat(&fbdo, "/data/pwmFan", fanPWM);
  Firebase.RTDB.setFloat(&fbdo, "/data/pwmHeater", heaterPWM);
  // Menghitung waktu penyimpanan
  unsigned long seconds = elapsedTime / 1000;
  unsigned long minutes = seconds / 60;
  unsigned long hours = minutes / 60;
  unsigned long days = hours / 24;

  seconds = seconds % 60;
  minutes = minutes % 60;
  hours = hours % 24;

  Firebase.RTDB.setFloat(&fbdo, "/duration/minutes", minutes);
  Firebase.RTDB.setFloat(&fbdo, "/duration/hours", hours);
  Firebase.RTDB.setFloat(&fbdo, "/duration/days", days);
  // Menampilkan status ke Serial Monitor
  Serial.print("Lama Penyimpanan: ");
  Serial.print(days);
  Serial.print(" Hari, ");
  Serial.print(hours % 24);
  Serial.print(" Jam, ");
  Serial.print(minutes % 60);
  Serial.print(" Menit, ");
  Serial.print(seconds % 60);
  Serial.println(" Detik");

  Serial.println(fanStatus);
  Serial.println(heaterStatus);
  Serial.print("PWM Kipas: ");
  Serial.println(fanPWM);
  Serial.print("PWM Heater: ");
  Serial.println(heaterPWM);
  Serial.println("");
}


void setup() {
  Serial.begin(115200);
  dht.begin();  // Inisialisasi DHT

  setupFuzzyLogic();  // Inisialisasi fuzzy logic

  Serial.print("Connecting to ");

  isDrying = false;

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);  // Begin the connection process

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());

  Serial.printf("Firebase Client v%s\n\n", FIREBASE_CLIENT_VERSION);

  // Menghubungkan ke Firebase RTDB
  config.api_key = API_KEY;
  config.token_status_callback = tokenStatusCallback;

  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;

  config.database_url = DATABASE_URL;

  if (WiFi.isConnected()) {
    Serial.println("WiFi connected");
    Firebase.begin(&config, &auth);
  }

  if (!Firebase.RTDB.beginStream(&stream, "/serviceState")) {
    Serial.print("Stream gagal dimulai! ");
    Serial.println(stream.errorReason().c_str());
  }
  Firebase.RTDB.setStreamCallback(&stream, streamCallback, streamTimeoutCallback);


  pinMode(FAN_ENA_PIN, OUTPUT);
  pinMode(FAN_ENB_PIN, OUTPUT);
  pinMode(HEATER_PWM_PIN, OUTPUT);
  pinMode(IN1_PIN, OUTPUT);
  pinMode(IN2_PIN, OUTPUT);
  pinMode(IN3_PIN, OUTPUT);
  pinMode(IN4_PIN, OUTPUT);

  // Atur kedua kipas untuk berputar maju
  digitalWrite(IN1_PIN, HIGH);
  digitalWrite(IN2_PIN, LOW);
  digitalWrite(IN3_PIN, HIGH);
  digitalWrite(IN4_PIN, LOW);

  startTime = millis();
}

void loop() {
  readDHT22();  // Membaca sensor DHT22

  if (dataChanged) {
    dataChanged = false;
  }

  if (!isDrying) {
    fuzzy->setInput(1, temperature);
    fuzzy->setInput(2, humidity);

    // Melakukan kalkulasi fuzzy
    fuzzy->fuzzify();

    // Mendapatkan output fuzzy
    int fanPWM = fuzzy->defuzzify(1);
    int heaterPWM = fuzzy->defuzzify(2);

    // Membatasi nilai PWM dalam rentang 0-255
    fanPWM = constrain(fanPWM, 0, 200);
    heaterPWM = constrain(heaterPWM, 0, 200);

    // Menampilkan output kondisi kipas dan heater serta lama penyimpanan
    unsigned long elapsedTime = millis() - startTime;
    displayFanHeaterStatus(fanPWM, heaterPWM, elapsedTime);

    // Mengendalikan kipas dan heater menggunakan PWM
    analogWrite(FAN_ENA_PIN, fanPWM);  // PWM untuk kipas pertama
    analogWrite(FAN_ENB_PIN, fanPWM);  // PWM untuk kipas kedua
    analogWrite(HEATER_PWM_PIN, heaterPWM);

    // Tampilkan mode dan data sensor

    delay(4000);
  } else {
    startTime = millis();
    // Mode DRYING: selalu output maksimum
    int fanPWM = 200;
    int heaterPWM = 200;

    if (humidity < 30) {
      Firebase.RTDB.setString(&fbdo, "/serviceState", "storage");
    }

    // Mengatur PWM kipas dan heater
    analogWrite(FAN_ENA_PIN, fanPWM);
    analogWrite(FAN_ENB_PIN, fanPWM);
    analogWrite(HEATER_PWM_PIN, heaterPWM);

    // Tampilkan suhu dan kelembapan
    Serial.println("");
    Serial.println("Suhu: " + String(temperature) + " °C");
    Serial.println("Kelembapan: " + String(humidity) + " %");

    Firebase.RTDB.setFloat(&fbdo, "/data/temp", temperature);
    Firebase.RTDB.setFloat(&fbdo, "/data/hum", humidity);
    delay(4000);
  }
}