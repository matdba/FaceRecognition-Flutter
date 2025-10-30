// ignore_for_file: depend_on_referenced_packages

import 'package:facerecognition_flutter/app/app_route.dart';
import 'package:facerecognition_flutter/bindings.dart';
import 'package:facerecognition_flutter/presentation/pages/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MainBinding().dependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'تایمند',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        fontFamily: 'Sans',
        scaffoldBackgroundColor: Colors.grey.shade100,
        appBarTheme: AppBarTheme(
          elevation: 1,
          shadowColor: Colors.grey.shade50,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          titleSpacing: 0,
        ),
      ),
      initialRoute: AppRoutes.HOME_ROUTE,
      getPages: [
        GetPage(
          name: AppRoutes.HOME_ROUTE,
          page: () => const HomePage(),
        ),
      ],
    );
  }
}
