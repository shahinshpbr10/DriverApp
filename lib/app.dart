import 'package:driver_app/pages/auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: AuthCheck(),),debugShowCheckedModeBanner: false,);
  }
}
