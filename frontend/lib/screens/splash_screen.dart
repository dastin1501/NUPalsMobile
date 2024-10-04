import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    getIsLogin();
  }

  void getIsLogin() {
    print('SplashScreen: Timer started');
    Timer(
      const Duration(seconds: 2),
      () {
        print('SplashScreen: Navigating to login screen');
        Navigator.pushReplacementNamed(context, '/');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: ScreenUtil().screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [nuBlue, nuYellow],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: ScreenUtil().setHeight(50)),
            Align(
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/icons/NU_shield.svg',
                width: ScreenUtil().setWidth(150),
                height: ScreenUtil().setHeight(150),
              ),
            ),
            SizedBox(height: ScreenUtil().setHeight(200)),
            Align(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/NUCCIT_Logo.png',
                scale: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
