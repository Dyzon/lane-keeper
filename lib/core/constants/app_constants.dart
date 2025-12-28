class AppConstants {
  static const String appName = "LaneKeeper";
  
  // Scoring Weights
  static const double weightSpeed = 0.30;
  static const double weightBraking = 0.20;
  static const double weightAccel = 0.20;
  static const double weightStability = 0.15;
  static const double weightPatience = 0.15;

  // Thresholds
  static const double minTripSpeedKmh = 8.0;
  static const double stopTripSpeedKmh = 5.0;
  static const int minTripDistanceMeters = 200;
  static const int tripStartDurationSeconds = 30; // Speed > 8km/h for 30s
  static const int tripStopDurationSeconds = 120; // Speed < 5km/h for 2m

  // Harsh Event Thresholds
  static const double harshBrakeThreshold = -3.5; // m/s^2
  static const double harshAccelThreshold = 3.0; // m/s^2
  
  static const List<String> indianCities = [
    "Mumbai",
    "Delhi",
    "Bangalore",
    "Hyderabad",
    "Ahmedabad",
    "Chennai",
    "Kolkata",
    "Surat",
    "Pune",
    "Jaipur",
    "Lucknow",
    "Kanpur",
    "Nagpur",
    "Indore",
    "Thane",
    "Bhopal",
    "Visakhapatnam",
    "Pimpri-Chinchwad",
    "Patna",
    "Vadodara",
    "Ghaziabad",
    "Ludhiana",
    "Agra",
    "Nashik",
    "Faridabad",
    "Meerut",
    "Rajkot",
    "Kalyan-Dombivli",
    "Vasai-Virar",
    "Varanasi",
    "Srinagar",
    "Aurangabad",
    "Dhanbad",
    "Amritsar",
    "Navi Mumbai",
    "Allahabad",
    "Howrah",
    "Ranchi",
    "Gwalior",
    "Jabalpur",
    "Coimbatore",
    "Vijayawada",
    "Jodhpur",
    "Madurai",
    "Raipur",
    "Kota",
    "Chandigarh",
    "Guwahati",
    "Solapur",
    "Hubli-Dharwad",
  ];
}
