class FriendProfileResponse {
  final String username;
  final String bio;
  final String gender;
  final DateTime? dob;
  final String avatarUrl;

  const FriendProfileResponse({
    required this.username,
    required this.bio,
    required this.gender,
    this.dob,
    required this.avatarUrl,
  });

  factory FriendProfileResponse.fromJson(Map<String, dynamic> json) {
    return FriendProfileResponse(
      username: _readString(json, 'username', 'Username'),
      bio: _readString(json, 'bio', 'Bio'),
      gender: _readString(json, 'gender', 'Gender'),
      dob: _parseDate(_readString(json, 'dob', 'Dob')),
      avatarUrl: _readString(json, 'avatarUrl', 'AvatarUrl'),
    );
  }
}

class FriendSpiritResponse {
  final String userId;
  final String userName;
  final String petNickName;
  final String petName;
  final int level;
  final int currentExp;
  final int maxExp;
  final int currentEnergy;
  final int maxEnergy;
  final int currentBond;
  final int maxBond;
  final int currentLifeForce;
  final int maxLifeForce;
  final String stageName;
  final String stageImage;

  const FriendSpiritResponse({
    required this.userId,
    required this.userName,
    required this.petNickName,
    required this.petName,
    required this.level,
    required this.currentExp,
    required this.maxExp,
    required this.currentEnergy,
    required this.maxEnergy,
    required this.currentBond,
    required this.maxBond,
    required this.currentLifeForce,
    required this.maxLifeForce,
    required this.stageName,
    required this.stageImage,
  });

  factory FriendSpiritResponse.fromJson(Map<String, dynamic> json) {
    return FriendSpiritResponse(
      userId: _readString(json, 'userId', 'UserId'),
      userName: _readString(json, 'userName', 'UserName'),
      petNickName: _readString(json, 'petNickName', 'PetNickName'),
      petName: _readString(json, 'petName', 'PetName'),
      level: _readInt(json, 'level', 'Level'),
      currentExp: _readInt(json, 'currentExp', 'CurrentExp'),
      maxExp: _readInt(json, 'maxExp', 'MaxExp', fallback: 100),
      currentEnergy: _readInt(json, 'currentEnergy', 'CurrentEnergy'),
      maxEnergy: _readInt(json, 'maxEnergy', 'MaxEnergy', fallback: 100),
      currentBond: _readInt(json, 'currentBond', 'CurrentBond'),
      maxBond: _readInt(json, 'maxBond', 'MaxBond', fallback: 100),
      currentLifeForce: _readInt(json, 'currentLifeForce', 'CurrentLifeForce'),
      maxLifeForce: _readInt(
        json,
        'maxLifeForce',
        'MaxLifeForce',
        fallback: 100,
      ),
      stageName: _readString(json, 'stageName', 'StageName'),
      stageImage: _readString(json, 'stageImage', 'StageImage'),
    );
  }
}

class FriendPlayerProfile {
  final String userId;
  final FriendProfileResponse? profile;
  final FriendSpiritResponse? spirit;

  const FriendPlayerProfile({
    required this.userId,
    required this.profile,
    required this.spirit,
  });

  String get displayName {
    final profileName = profile?.username.trim() ?? '';
    if (profileName.isNotEmpty) return profileName;
    final spiritUserName = spirit?.userName.trim() ?? '';
    if (spiritUserName.isNotEmpty) return spiritUserName;
    return '';
  }
}

String _readString(
  Map<String, dynamic> json,
  String camelKey,
  String pascalKey, {
  String fallback = '',
}) {
  final value = json[camelKey] ?? json[pascalKey];
  return value?.toString() ?? fallback;
}

int _readInt(
  Map<String, dynamic> json,
  String camelKey,
  String pascalKey, {
  int fallback = 0,
}) {
  return int.tryParse(_readString(json, camelKey, pascalKey)) ?? fallback;
}

DateTime? _parseDate(String value) {
  if (value.isEmpty) return null;
  return DateTime.tryParse(value);
}
