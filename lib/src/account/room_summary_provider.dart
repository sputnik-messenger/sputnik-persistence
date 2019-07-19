import 'package:matrix_rest_api/matrix_client_api_r0.dart';

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sputnik_app_state/sputnik_app_state.dart';
import 'package:sputnik_persistence/src/base_batch_writer.dart';
import 'package:sqflite/sqlite_api.dart';

import '../common.dart';

const TABLE_ROOM_SUMMARY = 'room_summary';
const COLUMN_PREVIOUS_BATCH_TOKEN = 'previous_batch_token';
const COLUMN_NOTIFICATION_COUNTS = 'notification_counts';
const COLUMN_MATRIX_ROOM_SUMMARY = 'matrix_room_summary';
const COLUMN_m_room_aliases = 'm_room_aliases';
const COLUMN_m_room_aliases_ts = 'm_room_aliases_ts';
const COLUMN_m_room_canonical_alias = 'm_room_canonical_alias';
const COLUMN_m_room_canonical_alias_ts = 'm_room_canonical_alias_ts';
const COLUMN_m_room_create = 'm_room_create_creator';
const COLUMN_m_room_create_ts = 'm_room_create_creator_ts';
const COLUMN_m_room_join_rule = 'm_room_join_rule';
const COLUMN_m_room_join_rule_ts = 'm_room_join_rule_ts';
const COLUMN_m_room_name = 'm_room_name';
const COLUMN_m_room_name_ts = 'm_room_name_ts';
const COLUMN_m_room_topic = 'm_room_topic';
const COLUMN_m_room_topic_ts = 'm_room_topic_ts';
const COLUMN_m_room_avatar = 'm_room_avatar';
const COLUMN_m_room_avatar_ts = 'm_room_avatar_ts';
const COLUMN_m_room_encryption = 'm_room_encryption';
const COLUMN_m_room_encryption_ts = 'm_room_encryption_ts';
const COLUMN_m_room_power_levels = 'm_room_power_levels';
const COLUMN_m_room_power_levels_ts = 'm_room_power_levels_ts';
const COLUMN_m_room_tombstone = 'm_room_tombstone';
const COLUMN_m_room_tombstone_ts = 'm_room_tombstone_ts';
const COLUMN_LAST_RELEVANT_ROOM_EVENT = 'last_relevant_room_event';
const COLUMN_LAST_RELEVANT_ROOM_EVENT_ts = 'last_relevant_room_event_ts';

const COLUMNS_WITHOUT_TS = [
  COLUMN_ROOM_ID,
  COLUMN_PREVIOUS_BATCH_TOKEN,
  COLUMN_NOTIFICATION_COUNTS,
  COLUMN_MATRIX_ROOM_SUMMARY,
  COLUMN_m_room_aliases,
  COLUMN_m_room_canonical_alias,
  COLUMN_m_room_create,
  COLUMN_m_room_join_rule,
  COLUMN_m_room_name,
  COLUMN_m_room_topic,
  COLUMN_m_room_avatar,
  COLUMN_m_room_encryption,
  COLUMN_m_room_power_levels,
  COLUMN_m_room_tombstone,
  COLUMN_LAST_RELEVANT_ROOM_EVENT,
];

class RoomSummaryBatchWriter extends BaseBatchWriter {
  RoomSummaryBatchWriter(Batch batch) : super(batch);

  insertRoomSummary(ExtendedRoomSummary roomSummary) {
    batch.insert(
        TABLE_ROOM_SUMMARY,
        {
          COLUMN_ROOM_ID: roomSummary.roomId,
          COLUMN_PREVIOUS_BATCH_TOKEN: roomSummary.previousBatchToken,
          COLUMN_NOTIFICATION_COUNTS: roomSummary.unreadNotificationCounts,
          COLUMN_MATRIX_ROOM_SUMMARY: encode(roomSummary.roomSummary),
          COLUMN_m_room_aliases: encode(roomSummary.roomStateValues.aliases?.roomEvent),
          COLUMN_m_room_aliases_ts: roomSummary.roomStateValues.aliases?.roomEvent?.origin_server_ts ?? 0,
          COLUMN_m_room_canonical_alias: encode(roomSummary.roomStateValues.canonicalAlias?.roomEvent),
          COLUMN_m_room_canonical_alias_ts: roomSummary.roomStateValues.canonicalAlias?.roomEvent?.origin_server_ts ?? 0,
          COLUMN_m_room_create: encode(roomSummary.roomStateValues.create?.roomEvent),
          COLUMN_m_room_create_ts: roomSummary.roomStateValues.create?.roomEvent?.origin_server_ts ?? 0,
          COLUMN_m_room_join_rule: encode(roomSummary.roomStateValues.joinRule?.roomEvent),
          COLUMN_m_room_join_rule_ts: roomSummary.roomStateValues.joinRule?.roomEvent?.origin_server_ts ?? 0,
          COLUMN_m_room_name: encode(roomSummary.roomStateValues.name?.roomEvent),
          COLUMN_m_room_name_ts: roomSummary.roomStateValues.name?.roomEvent?.origin_server_ts ?? 0,
          COLUMN_m_room_topic: encode(roomSummary.roomStateValues.topic?.roomEvent),
          COLUMN_m_room_topic_ts: roomSummary.roomStateValues.topic?.roomEvent?.origin_server_ts ?? 0,
          COLUMN_m_room_avatar: encode(roomSummary.roomStateValues.avatar?.roomEvent),
          COLUMN_m_room_avatar_ts: roomSummary.roomStateValues.avatar?.roomEvent?.origin_server_ts ?? 0,
          COLUMN_m_room_encryption: encode(roomSummary.roomStateValues.encryption?.roomEvent),
          COLUMN_m_room_encryption_ts: roomSummary.roomStateValues.encryption?.roomEvent?.origin_server_ts ?? 0,
          COLUMN_m_room_power_levels: encode(roomSummary.roomStateValues.powerLevels?.roomEvent),
          COLUMN_m_room_power_levels_ts: roomSummary.roomStateValues.powerLevels?.roomEvent?.origin_server_ts ?? 0,
          COLUMN_LAST_RELEVANT_ROOM_EVENT: encode(roomSummary.lastRelevantRoomEvent),
          COLUMN_LAST_RELEVANT_ROOM_EVENT_ts: roomSummary.lastRelevantRoomEvent?.origin_server_ts ?? 0,
        },
        conflictAlgorithm: ConflictAlgorithm.fail);
  }

  updatePreviousBatchToken(String roomId, String previousBatch) {
    batch.update(
      TABLE_ROOM_SUMMARY,
      {
        COLUMN_PREVIOUS_BATCH_TOKEN: previousBatch,
      },
      where: '$COLUMN_ROOM_ID = ?',
      whereArgs: [roomId],
    );
  }

  updateUnreadNotificationCounts(String roomId, UnreadNotificationCounts counts) {
    batch.update(
      TABLE_ROOM_SUMMARY,
      {
        COLUMN_NOTIFICATION_COUNTS: jsonEncode(counts.toJson()),
      },
      where: '$COLUMN_ROOM_ID = ?',
      whereArgs: [roomId],
    );
  }

  updateLastRelevantRoomEvent(String roomId, RoomEvent roomEvent) {
    batch.update(
      TABLE_ROOM_SUMMARY,
      {
        COLUMN_LAST_RELEVANT_ROOM_EVENT: jsonEncode(roomEvent.toJson()),
        COLUMN_LAST_RELEVANT_ROOM_EVENT_ts: roomEvent.origin_server_ts,
      },
      where: '$COLUMN_ROOM_ID = ? and $COLUMN_LAST_RELEVANT_ROOM_EVENT_ts <= ?',
      whereArgs: [roomId, roomEvent.origin_server_ts],
    );
  }

  updateName(String roomId, RoomEvent name) {
    batch.update(
      TABLE_ROOM_SUMMARY,
      {
        COLUMN_m_room_name: jsonEncode(name.toJson()),
        COLUMN_m_room_name_ts: name.origin_server_ts,
      },
      where: '$COLUMN_ROOM_ID = ? and $COLUMN_m_room_name_ts <= ?',
      whereArgs: [roomId, name.origin_server_ts],
    );
  }

  updateTopic(String roomId, RoomEvent topic) {
    batch.update(
      TABLE_ROOM_SUMMARY,
      {
        COLUMN_m_room_topic: jsonEncode(topic.toJson()),
        COLUMN_m_room_topic_ts: topic.origin_server_ts,
      },
      where: '$COLUMN_ROOM_ID = ? and $COLUMN_m_room_topic_ts <= ?',
      whereArgs: [roomId, topic.origin_server_ts],
    );
  }

  updateAvatar(String roomId, RoomEvent avatar) {
    batch.update(
      TABLE_ROOM_SUMMARY,
      {
        COLUMN_m_room_avatar: jsonEncode(avatar.toJson()),
        COLUMN_m_room_avatar_ts: avatar.origin_server_ts,
      },
      where: '$COLUMN_ROOM_ID = ? and $COLUMN_m_room_avatar_ts <= ?',
      whereArgs: [roomId, avatar.origin_server_ts],
    );
  }

  updateTombstone(String roomId, RoomEvent tombstone) {
    batch.update(
      TABLE_ROOM_SUMMARY,
      {
        COLUMN_m_room_tombstone: jsonEncode(tombstone.toJson()),
        COLUMN_m_room_tombstone_ts: tombstone.origin_server_ts,
      },
      where: '$COLUMN_ROOM_ID = ? and $COLUMN_m_room_tombstone_ts <= ?',
      whereArgs: [roomId, tombstone.origin_server_ts],
    );
  }

  updateMatrixRoomSummary(String roomId, RoomSummary roomSummary) {
    batch.update(
      TABLE_ROOM_SUMMARY,
      {
        COLUMN_MATRIX_ROOM_SUMMARY: encode(roomSummary),
      },
      where: '$COLUMN_ROOM_ID = ?',
      whereArgs: [roomId],
    );
  }

  delete(String roomId) {
    batch.delete(TABLE_ROOM_SUMMARY, where: '$COLUMN_ROOM_ID = ?', whereArgs: [roomId]);
  }

  static String encode(dynamic encodable) {
    String value;
    if (encodable != null) {
      value = jsonEncode(encodable.toJson());
    }
    return value;
  }
}

class RoomSummaryProvider {
  final Database _db;

  RoomSummaryProvider(this._db);

  RoomSummaryBatchWriter get batch => RoomSummaryBatchWriter(_db.batch());

  Future<List<ExtendedRoomSummary>> getAllRoomSummaries() async {
    final result = await _db.query(
      TABLE_ROOM_SUMMARY,
      columns: COLUMNS_WITHOUT_TS,
    );

    return result.map(extendedRoomSummaryFromRow).toList();
  }

  Future<ExtendedRoomSummary> getRoomSummaryFor(String roomId) async {
    final result = await _db.query(
      TABLE_ROOM_SUMMARY,
      columns: COLUMNS_WITHOUT_TS,
      where: '$COLUMN_ROOM_ID = ?',
      whereArgs: [roomId],
      limit: 1,
    );

    ExtendedRoomSummary roomSummary;

    if (result.isNotEmpty) {
      roomSummary = result.map(extendedRoomSummaryFromRow).single;
    }

    return roomSummary;
  }

  static createTables(Database db, int version) async {
    const statement = '''
        create table $TABLE_ROOM_SUMMARY ( 
          $COLUMN_ROOM_ID text not null,
          $COLUMN_PREVIOUS_BATCH_TOKEN text,
          $COLUMN_NOTIFICATION_COUNTS text,
          $COLUMN_MATRIX_ROOM_SUMMARY text,
          $COLUMN_m_room_aliases text,
          $COLUMN_m_room_aliases_ts int dafault (0),
          $COLUMN_m_room_canonical_alias text,
          $COLUMN_m_room_canonical_alias_ts int dafault (0),
          $COLUMN_m_room_create text,
          $COLUMN_m_room_create_ts int dafault (0),
          $COLUMN_m_room_join_rule text,
          $COLUMN_m_room_join_rule_ts int dafault (0),
          $COLUMN_m_room_name text,
          $COLUMN_m_room_name_ts int dafault (0),
          $COLUMN_m_room_topic text,
          $COLUMN_m_room_topic_ts int dafault (0),
          $COLUMN_m_room_avatar text,
          $COLUMN_m_room_avatar_ts int dafault (0),
          $COLUMN_m_room_encryption text,
          $COLUMN_m_room_encryption_ts int dafault (0),
          $COLUMN_m_room_power_levels text,
          $COLUMN_m_room_power_levels_ts int dafault (0),
          $COLUMN_m_room_tombstone text,
          $COLUMN_m_room_tombstone_ts int dafault (0),
          $COLUMN_LAST_RELEVANT_ROOM_EVENT text,
          $COLUMN_LAST_RELEVANT_ROOM_EVENT_ts int default (0),
          PRIMARY KEY ($COLUMN_ROOM_ID)
        )
      ''';
    debugPrint(statement);
    await db.execute(statement);
  }

  static dropTables(Database db, int oldVersion, int newVersion) {
    db.execute('drop table if exists $TABLE_ROOM_SUMMARY');
  }

  static ExtendedRoomSummary extendedRoomSummaryFromRow(Map<String, dynamic> row) {
    final lastRelevantEventValue = row[COLUMN_LAST_RELEVANT_ROOM_EVENT];
    var lastRelevantEvent;
    if (lastRelevantEventValue != null) {
      lastRelevantEvent = RoomEvent.fromJson(jsonDecode(lastRelevantEventValue));
    }

    return ExtendedRoomSummary(
      (builder) => builder
        ..roomId = row[COLUMN_ROOM_ID]
        ..previousBatchToken = row[COLUMN_PREVIOUS_BATCH_TOKEN]
        ..roomSummary = roomSummaryFromRow(row)
        ..unreadNotificationCounts = notificationCountsFromRow(row)
        ..roomStateValues = roomStateValuesFromRow(row)
        ..lastRelevantRoomEvent = lastRelevantEvent,
    );
  }

  static RoomStateValuesBuilder roomStateValuesFromRow(Map<String, dynamic> row) {
    return RoomStateValuesBuilder()
      ..aliases = stateEventFrom(row, COLUMN_m_room_aliases, (json) => AliasesContent.fromJson(json))
      ..canonicalAlias = stateEventFrom(row, COLUMN_m_room_canonical_alias, (json) => CanonicalAliasContent.fromJson(json))
      ..create = stateEventFrom(row, COLUMN_m_room_create, (json) => CreateContent.fromJson(json))
      ..joinRule = stateEventFrom(row, COLUMN_m_room_join_rule, (json) => JoinRuleContent.fromJson(json))
      ..name = stateEventFrom(row, COLUMN_m_room_name, (json) => NameContent.fromJson(json))
      ..topic = stateEventFrom(row, COLUMN_m_room_topic, (json) => TopicContent.fromJson(json))
      ..avatar = stateEventFrom(row, COLUMN_m_room_avatar, (json) => AvatarContent.fromJson(json))
      ..encryption = stateEventFrom(row, COLUMN_m_room_encryption, (json) => EncryptionContent.fromJson(json))
      ..powerLevels = stateEventFrom(row, COLUMN_m_room_power_levels, (json) => PowerLevels.fromJson(json))
      ..tombstone = stateEventFrom(row, COLUMN_m_room_tombstone, (json) => TombstoneContent.fromJson(json));
  }

  static StateEventBuilder<T> stateEventFrom<T>(Map<String, dynamic> row, String column, T Function(Map<String, dynamic>) mapper) {
    final value = row[column];
    StateEventBuilder b;
    if (value != null) {
      final roomEvent = RoomEvent.fromJson(jsonDecode(value));
      b = StateEventBuilder<T>()
        ..roomEvent = roomEvent
        ..content = mapper(roomEvent.content);
    }
    return b;
  }

  static UnreadNotificationCounts notificationCountsFromRow(Map<String, dynamic> row) {
    UnreadNotificationCounts result;
    final value = row[COLUMN_NOTIFICATION_COUNTS];
    if (value != null) {
      result = UnreadNotificationCounts.fromJson(jsonDecode(value));
    }
    return result;
  }

  static RoomSummary roomSummaryFromRow(Map<String, dynamic> row) {
    RoomSummary result;
    final value = row[COLUMN_MATRIX_ROOM_SUMMARY];
    if (value != null) {
      result = RoomSummary.fromJson(jsonDecode(value));
    }
    return result;
  }
}
