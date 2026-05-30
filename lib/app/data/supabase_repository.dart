import 'dart:io';

import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRepository {
  SupabaseRepository._();

  static SupabaseClient get client => Supabase.instance.client;

  static String? get currentUserId => client.auth.currentUser?.id;

  static String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  static String? storagePathFromPublicUrl(String url) {
    if (url.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }

    final segments = uri.pathSegments;
    final publicIndex = segments.indexOf('public');
    if (publicIndex == -1 || publicIndex + 2 >= segments.length) {
      return null;
    }

    final bucket = segments[publicIndex + 1];
    if (bucket != 'uploads') {
      return null;
    }

    return segments.skip(publicIndex + 2).join('/');
  }

  static Future<void> deleteStorageObjectFromUrl(String url) async {
    final path = storagePathFromPublicUrl(url);
    if (path == null) {
      return;
    }

    await client.storage.from('uploads').remove([path]);
  }

  static Future<Map<String, Map<String, dynamic>>> _fetchProfilesByUserIds(
    Iterable<String> userIds,
  ) async {
    final ids = userIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) {
      return {};
    }

    final inList = ids.map((id) => '"$id"').join(',');
    final rows = await client.from('profiles').select().filter('id', 'in', '($inList)');

    final profiles = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final profile = Map<String, dynamic>.from(row);
      profiles[profile['id'].toString()] = profile;
    }
    return profiles;
  }

  static Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      final metadata = client.auth.currentUser?.userMetadata ?? const {};
      if (userId == currentUserId && (metadata['profile_url'] ?? '').toString().isNotEmpty) {
        return {
          'id': userId,
          'name': (metadata['name'] ?? client.auth.currentUser?.email ?? 'User').toString(),
          'phone': (metadata['phone'] ?? '').toString(),
          'address': (metadata['address'] ?? '').toString(),
          'profile_url': (metadata['profile_url'] ?? '').toString(),
          'total_score': 0,
        };
      }

      return null;
    }

    final profile = Map<String, dynamic>.from(response);
    final metadata = client.auth.currentUser?.userMetadata ?? const {};
    final fallbackAvatar = (metadata['profile_url'] ?? '').toString();
    if ((profile['profile_url'] ?? '').toString().isEmpty &&
        userId == currentUserId &&
        fallbackAvatar.isNotEmpty) {
      profile['profile_url'] = fallbackAvatar;
    }

    return profile;
  }

  static Future<Map<String, dynamic>?> fetchCurrentProfile() async {
    final userId = currentUserId;
    if (userId == null) {
      return null;
    }

    return fetchProfile(userId);
  }

  static Future<Map<String, dynamic>?> ensureCurrentProfileExists() async {
    final user = client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final existing = await fetchProfile(user.id);
    if (existing != null) {
      return existing;
    }

    final metadata = user.userMetadata ?? const {};
    final profile = {
      'id': user.id,
      'name': (metadata['name'] ?? user.email ?? 'User').toString(),
      'phone': (metadata['phone'] ?? '').toString(),
      'address': (metadata['address'] ?? '').toString(),
      'profile_url': (metadata['profile_url'] ?? '').toString(),
      'total_score': 0,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    await client.from('profiles').insert(profile);
    return fetchProfile(user.id);
  }

  static Future<void> saveProfile({
    required String userId,
    required String name,
    required String phone,
    required String address,
    required String profileUrl,
    int? totalScore,
  }) async {
    await client.from('profiles').upsert({
      'id': userId,
      'name': name,
      'phone': phone,
      'address': address,
      'profile_url': profileUrl,
      if (totalScore != null) 'total_score': totalScore,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    if (client.auth.currentUser?.id == userId) {
      await client.auth.updateUser(
        UserAttributes(
          data: {
            'name': name,
            'phone': phone,
            'address': address,
            'profile_url': profileUrl,
          },
        ),
      );
    }
  }

  static Future<String> uploadFile({
    required File file,
    required String bucket,
    required String folder,
  }) async {
    final originalName = file.path.split(RegExp(r'[\\/]+')).last;
    final storagePath =
        '$folder/${DateTime.now().microsecondsSinceEpoch}_$originalName';

    final bytes = await file.readAsBytes();
    await client.storage.from(bucket).uploadBinary(
      storagePath,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );
    return client.storage.from(bucket).getPublicUrl(storagePath);
  }

  static Future<List<Map<String, dynamic>>> fetchProducts() async {
    final rows = await client
        .from('products')
        .select()
        .order('created_at', ascending: false);

    final profilesById = await _fetchProfilesByUserIds(
      rows.map((row) => row['user_id']?.toString() ?? ''),
    );

    return rows.map<Map<String, dynamic>>((row) {
      final product = Map<String, dynamic>.from(row);
      final sellerId = product['user_id']?.toString();
      final profile = sellerId == null ? null : profilesById[sellerId];
      if (profile != null) {
        product['seller_name'] = profile['name']?.toString() ?? 'Seller';
        product['seller_profile_url'] = (profile['profile_url'] ?? '').toString();
      }
      return product;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> fetchMyProducts(String userId) async {
    final rows = await client
        .from('products')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final profilesById = await _fetchProfilesByUserIds(
      rows.map((row) => row['user_id']?.toString() ?? ''),
    );

    return rows.map<Map<String, dynamic>>((row) {
      final product = Map<String, dynamic>.from(row);
      final sellerId = product['user_id']?.toString();
      final profile = sellerId == null ? null : profilesById[sellerId];
      if (profile != null) {
        product['seller_name'] = profile['name']?.toString() ?? 'You';
        product['seller_profile_url'] = (profile['profile_url'] ?? '').toString();
      }
      return product;
    }).toList();
  }

  static Future<void> insertProduct({
    required String userId,
    required String name,
    required num price,
    required String description,
    required String address,
    required String email,
    required String phone,
    required String imageUrl,
    required List<String> topics,
  }) async {
    await client.from('products').insert({
      'user_id': userId,
      'name': name,
      'price': price,
      'description': description,
      'address': address,
      'email': email,
      'phone': phone,
      'image_url': imageUrl,
      'topics': topics,
    });
  }

  static Future<void> deleteProduct(String productId) async {
    final product = await client.from('products').select('image_url').eq('id', productId).maybeSingle();
    final imageUrl = (product?['image_url'] ?? '').toString();

    await client.from('products').delete().eq('id', productId);
    if (imageUrl.isNotEmpty) {
      await deleteStorageObjectFromUrl(imageUrl);
    }
  }

  static Future<List<Map<String, dynamic>>> fetchMessages({
    String? currentUserId,
  }) async {
    final messageRows = await client
        .from('messages')
        .select()
        .order('created_at', ascending: false);

    final likeRows = await client.from('message_likes').select('message_id,user_id');

    final likeMap = <String, Set<String>>{};
    for (final row in likeRows) {
      final messageId = row['message_id'].toString();
      final likerId = row['user_id'].toString();
      likeMap.putIfAbsent(messageId, () => <String>{}).add(likerId);
    }

    // Fetch profiles for the authors of the messages so we always show the
    // latest profile_url (avatar) from the profiles table instead of relying
    // on a possibly-stale value embedded on the message row.
    final userIds = <String>{};
    for (final row in messageRows) {
      final uid = row['user_id']?.toString();
      if (uid != null && uid.isNotEmpty) userIds.add(uid);
    }

    Map<String, Map<String, dynamic>> profilesById = {};
    if (userIds.isNotEmpty) {
      final inList = userIds.map((s) => '"$s"').join(',');
      final profileRows = await client.from('profiles').select().filter('id', 'in', '($inList)');
      for (final r in profileRows) {
        final p = Map<String, dynamic>.from(r);
        profilesById[p['id'].toString()] = p;
      }
    }

    return messageRows.map<Map<String, dynamic>>((row) {
      final message = Map<String, dynamic>.from(row);
      final messageId = message['id'].toString();
      final likedBy = likeMap[messageId] ?? <String>{};
      message['like_count'] = likedBy.length;
      message['is_liked'] = currentUserId != null && likedBy.contains(currentUserId);

      final authorId = message['user_id']?.toString();
      if (authorId != null && profilesById.containsKey(authorId)) {
        final prof = profilesById[authorId]!;
        message['profile_url'] = (prof['profile_url'] ?? '').toString();
      }

      return message;
    }).toList();
  }

  static Future<void> deleteMessage(String messageId) async {
    final message = await client.from('messages').select('image_url').eq('id', messageId).maybeSingle();
    final imageUrl = (message?['image_url'] ?? '').toString();

    await client.from('messages').delete().eq('id', messageId);
    if (imageUrl.isNotEmpty) {
      await deleteStorageObjectFromUrl(imageUrl);
    }
  }

  static Future<void> insertMessage({
    required String userId,
    required String senderName,
    required String description,
    required String profileUrl,
    String? imageUrl,
  }) async {
    await client.from('messages').insert({
      'user_id': userId,
      'sender_name': senderName,
      'description': description,
      'profile_url': profileUrl,
      'image_url': imageUrl,
    });
  }

  static Future<void> toggleMessageLike({
    required String messageId,
    required String userId,
    required bool isLiked,
  }) async {
    final likeRef = client
        .from('message_likes')
        .delete()
        .eq('message_id', messageId)
        .eq('user_id', userId);

    if (isLiked) {
      await likeRef;
      return;
    }

    await client.from('message_likes').insert({
      'message_id': messageId,
      'user_id': userId,
    });
  }

  static Future<int> fetchRewardPoints({String? userId}) async {
    final resolvedUserId = userId ?? currentUserId;
    if (resolvedUserId == null) {
      return 0;
    }

    final rewardRow = await client
        .from('rewards')
        .select('points')
        .eq('user_id', resolvedUserId)
        .maybeSingle();

    if (rewardRow != null) {
      return (rewardRow['points'] as num?)?.toInt() ?? 0;
    }

    final profile = await fetchProfile(resolvedUserId);
    return (profile?['total_score'] as num?)?.toInt() ?? 0;
  }

  static Future<int> fetchCurrentRewardPoints() async {
    return fetchRewardPoints();
  }

  static Future<Map<String, dynamic>?> fetchGameBySlug(String slug) async {
    final response = await client
        .from('games')
        .select()
        .eq('slug', slug)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Map<String, dynamic>.from(response);
  }

  static Future<List<Map<String, dynamic>>> fetchLeaderboard({
    required String gameId,
    int limit = 10,
  }) async {
    final rows = await client
        .from('leaderboards')
        .select('game_id,user_id,best_score,rank')
        .eq('game_id', gameId)
        .order('rank', ascending: true)
        .limit(limit);

    return rows
        .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> fetchGameChallenges({
    required String gameId,
    int limit = 8,
  }) async {
    final rows = await client
        .from('game_challenges')
        .select('item,hint,correct_bin,points,explanation,sort_order')
        .eq('game_id', gameId)
        .eq('is_active', true)
        .order('sort_order', ascending: true);

      final challenges = rows
        .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
        .toList();

      challenges.shuffle();
      return challenges.take(limit).toList();
  }

  static Future<Map<String, dynamic>> submitGameScore({
    required String gameId,
    required int score,
    int? durationSeconds,
    Map<String, dynamic> metadata = const {},
  }) async {
    final response = await client.rpc(
      'submit_score',
      params: {
        'p_game_id': gameId,
        'p_score': score,
        'p_duration_seconds': durationSeconds,
        'p_metadata': metadata,
      },
    );

    if (response is Map) {
      return Map<String, dynamic>.from(response.cast<String, dynamic>());
    }

    return <String, dynamic>{};
  }

  static Future<void> ensureQuizSeeded(DateTime date) async {
    final quizDate = _dateKey(date);
    final existing = await client
        .from('quiz_sets')
        .select('quiz_date')
        .eq('quiz_date', quizDate)
        .maybeSingle();

    if (existing != null) {
      return;
    }

    await client.from('quiz_sets').insert({
      'quiz_date': quizDate,
      'title': 'Daily Eco Quiz',
    });

    final questions = _defaultQuizQuestions();
    await client.from('quiz_questions').insert(
      questions.asMap().entries.map((entry) {
        final question = entry.value;
        return {
          'quiz_date': quizDate,
          'sort_order': entry.key,
          'question_text': question['question_text'],
          'options': question['options'],
          'correct_answer': question['correct_answer'],
        };
      }).toList(),
    );
  }

  static Future<List<Map<String, dynamic>>> fetchQuizQuestions(DateTime date) async {
    await ensureQuizSeeded(date);
    final quizDate = _dateKey(date);
    final rows = await client
        .from('quiz_questions')
        .select()
        .eq('quiz_date', quizDate)
        .order('sort_order', ascending: true);

    return rows
        .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static Future<bool> hasAttemptedQuiz({
    required String userId,
    required DateTime date,
  }) async {
    final quizDate = _dateKey(date);
    final row = await client
        .from('quiz_attempts')
        .select('attempted')
        .eq('user_id', userId)
        .eq('quiz_date', quizDate)
        .maybeSingle();

    if (row == null) {
      return false;
    }

    return row['attempted'] == true;
  }

  static Future<int> fetchQuizScore({
    required String userId,
    required DateTime date,
  }) async {
    final quizDate = _dateKey(date);
    final row = await client
        .from('quiz_attempts')
        .select('score')
        .eq('user_id', userId)
        .eq('quiz_date', quizDate)
        .maybeSingle();

    if (row == null) {
      return 0;
    }

    return (row['score'] as num?)?.toInt() ?? 0;
  }

  static Future<void> submitQuizAttempt({
    required String userId,
    required DateTime date,
    required int score,
  }) async {
    final quizDate = _dateKey(date);
    await client.from('quiz_attempts').upsert({
      'user_id': userId,
      'quiz_date': quizDate,
      'attempted': true,
      'score': score,
    }, onConflict: 'user_id,quiz_date');

    final profile = await fetchProfile(userId);
    final currentScore = (profile?['total_score'] as num?)?.toInt() ?? 0;
    final currentRewardPoints = await fetchRewardPoints(userId: userId);
    await client
        .from('profiles')
        .update({'total_score': currentScore + score, 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', userId);

    await client.from('rewards').upsert({
      'user_id': userId,
      'points': currentRewardPoints + score,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static List<Map<String, dynamic>> _defaultQuizQuestions() {
    return [
      {
        'question_text':
            'Which rare earth metal, commonly found in smartphones, is critical for producing strong magnets used in electric vehicles and wind turbines?',
        'correct_answer': 'Neodymium',
        'options': ['Lithium', 'Neodymium', 'Beryllium', 'Indium'],
      },
      {
        'question_text':
            'What is the primary environmental hazard caused by improper disposal of cathode ray tube (CRT) monitors?',
        'correct_answer': 'Lead contamination',
        'options': [
          'Plastic pollution',
          'Mercury leakage',
          'Lead contamination',
          'Radiation leakage',
        ],
      },
      {
        'question_text':
            'Which country is known as the world\'s largest producer of e-waste according to the Global E-waste Monitor 2020?',
        'correct_answer': 'USA',
        'options': ['India', 'China', 'USA', 'Japan'],
      },
      {
        'question_text': 'What is "urban mining" in the context of e-waste management?',
        'correct_answer': 'Recovering valuable metals from e-waste',
        'options': [
          'Mining landfills',
          'Extracting minerals from rocks',
          'Recovering valuable metals from e-waste',
          'Mining in cities',
        ],
      },
      {
        'question_text':
            'Which of the following electronic components contains the highest concentration of gold?',
        'correct_answer': 'Circuit board',
        'options': ['Battery', 'Circuit board', 'LCD screen', 'Hard disk drive'],
      },
      {
        'question_text':
            'Which international treaty regulates the transboundary movement of hazardous e-waste?',
        'correct_answer': 'Basel Convention',
        'options': [
          'Paris Agreement',
          'Kyoto Protocol',
          'Basel Convention',
          'Geneva Protocol',
        ],
      },
      {
        'question_text': 'What is the approximate average gold content in 1 ton of mobile phones?',
        'correct_answer': '300g',
        'options': ['5g', '100g', '300g', '1kg'],
      },
      {
        'question_text':
            'Which harmful chemical is used as a flame retardant in older electronics and is known to cause serious health problems?',
        'correct_answer': 'Polychlorinated biphenyls (PCBs)',
        'options': [
          'Polychlorinated biphenyls (PCBs)',
          'DDT',
          'CFCs',
          'Methanol',
        ],
      },
      {
        'question_text':
            'Which of these e-waste components is most responsible for releasing dioxins when burned improperly?',
        'correct_answer': 'Metal wires with PVC coating',
        'options': [
          'Glass',
          'Metal wires with PVC coating',
          'Lithium-ion batteries',
          'Ceramic resistors',
        ],
      },
      {
        'question_text':
            'Why is improper e-waste recycling dangerous for informal workers?',
        'correct_answer': 'Because of toxic exposure like mercury and cadmium',
        'options': [
          'Because of high voltage shocks',
          'Because of toxic exposure like mercury and cadmium',
          'Because devices explode when opened',
          'Because of sharp plastic edges',
        ],
      },
    ];
  }
}
