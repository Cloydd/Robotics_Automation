import 'package:rxdart/rxdart.dart';
import '../../models/errors.dart';
import '../../models/medicine_type.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:provider/provider.dart';

class NewEntryBloc {
  BehaviorSubject<MedicineType>? _selectedMedicineType$;
  ValueStream<MedicineType>? get selectedMedicineType =>
      _selectedMedicineType$!.stream;

  BehaviorSubject<int>? _selectedInterval$;
  BehaviorSubject<int>? get selectIntervals => _selectedInterval$;

  BehaviorSubject<int>? _selectedCompartment$;
  BehaviorSubject<int>? get selectCompartment$ => _selectedCompartment$;

  BehaviorSubject<String>? _selectedTimeOfDay$;
  BehaviorSubject<String>? get selectedTimeOfDay$ => _selectedTimeOfDay$;

  // error state
  BehaviorSubject<EntryError>? _errorState$;
  BehaviorSubject<EntryError>? get errorState$ => _errorState$;

  NewEntryBloc() {
    _selectedMedicineType$ =
        BehaviorSubject<MedicineType>.seeded(MedicineType.none);

    _selectedTimeOfDay$ = BehaviorSubject<String>.seeded('none');
    _selectedInterval$ = BehaviorSubject<int>.seeded(0);
    _selectedCompartment$ = BehaviorSubject<int>.seeded(0);

    _errorState$ = BehaviorSubject<EntryError>();
  }

  void dispose() {
    _selectedMedicineType$!.close();
    _selectedTimeOfDay$!.close();
    _selectedInterval$!.close();
    _selectedCompartment$!.close();
  }

  void submitError(EntryError error) {
    _errorState$!.add(error);
  }

  void updateInterval(int interval) {
    _selectedInterval$!.add(interval);
  }

  void updateCompartment(int compartment) {
    _selectedCompartment$!.add(compartment);
  }

  void updateTime(String time) {
    _selectedTimeOfDay$!.add(time);
  }

  void updateSelectedMedicine(MedicineType type) {
    MedicineType _tempType = _selectedMedicineType$!.value;
    if (type == _tempType) {
      _selectedMedicineType$!.add(MedicineType.none);
    } else {
      _selectedMedicineType$!.add(type);
    }
  }
}
