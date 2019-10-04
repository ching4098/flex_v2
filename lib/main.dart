import 'package:flutter/material.dart';
import 'package:flex_v2/Pages/root_page.dart';
import 'package:flex_v2/Auth/authentication.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flex Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
/*      initialRoute: MyHomePage.id,
      routes: {
        MyHomePage.id: (context) => MyHomePage(),
        Registration.id: (context) => Registration(),
        Login.id: (context) => Login(),
        Dashboard.id: (context) => Dashboard(),
      },*/
      home: new RootPage(auth: new Auth()));
  }
}