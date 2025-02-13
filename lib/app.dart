import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/router/app_router.dart';
import 'core/styles/theme.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:google_fonts/google_fonts.dart';

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({
    super.key,
    this.initialRoute = '/',
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: MaterialApp.router(
        title: 'Smart Medica',
        theme: appTheme.copyWith(
          scaffoldBackgroundColor: AppColors.white,
          textTheme: GoogleFonts.ysabeauInfantTextTheme(),
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
