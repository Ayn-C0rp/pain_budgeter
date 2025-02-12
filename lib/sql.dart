

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';




  Future setupDatabase()
  async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  WidgetsFlutterBinding.ensureInitialized();
  return openDatabase(
    join(await getDatabasesPath(), 'TestDatabase.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE Budget(id TEXT PRIMARY KEY, date DATE, name TEXT, price DOUBLE)',
      );
    },
    version: 1,
  );


  }
  Future<void> insertEntry(Entry entry, Database database) async {
    final db = await database;
    await db.insert(
      'Budget',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Entry>> getEntry(Database database) async {
    final db = await database;
    final List<Map<String, Object?>> entryMap = await db.query('Budget');
    return [
      for (final {
            'id': id as String,
            'date': date as String,
            'name': name as String,
            'price': price as double,
          } in entryMap)
       Entry(id: id, date: date, name: name, price: price),
    ];
  }



  Future<List<Entry>> getEntryFromRange(Database database, date1, date2) async {
    final db = await database;
    final List<Map<String, Object?>> entryMap = await db.rawQuery("SELECT * FROM Budget where date >= '$date1' and date <= '$date2' ");
    return [
      for (final {
            'id': id as String,
            'date': date as String,
            'name': name as String,
            'price': price as double,
          } in entryMap)
       Entry(id:id, date: date, name: name, price: price),
    ];
  }





  Future<void> updateEntry(Entry entry, Database database) async {
    final db = await database;
    await db.update(
      'Budget',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> deleteEntry(String id, Database database) async {
    final db = await database;
    await db.delete(
      'Budget',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


class Entry {
  final String id;
  final String date;
  final String name;
  final double price;

  

  Entry({
    required this.id,
    required this.date,
    required this.name,
    required this.price,
    
  });

  // Convert a Dog into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date,
      'name': name,
      'price': price
    };
  }

 
  @override
  String toString() {
    return 'Entry{data id: $id date: $date, name: $name, price: $price}';
  }

  double getPrice()
  {
    return price;
  }

  

}


void main() async
{
  var uuid = Uuid();
  Database db = await setupDatabase();
  insertEntry(Entry(id: uuid.v4() , date: '2025-2-11', name: 'pulbit rice', price: 6400), db);
  //insertEntry(Entry(id: 2, date: '2025-2-12', name: 'pulbit rice', price: 6400), db);
  var data = await getEntryFromRange(db, '2025-2-11', '2025-2-12');
  print(data);



  



}