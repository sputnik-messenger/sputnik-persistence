import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:matrix_rest_api/matrix_client_api_r0.dart';
import 'package:sputnik_app_state/sputnik_app_state.dart';
import 'package:sqflite/sqlite_api.dart';

import 'package:sputnik_persistence/src/common.dart';

import '../base_batch_writer.dart';
import 'user_summary_provider.dart';

const TABLE_ROOM_EVENT = 'room_event';
const COLUMN_RAW_EVENT = 'raw_event';
const COLUMN_CONTENT = 'content';
const COLUMN_TYPE = 'type';
const COLUMN_SENDER = 'sender';
const COLUMN_IS_STATE_EVENT = 'is_state_event';
const COLUMN_IS_MESSAGE = 'is_message';

class RoomEventBatchWriter extends BaseBatchWriter {
  RoomEventBatchWriter(Batch batch) : super(batch);

  insertRoomEvents(String roomId, Iterable<RoomEvent> roomEvents) {
    for (var roomEvent in roomEvents) {
      insertRoomEvent(roomId, roomEvent);
    }
  }

  insertRoomEvent(String roomId, RoomEvent roomEvent) {
    batch.insert(
        TABLE_ROOM_EVENT,
        {
          COLUMN_ID: roomEvent.event_id,
          COLUMN_ROOM_ID: roomId,
          COLUMN_TYPE: roomEvent.type,
          COLUMN_CONTENT: jsonEncode(roomEvent.content),
          COLUMN_IS_MESSAGE: roomEvent.type == 'm.room.message' ? 1 : 0,
          COLUMN_IS_STATE_EVENT: roomEvent.isStateEvent,
          COLUMN_SENDER: roomEvent.sender,
          COLUMN_TIMESTAMP: roomEvent.origin_server_ts,
          COLUMN_RAW_EVENT: jsonEncode(roomEvent)
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  deleteAllForRoom(String roomId) {
    batch.delete(TABLE_ROOM_EVENT,
        where: '$COLUMN_ROOM_ID = ?', whereArgs: [roomId]);
  }

  deleteRoomEvent(String roomId, String eventId) {
    batch.delete(TABLE_ROOM_EVENT,
        where: '$COLUMN_ROOM_ID = ? and $COLUMN_ID = ?',
        whereArgs: [roomId, eventId]);
  }
}

class RoomEventProvider {
  final Database _db;

  RoomEventProvider(this._db);

  RoomEventBatchWriter get batch => RoomEventBatchWriter(_db.batch());

  Future<List<RoomEvent>> getRoomEventsFor(
      String roomId, Iterable<String> eventIds) async {
    final rows = await _db.query(
      TABLE_ROOM_EVENT,
      where:
          '$COLUMN_ROOM_ID = ? and $COLUMN_ID in (${eventIds.map((_) => '?').join(',')})',
      whereArgs: [roomId, ...eventIds],
    );
    final List<RoomEvent> list = rows.map(_extractRawEvent).toList();
    return list;
  }

  Future<TimelineAndMembers> getRoomEventsWithSenderInfoFor(String roomId,
      {int limit, int offset}) async {
    final args = <dynamic>[roomId];
    String limitPart = '';
    String offsetPart = '';
    if (limit != null) {
      limitPart = 'limit ?';
      args.add(limit);
    }
    if (offset != null) {
      offsetPart = 'offset ?';
      args.add(offset);
    }

    final result = await _db.rawQuery('''
        select *
        from 
          $TABLE_ROOM_EVENT as event 
        left join 
          ${UserSummaryProvider.TABLE_USER_SUMMARY} as user 
        ON event.$COLUMN_SENDER = user.${UserSummaryProvider.COLUMN_USER_ID}   
        where event.$COLUMN_ROOM_ID = ? and event.$COLUMN_TYPE != 'm.room.redaction'
        order by event.$COLUMN_TIMESTAMP desc
        $limitPart
        $offsetPart
      ''', args);

    final memberMap = Map<String, UserSummary>();
    final timeline = List<RoomEvent>();

    result.forEach((row) {
      final roomEvent = _extractRawEvent(row);
      timeline.add(roomEvent);
      if (row[UserSummaryProvider.COLUMN_USER_ID] != null) {
        final user = UserSummaryProvider.userSummaryFromRow(row);
        memberMap.putIfAbsent(user.userId, () => user);
      }
    });

    return TimelineAndMembers(timeline, memberMap);
  }

  Future<List<String>> getRoomIds() async {
    final result = await _db.query(TABLE_ROOM_EVENT,
        columns: [COLUMN_ROOM_ID], distinct: true);
    final List<String> mapped =
        result.map((row) => row[COLUMN_ROOM_ID] as String).toList();
    return mapped;
  }

  Future<RoomEvent> getLatestStateEventFor(
      String roomId, String eventType) async {
    final result = await _db.query(
      TABLE_ROOM_EVENT,
      where:
          '$COLUMN_ROOM_ID = ? and $COLUMN_IS_STATE_EVENT = 1 and $COLUMN_TYPE = ?',
      orderBy: '$COLUMN_TIMESTAMP desc',
      columns: [COLUMN_RAW_EVENT],
      limit: 1,
      whereArgs: [roomId, eventType],
    );

    return result.isEmpty ? null : result.map(_extractRawEvent).first;
  }

  static RoomEvent _extractRawEvent(Map<String, dynamic> row) {
    return RoomEvent.fromJson(jsonDecode(row[COLUMN_RAW_EVENT] as String));
  }

  static createTables(Database db, int version) async {
    const create = '''
        create table $TABLE_ROOM_EVENT ( 
          $COLUMN_ID text not null,
          $COLUMN_ROOM_ID text not null,
          $COLUMN_TYPE text not null,
          $COLUMN_SENDER text not null,
          $COLUMN_CONTENT text not null,
          $COLUMN_IS_MESSAGE number not null,
          $COLUMN_IS_STATE_EVENT number not null, 
          $COLUMN_TIMESTAMP integer not null,
          $COLUMN_RAW_EVENT text unique not null,
          PRIMARY KEY ($COLUMN_ID, $COLUMN_ROOM_ID)
        )
      ''';
    const index = ''' 
      CREATE INDEX index_$COLUMN_TYPE ON $TABLE_ROOM_EVENT($COLUMN_TYPE);
    ''';
    debugPrint(create);
    await db.execute(create);
    await db.execute(index);
  }

  static dropTables(Database db, int oldVersion, int newVersion) {
    db.execute('drop table if exists $TABLE_ROOM_EVENT');
  }
}

class RoomEventAndUserSummary {
  final RoomEvent event;
  final UserSummary userSummary;

  RoomEventAndUserSummary(this.event, this.userSummary);
}

class TimelineAndMembers {
  final List<RoomEvent> timeline;
  final Map<String, UserSummary> members;

  TimelineAndMembers(this.timeline, this.members);
}
