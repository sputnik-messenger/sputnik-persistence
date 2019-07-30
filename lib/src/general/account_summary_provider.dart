import 'dart:convert';

import 'package:matrix_rest_api/matrix_client_api_r0.dart';
import 'package:sputnik_app_state/sputnik_app_state.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

const TABLE_ACCOUNT_SUMMARY = 'account_summary';
const COLUMN_USER_ID = 'user_id';
const COLUMN_SERVER_URL = 'server_url';
const COLUMN_DISPLAY_NAME = 'display_name';
const COLUMN_AVATAR_URL = 'avatar_url';
const COLUMN_NEXT_BATCH_SYNC_TOKEN = 'next_batch_sync_token';
const COLUMN_LOGIN_RESPONSE_JSON = 'login_response';

class AccountSummaryProvider {
  final Database db;

  AccountSummaryProvider(this.db);

  Future<Iterable<AccountSummary>> getAllAccountSummaries() async {
    final rows = await db.query(TABLE_ACCOUNT_SUMMARY);
    return rows.map(rowToAccountSummary);
  }

  Future insertAccountSummary(AccountSummary accountSummary) {
    return db.insert(TABLE_ACCOUNT_SUMMARY, accountSummaryToRow(accountSummary));
  }

  Future updateAccountSummary(AccountSummary accountSummary) {
    return db.update(
      TABLE_ACCOUNT_SUMMARY,
      accountSummaryToRow(accountSummary),
      where: '$COLUMN_USER_ID = ?',
      whereArgs: [accountSummary.userId],
    );
  }

  Future deleteAccountSummary(String userId) async {
    return db.delete(
      TABLE_ACCOUNT_SUMMARY,
      where: '$COLUMN_USER_ID = ?',
      whereArgs: [userId],
    );
  }

  Future resetAllNextBatchSyncTokens() async {
    db.update(
      TABLE_ACCOUNT_SUMMARY,
      {COLUMN_NEXT_BATCH_SYNC_TOKEN: null},
    );
  }

  Future updateNextBatchSyncToken(String userId, String token) async {
    db.update(
      TABLE_ACCOUNT_SUMMARY,
      {COLUMN_NEXT_BATCH_SYNC_TOKEN: token},
      where: '$COLUMN_USER_ID = ?',
      whereArgs: [userId],
    );
  }

  static Future<void> createTables(Database db, int version) async {
    const statement = '''
        create table $TABLE_ACCOUNT_SUMMARY ( 
          $COLUMN_USER_ID text not null,
          $COLUMN_SERVER_URL text,
          $COLUMN_DISPLAY_NAME text,
          $COLUMN_AVATAR_URL int,
          $COLUMN_NEXT_BATCH_SYNC_TOKEN int,
          $COLUMN_LOGIN_RESPONSE_JSON text,
          PRIMARY KEY ($COLUMN_USER_ID)
        )
      ''';
    debugPrint(statement);
    return db.execute(statement);
  }

  static Future<void> dropTables(Database db) async {
    return db.execute('drop table if exists $TABLE_ACCOUNT_SUMMARY');
  }

  static Map<String, dynamic> accountSummaryToRow(AccountSummary accountSummary) {
    return {
      COLUMN_USER_ID: accountSummary.userId,
      COLUMN_SERVER_URL: accountSummary.serverUrl,
      COLUMN_DISPLAY_NAME: accountSummary.displayName,
      COLUMN_AVATAR_URL: accountSummary.avatarUrl,
      COLUMN_NEXT_BATCH_SYNC_TOKEN: accountSummary.nextBatchSyncToken,
      COLUMN_LOGIN_RESPONSE_JSON: jsonEncode(accountSummary.loginResponse.toJson()),
    };
  }

  static AccountSummary rowToAccountSummary(Map<String, dynamic> row) {
    return AccountSummary((builder) => builder
      ..userId = row[COLUMN_USER_ID]
      ..serverUrl = row[COLUMN_SERVER_URL]
      ..displayName = row[COLUMN_DISPLAY_NAME]
      ..avatarUrl = valueToUri(row[COLUMN_AVATAR_URL])
      ..nextBatchSyncToken = row[COLUMN_NEXT_BATCH_SYNC_TOKEN]
      ..loginResponse = LoginResponse.fromJson(jsonDecode(row[COLUMN_LOGIN_RESPONSE_JSON])));
  }

  static Uri valueToUri(String value) {
    return value == null ? null : Uri.parse(value);
  }
}
