import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

import 'package:sputnik_persistence/src/common.dart';

import 'account_summary_provider.dart';

class SputnikDatabase {
  Database _db;
  String _databasePath;
  bool _permissionsGranted = false;

  AccountSummaryProvider accountSummaryProvider;

  SputnikDatabase();

  Future<void> open() async {
    final dbFolder = await getDatabasesPath();

    _requestPermissionsIfNeeded(dbFolder);

    _databasePath = join(dbFolder, 'general');

    _db = await openDatabase(
      _databasePath,
      version: DB_VERSION,
      onCreate: (db, version) async {
        await AccountSummaryProvider.createTables(db, version);
      },
      onUpgrade: (db, oldVersion, newVersion) {
        AccountSummaryProvider.resetNextBatchSyncTokens(db);
      }
    );
    accountSummaryProvider = AccountSummaryProvider(_db);

    debugPrint('finished opening database');
  }

  Future close() async => _db.close();

  _requestPermissionsIfNeeded(String dbFolder) async {
    if (!_permissionsGranted) {
      PermissionStatus permission = await PermissionHandler().checkPermissionStatus(PermissionGroup.storage);
      _permissionsGranted = permission == PermissionStatus.granted;

      if (!_permissionsGranted) {
        File writeTest = File(join(dbFolder, 'sputnik-write-test.temp'));
        try {
          await writeTest.create(recursive: true);
          await writeTest.delete();
        } catch (e) {
          debugPrint(e.toString());
          await PermissionHandler().requestPermissions([PermissionGroup.storage]);
        }
      }
    }
  }
}
