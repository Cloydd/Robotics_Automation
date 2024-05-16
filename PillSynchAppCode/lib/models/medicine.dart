class Medicine {
  final List<dynamic>? notificationIDs;
  final String? medicineName;
  final int? dosage;
  final String? medicineType;
  final int? interval;
  final String? startTime;
  final String? documentID;
  final int? compartment;

  Medicine(
      {this.notificationIDs,
      this.medicineName,
      this.dosage,
      this.medicineType,
      this.interval,
      this.startTime,
      this.documentID,
      this.compartment});

  // getters
  String get getName => medicineName!;
  int get getDosage => dosage!;
  String get getType => medicineType!;
  int get getInterval => interval!;
  String get getStartTime => startTime!;
  List<dynamic> get getIDs => notificationIDs!;
  String get getdDocumentID => documentID!;
  int get getCompartment => compartment!;

  Map<String, dynamic> toJson() {
    return {
      'ids': notificationIDs,
      'name': medicineName,
      'dosage': dosage,
      'type': medicineType,
      'interval': interval,
      'start': startTime,
      'documentID': documentID,
      'compartment': compartment,
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> parsedJson) {
    return Medicine(
        notificationIDs: parsedJson['ids'],
        medicineName: parsedJson['name'],
        dosage: parsedJson['dosage'],
        medicineType: parsedJson['type'],
        interval: parsedJson['interval'],
        startTime: parsedJson['start'],
        documentID: parsedJson['documentID'],
        compartment: parsedJson['compartment']);
  }
}
