import 'package:sputnik_app_state/sputnik_app_state.dart';
import 'package:flutter/foundation.dart';
import 'package:sputnik_persistence/src/base_batch_writer.dart';
import 'package:sqflite/sqflite.dart';
import 'package:matrix_rest_api/matrix_client_api_r0.dart';

class UserSummaryBatchWriter extends BaseBatchWriter {
  UserSummaryBatchWriter(Batch batch) : super(batch);

  insertInitialUserSummary(String userId, int timestamp) {
    batch.insert(
      UserSummaryProvider.TABLE_USER_SUMMARY,
      {
        UserSummaryProvider.COLUMN_USER_ID: userId,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  upsertUserSummary(UserSummary userSummary) {
    insertInitialUserSummary(userSummary.userId, 0);

    if (userSummary.displayName != null) {
      batch.update(
        UserSummaryProvider.TABLE_USER_SUMMARY,
        {
          UserSummaryProvider.COLUMN_DISPLAY_NAME: userSummary.displayName.value,
          UserSummaryProvider.COLUMN_DISPLAY_NAME_TS: userSummary.displayName.timestamp,
        },
        where: '${UserSummaryProvider.COLUMN_USER_ID} = ? and ${UserSummaryProvider.COLUMN_DISPLAY_NAME_TS} <= ?',
        whereArgs: [userSummary.userId, userSummary.displayName.timestamp],
      );
    }

    if (userSummary.avatarUrl != null) {
      batch.update(
        UserSummaryProvider.TABLE_USER_SUMMARY,
        {
          UserSummaryProvider.COLUMN_AVATAR_URL: userSummary.avatarUrl.value,
          UserSummaryProvider.COLUMN_AVATAR_URL_TS: userSummary.avatarUrl.timestamp,
        },
        where: '${UserSummaryProvider.COLUMN_USER_ID} = ? and ${UserSummaryProvider.COLUMN_AVATAR_URL_TS} <= ?',
        whereArgs: [userSummary.userId, userSummary.avatarUrl.timestamp],
      );
    }
  }

  static String membershipToString(Membership membership) {
    return membership.toString().split('.').last;
  }
}

class UserSummaryProvider {
  static const TABLE_USER_SUMMARY = 'user_summary';
  static const COLUMN_USER_ID = 'user_id';
  static const COLUMN_DISPLAY_NAME = 'display_name';
  static const COLUMN_DISPLAY_NAME_TS = 'display_name_ts';
  static const COLUMN_AVATAR_URL = 'avatar_url';
  static const COLUMN_AVATAR_URL_TS = 'avatar_url_ts';

  final Database _db;

  UserSummaryProvider(this._db);

  Future<List<UserSummary>> getUserSummariesFor(Iterable<String> userIds) async {
    final rows = await _db.query(TABLE_USER_SUMMARY,
        where: '${UserSummaryProvider.COLUMN_USER_ID} in (${userIds.map((_) => '?').join(',')})', whereArgs: userIds.toList());
    final List<UserSummary> list = rows.map(userSummaryFromRow).toList();
    return list;
  }

  Future<List<UserSummary>> getUserSummaries(String roomId) async {
    final rows = await _db.query(TABLE_USER_SUMMARY);
    final List<UserSummary> list = rows.map(userSummaryFromRow).toList();
    return list;
  }

  static UserSummary userSummaryFromRow(Map<String, dynamic> row) {
    final b = UserSummaryBuilder();
    b.userId = row[COLUMN_USER_ID];

    if (row[COLUMN_DISPLAY_NAME] != null) {
      b.displayName = TimestampedBuilder()
        ..value = row[COLUMN_DISPLAY_NAME]
        ..timestamp = row[COLUMN_DISPLAY_NAME_TS];
    }
    if (row[COLUMN_AVATAR_URL] != null) {
      b.avatarUrl = TimestampedBuilder()
        ..value = row[COLUMN_AVATAR_URL]
        ..timestamp = row[COLUMN_AVATAR_URL_TS];
    }
    return b.build();
  }

  UserSummaryBatchWriter get batch => UserSummaryBatchWriter(_db.batch());

  static createTables(Database db, int version) async {
    const statement = '''
        create table $TABLE_USER_SUMMARY ( 
          $COLUMN_USER_ID text not null,
          $COLUMN_DISPLAY_NAME text,
          $COLUMN_DISPLAY_NAME_TS int default (0),
          $COLUMN_AVATAR_URL text,
          $COLUMN_AVATAR_URL_TS int default (0),
          PRIMARY KEY ($COLUMN_USER_ID)
        )
      ''';
    debugPrint(statement);
    await db.execute(statement);
  }

  static dropTables(Database db, int oldVersion, int newVersion) {
    db.execute('drop table if exists $TABLE_USER_SUMMARY');
  }
}
