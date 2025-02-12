import 'package:flutter/material.dart';
import 'currency.dart';
import 'sql.dart';

class UI extends StatefulWidget {
  const UI({super.key});

  @override
  State<UI> createState() => _UIState();
}

class _UIState extends State<UI> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
      appBar: AppBar(title: Text("Pain Budgeter"),),
      body: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Container(child: Text("sum"),)
        ],),
        Row(children: [TextButton(onPressed: null, child: Text("Select days")),
        TextButton(onPressed: null, child: Text("Change Currency"))],),
        Table()

      ],),
    ));
  }
}