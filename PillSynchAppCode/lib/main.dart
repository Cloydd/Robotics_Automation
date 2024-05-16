import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:PillSynch/constants.dart';
import 'package:PillSynch/global_bloc.dart';
import 'package:PillSynch/pages/home_page.dart';
// import 'package:PillSynch/pages/new_entry/new_entry_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
    apiKey: 'AIzaSyAJ6aq6OzYAR_AwhcJ3gEM13A47qbWQoKM',
    appId: '1:800546816369:android:5593329970089af78536d0',
    messagingSenderId: '800546816369',
    projectId: 'medicine-reminder-app-11b54',
  ));

  tz.initializeTimeZones();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  GlobalBloc? globalBloc;

  @override
  void initState() {
    globalBloc = GlobalBloc();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Provider<GlobalBloc>.value(
      value: globalBloc!,
      child: Sizer(builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: "PillSynch",
          // Theme customization
          theme: ThemeData.dark().copyWith(
              primaryColor: kPrimaryColor,
              scaffoldBackgroundColor: kScaffoldColor,
              //appbar theme
              appBarTheme: AppBarTheme(
                toolbarHeight: 7.h,
                backgroundColor: kScaffoldColor,
                elevation: 0,
                iconTheme: IconThemeData(
                  color: kSecondaryColor,
                  size: 20.sp,
                ),
                titleTextStyle: GoogleFonts.poppins(
                  color: kTextColor,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.normal,
                  fontSize: 16.sp,
                ),
              ),
              textTheme: TextTheme(
                headlineMedium: TextStyle(
                  fontSize: 28.sp,
                  color: kSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
                headlineLarge: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                  color: kTextColor,
                ),
                headlineSmall: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: kTextColor,
                ),
                titleSmall: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: kTextColor,
                ),
                bodySmall: GoogleFonts.poppins(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w500,
                  color: kTextLightColor,
                ),
                bodyMedium: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: kTextColor,
                  letterSpacing: 1.0,
                ),
                labelMedium: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: kTextColor,
                ),
                labelSmall: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: kTextLightColor,
                ),
              ),
              inputDecorationTheme: const InputDecorationTheme(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: kTextLightColor,
                    width: 0.7,
                  ),
                ),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: kTextLightColor),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: kPrimaryColor,
                  ),
                ),
              ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor: kScaffoldColor,
                hourMinuteColor: kTextColor,
                hourMinuteTextColor: kScaffoldColor,
                dayPeriodColor: kTextColor,
                dayPeriodTextColor: kScaffoldColor,
                dialBackgroundColor: kTextColor,
                dialHandColor: kPrimaryColor,
                dialTextColor: kScaffoldColor,
                entryModeIconColor: kOtherColor,
                dayPeriodTextStyle: GoogleFonts.poppins(
                  fontSize: 8.sp,
                ),
              )),
          home: const HomePage(),
        );
      }),
    );
  }
}
