import 'package:sqflite/sqlite_api.dart';

class BaseBatchWriter {
  final Batch batch;

  BaseBatchWriter(this.batch);

  Future<List<dynamic>> commit({bool exclusive, bool noResult, bool continueOnError}) async {
    return batch.commit(exclusive: exclusive, noResult: noResult, continueOnError: continueOnError);
  }
}