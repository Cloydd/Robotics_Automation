import 'package:flutter/material.dart';
import 'package:PillSynch/constants.dart';
import 'package:PillSynch/global_bloc.dart';
// import 'package:PillSynch/notif_service.dart';
import 'package:PillSynch/pages/medicine_details/medicine_details.dart';
import 'package:PillSynch/pages/new_entry/new_entry_page.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/medicine.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: EdgeInsets.all(2.h),
        child: Column(
          children: [
            const TopContainer(),
            SizedBox(height: 2.h),
            //the widget take space as per need
            const Flexible(
              child: BottomContainer(),
            ),
          ],
        ),
      ),
      floatingActionButton: InkResponse(
        onTap: () {
          //go to new entry page
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const NewEntryPage()));
        },
        child: SizedBox(
          width: 18.w,
          height: 9.h,
          child: Card(
              color: kPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2.h),
              ),
              child:
                  Icon(Icons.add_outlined, color: kScaffoldColor, size: 50.sp)),
        ),
      ),
    );
  }
}

class TopContainer extends StatelessWidget {
  const TopContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalBloc globalBloc = Provider.of<GlobalBloc>(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.topLeft,
          padding: EdgeInsets.only(
            bottom: 1.h,
          ),
          child: Text("Stay in Synch. \nStay Strong.",
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.headlineLarge),
        ),
        Container(
          alignment: Alignment.topLeft,
          padding: EdgeInsets.only(bottom: 1.h),
          child: Text("Welcome to PillSynch.",
              style: Theme.of(context).textTheme.titleSmall),
        ),
        SizedBox(
          height: 2.h,
        ),
        StreamBuilder<List<Medicine>>(
            stream: globalBloc.medicinelist$,
            builder: (context, snapshot) {
              return Container(
                alignment: Alignment.center,
                padding: EdgeInsets.only(bottom: 1.h),
                child: Text(
                  !snapshot.hasData ? '0' : snapshot.data!.length.toString(),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              );
            }),
      ],
    );
  }
}

class BottomContainer extends StatelessWidget {
  const BottomContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GlobalBloc globalBloc = Provider.of<GlobalBloc>(context);
    return StreamBuilder(
      stream: globalBloc.medicinelist$,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // if no data is saved
          return Container();
        } else if (snapshot.data!.isEmpty) {
          return Center(
            child: Text('No Medicine',
                style: Theme.of(context).textTheme.titleSmall),
          );
        } else {
          return GridView.builder(
            padding: EdgeInsets.only(top: 1.h),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return MedicineCard(medicine: snapshot.data![index]);
            },
          );
        }
      },
    );
  }
}

class MedicineCard extends StatelessWidget {
  const MedicineCard({super.key, required this.medicine});
  final Medicine medicine;

  Hero makeIcon(double size) {
    if (medicine.medicineType == 'bottle') {
      return Hero(
        tag: medicine.medicineName! + medicine.medicineType!,
        child: SvgPicture.asset(
          'assets/icons/bottle.svg',
          color: kOtherColor,
          height: 7.h,
        ),
      );
    } else if (medicine.medicineType == 'pill') {
      return Hero(
        tag: medicine.medicineName! + medicine.medicineType!,
        child: SvgPicture.asset(
          'assets/icons/pill.svg',
          color: kOtherColor,
          height: 7.h,
        ),
      );
    } else if (medicine.medicineType == 'shot') {
      return Hero(
        tag: medicine.medicineName! + medicine.medicineType!,
        child: SvgPicture.asset(
          'assets/icons/syringe.svg',
          color: kOtherColor,
          height: 7.h,
        ),
      );
    } else if (medicine.medicineType == 'tablet') {
      return Hero(
        tag: medicine.medicineName! + medicine.medicineType!,
        child: SvgPicture.asset(
          'assets/icons/tablet.svg',
          color: kOtherColor,
          height: 7.h,
        ),
      );
    }

    // in case of no medicine type icon selection
    return Hero(
      tag: medicine.medicineName! + medicine.medicineType!,
      child: Icon(
        Icons.error,
        color: kOtherColor,
        size: size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      highlightColor: Colors.white,
      splashColor: Colors.grey,
      onTap: () {
        // go to details activity with animation, tbf
        Navigator.of(context).push(
          PageRouteBuilder<void>(
            pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, Widget? child) {
                  return Opacity(
                    opacity: animation.value,
                    child: MedicineDetails(medicine),
                  );
                },
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      },

      // Medicine name icon
      child: Container(
        padding: EdgeInsets.only(left: 4.w, right: 2.w, top: 1.h, bottom: 2.h),
        margin: EdgeInsets.all(1.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2.h),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            makeIcon(7.h),

            const Spacer(),
            Hero(
              tag: medicine.medicineName!,
              child: Text(
                medicine.medicineName!,
                overflow: TextOverflow.fade,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            SizedBox(
              height: 0.3.h,
            ),
            //time interval data with condition
            Text(
              medicine.interval == 1
                  ? "Every ${medicine.interval} hour"
                  : "Every ${medicine.interval} hour",
              overflow: TextOverflow.fade,
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
