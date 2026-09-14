/// Session-scoped cosmetic arbitration. Claim/evolution work never runs here.
class GamePresentationCoordinator {
  final _seen = <String>{};
  String? _active;
  String? get active => _active;

  bool begin(String id) {
    if (_active != null || !acknowledge(id)) return false;
    _active = id;
    return true;
  }

  bool acknowledge(String id) {
    if (_seen.contains(id)) return false;
    _seen.add(id);
    if (_seen.length > 1024) _seen.remove(_seen.first);
    return true;
  }

  void finish() => _active = null;
  void reset() {
    _active = null;
    _seen.clear();
  }
}
