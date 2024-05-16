import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:PillSynch/constants.dart';
import 'package:PillSynch/global_bloc.dart';
// import 'package:PillSynch/notificationapi.dart';
import 'package:PillSynch/pages/home_page.dart';
import 'package:PillSynch/pages/new_entry/new_entry_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../common/convert_time.dart';
import '../../models/errors.dart';
import '../../models/medicine.dart';
import '../../models/medicine_type.dart';
import '../success_screen/success_screen.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_database/firebase_database.dart';

class NewEntryPage extends StatefulWidget {
  const NewEntryPage({Key? key}) : super(key: key);

  @override
  State<NewEntryPage> createState() => _NewEntryPageState();
}

class _NewEntryPageState extends State<NewEntryPage> {
  late TextEditingController nameController;
  late TextEditingController dosageController;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late NewEntryBloc _newEntryBloc;
  late GlobalKey<ScaffoldState> _scaffoldKey;

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    dosageController.dispose();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _newEntryBloc.dispose();
  }

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    dosageController = TextEditingController();
    _newEntryBloc = NewEntryBloc();
    _scaffoldKey = GlobalKey<ScaffoldState>();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    initializeNotification();
    initializeErrorListen();
  }

  @override
  Widget build(BuildContext context) {
    final GlobalBloc globalBloc = Provider.of<GlobalBloc>(context);
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Add New'),
      ),
      body: Provider<NewEntryBloc>.value(
        value: _newEntryBloc,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelTitle(
                title: 'Medicine Name',
                isRequired: true,
              ),
              TextFormField(
                  maxLength: 12,
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                  ),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(color: kOtherColor)),
              const PanelTitle(
                title: 'Dosage in mg',
                isRequired: false,
              ),
              TextFormField(
                  maxLength: 12,
                  controller: dosageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                  ),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(color: kOtherColor)),
              SizedBox(
                height: 2.h,
              ),
              const PanelTitle(title: "Medicine Type", isRequired: false),
              Padding(
                padding: EdgeInsets.only(top: 1.h),
                child: StreamBuilder<MedicineType>(
                  stream: _newEntryBloc.selectedMedicineType,
                  builder: (context, snapshot) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MedicineTypeColumn(
                            medicineType: MedicineType.pill,
                            name: 'Pill',
                            iconValue: 'assets/icons/pill.svg',
                            isSelected: snapshot.data == MedicineType.pill
                                ? true
                                : false),
                        MedicineTypeColumn(
                            medicineType: MedicineType.bottle,
                            name: 'Bottle',
                            iconValue: 'assets/icons/bottle.svg',
                            isSelected: snapshot.data == MedicineType.bottle
                                ? true
                                : false),
                        MedicineTypeColumn(
                            medicineType: MedicineType.shot,
                            name: 'Shot',
                            iconValue: 'assets/icons/syringe.svg',
                            isSelected: snapshot.data == MedicineType.shot
                                ? true
                                : false),
                        MedicineTypeColumn(
                            medicineType: MedicineType.tablet,
                            name: 'Tablet',
                            iconValue: 'assets/icons/tablet.svg',
                            isSelected: snapshot.data == MedicineType.tablet
                                ? true
                                : false),
                      ],
                    );
                  },
                ),
              ),
              const PanelTitle(
                  title: "Select Compartment [1 or 2, 0 if not applicable]",
                  isRequired: false),
              const CompartmentSelection(),
              const PanelTitle(title: "Interval Selection", isRequired: true),
              const IntervalSelection(),
              const PanelTitle(title: 'Starting Time', isRequired: true),
              const SelectTime(),
              SizedBox(
                height: 2.h,
              ),
              Padding(
                padding: EdgeInsets.only(left: 8.w, right: 8.w),
                child: SizedBox(
                  width: 80.w,
                  height: 5.h,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: const StadiumBorder(),
                    ),
                    child: Center(
                      child: Text(
                        'Confirm',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: kScaffoldColor,
                            ),
                      ),
                    ),
                    onPressed: () async {
                      // add medicine
                      String? medicineName;
                      int? dosage;

                      //medicine name
                      if (nameController.text == "") {
                        _newEntryBloc.submitError(EntryError.nameNull);
                        return;
                      }
                      if (nameController.text != "") {
                        medicineName = nameController.text;
                      }

                      //dosageController

                      if (dosageController.text == "") {
                        dosage = 0;
                      }
                      if (dosageController.text != "") {
                        dosage = int.parse(dosageController.text);
                      }

                      for (var medicine in globalBloc.medicinelist$!.value) {
                        if (medicineName == medicine.medicineName) {
                          _newEntryBloc.submitError(EntryError.nameDuplicate);
                          return;
                        }

                        if (_newEntryBloc.selectCompartment$!.value != 0 &&
                            _newEntryBloc.selectCompartment$!.value ==
                                medicine.compartment) {
                          _newEntryBloc
                              .submitError(EntryError.compartmentDuplicate);
                          return;
                        }
                      }

                      if (_newEntryBloc.selectIntervals!.value == 0) {
                        _newEntryBloc.submitError(EntryError.interval);
                        return;
                      }

                      if (_newEntryBloc.selectedTimeOfDay$!.value == 'None') {
                        _newEntryBloc.submitError(EntryError.startTime);
                        return;
                      }

                      String medicineType = _newEntryBloc
                          .selectedMedicineType!.value
                          .toString()
                          .substring(13);

                      int interval = _newEntryBloc.selectIntervals!.value;
                      int compartment = _newEntryBloc.selectCompartment$!.value;

                      String startTime =
                          _newEntryBloc.selectedTimeOfDay$!.value;
                      print(startTime);
                      // comment if not working
                      List<int> intIDs =
                          makeIDs(24 / _newEntryBloc.selectIntervals!.value);
                      List<String> notificationIDs =
                          intIDs.map((i) => i.toString()).toList();

                      // var reset_time;
                      // reset_time = (int.parse(startTime) + 2).toString();
                      // print(reset_time);

                      // Send this to NodeMCU
                      Map<String, dynamic> medicineData = {
                        'compartment': compartment.toString(),
                        'dosage': dosage,
                        'interval': interval.toString(),
                        'medicineName': medicineName,
                        // 'reset_time_hour': reset_time[0] + reset_time[1],
                        // 'reset_time_min': reset_time[2] + reset_time[3],
                        'time_hour': startTime[0] + startTime[1],
                        'time_min': startTime[2] + startTime[3],
                        'time': startTime,
                      };

                      print(medicineData);

                      // Sending to Firebase

                      CollectionReference collRef =
                          FirebaseFirestore.instance.collection('medicine');

                      DocumentReference docRef =
                          await collRef.add(medicineData);

                      String documentID = docRef.id;

                      if (compartment == 1) {
                        DatabaseReference dbRef = FirebaseDatabase.instance
                            .ref()
                            .child("/Compartments/Compartment 1");

                        dbRef.update(medicineData);
                      }

                      if (compartment == 2) {
                        DatabaseReference dbRef = FirebaseDatabase.instance
                            .ref()
                            .child("/Compartments/Compartment 2");

                        dbRef.update(medicineData);
                      }

                      if (compartment == 0) {
                        FirebaseDatabase.instance
                            .ref()
                            .child(documentID)
                            .set(medicineData);
                      }

                      Medicine newEntryMedicine = Medicine(
                        notificationIDs: notificationIDs,
                        medicineName: medicineName,
                        dosage: dosage,
                        medicineType: medicineType,
                        interval: interval,
                        startTime: startTime,
                        documentID: documentID,
                        compartment: compartment,
                      );

                      //update medicine list via global bloc
                      globalBloc.updateMedicineList(newEntryMedicine);

                      // schedule notification
                      scheduleNotification(
                          newEntryMedicine); // comment if not working

                      //go to success screen
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SuccessScreen()));
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void initializeErrorListen() {
    _newEntryBloc.errorState$!.listen((EntryError error) {
      switch (error) {
        case EntryError.nameNull:
          displayError("Please enter the medicine's name");
          break;

        case EntryError.nameDuplicate:
          displayError("Medicine name already exists");
          break;

        case EntryError.dosage:
          displayError("Please enter the dosage required");
          break;

        case EntryError.interval:
          displayError("Please select the reminder's interval");
          break;

        case EntryError.compartmentDuplicate:
          displayError(
              "Compartment is already occupied, choose other compartments.");
          break;

        case EntryError.startTime:
          displayError("Please select the reminder's starting time");
          break;
        default:
      }
    });
  }

  void displayError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kOtherColor,
        content: Text(error),
        duration: const Duration(milliseconds: 2000),
      ),
    );
  }

  List<int> makeIDs(double n) {
    var rng = Random();
    List<int> ids = [];
    for (int i = 0; i < n; i++) {
      ids.add(rng.nextInt(1000000000));
    }
    return ids;
  }

  initializeNotification() async {
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('bell');

    var initializationSettingsIOS = const DarwinInitializationSettings();

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();
  }

  Future onSelectNotification(String? payload) async {
    if (payload != null) {
      debugPrint('notification payload: $payload');
    }

    await Navigator.push(
        context, MaterialPageRoute(builder: (context) => const HomePage()));
  }

  Future<void> scheduleNotification(Medicine medicine) async {
    int? hour = int.tryParse(medicine.startTime![0] + medicine.startTime![1]);
    var ogValue = hour;
    int? minute = int.tryParse(medicine.startTime![2] + medicine.startTime![3]);

    var scheduledTime = DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day, hour!.toInt(), minute!.toInt());

    if (scheduledTime.isBefore(DateTime.now())) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
        'repeatDailyAtTime channel id', 'repeatDailyAtTime channel name',
        importance: Importance.max,
        ledColor: kOtherColor,
        ledOffMs: 1000,
        ledOnMs: 1000,
        enableLights: true);

    var iOSPlatformChannelSpecifics = const DarwinNotificationDetails();

    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);

    var location = tz.getLocation('Asia/Manila');

    var tzdatetime = tz.TZDateTime.from(
        scheduledTime, location); //could be var instead of final

    for (int i = 0; i < (24 / medicine.interval!).floor(); i++) {
      if (hour! + (medicine.interval! * i) > 23) {
        hour = hour + (medicine.interval! * i) - 24;
      } else {
        hour = hour + (medicine.interval! * i);
      }

      scheduledTime = DateTime(DateTime.now().year, DateTime.now().month,
          DateTime.now().day, hour.toInt(), minute.toInt());

      if (scheduledTime.isBefore(DateTime.now())) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
      await flutterLocalNotificationsPlugin.zonedSchedule(
        int.parse(medicine.notificationIDs![i]),
        'Reminder: ${medicine.medicineName}',
        medicine.medicineType.toString() != MedicineType.none.toString()
            ? 'It is time to take your ${medicine.medicineType!.toLowerCase()}, according to schedule'
            : 'It is time to take your medicine, according to schedule',
        tz.TZDateTime.from(scheduledTime, location),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      hour = ogValue;
    }
  }
}

class SelectTime extends StatefulWidget {
  const SelectTime({super.key});

  @override
  State<SelectTime> createState() => _SelectTimeState();
}

class _SelectTimeState extends State<SelectTime> {
  TimeOfDay _time = const TimeOfDay(hour: 0, minute: 00);
  bool _clicked = false;

  Future<TimeOfDay> _selectTime() async {
    final NewEntryBloc newEntryBloc =
        Provider.of<NewEntryBloc>(context, listen: false);
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: _time);

    if (picked != null && picked != _time) {
      setState(() {
        _time = picked;
        _clicked = true;

        //update state via provider
        newEntryBloc.updateTime(convertTime(_time.hour.toString()) +
            convertTime(_time.minute.toString()));
      });
    }
    return picked!;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8.h,
      child: Padding(
        padding: EdgeInsets.only(top: 2.h),
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: kPrimaryColor,
            shape: const StadiumBorder(),
          ),
          onPressed: () {
            _selectTime();
          },
          child: Center(
            child: Text(
              _clicked == false
                  ? "Select Time"
                  : "${convertTime(_time.hour.toString())}:${convertTime(_time.minute.toString())}",
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: kScaffoldColor),
            ),
          ),
        ),
      ),
    );
  }
}

class CompartmentSelection extends StatefulWidget {
  const CompartmentSelection({super.key});

  @override
  State<CompartmentSelection> createState() => _CompartmentSelectionState();
}

class _CompartmentSelectionState extends State<CompartmentSelection> {
  final _compartments = [1, 2, 0];
  var _selected = 0;
  @override
  Widget build(BuildContext context) {
    final NewEntryBloc newEntryBloc = Provider.of<NewEntryBloc>(context);
    return Padding(
        padding: EdgeInsets.only(top: 1.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Compartment',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: kTextColor,
                  ),
            ),
            DropdownButton(
              iconEnabledColor: kOtherColor,
              dropdownColor: kScaffoldColor,
              itemHeight: 8.h,
              hint: _selected == 0
                  ? Text(
                      'Choose Compartment',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: kTextColor,
                          ),
                    )
                  : null,
              elevation: 4,
              value: _selected == 0 ? null : _selected,
              items: _compartments.map(
                (int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(
                      value.toString(),
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: kSecondaryColor,
                          ),
                    ),
                  );
                },
              ).toList(),
              onChanged: (newVal) {
                setState(
                  () {
                    _selected = newVal!;
                    newEntryBloc.updateCompartment(newVal);
                  },
                );
              },
            ),
          ],
        ));
  }
}

class IntervalSelection extends StatefulWidget {
  const IntervalSelection({super.key});

  @override
  State<IntervalSelection> createState() => _IntervalSelectionState();
}

class _IntervalSelectionState extends State<IntervalSelection> {
  final _intervals = [6, 8, 12, 24];
  var _selected = 0;
  @override
  Widget build(BuildContext context) {
    final NewEntryBloc newEntryBloc = Provider.of<NewEntryBloc>(context);
    return Padding(
      padding: EdgeInsets.only(top: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Remind me every',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: kTextColor,
                ),
          ),
          DropdownButton(
            iconEnabledColor: kOtherColor,
            dropdownColor: kScaffoldColor,
            itemHeight: 8.h,
            hint: _selected == 0
                ? Text(
                    'Select an Interval',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: kOtherColor,
                        ),
                  )
                : null,
            elevation: 4,
            value: _selected == 0 ? null : _selected,
            items: _intervals.map(
              (int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(
                    value.toString(),
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: kSecondaryColor,
                        ),
                  ),
                );
              },
            ).toList(),
            onChanged: (newVal) {
              setState(
                () {
                  _selected = newVal!;
                  newEntryBloc.updateInterval(newVal);
                },
              );
            },
          ),
          Text(
            _selected == 1 ? " hour" : "hours",
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: kTextColor,
                ),
          ),
        ],
      ),
    );
  }
}

class MedicineTypeColumn extends StatelessWidget {
  const MedicineTypeColumn(
      {Key? key,
      required this.medicineType,
      required this.name,
      required this.iconValue,
      required this.isSelected})
      : super(key: key);
  final MedicineType medicineType;
  final String name;
  final String iconValue;
  final bool isSelected;
  @override
  Widget build(BuildContext context) {
    final NewEntryBloc newEntryBloc = Provider.of<NewEntryBloc>(context);
    return GestureDetector(
      onTap: () {
        //select medicine type
        newEntryBloc.updateSelectedMedicine(medicineType);
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              width: 20.w,
              alignment: Alignment.center,
              height: 10.h,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2.h),
                  color: isSelected ? kOtherColor : Colors.white),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 1,
                    bottom: 1,
                  ),
                  child: SvgPicture.asset(
                    iconValue,
                    height: 7.h,
                    color: isSelected ? Colors.white : kOtherColor,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: Container(
              width: 20.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: isSelected ? kOtherColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  name,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall!
                      .copyWith(color: isSelected ? Colors.white : kOtherColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PanelTitle extends StatelessWidget {
  const PanelTitle({Key? key, required this.title, required this.isRequired})
      : super(key: key);
  final String title;
  final bool isRequired;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 2.0),
      child: Text.rich(
        TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: title,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            TextSpan(
              text: isRequired ? " *" : "",
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: kPrimaryColor,
                  ),
            )
          ],
        ),
      ),
    );
  }
}
