import 'package:floor/floor.dart';
import 'dart:async';
import 'package:live_music/data/model/liked_artist/profile_base.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import '../../widgets/list_string_converter.dart';

part 'internal_data_base.g.dart'; // Esto incluye el archivo generado

@Entity(tableName: 'works_content')
class WorksContentEntity {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final String userId;
  final String mediaUrl;
  final bool isVideo;
  final int timestamp;

  WorksContentEntity({
    this.id,
    required this.userId,
    required this.mediaUrl,
    required this.isVideo,
    required this.timestamp,
  });
}

@Entity(tableName: 'artists')
class Artist {
  @PrimaryKey()
  final String userId;
  final String? name;
  final String? profileImageUrl;
  final double? price;
  final int? timestamp;
  final bool userLiked;

  Artist({
    required this.userId,
    this.name,
    this.profileImageUrl,
    this.price,
    this.timestamp,
    this.userLiked = false,
  });
}

@Entity(tableName: 'liked_profile')
class LikedProfile {
  @PrimaryKey()
  final String userId;
  final String profileImageUrl;
  final String name;
  final int timestamp;
  final double price;
  final bool userLiked;

  LikedProfile({
    required this.userId,
    required this.profileImageUrl,
    required this.name,
    required this.timestamp,
    required this.price,
    required this.userLiked,
  });

  @override
  String toString() {
    return 'LikedProfile(userId: $userId, name: $name, price: $price, liked: $userLiked)';
  }

  ProfileBase toProfileBase() {
    return _LikedProfileBaseAdapter(this);
  }
}

class _LikedProfileBaseAdapter implements ProfileBase {
  final LikedProfile likedProfile;

  _LikedProfileBaseAdapter(this.likedProfile);

  @override
  String get userId => likedProfile.userId;

  @override
  String get profileImageUrl => likedProfile.profileImageUrl;

  @override
  String get name => likedProfile.name;

  @override
  int get timestamp => likedProfile.timestamp;

  @override
  double get price => likedProfile.price;

  @override
  bool get userLiked => likedProfile.userLiked;
}

@Entity(tableName: 'liked_users_list')
class LikedUsersList {
  @PrimaryKey()
  final String listId;
  final String name;
  final int creationDate;
  @TypeConverters([ListStringConverter])
  final List<String> likedUsersList; // IDs de usuarios
  final String imageUrl; // Imagen del primer usuario de la lista

  LikedUsersList({
    required this.listId,
    required this.name,
    required this.creationDate,
    required this.likedUsersList,
    required this.imageUrl,
  });
}

@Entity(tableName: 'recently_viewed_profiles')
class RecentlyViewedProfile implements ProfileBase {
  @PrimaryKey()
  @override
  final String userId;

  @override
  final String profileImageUrl;

  @override
  final String name;

  @override
  final double price;

  @override
  final int timestamp;

  @override
  final bool userLiked;

  RecentlyViewedProfile({
    required this.userId,
    required this.profileImageUrl,
    required this.name,
    required this.price,
    required this.timestamp,
    required this.userLiked,
  });

  factory RecentlyViewedProfile.fromMap(Map<String, dynamic> map) {
    return RecentlyViewedProfile(
      userId: map['userId'] as String,
      profileImageUrl: map['profileImageUrl'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      timestamp: map['timestamp'] as int,
      userLiked: map['userLiked'] as bool,
    );
  }
}

@Entity(tableName: 'reviews')
class ReviewEntity {
  @PrimaryKey()
  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String senderProfileImageUrl;
  final int stars;
  final String text;
  final int timestamp;
  final String date;

  ReviewEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.senderProfileImageUrl,
    required this.stars,
    required this.text,
    required this.timestamp,
    required this.date,
  });
}

@Entity(tableName: 'profiles')
class Profile {
  @PrimaryKey()
  final String userId;
  final String? profileImageUrl;
  final String name;
  final String nickname;
  final bool isOfficial;

  Profile({
    required this.userId,
    required this.name,
    required this.nickname,
    required this.isOfficial,
    this.profileImageUrl,
  });
}

@Entity(tableName: 'conversations')
class Conversation {
  @PrimaryKey()
  final String otherUserId;
  final String nickname;
  final String currentUserId;
  final String lastMessage;
  final int timestamp;
  final String? profileImage;
  final String name;
  final int messagesUnread;
  final String conversationName;
  final String? formattedTimestamp;
  final bool artist;

  Conversation({
    required this.nickname,
    required this.currentUserId,
    required this.otherUserId,
    required this.lastMessage,
    required this.timestamp,
    required this.profileImage,
    required this.name,
    required this.messagesUnread,
    required this.conversationName,
    this.formattedTimestamp,
    required this.artist,
  });
}

@Entity(tableName: 'messages')
class MessageEntity {
  @PrimaryKey()
  final String id;
  final String type; // Tipo de mensaje: "text", "image", "location"
  final String
  content; // Contenido del mensaje (texto o URL de imagen/ubicación)
  final String senderId;
  final String receiverId;
  final int timestamp; // Fecha y hora del mensaje
  final bool messageRead; // Indica si el mensaje ha sido leído

  MessageEntity({
    required this.id,
    required this.type,
    required this.content,
    required this.senderId,
    required this.receiverId,
    required this.timestamp,
    required this.messageRead,
  });
}

@Entity(tableName: 'cached_data')
class CachedData {
  @PrimaryKey()
  final String id;
  final String content;

  CachedData({required this.id, required this.content});
}

@Entity(tableName: 'images')
class ImageEntity {
  @PrimaryKey()
  final String id; // Puede ser la URL de la imagen o un ID único
  final String userId; // ID del usuario al que pertenece la imagen
  final String imageUrl; // URL de la imagen en S3
  final int timestamp;

  ImageEntity({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.timestamp,
  });
}

@dao
abstract class ReviewDao {
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertOrUpdate(ReviewEntity review);

  @Query(
    'SELECT * FROM reviews WHERE receiverId = :receiverId ORDER BY date DESC',
  )
  Future<List<ReviewEntity>> getReviewsByReceiver(String receiverId);

  @Query('DELETE FROM reviews WHERE id = :id')
  Future<void> deleteReviewById(String id);

  @Query(
    'SELECT * FROM reviews WHERE receiverId = :receiverId AND senderId = :senderId LIMIT 1',
  )
  Future<ReviewEntity?> getReviewByReceiverAndSender(
    String receiverId,
    String senderId,
  );
}

@dao
abstract class WorksContentDao {
  @Query(
    'SELECT * FROM works_content WHERE userId = :userId ORDER BY timestamp DESC',
  )
  Future<List<WorksContentEntity>> getWorksByUser(String userId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertWorksContent(WorksContentEntity worksContent);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAllWorks(List<WorksContentEntity> worksContents);

  @Query('DELETE FROM works_content WHERE userId = :userId')
  Future<void> deleteAllWorksForUser(String userId);

  @Query('DELETE FROM works_content WHERE mediaUrl = :mediaUrl')
  Future<void> deleteWorkByUrl(String mediaUrl);
}

@dao
abstract class ProfileDao {
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertOrUpdate(Profile profile);

  @Update()
  Future<void> update(Profile profile);

  @Query('SELECT * FROM profiles WHERE userId = :userId')
  Future<Profile?> getProfileById(String userId);

  @Query('SELECT * FROM profiles')
  Stream<List<Profile>> getAllProfiles();

  @Query('DELETE FROM profiles WHERE userId = :userId')
  Future<void> deleteProfile(String userId);
}

@dao
abstract class ConversationDao {
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertOrUpdate(Conversation conversation);

  @Update()
  Future<void> update(Conversation conversation);

  @Query('SELECT * FROM conversations WHERE otherUserId = :userId')
  Future<Conversation?> getConversationById(String userId);

  @Query('DELETE FROM conversations WHERE otherUserId = :userId')
  Future<void> deleteConversation(String userId);

  @Query(
    'SELECT * FROM conversations WHERE currentUserId = :currentUserId ORDER BY timestamp DESC',
  )
  Stream<List<Conversation>> getConversationsByCurrentUserId(
    String currentUserId,
  );

  @Query(
    'SELECT * FROM conversations WHERE currentUserId = :currentUserId ORDER BY timestamp DESC',
  )
  Future<List<Conversation>> getConversationsListByCurrentUserId(
    String currentUserId,
  ); // Nuevo método
}

@dao
abstract class MessageDao {
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAll(List<MessageEntity> messages);

  @Query(
    'SELECT * FROM messages WHERE (senderId = :userId AND receiverId = :otherUserId) OR (senderId = :otherUserId AND receiverId = :userId) ORDER BY timestamp DESC',
  )
  Future<List<MessageEntity>> getMessages(String userId, String otherUserId);

  @Query(
    'DELETE FROM messages WHERE (senderId = :userId AND receiverId = :otherUserId) OR (senderId = :otherUserId AND receiverId = :userId)',
  )
  Future<void> deleteAllMessages(String userId, String otherUserId);

  @Query(
    'SELECT * FROM messages WHERE (senderId = :senderId AND receiverId = :receiverId) OR (senderId = :receiverId AND receiverId = :senderId) ORDER BY timestamp DESC',
  )
  Future<List<MessageEntity>> getMessagesBySenderAndReceiver(
    String senderId,
    String receiverId,
  );
}

@dao
abstract class ImageDao {
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insert(ImageEntity image);

  @Query('SELECT * FROM images WHERE userId = :userId ORDER BY timestamp DESC')
  Future<List<ImageEntity>> getImagesByUser(String userId);

  @Query('DELETE FROM images WHERE userId = :userId')
  Future<void> deleteImagesByUser(String userId);
}

@dao
abstract class CachedDataDao {
  @Query('SELECT * FROM cached_data WHERE id = :id')
  Future<CachedData?> getById(String id);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insert(CachedData data);

  @Query('DELETE FROM cached_data WHERE id = :id')
  Future<void> deleteById(String id);
}

@dao
abstract class RecentlyViewedDao {
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insert(RecentlyViewedProfile recentlyViewedProfile);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAll(List<RecentlyViewedProfile> profiles);

  @Query('SELECT * FROM recently_viewed_profiles ORDER BY timestamp DESC')
  Stream<List<RecentlyViewedProfile>> getAll();

  @Query('DELETE FROM recently_viewed_profiles WHERE timestamp < :timestamp')
  Future<void> deleteOldProfiles(int timestamp);
}

@dao
abstract class LikedUsersListDao {
  @Query('SELECT * FROM liked_users_list WHERE listId = :listId LIMIT 1')
  Future<LikedUsersList?> getById(String listId);

  @Query('SELECT * FROM liked_users_list')
  Stream<List<LikedUsersList>> getAll();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insert(LikedUsersList list);

  @Query('DELETE FROM liked_users_list WHERE listId = :listId')
  Future<void> delete(String listId);
}

@dao
abstract class LikedProfileDao {
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insert(LikedProfile likedProfile);

  @Query('SELECT * FROM liked_profile')
  Future<List<LikedProfile>> getAllLikedProfiles();

  @Query('SELECT * FROM liked_profile WHERE userId = :userId')
  Future<LikedProfile?> getLikedProfileById(String userId);

  @Query('DELETE FROM liked_profile')
  Future<void> clearAll();

  @Query('SELECT * FROM liked_profile WHERE userId IN (:userIds)')
  Stream<List<LikedProfile>> getProfilesByIds(List<String> userIds);
}

@dao
abstract class ArtistDao {
  @Query('SELECT * FROM artists WHERE userId = :userId LIMIT 1')
  Future<Artist?> getArtistById(String userId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insert(Artist artist);

  @Update()
  Future<void> update(Artist artist);

  @Query('SELECT * FROM artists')
  Future<List<Artist>> getAllArtists();
}

@Database(
  version: 2, // Incrementar versión
  entities: [
    Artist,
    Profile,
    Conversation,
    MessageEntity,
    CachedData,
    ImageEntity,
    ReviewEntity,
    RecentlyViewedProfile,
    LikedProfile,
    LikedUsersList,
    WorksContentEntity, // Nueva entidad
  ],
)
@TypeConverters([ListStringConverter])
abstract class AppDatabase extends FloorDatabase {
  ArtistDao get artistDao;
  ProfileDao get profileDao;
  ConversationDao get conversationDao;
  MessageDao get messageDao;
  CachedDataDao get cachedDataDao;
  ImageDao get imageDao;
  ReviewDao get reviewDao;
  RecentlyViewedDao get recentlyViewedDao;
  LikedProfileDao get likedProfileDao;
  LikedUsersListDao get likedUsersListDao;
  WorksContentDao get worksContentDao; // Nuevo DAO

  static AppDatabase? _instance;

  static Future<AppDatabase> getInstance() async {
    if (_instance != null) {
      return _instance!;
    }

    // Inicialización de la base de datos con migración
    final database =
        await $FloorAppDatabase
            .databaseBuilder('app_database.db')
            .addMigrations([
              Migration(1, 2, (database) async {
                await database.execute('''
          CREATE TABLE works_content (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId TEXT NOT NULL,
            mediaUrl TEXT NOT NULL,
            isVideo INTEGER NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
              }),
            ])
            .build();

    _instance = database;
    return _instance!;
  }
}
