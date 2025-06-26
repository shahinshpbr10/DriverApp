import 'package:device_preview/device_preview.dart';
import 'package:driver_app/pages/auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


var height;
var width;


class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return MaterialApp(
      builder: DevicePreview.appBuilder, // <--- Required
      useInheritedMediaQuery: true,       // <--- Required
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context), // <--- Optional
      home: AuthCheck(), // Replace with your homepage widget
    );
  }
}
