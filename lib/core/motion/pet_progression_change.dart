/// Confirmed pet progression, separate from unsynced local step counters.
class PetProgressionSnapshot {
  const PetProgressionSnapshot({
    required this.petId,
    required this.level,
    required this.exp,
    required this.maxExp,
  });
  final String petId;
  final int level;
  final int exp;
  final int maxExp;
}

class PetProgressionChange {
  const PetProgressionChange({
    required this.id,
    required this.before,
    required this.after,
  });
  final String id;
  final PetProgressionSnapshot before;
  final PetProgressionSnapshot after;
}

/// First load and pet/account changes establish a silent baseline.
class PetProgressionTracker {
  PetProgressionSnapshot? _previous;
  PetProgressionChange? latest;
  int _serial = 0;

  void accept(PetProgressionSnapshot snapshot) {
    final previous = _previous;
    _previous = snapshot;
    if (previous == null || previous.petId != snapshot.petId) {
      latest = null;
      return;
    }
    if (snapshot.level > previous.level) {
      latest = PetProgressionChange(
        id: '${snapshot.petId}:${++_serial}',
        before: previous,
        after: snapshot,
      );
    }
  }

  void reset() {
    _previous = null;
    latest = null;
    _serial++;
  }
}
