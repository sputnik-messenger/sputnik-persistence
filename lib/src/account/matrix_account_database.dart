import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:sputnik_persistence/src/common.dart';

import 'room_event_provider.dart';
import 'room_summary_provider.dart';
import 'user_summary_provider.dart';

class MatrixAccountDatabase {
  final String userId;
  final String userHash;
  Database _db;
  String _databasePath;

  RoomSummaryProvider roomSummaryProvider;
  RoomEventProvider roomEventProvider;
  UserSummaryProvider userSummaryProvider;

  MatrixAccountDatabase._(this.userId, this.userHash);

  factory MatrixAccountDatabase(String userId) {
    return MatrixAccountDatabase._(
      userId,
      userId.hashCode.toString(),
    );
  }

  Future<void> open() async {
    _databasePath = join(await getDatabasesPath(), userId.hashCode.toString());

    _db = await openDatabase(
      _databasePath,
      version: DB_VERSION,
      onCreate: (db, version) async {
        await createTables(db, version);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await dropTables(db, oldVersion, newVersion);
        await createTables(db, newVersion);
      },
    );

    roomEventProvider = RoomEventProvider(_db);
    roomSummaryProvider = RoomSummaryProvider(_db);
    userSummaryProvider = UserSummaryProvider(_db);
  }

  Future close() async => _db.close();

  Future dropTables(Database db, int oldVersion, int newVersion) async {
    await RoomEventProvider.dropTables(db, oldVersion, newVersion);
    await RoomSummaryProvider.dropTables(db, oldVersion, newVersion);
    await UserSummaryProvider.dropTables(db, oldVersion, newVersion);
  }

  Future createTables(Database db, int version) async {
    await RoomEventProvider.createTables(db, version);
    await RoomSummaryProvider.createTables(db, version);
    await UserSummaryProvider.createTables(db, version);
  }
}
