import 'dart:developer';

import 'package:mongo_dart/mongo_dart.dart';
import 'constant.dart';

class MongoDatabase{
  static Db? _db;

  static get instance {
    if (_db == null) {
      throw Exception('Database not connected. Call connect() first.');
    }
    return _db!;  
  }

  static Future<void> connect() async {
   _db = await Db.create(MONGO_URI);
  await _db!.open();
  inspect(_db);
  print('Connected to database');
  var shops_Collection = _db!.collection(SHOPS_COLLECTION);

  // await collection.insertOne(
  //   {
  //     'name': 'Sample Item',
  //     'value': 42,
  //     'age': 25,
  //     'createdAt': DateTime.now(),
  //     'mail': 'sample@example.com'
  //   }
  // );

  print(await shops_Collection.find().toList());

  }
}