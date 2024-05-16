import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:flare_flutter/flare_actor.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2200), () {
      Navigator.popUntil(context, ModalRoute.withName('/'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Material(
        color: Colors.white, child: Center(child: Text('Success!')));
  }
}
