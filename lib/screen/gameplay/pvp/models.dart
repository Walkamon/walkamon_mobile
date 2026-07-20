class FriendMock {
  final int id;
  final String name;
  final int level;
  final bool isOnline;

  FriendMock({required this.id, required this.name, required this.level, required this.isOnline});
}

class MatchHistoryMock {
  final int id;
  final String opponent;
  final String result;
  final String date;
  final String points;

  MatchHistoryMock({
    required this.id,
    required this.opponent,
    required this.result,
    required this.date,
    required this.points,
  });
}

class IncomingChallengeMock {
  final int id;
  final String name;
  final int level;

  IncomingChallengeMock({required this.id, required this.name, required this.level});
}

final List<FriendMock> mockOnlineFriends = [
  FriendMock(id: 1, name: "Hải Đăng", level: 12, isOnline: true),
  FriendMock(id: 3, name: "Lan Anh", level: 24, isOnline: true),
];

final List<FriendMock> mockOfflineFriends = [
  FriendMock(id: 2, name: "Minh Tuấn", level: 18, isOnline: false),
  FriendMock(id: 4, name: "Thảo Vy", level: 9, isOnline: false),
];

final List<IncomingChallengeMock> mockIncomingChallenges = [
  IncomingChallengeMock(id: 101, name: "Cáo Nhỏ", level: 15),
];

final List<MatchHistoryMock> mockMatchHistory = [
  MatchHistoryMock(id: 1, opponent: "LuminaMaster99", result: "win", date: "Hôm nay, 10:30", points: "+50"),
  MatchHistoryMock(id: 2, opponent: "Cáo Nhỏ", result: "loss", date: "Hôm nay, 09:15", points: "+10"),
  MatchHistoryMock(id: 3, opponent: "Hải Đăng", result: "win", date: "Hôm qua, 20:00", points: "+50"),
  MatchHistoryMock(id: 4, opponent: "Lan Anh", result: "loss", date: "Hôm qua, 15:30", points: "+10"),
];
