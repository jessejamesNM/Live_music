// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'internal_data_base.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path =
        name != null
            ? await sqfliteDatabaseFactory.getDatabasePath(name!)
            : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(path, _migrations, _callback);
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  ArtistDao? _artistDaoInstance;

  ProfileDao? _profileDaoInstance;

  ConversationDao? _conversationDaoInstance;

  MessageDao? _messageDaoInstance;

  CachedDataDao? _cachedDataDaoInstance;

  ImageDao? _imageDaoInstance;

  ReviewDao? _reviewDaoInstance;

  RecentlyViewedDao? _recentlyViewedDaoInstance;

  LikedProfileDao? _likedProfileDaoInstance;

  LikedUsersListDao? _likedUsersListDaoInstance;

  WorksContentDao? _worksContentDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 2,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
          database,
          startVersion,
          endVersion,
          migrations,
        );

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
          'CREATE TABLE IF NOT EXISTS `artists` (`userId` TEXT NOT NULL, `name` TEXT, `profileImageUrl` TEXT, `price` REAL, `timestamp` INTEGER, `userLiked` INTEGER NOT NULL, PRIMARY KEY (`userId`))',
        );
        await database.execute(
          'CREATE TABLE IF NOT EXISTS `profiles` (`userId` TEXT NOT NULL, `profileImageUrl` TEXT, `name` TEXT NOT NULL, `nickname` TEXT NOT NULL, `isOfficial` INTEGER NOT NULL, PRIMARY KEY (`userId`))',
        );
        await database.execute(
          'CREATE TABLE IF NOT EXISTS `conversations` (`otherUserId` TEXT NOT NULL, `nickname` TEXT NOT NULL, `currentUserId` TEXT NOT NULL, `lastMessage` TEXT NOT NULL, `timestamp` INTEGER NOT NULL, `profileImage` TEXT, `name` TEXT NOT NULL, `messagesUnread` INTEGER NOT NULL, `conversationName` TEXT NOT NULL, `formattedTimestamp` TEXT, `artist` INTEGER NOT NULL, PRIMARY KEY (`otherUserId`))',
        );
        await database.execute(
          'CREATE TABLE IF NOT EXISTS `messages` (`id` TEXT NOT NULL, `type` TEXT NOT NULL, `content` TEXT NOT NULL, `senderId` TEXT NOT NULL, `receiverId` TEXT NOT NULL, `timestamp` INTEGER NOT NULL, `messageRead` INTEGER NOT NULL, PRIMARY KEY (`id`))',
        );
        await database.execute(
          'CREATE TABLE IF NOT EXISTS `cached_data` (`id` TEXT NOT NULL, `content` TEXT NOT NULL, PRIMARY KEY (`id`))',
        );
        await database.execute(
          'CREATE TABLE IF NOT EXISTS `images` (`id` TEXT NOT NULL, `userId` TEXT NOT NULL, `imageUrl` TEXT NOT NULL, `timestamp` INTEGER NOT NULL, PRIMARY KEY (`id`))',
        );
        await database.execute(
          'CREATE TABLE IF NOT EXISTS `reviews` (`id` TEXT NOT NULL, `senderId` TEXT NOT NULL, `receiverId` TEXT NOT NULL, `senderName` TEXT NOT NULL, `senderProfileImageUrl` TEXT NOT NULL, `stars` INTEGER NOT NULL, `text` TEXT NOT NULL, `timestamp` INTEGER NOT NULL, `date` TEXT NOT NULL, PRIMARY KEY (`id`))',
        );
        await database.execute(
          'CREATE TABLE IF NOT EXISTS `recently_viewed_profiles` (`userId` TEXT NOT NULL, `profileImageUrl` TEXT NOT NULL, `name` TEXT NOT NULL, `price` REAL NOT NULL, `timestamp` INTEGER NOT NULL, `userLiked` INTEGER NOT NULL, PRIMARY KEY (`userId`))',
        );
        await database.execute(
          'CREATE TABLE IF NOT EXISTS `liked_profile` (`userId` TEXT NOT NULL, `profileImageUrl` TEXT NOT NULL, `name` TEXT NOT NULL, `timestamp` INTEGER NOT NULL, `price` REAL NOT NULL, `userLiked` INTEGER NOT NULL, PRIMARY KEY (`userId`))',
        );
        await database.execute(
          'CREATE TABLE IF NOT EXISTS `liked_users_list` (`listId` TEXT NOT NULL, `name` TEXT NOT NULL, `creationDate` INTEGER NOT NULL, `likedUsersList` TEXT NOT NULL, `imageUrl` TEXT NOT NULL, PRIMARY KEY (`listId`))',
        );
        await database.execute(
          'CREATE TABLE IF NOT EXISTS `works_content` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `userId` TEXT NOT NULL, `mediaUrl` TEXT NOT NULL, `isVideo` INTEGER NOT NULL, `timestamp` INTEGER NOT NULL)',
        );

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  ArtistDao get artistDao {
    return _artistDaoInstance ??= _$ArtistDao(database, changeListener);
  }

  @override
  ProfileDao get profileDao {
    return _profileDaoInstance ??= _$ProfileDao(database, changeListener);
  }

  @override
  ConversationDao get conversationDao {
    return _conversationDaoInstance ??= _$ConversationDao(
      database,
      changeListener,
    );
  }

  @override
  MessageDao get messageDao {
    return _messageDaoInstance ??= _$MessageDao(database, changeListener);
  }

  @override
  CachedDataDao get cachedDataDao {
    return _cachedDataDaoInstance ??= _$CachedDataDao(database, changeListener);
  }

  @override
  ImageDao get imageDao {
    return _imageDaoInstance ??= _$ImageDao(database, changeListener);
  }

  @override
  ReviewDao get reviewDao {
    return _reviewDaoInstance ??= _$ReviewDao(database, changeListener);
  }

  @override
  RecentlyViewedDao get recentlyViewedDao {
    return _recentlyViewedDaoInstance ??= _$RecentlyViewedDao(
      database,
      changeListener,
    );
  }

  @override
  LikedProfileDao get likedProfileDao {
    return _likedProfileDaoInstance ??= _$LikedProfileDao(
      database,
      changeListener,
    );
  }

  @override
  LikedUsersListDao get likedUsersListDao {
    return _likedUsersListDaoInstance ??= _$LikedUsersListDao(
      database,
      changeListener,
    );
  }

  @override
  WorksContentDao get worksContentDao {
    return _worksContentDaoInstance ??= _$WorksContentDao(
      database,
      changeListener,
    );
  }
}

class _$ArtistDao extends ArtistDao {
  _$ArtistDao(this.database, this.changeListener)
    : _queryAdapter = QueryAdapter(database),
      _artistInsertionAdapter = InsertionAdapter(
        database,
        'artists',
        (Artist item) => <String, Object?>{
          'userId': item.userId,
          'name': item.name,
          'profileImageUrl': item.profileImageUrl,
          'price': item.price,
          'timestamp': item.timestamp,
          'userLiked': item.userLiked ? 1 : 0,
        },
      ),
      _artistUpdateAdapter = UpdateAdapter(
        database,
        'artists',
        ['userId'],
        (Artist item) => <String, Object?>{
          'userId': item.userId,
          'name': item.name,
          'profileImageUrl': item.profileImageUrl,
          'price': item.price,
          'timestamp': item.timestamp,
          'userLiked': item.userLiked ? 1 : 0,
        },
      );

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Artist> _artistInsertionAdapter;

  final UpdateAdapter<Artist> _artistUpdateAdapter;

  @override
  Future<Artist?> getArtistById(String userId) async {
    return _queryAdapter.query(
      'SELECT * FROM artists WHERE userId = ?1 LIMIT 1',
      mapper:
          (Map<String, Object?> row) => Artist(
            userId: row['userId'] as String,
            name: row['name'] as String?,
            profileImageUrl: row['profileImageUrl'] as String?,
            price: row['price'] as double?,
            timestamp: row['timestamp'] as int?,
            userLiked: (row['userLiked'] as int) != 0,
          ),
      arguments: [userId],
    );
  }

  @override
  Future<List<Artist>> getAllArtists() async {
    return _queryAdapter.queryList(
      'SELECT * FROM artists',
      mapper:
          (Map<String, Object?> row) => Artist(
            userId: row['userId'] as String,
            name: row['name'] as String?,
            profileImageUrl: row['profileImageUrl'] as String?,
            price: row['price'] as double?,
            timestamp: row['timestamp'] as int?,
            userLiked: (row['userLiked'] as int) != 0,
          ),
    );
  }

  @override
  Future<void> insert(Artist artist) async {
    await _artistInsertionAdapter.insert(artist, OnConflictStrategy.replace);
  }

  @override
  Future<void> update(Artist artist) async {
    await _artistUpdateAdapter.update(artist, OnConflictStrategy.abort);
  }
}

class _$ProfileDao extends ProfileDao {
  _$ProfileDao(this.database, this.changeListener)
    : _queryAdapter = QueryAdapter(database, changeListener),
      _profileInsertionAdapter = InsertionAdapter(
        database,
        'profiles',
        (Profile item) => <String, Object?>{
          'userId': item.userId,
          'profileImageUrl': item.profileImageUrl,
          'name': item.name,
          'nickname': item.nickname,
          'isOfficial': item.isOfficial ? 1 : 0,
        },
        changeListener,
      ),
      _profileUpdateAdapter = UpdateAdapter(
        database,
        'profiles',
        ['userId'],
        (Profile item) => <String, Object?>{
          'userId': item.userId,
          'profileImageUrl': item.profileImageUrl,
          'name': item.name,
          'nickname': item.nickname,
          'isOfficial': item.isOfficial ? 1 : 0,
        },
        changeListener,
      );

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Profile> _profileInsertionAdapter;

  final UpdateAdapter<Profile> _profileUpdateAdapter;

  @override
  Future<Profile?> getProfileById(String userId) async {
    return _queryAdapter.query(
      'SELECT * FROM profiles WHERE userId = ?1',
      mapper:
          (Map<String, Object?> row) => Profile(
            userId: row['userId'] as String,
            name: row['name'] as String,
            nickname: row['nickname'] as String,
            isOfficial: (row['isOfficial'] as int) != 0,
            profileImageUrl: row['profileImageUrl'] as String?,
          ),
      arguments: [userId],
    );
  }

  @override
  Stream<List<Profile>> getAllProfiles() {
    return _queryAdapter.queryListStream(
      'SELECT * FROM profiles',
      mapper:
          (Map<String, Object?> row) => Profile(
            userId: row['userId'] as String,
            name: row['name'] as String,
            nickname: row['nickname'] as String,
            isOfficial: (row['isOfficial'] as int) != 0,
            profileImageUrl: row['profileImageUrl'] as String?,
          ),
      queryableName: 'profiles',
      isView: false,
    );
  }

  @override
  Future<void> deleteProfile(String userId) async {
    await _queryAdapter.queryNoReturn(
      'DELETE FROM profiles WHERE userId = ?1',
      arguments: [userId],
    );
  }

  @override
  Future<void> insertOrUpdate(Profile profile) async {
    await _profileInsertionAdapter.insert(profile, OnConflictStrategy.replace);
  }

  @override
  Future<void> update(Profile profile) async {
    await _profileUpdateAdapter.update(profile, OnConflictStrategy.abort);
  }
}

class _$ConversationDao extends ConversationDao {
  _$ConversationDao(this.database, this.changeListener)
    : _queryAdapter = QueryAdapter(database, changeListener),
      _conversationInsertionAdapter = InsertionAdapter(
        database,
        'conversations',
        (Conversation item) => <String, Object?>{
          'otherUserId': item.otherUserId,
          'nickname': item.nickname,
          'currentUserId': item.currentUserId,
          'lastMessage': item.lastMessage,
          'timestamp': item.timestamp,
          'profileImage': item.profileImage,
          'name': item.name,
          'messagesUnread': item.messagesUnread,
          'conversationName': item.conversationName,
          'formattedTimestamp': item.formattedTimestamp,
          'artist': item.artist ? 1 : 0,
        },
        changeListener,
      ),
      _conversationUpdateAdapter = UpdateAdapter(
        database,
        'conversations',
        ['otherUserId'],
        (Conversation item) => <String, Object?>{
          'otherUserId': item.otherUserId,
          'nickname': item.nickname,
          'currentUserId': item.currentUserId,
          'lastMessage': item.lastMessage,
          'timestamp': item.timestamp,
          'profileImage': item.profileImage,
          'name': item.name,
          'messagesUnread': item.messagesUnread,
          'conversationName': item.conversationName,
          'formattedTimestamp': item.formattedTimestamp,
          'artist': item.artist ? 1 : 0,
        },
        changeListener,
      );

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Conversation> _conversationInsertionAdapter;

  final UpdateAdapter<Conversation> _conversationUpdateAdapter;

  @override
  Future<Conversation?> getConversationById(String userId) async {
    return _queryAdapter.query(
      'SELECT * FROM conversations WHERE otherUserId = ?1',
      mapper:
          (Map<String, Object?> row) => Conversation(
            nickname: row['nickname'] as String,
            currentUserId: row['currentUserId'] as String,
            otherUserId: row['otherUserId'] as String,
            lastMessage: row['lastMessage'] as String,
            timestamp: row['timestamp'] as int,
            profileImage: row['profileImage'] as String?,
            name: row['name'] as String,
            messagesUnread: row['messagesUnread'] as int,
            conversationName: row['conversationName'] as String,
            formattedTimestamp: row['formattedTimestamp'] as String?,
            artist: (row['artist'] as int) != 0,
          ),
      arguments: [userId],
    );
  }

  @override
  Future<void> deleteConversation(String userId) async {
    await _queryAdapter.queryNoReturn(
      'DELETE FROM conversations WHERE otherUserId = ?1',
      arguments: [userId],
    );
  }

  @override
  Stream<List<Conversation>> getConversationsByCurrentUserId(
    String currentUserId,
  ) {
    return _queryAdapter.queryListStream(
      'SELECT * FROM conversations WHERE currentUserId = ?1 ORDER BY timestamp DESC',
      mapper:
          (Map<String, Object?> row) => Conversation(
            nickname: row['nickname'] as String,
            currentUserId: row['currentUserId'] as String,
            otherUserId: row['otherUserId'] as String,
            lastMessage: row['lastMessage'] as String,
            timestamp: row['timestamp'] as int,
            profileImage: row['profileImage'] as String?,
            name: row['name'] as String,
            messagesUnread: row['messagesUnread'] as int,
            conversationName: row['conversationName'] as String,
            formattedTimestamp: row['formattedTimestamp'] as String?,
            artist: (row['artist'] as int) != 0,
          ),
      arguments: [currentUserId],
      queryableName: 'conversations',
      isView: false,
    );
  }

  @override
  Future<List<Conversation>> getConversationsListByCurrentUserId(
    String currentUserId,
  ) async {
    return _queryAdapter.queryList(
      'SELECT * FROM conversations WHERE currentUserId = ?1 ORDER BY timestamp DESC',
      mapper:
          (Map<String, Object?> row) => Conversation(
            nickname: row['nickname'] as String,
            currentUserId: row['currentUserId'] as String,
            otherUserId: row['otherUserId'] as String,
            lastMessage: row['lastMessage'] as String,
            timestamp: row['timestamp'] as int,
            profileImage: row['profileImage'] as String?,
            name: row['name'] as String,
            messagesUnread: row['messagesUnread'] as int,
            conversationName: row['conversationName'] as String,
            formattedTimestamp: row['formattedTimestamp'] as String?,
            artist: (row['artist'] as int) != 0,
          ),
      arguments: [currentUserId],
    );
  }

  @override
  Future<void> insertOrUpdate(Conversation conversation) async {
    await _conversationInsertionAdapter.insert(
      conversation,
      OnConflictStrategy.replace,
    );
  }

  @override
  Future<void> update(Conversation conversation) async {
    await _conversationUpdateAdapter.update(
      conversation,
      OnConflictStrategy.abort,
    );
  }
}

class _$MessageDao extends MessageDao {
  _$MessageDao(this.database, this.changeListener)
    : _queryAdapter = QueryAdapter(database),
      _messageEntityInsertionAdapter = InsertionAdapter(
        database,
        'messages',
        (MessageEntity item) => <String, Object?>{
          'id': item.id,
          'type': item.type,
          'content': item.content,
          'senderId': item.senderId,
          'receiverId': item.receiverId,
          'timestamp': item.timestamp,
          'messageRead': item.messageRead ? 1 : 0,
        },
      );

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<MessageEntity> _messageEntityInsertionAdapter;

  @override
  Future<List<MessageEntity>> getMessages(
    String userId,
    String otherUserId,
  ) async {
    return _queryAdapter.queryList(
      'SELECT * FROM messages WHERE (senderId = ?1 AND receiverId = ?2) OR (senderId = ?2 AND receiverId = ?1) ORDER BY timestamp DESC',
      mapper:
          (Map<String, Object?> row) => MessageEntity(
            id: row['id'] as String,
            type: row['type'] as String,
            content: row['content'] as String,
            senderId: row['senderId'] as String,
            receiverId: row['receiverId'] as String,
            timestamp: row['timestamp'] as int,
            messageRead: (row['messageRead'] as int) != 0,
          ),
      arguments: [userId, otherUserId],
    );
  }

  @override
  Future<void> deleteAllMessages(String userId, String otherUserId) async {
    await _queryAdapter.queryNoReturn(
      'DELETE FROM messages WHERE (senderId = ?1 AND receiverId = ?2) OR (senderId = ?2 AND receiverId = ?1)',
      arguments: [userId, otherUserId],
    );
  }

  @override
  Future<List<MessageEntity>> getMessagesBySenderAndReceiver(
    String senderId,
    String receiverId,
  ) async {
    return _queryAdapter.queryList(
      'SELECT * FROM messages WHERE (senderId = ?1 AND receiverId = ?2) OR (senderId = ?2 AND receiverId = ?1) ORDER BY timestamp DESC',
      mapper:
          (Map<String, Object?> row) => MessageEntity(
            id: row['id'] as String,
            type: row['type'] as String,
            content: row['content'] as String,
            senderId: row['senderId'] as String,
            receiverId: row['receiverId'] as String,
            timestamp: row['timestamp'] as int,
            messageRead: (row['messageRead'] as int) != 0,
          ),
      arguments: [senderId, receiverId],
    );
  }

  @override
  Future<void> insertAll(List<MessageEntity> messages) async {
    await _messageEntityInsertionAdapter.insertList(
      messages,
      OnConflictStrategy.replace,
    );
  }
}

class _$CachedDataDao extends CachedDataDao {
  _$CachedDataDao(this.database, this.changeListener)
    : _queryAdapter = QueryAdapter(database),
      _cachedDataInsertionAdapter = InsertionAdapter(
        database,
        'cached_data',
        (CachedData item) => <String, Object?>{
          'id': item.id,
          'content': item.content,
        },
      );

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<CachedData> _cachedDataInsertionAdapter;

  @override
  Future<CachedData?> getById(String id) async {
    return _queryAdapter.query(
      'SELECT * FROM cached_data WHERE id = ?1',
      mapper:
          (Map<String, Object?> row) => CachedData(
            id: row['id'] as String,
            content: row['content'] as String,
          ),
      arguments: [id],
    );
  }

  @override
  Future<void> deleteById(String id) async {
    await _queryAdapter.queryNoReturn(
      'DELETE FROM cached_data WHERE id = ?1',
      arguments: [id],
    );
  }

  @override
  Future<void> insert(CachedData data) async {
    await _cachedDataInsertionAdapter.insert(data, OnConflictStrategy.replace);
  }
}

class _$ImageDao extends ImageDao {
  _$ImageDao(this.database, this.changeListener)
    : _queryAdapter = QueryAdapter(database),
      _imageEntityInsertionAdapter = InsertionAdapter(
        database,
        'images',
        (ImageEntity item) => <String, Object?>{
          'id': item.id,
          'userId': item.userId,
          'imageUrl': item.imageUrl,
          'timestamp': item.timestamp,
        },
      );

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ImageEntity> _imageEntityInsertionAdapter;

  @override
  Future<List<ImageEntity>> getImagesByUser(String userId) async {
    return _queryAdapter.queryList(
      'SELECT * FROM images WHERE userId = ?1 ORDER BY timestamp DESC',
      mapper:
          (Map<String, Object?> row) => ImageEntity(
            id: row['id'] as String,
            userId: row['userId'] as String,
            imageUrl: row['imageUrl'] as String,
            timestamp: row['timestamp'] as int,
          ),
      arguments: [userId],
    );
  }

  @override
  Future<void> deleteImagesByUser(String userId) async {
    await _queryAdapter.queryNoReturn(
      'DELETE FROM images WHERE userId = ?1',
      arguments: [userId],
    );
  }

  @override
  Future<void> insert(ImageEntity image) async {
    await _imageEntityInsertionAdapter.insert(
      image,
      OnConflictStrategy.replace,
    );
  }
}

class _$ReviewDao extends ReviewDao {
  _$ReviewDao(this.database, this.changeListener)
    : _queryAdapter = QueryAdapter(database),
      _reviewEntityInsertionAdapter = InsertionAdapter(
        database,
        'reviews',
        (ReviewEntity item) => <String, Object?>{
          'id': item.id,
          'senderId': item.senderId,
          'receiverId': item.receiverId,
          'senderName': item.senderName,
          'senderProfileImageUrl': item.senderProfileImageUrl,
          'stars': item.stars,
          'text': item.text,
          'timestamp': item.timestamp,
          'date': item.date,
        },
      );

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ReviewEntity> _reviewEntityInsertionAdapter;

  @override
  Future<List<ReviewEntity>> getReviewsByReceiver(String receiverId) async {
    return _queryAdapter.queryList(
      'SELECT * FROM reviews WHERE receiverId = ?1 ORDER BY date DESC',
      mapper:
          (Map<String, Object?> row) => ReviewEntity(
            id: row['id'] as String,
            senderId: row['senderId'] as String,
            receiverId: row['receiverId'] as String,
            senderName: row['senderName'] as String,
            senderProfileImageUrl: row['senderProfileImageUrl'] as String,
            stars: row['stars'] as int,
            text: row['text'] as String,
            timestamp: row['timestamp'] as int,
            date: row['date'] as String,
          ),
      arguments: [receiverId],
    );
  }

  @override
  Future<void> deleteReviewById(String id) async {
    await _queryAdapter.queryNoReturn(
      'DELETE FROM reviews WHERE id = ?1',
      arguments: [id],
    );
  }

  @override
  Future<ReviewEntity?> getReviewByReceiverAndSender(
    String receiverId,
    String senderId,
  ) async {
    return _queryAdapter.query(
      'SELECT * FROM reviews WHERE receiverId = ?1 AND senderId = ?2 LIMIT 1',
      mapper:
          (Map<String, Object?> row) => ReviewEntity(
            id: row['id'] as String,
            senderId: row['senderId'] as String,
            receiverId: row['receiverId'] as String,
            senderName: row['senderName'] as String,
            senderProfileImageUrl: row['senderProfileImageUrl'] as String,
            stars: row['stars'] as int,
            text: row['text'] as String,
            timestamp: row['timestamp'] as int,
            date: row['date'] as String,
          ),
      arguments: [receiverId, senderId],
    );
  }

  @override
  Future<void> insertOrUpdate(ReviewEntity review) async {
    await _reviewEntityInsertionAdapter.insert(
      review,
      OnConflictStrategy.replace,
    );
  }
}

class _$RecentlyViewedDao extends RecentlyViewedDao {
  _$RecentlyViewedDao(this.database, this.changeListener)
    : _queryAdapter = QueryAdapter(database, changeListener),
      _recentlyViewedProfileInsertionAdapter = InsertionAdapter(
        database,
        'recently_viewed_profiles',
        (RecentlyViewedProfile item) => <String, Object?>{
          'userId': item.userId,
          'profileImageUrl': item.profileImageUrl,
          'name': item.name,
          'price': item.price,
          'timestamp': item.timestamp,
          'userLiked': item.userLiked ? 1 : 0,
        },
        changeListener,
      );

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<RecentlyViewedProfile>
  _recentlyViewedProfileInsertionAdapter;

  @override
  Stream<List<RecentlyViewedProfile>> getAll() {
    return _queryAdapter.queryListStream(
      'SELECT * FROM recently_viewed_profiles ORDER BY timestamp DESC',
      mapper:
          (Map<String, Object?> row) => RecentlyViewedProfile(
            userId: row['userId'] as String,
            profileImageUrl: row['profileImageUrl'] as String,
            name: row['name'] as String,
            price: row['price'] as double,
            timestamp: row['timestamp'] as int,
            userLiked: (row['userLiked'] as int) != 0,
          ),
      queryableName: 'recently_viewed_profiles',
      isView: false,
    );
  }

  @override
  Future<void> deleteOldProfiles(int timestamp) async {
    await _queryAdapter.queryNoReturn(
      'DELETE FROM recently_viewed_profiles WHERE timestamp < ?1',
      arguments: [timestamp],
    );
  }

  @override
  Future<void> insert(RecentlyViewedProfile recentlyViewedProfile) async {
    await _recentlyViewedProfileInsertionAdapter.insert(
      recentlyViewedProfile,
      OnConflictStrategy.replace,
    );
  }

  @override
  Future<void> insertAll(List<RecentlyViewedProfile> profiles) async {
    await _recentlyViewedProfileInsertionAdapter.insertList(
      profiles,
      OnConflictStrategy.replace,
    );
  }
}

class _$LikedProfileDao extends LikedProfileDao {
  _$LikedProfileDao(this.database, this.changeListener)
    : _queryAdapter = QueryAdapter(database, changeListener),
      _likedProfileInsertionAdapter = InsertionAdapter(
        database,
        'liked_profile',
        (LikedProfile item) => <String, Object?>{
          'userId': item.userId,
          'profileImageUrl': item.profileImageUrl,
          'name': item.name,
          'timestamp': item.timestamp,
          'price': item.price,
          'userLiked': item.userLiked ? 1 : 0,
        },
        changeListener,
      );

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<LikedProfile> _likedProfileInsertionAdapter;

  @override
  Future<List<LikedProfile>> getAllLikedProfiles() async {
    return _queryAdapter.queryList(
      'SELECT * FROM liked_profile',
      mapper:
          (Map<String, Object?> row) => LikedProfile(
            userId: row['userId'] as String,
            profileImageUrl: row['profileImageUrl'] as String,
            name: row['name'] as String,
            timestamp: row['timestamp'] as int,
            price: row['price'] as double,
            userLiked: (row['userLiked'] as int) != 0,
          ),
    );
  }

  @override
  Future<LikedProfile?> getLikedProfileById(String userId) async {
    return _queryAdapter.query(
      'SELECT * FROM liked_profile WHERE userId = ?1',
      mapper:
          (Map<String, Object?> row) => LikedProfile(
            userId: row['userId'] as String,
            profileImageUrl: row['profileImageUrl'] as String,
            name: row['name'] as String,
            timestamp: row['timestamp'] as int,
            price: row['price'] as double,
            userLiked: (row['userLiked'] as int) != 0,
          ),
      arguments: [userId],
    );
  }

  @override
  Future<void> clearAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM liked_profile');
  }

  @override
  Stream<List<LikedProfile>> getProfilesByIds(List<String> userIds) {
    const offset = 1;
    final _sqliteVariablesForUserIds = Iterable<String>.generate(
      userIds.length,
      (i) => '?${i + offset}',
    ).join(',');
    return _queryAdapter.queryListStream(
      'SELECT * FROM liked_profile WHERE userId IN (' +
          _sqliteVariablesForUserIds +
          ')',
      mapper:
          (Map<String, Object?> row) => LikedProfile(
            userId: row['userId'] as String,
            profileImageUrl: row['profileImageUrl'] as String,
            name: row['name'] as String,
            timestamp: row['timestamp'] as int,
            price: row['price'] as double,
            userLiked: (row['userLiked'] as int) != 0,
          ),
      arguments: [...userIds],
      queryableName: 'liked_profile',
      isView: false,
    );
  }

  @override
  Future<void> insert(LikedProfile likedProfile) async {
    await _likedProfileInsertionAdapter.insert(
      likedProfile,
      OnConflictStrategy.replace,
    );
  }
}

class _$LikedUsersListDao extends LikedUsersListDao {
  _$LikedUsersListDao(this.database, this.changeListener)
    : _queryAdapter = QueryAdapter(database, changeListener),
      _likedUsersListInsertionAdapter = InsertionAdapter(
        database,
        'liked_users_list',
        (LikedUsersList item) => <String, Object?>{
          'listId': item.listId,
          'name': item.name,
          'creationDate': item.creationDate,
          'likedUsersList': _listStringConverter.encode(item.likedUsersList),
          'imageUrl': item.imageUrl,
        },
        changeListener,
      );

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<LikedUsersList> _likedUsersListInsertionAdapter;

  @override
  Future<LikedUsersList?> getById(String listId) async {
    return _queryAdapter.query(
      'SELECT * FROM liked_users_list WHERE listId = ?1 LIMIT 1',
      mapper:
          (Map<String, Object?> row) => LikedUsersList(
            listId: row['listId'] as String,
            name: row['name'] as String,
            creationDate: row['creationDate'] as int,
            likedUsersList: _listStringConverter.decode(
              row['likedUsersList'] as String,
            ),
            imageUrl: row['imageUrl'] as String,
          ),
      arguments: [listId],
    );
  }

  @override
  Stream<List<LikedUsersList>> getAll() {
    return _queryAdapter.queryListStream(
      'SELECT * FROM liked_users_list',
      mapper:
          (Map<String, Object?> row) => LikedUsersList(
            listId: row['listId'] as String,
            name: row['name'] as String,
            creationDate: row['creationDate'] as int,
            likedUsersList: _listStringConverter.decode(
              row['likedUsersList'] as String,
            ),
            imageUrl: row['imageUrl'] as String,
          ),
      queryableName: 'liked_users_list',
      isView: false,
    );
  }

  @override
  Future<void> delete(String listId) async {
    await _queryAdapter.queryNoReturn(
      'DELETE FROM liked_users_list WHERE listId = ?1',
      arguments: [listId],
    );
  }

  @override
  Future<void> insert(LikedUsersList list) async {
    await _likedUsersListInsertionAdapter.insert(
      list,
      OnConflictStrategy.replace,
    );
  }
}

class _$WorksContentDao extends WorksContentDao {
  _$WorksContentDao(this.database, this.changeListener)
    : _queryAdapter = QueryAdapter(database),
      _worksContentEntityInsertionAdapter = InsertionAdapter(
        database,
        'works_content',
        (WorksContentEntity item) => <String, Object?>{
          'id': item.id,
          'userId': item.userId,
          'mediaUrl': item.mediaUrl,
          'isVideo': item.isVideo ? 1 : 0,
          'timestamp': item.timestamp,
        },
      );

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<WorksContentEntity>
  _worksContentEntityInsertionAdapter;

  @override
  Future<List<WorksContentEntity>> getWorksByUser(String userId) async {
    return _queryAdapter.queryList(
      'SELECT * FROM works_content WHERE userId = ?1 ORDER BY timestamp DESC',
      mapper:
          (Map<String, Object?> row) => WorksContentEntity(
            id: row['id'] as int?,
            userId: row['userId'] as String,
            mediaUrl: row['mediaUrl'] as String,
            isVideo: (row['isVideo'] as int) != 0,
            timestamp: row['timestamp'] as int,
          ),
      arguments: [userId],
    );
  }

  @override
  Future<void> deleteAllWorksForUser(String userId) async {
    await _queryAdapter.queryNoReturn(
      'DELETE FROM works_content WHERE userId = ?1',
      arguments: [userId],
    );
  }

  @override
  Future<void> deleteWorkByUrl(String mediaUrl) async {
    await _queryAdapter.queryNoReturn(
      'DELETE FROM works_content WHERE mediaUrl = ?1',
      arguments: [mediaUrl],
    );
  }

  @override
  Future<void> insertWorksContent(WorksContentEntity worksContent) async {
    await _worksContentEntityInsertionAdapter.insert(
      worksContent,
      OnConflictStrategy.replace,
    );
  }

  @override
  Future<void> insertAllWorks(List<WorksContentEntity> worksContents) async {
    await _worksContentEntityInsertionAdapter.insertList(
      worksContents,
      OnConflictStrategy.replace,
    );
  }
}

// ignore_for_file: unused_element
final _listStringConverter = ListStringConverter();
