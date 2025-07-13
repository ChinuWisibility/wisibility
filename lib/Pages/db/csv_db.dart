import '../../main.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:uuid/uuid.dart';

class CsvDB {
  static DbCollection get _collection {
    return db.collection('CSV');
  }

  static Future<String> saveCsvUpload({
    required String appName,
    required String ownerName,
    required List<List<dynamic>> csvTable,
  }) async {
    final collection = _collection;

    print('📥 Saving CSV upload...');
    print('👉 DB name: ${db.databaseName}');
    print('👉 Collection: ${collection.collectionName}');

    final id = const Uuid().v4();

    final upload = {
      '_id': id,
      'appName': appName,
      'ownerName': ownerName,
      'csvData': csvTable,
      'createdAt': DateTime.now().toIso8601String(),
    };

    final result = await collection.insertOne(upload);
    print('✅ Insert success: ${result.isSuccess}');

    return id;
  }
}
