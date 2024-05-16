// -------------------------- Libraries -------------------------- //


// Initialize WiFi module
#include <ESP8266WiFi.h>

// For Dynamic WiFi
#include <ESP8266WebServer.h>
#include <WiFiManager.h>

// For IRL Time
#include <time.h>


// For Getting Data in Firebase Database
#include<Firebase_ESP_Client.h>
#include"addons/TokenHelper.h"
#include"addons/RTDBHelper.h"


// ------------------- Objects and Definitions ------------------- //


// Objects and References for Firebase
#define API_KEY "AIzaSyAJ6aq6OzYAR_AwhcJ3gEM13A47qbWQoKM" // API Key
#define DATABASE_URL "https://medicine-reminder-app-11b54-default-rtdb.firebaseio.com/" // Reference URL


// WiFi Manager Object
WiFiManager wifiManager;


// ------------------- Objects for FireBase ------------------- //
FirebaseData fbdo, fbdo_TML, fbdo_TMR;

FirebaseAuth auth;
FirebaseConfig config;

bool signupOK = false;

// Data paths

String TML_DataPath = "/Compartments/Compartment 1/time";
String TMR_DataPath = "/Compartments/Compartment 2/time";

String TML_val, TMR_val;


// ---------------------- Global Variables ---------------------- //


//Synchronize to PH time
const int timezone = 8 * 3600; // UTC + 08
const int dst = 0; // Daylight Savings Time


// ---------- Time-Based Parameters ---------- //
// Left Side Alarm
int alarm_hour = 99;
int alarm_min = 99;

// Right Side Alarm
int alarm_hour2 = 99;
int alarm_min2 = 99;

// For Demonstration Purposes
// int medicine_reset_time_hour_left;  // Reset time in Hours... typically 00:00:00
int medicine_reset_time_min_left;      // Reset time in Minutes... typically 00:00:00
// int medicine_reset_time_hour_right; // Reset time in Hours... typically 00:00:00
int medicine_reset_time_min_right;     // Reset time in Minutes... typically 00:00:00


// Timeout Timers
int manual_timer_start_Left = 0; // Gets the time for the start of the Manual Release for Left Compartment
int manual_timer_start_Right = 0; // Gets the time for the start of the Manual Release for Right Compartment

int timeout_timer_start_Left = 0; // Gets the time for the start of the alarm for Left Compartment
int timeout_timer_start_Right = 0; // Gets the time for the start of the alarm for Right Compartment

int timeout_time_Left = (1000 * 30); // Timeout time for Left Compartment
int timeout_time_Right = (1000 *30); // Timeout time for Right Compartment


int right;
// ---------- State Variables ---------- //

bool isTaken_Left = false; // Checks if the Pill has been retrieved in the Left compartment
bool isTaken_Right = false; // Checks if the Pill has been retrieved in the Right compartment

bool reset_Left = false; // Checks if the Motor has been reset
bool reset_Right = false; // Checks if the Right Motor has been reset

bool TakenToday_Left = false; // Checks if a Pill in the Left compartment has been taken on the same day
bool TakenToday_Right = false; // Checks if a Pill in the Right compartment has been taken on the same day

bool ButtonState_Left = 0; // Checks for Left Button toggle switch (ON or OFF)
bool ButtonState_Right = 0; // Checks for Right Button toggle switch (ON or OFF)

bool LeftButton = 0; // Checks for Left Button presses
bool RightButton = 0; // Checks for Right Button presses

bool prevLeftButton = 0; // Stores previous Left Button press
bool prevRightButton = 0; // Stores previous Right Button press

bool reset_timeout = false; // Checks if the time has exceeded the timeout

bool timeoutState_Left = false; // Checks if Left Compartment has timed out
bool timeoutState_Right = false; // Checks if Right Compartment has timed out

bool medicine_reset = false; // Resets the limit for daily intake





// --------------------------- Setup --------------------------- //


void setup() {
  // ---------- Pin Configuration ---------- //
  pinMode(D8, OUTPUT); // Left LED
  pinMode(D5, OUTPUT); // Right LED

  pinMode(D1, OUTPUT); // Motor A+
  pinMode(D2, OUTPUT); // Motor A-
  pinMode(D3, OUTPUT); // Motor B+
  pinMode(D4, OUTPUT); // Motor B-

  pinMode(D7, INPUT); // Left Infrared
  pinMode(A0, INPUT); // Right Infrared

  pinMode(D6, INPUT_PULLUP); // Left Button
  pinMode(D0, INPUT_PULLUP); // Right Button


  // ---------- WiFi Settings ---------- //
  WiFi.mode(WIFI_STA); // Initialize as Station-Mode

  // To reset settings of WifiManager (For Experimental use only)
  //wifiManager.resetSettings();

  Serial.begin(115200);

  wifiManager.autoConnect("ESP8266", "password"); // Create Soft Access Point


  // ---------- FireBase Settings ---------- //
  initFirebase();
  Firebase.RTDB.beginStream(&fbdo_TML, TML_DataPath);
  Firebase.RTDB.beginStream(&fbdo_TMR, TMR_DataPath);


// ---------- Real-Time Clock Settings ---------- //  
  configTime(timezone, dst, "pool.ntp.org", "time.nist.gov"); //Config Time
  Serial.println("Waiting for Internet time");

  // Print * when trying to connect
  while(!time(nullptr))
   {
     Serial.print("*");
     delay(1000);
   }

  Serial.println("Time response.... OK");

  getTime();
}


// ---------------------------- Loop ---------------------------- //


void loop() {
  getTime(); // Function for Time-based operations
  Get_FirebaseData(); // Fetch data from Firebase
  
  LeftButton = digitalRead(D6);
  RightButton = digitalRead(D0);

  if(prevLeftButton == 1 && LeftButton == 0 && timeoutState_Left == false && TakenToday_Left == false)
  {
    ButtonState_Left = true; 
  }

  if(prevRightButton == 1 && RightButton == 0 && timeoutState_Left == false && TakenToday_Right == false)
  {
    ButtonState_Right = true; 
  }

  // Debug Statements
  // Serial.print("LeftButton: ");
  // Serial.println(LeftButton);
  
  // Serial.print("prevLeftButton: ");
  // Serial.println(prevLeftButton);

  // Serial.print("ButtonState_Left: ");
  // Serial.println(ButtonState_Left);

  // Serial.println("---------------------");

  // Serial.print("RightButton: ");
  // Serial.println(RightButton);
  
  // Serial.print("prevRightButton: ");
  // Serial.println(prevRightButton);

  // Serial.print("ButtonState_Right: ");
  // Serial.println(ButtonState_Right);

  prevLeftButton = LeftButton;
  prevRightButton = RightButton;

  delay(1000);
}


// -------------------------- Functions -------------------------- //


// --------------------- FireBase --------------------- //
void initFirebase() {
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("signUp OK");
    signupOK = true;
  } else {
    Serial.printf("%s\n", config.signer.signupError.message.c_str());
  }
  config.token_status_callback = tokenStatusCallback;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void Get_FirebaseData()
{
  if(Firebase.ready() && signupOK){

    //Left Minute
    if(!Firebase.RTDB.readStream(&fbdo_TML))
      Serial.printf("Stream RTML read error, %s\n\n", fbdo_TML.errorReason().c_str());
    
    if(fbdo_TML.streamAvailable()){
        TML_val = fbdo_TML.stringData();
        String alarm_hour_str = TML_val.substring(0, 2);
        String alarm_min_str = TML_val.substring(2, 4);
        alarm_min = alarm_min_str.toInt();
        alarm_hour = alarm_hour_str.toInt();
        medicine_reset_time_min_left = alarm_min + 2;
        Serial.println("Successful read from " + fbdo_TML.dataPath() + " : " + alarm_hour);
      }
    
    //Right Minute
    if(!Firebase.RTDB.readStream(&fbdo_TMR))
      Serial.printf("Stream TMR read error, %s\n\n", fbdo_TMR.errorReason().c_str());
    
    if(fbdo_TMR.streamAvailable()){
        TMR_val = fbdo_TMR.stringData();
        String alarm_hour2_str = TMR_val.substring(0, 2);
        String alarm_min2_str = TMR_val.substring(2, 4);
        alarm_min2 = alarm_min2_str.toInt();
        alarm_hour2 = alarm_hour2_str.toInt();
        medicine_reset_time_min_right = alarm_min2 + 2;
        Serial.println("Successful read from " + fbdo_TMR.dataPath() + " : " + alarm_hour2);
      }
  }

  // Debug Statements
  Serial.print("Left Time: ");
  Serial.print(alarm_hour);
  Serial.print(":");
  Serial.println(alarm_min);

  Serial.println("--------------");

  Serial.print("Right Time: ");
  Serial.print(alarm_hour2);
  Serial.print(":");
  Serial.println(alarm_min2);

  Serial.println("--------------");

  Serial.print("Left RESET: ");
  Serial.println(medicine_reset_time_min_left);
  
  Serial.println("--------------");

  Serial.print("Right RESET: ");
  Serial.println(medicine_reset_time_min_right);
}



// --------------------- Time --------------------- //
void getTime()
{
  time_t now = time(nullptr); //Object
  struct tm* p_tm = localtime(&now); //Calculate Time

  int hour = p_tm->tm_hour; //Get Hours
  int min = p_tm->tm_min; //Get Minutes
  int sec = p_tm->tm_sec; //Get Seconds

  // Reset Time for Daily intake
  if(min == medicine_reset_time_min_left && sec == 0)
  {
    TakenToday_Left = false;
  }

  if(min == medicine_reset_time_min_right && sec == 0)
  {
    TakenToday_Right = false;
  }

  timeout(hour, min, sec);

  alarmConfig(hour, min); // Configure and Set Alarm

  Serial.print(hour);
  Serial.print(":");
  Serial.print(min);
  Serial.print(":");
  Serial.println(sec);
}


void alarmConfig(int hour, int min)
{
  // Condition for Alarm (Left)
  if(TakenToday_Left == false && timeoutState_Left == false)
  {
    if(hour == alarm_hour && min == alarm_min || ButtonState_Left)
    {
      if(!reset_timeout)
      {
        if(!isTaken_Left) // State variable to check if the pill has been taken
        {
          digitalWrite(D8, HIGH); // Activate Left LED
          // Activate Motor
          dispense(1);
        }
        else if(isTaken_Left)
        {
          Serial.println("Passed in Reset, isTaken_Left returned TRUE");
          reset(1); // Reset Motor
        }
      }
      else if(reset_timeout)
      {
        override_reset(1);
      }
    }
    else
    {
      digitalWrite(D8, LOW); // Turn off LED
      digitalWrite(D1, LOW); // Turn off Motor
      digitalWrite(D2, LOW); // Turn off Motor
      isTaken_Left = false; // Reset State Variable
      reset_Left = false; // Left Compartment Successfully Reset
      ButtonState_Left = false;
    }
  }
  else if(TakenToday_Left == true)
  {
    Serial.println("Left Medicine Taken.");
  }

  // Condition for Alarm (Right)
  if(TakenToday_Right == false && timeoutState_Right == false)
  {
    if(hour == alarm_hour2 && min == alarm_min2 || ButtonState_Right)
    {
      if(!reset_timeout)
      {
        if(!isTaken_Right) // State variable to check if the pill has been taken
        {
          digitalWrite(D5, HIGH); // Activate Right LED
          // Activate Motor
          dispense(2);
        }
        else if(isTaken_Right)
        {
          Serial.println("Passed in Reset, isTaken_Right returned TRUE");
          reset(2); // Reset Motor
        }
      }
      else if(reset_timeout)
      {
        override_reset(2);
      }
    }
    else
    {
      digitalWrite(D5, LOW); // Turn off LED
      digitalWrite(D3, LOW); // Turn off Motor
      digitalWrite(D4, LOW); // Turn off Motor
      isTaken_Right = false; // Reset State Variable
      reset_Right = false; // Left Compartment Successfully Reset
      ButtonState_Right = false;
    }
  }
  else if(TakenToday_Right == true)
  {
    Serial.println("Right Medicine Taken.");
  }
}




// --------------------- Mechanisms --------------------- //
void dispense(int compartment)
{
  if(compartment == 1) // Left
  {
    int left = digitalRead(D7); // Check Left IR

    // While Pill is NOT detected, dispense
    if(left)
    {
      digitalWrite(D2, HIGH); // Going Up
      digitalWrite(D1, LOW); // Going Up

      delay(75);

      digitalWrite(D2, LOW);
    }
    else // When detected, stop motor
    {
      digitalWrite(D2, LOW); // Stop Motor
      digitalWrite(D1, LOW); // Stop Motor
      isTaken_Left = true;
      Serial.print("Passed in flip value isTaken_Left, Current Value is: ");
      Serial.println(isTaken_Left);
    }
  }
  else if (compartment == 2) // Right
  {
    right = analogRead(A0); // Check Right IR

    Serial.println("-------------------");
    Serial.println(right);
    Serial.println("-------------------");

    // While Pill is NOT detected, dispense
    if(right > 55)
    {
      digitalWrite(D3, HIGH); // Going Up
      digitalWrite(D4, LOW); // Going Up

      delay(60);

      digitalWrite(D3, LOW);
    }
    else // When detected, stop motor
    {
      digitalWrite(D3, LOW); // Stop Motor
      digitalWrite(D4, LOW); // Stop Motor
      isTaken_Right = true;
      Serial.print("Passed in flip value isTaken_Right, Current Value is: ");
      Serial.println(isTaken_Right);
    }
  }
}

void reset(int compartment)
{
  if(compartment == 1) // Left
  {
    int left = digitalRead(D7); // Check Left IR

    if(reset_Left)
    {
      digitalWrite(D8, LOW); // Turn Off LED
      ButtonState_Left = false;
      TakenToday_Left = true;
    }
    else if (!reset_Left)
    {
      if(!left) // If Pill is still Container
      {
        digitalWrite(D2, LOW); // Hold Motor
        digitalWrite(D1, LOW); // Hold Motor
      }
      else if(left)
      {
        digitalWrite(D2, LOW); // Going Down
        digitalWrite(D1, HIGH); // Going Down

        // Condition to stop
        delay(300);

        digitalWrite(D2, LOW); // Stop Motor
        digitalWrite(D1, LOW); // Stop Motor
        reset_Left = true;
      }
    }
  }
  else if (compartment == 2) // Right
  {
    right = analogRead(A0); // Check Right IR

    if(reset_Right)
    {
      digitalWrite(D5, LOW); // Turn Off LED
      ButtonState_Right = false;
      TakenToday_Right = true;
    }
    else if (!reset_Right)
    {
      if(right < 55) // If Pill is still Container
      {
        digitalWrite(D3, LOW); // Hold Motor
        digitalWrite(D4, LOW); // Hold Motor
      }
      else if(right > 55)
      {
        digitalWrite(D3, LOW); // Going Down
        digitalWrite(D4, HIGH); // Going Down

        // Condition to stop
        delay(300);

        digitalWrite(D3, LOW); // Stop Motor
        digitalWrite(D4, LOW); // Stop Motor
        reset_Right = true;
      }
    }
  }
}


void override_reset(int compartment)
{
  if(compartment == 1) // Left  
  {
    digitalWrite(D2, LOW); // Going Down
    digitalWrite(D1, HIGH); // Going Down

    // Condition to stop
    delay(300);

    digitalWrite(D2, LOW); // Stop Motor
    digitalWrite(D1, LOW);

    digitalWrite(D8, LOW); // Turn off LED
    isTaken_Left = false; // Reset State Variable
    reset_timeout = false; // Left Compartment Successfully Reset
    ButtonState_Left = false;
    timeoutState_Left = true; // Left Compartment has Timed out
  }
  else if (compartment == 2) // Right
  {
    digitalWrite(D3, LOW); // Going Down
    digitalWrite(D4, HIGH); // Going Down

    // Condition to stop
    delay(300);

    digitalWrite(D3, LOW); // Stop Motor
    digitalWrite(D4, LOW);

    digitalWrite(D5, LOW); // Turn off LED
    isTaken_Right = false; // Reset State Variable
    reset_timeout = false; // Left Compartment Successfully Reset
    ButtonState_Right = false;
    timeoutState_Right = true; // Left Compartment has Timed out    
  }
}

void timeout(int hour, int min, int sec)
{
  // Manual Release Timeout for Left Compartment
  if(!ButtonState_Left)
  {
    Serial.println("Passed Left Manual");
    manual_timer_start_Left = millis(); // Save the last instance of Second while Button is not pressed
  }
  else if(ButtonState_Left && TakenToday_Left == false)
  {
    if(millis() - manual_timer_start_Left > timeout_time_Left)
    {
      reset_timeout = true; // If pill is not retrieved within timeout, the system resets
    }
  }


  // Automatic Release Timeout for Left Compartment
  if(hour != alarm_hour || min != alarm_min)
  {
    Serial.println("Passed Left Auto");
    timeout_timer_start_Left = millis(); // Save the last instance of Second while Button is not pressed
    timeoutState_Left = false;
  }
  else if(hour == alarm_hour && min == alarm_min && timeoutState_Left == false && TakenToday_Left == false)
  {
    Serial.println("Passed TIMEOUT CHECK");
    if(millis() - timeout_timer_start_Left > timeout_time_Left)
    {
      reset_timeout = true; // If pill is not retrieved within timeout, the system resets
      Serial.println("TIMEOUT ACTIVATED");
    }
  }
  else if(timeoutState_Left)
  {
    Serial.println("TIMEOUT ACTIVE");
    Serial.print("reset_timeout: ");
    Serial.println(reset_timeout);
  }


  // Manual Release Timeout for Right Compartment
  if(!ButtonState_Right)
  {
    Serial.println("Passed Right Manual");
    manual_timer_start_Right = millis(); // Save the last instance of Second while Button is not pressed
  }
  else if(ButtonState_Right && TakenToday_Right == false)
  {
    if(millis() - manual_timer_start_Right > timeout_time_Right)
    {
      reset_timeout = true; // If pill is not retrieved within timeout, the system resets
    }
  }


  // Automatic Release Timeout for Right Compartment
  if(hour != alarm_hour2 || min != alarm_min2)
  {
    Serial.println("Passed Right Auto");
    timeout_timer_start_Right = millis(); // Save the last instance of Second while Button is not pressed
    timeoutState_Right = false;
  }
  else if(hour == alarm_hour2 && min == alarm_min2 && timeoutState_Right == false && TakenToday_Right == false)
  {
    Serial.println("Passed TIMEOUT CHECK");
    if(millis() - timeout_timer_start_Right > timeout_time_Right)
    {
      reset_timeout = true; // If pill is not retrieved within timeout, the system resets
      Serial.println("TIMEOUT ACTIVATED");
    }
  }
  else if(timeoutState_Right)
  {
    Serial.println("TIMEOUT ACTIVE");
    Serial.print("reset_timeout: ");
    Serial.println(reset_timeout);
  }
}