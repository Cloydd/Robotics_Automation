import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // comment if not working
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/medicine.dart';

class GlobalBloc {
  BehaviorSubject<List<Medicine>>? _medicineList$;
  BehaviorSubject<List<Medicine>>? get medicinelist$ => _medicineList$;

  GlobalBloc() {
    _medicineList$ = BehaviorSubject<List<Medicine>>.seeded([]);
    makeMedicineList();
  }

  Future removedMedicine(Medicine tobeRemoved, DocumentReference documentRef,
      var compartment) async {
    FlutterLocalNotificationsPlugin
        flutterLocalNotificationsPlugin = // comment if not working
        FlutterLocalNotificationsPlugin();
    SharedPreferences sharedUser = await SharedPreferences.getInstance();
    List<String> medicineJsonList = [];

    Map<String, dynamic> medicineDataNull = {
      'compartment': "Null",
      'dosage': "Null",
      'interval': "Null",
      'medicineName': "Null",
      // 'reset_time_hour': "Null",
      // 'reset_time_min': "Null",
      'time_hour': "Null",
      'time_min': "Null",
      'time': "9999",
    };

    var blockList = _medicineList$!.value;
    blockList.removeWhere(
        (medicine) => medicine.medicineName == tobeRemoved.medicineName);

    // Remove notification
    for (int i = 0; i < (24 / tobeRemoved.interval!).floor(); i++) {
      flutterLocalNotificationsPlugin
          .cancel(int.parse(tobeRemoved.notificationIDs![i]));
    } // comment if not working

    if (compartment == 1) {
      await FirebaseDatabase.instance
          .ref()
          .child("/Compartments/Compartment 1")
          .set(medicineDataNull);
      await documentRef.delete();
    }

    if (compartment == 2) {
      await FirebaseDatabase.instance
          .ref()
          .child("/Compartments/Compartment 2")
          .set(medicineDataNull);
      await documentRef.delete();
    } else {
      await FirebaseDatabase.instance.ref().child(documentRef.id).remove();
      await documentRef.delete();
    }

    if (blockList.isNotEmpty) {
      for (var blockMedicine in blockList) {
        String medicineJson = jsonEncode(blockMedicine.toJson());
        medicineJsonList.add(medicineJson);
      }
    }

    sharedUser.setStringList('medicines', medicineJsonList);
    _medicineList$!.add(blockList);
  }

  Future updateMedicineList(Medicine newMedicine) async {
    var blocList = _medicineList$!.value;
    blocList.add(newMedicine);
    _medicineList$!.add(blocList);

    Map<String, dynamic> tempMap = newMedicine.toJson();
    SharedPreferences? sharedUser = await SharedPreferences.getInstance();
    String newMedicineJson = jsonEncode(tempMap);
    List<String> medicineJsonList = [];
    if (sharedUser.getStringList('medicines') == null) {
      medicineJsonList.add(newMedicineJson);
    } else {
      medicineJsonList = sharedUser.getStringList('medicines')!;
      medicineJsonList.add(newMedicineJson);
    }
    sharedUser.setStringList('medicines', medicineJsonList);
  }

  Future makeMedicineList() async {
    SharedPreferences? sharedUser = await SharedPreferences.getInstance();
    List<String>? jsonList = sharedUser.getStringList('medicines');
    List<Medicine> prefList = [];

    if (jsonList == null) {
      return;
    } else {
      for (String jsonMedicine in jsonList) {
        dynamic userMap = jsonDecode(jsonMedicine);
        Medicine tempMedicine = Medicine.fromJson(userMap);
        prefList.add(tempMedicine);
      }
      // state update
      _medicineList$!.add(prefList);
    }
  }

  void dispose() {
    _medicineList$!.close();
  }
}
