class DailyStepStatisticItemResponse {
  final String label;
  final int stepCount;

  DailyStepStatisticItemResponse({
    required this.label,
    required this.stepCount,
  });

  factory DailyStepStatisticItemResponse.fromJson(Map<String, dynamic> json) {
    return DailyStepStatisticItemResponse(
      label: json['label']?.toString() ?? '',
      stepCount: int.tryParse(json['stepCount']?.toString() ?? '0') ?? 0,
    );
  }
}

class DailyStepStatisticResponse {
  final String type;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<DailyStepStatisticItemResponse> data;

  DailyStepStatisticResponse({
    required this.type,
    required this.fromDate,
    required this.toDate,
    required this.data,
  });

  factory DailyStepStatisticResponse.fromJson(Map<String, dynamic> json) {
    return DailyStepStatisticResponse(
      type: json['type']?.toString() ?? '',
      fromDate: DateTime.tryParse(json['fromDate']?.toString() ?? ''),
      toDate: DateTime.tryParse(json['toDate']?.toString() ?? ''),
      data: json['data'] is List
          ? (json['data'] as List)
              .map(
                (item) => DailyStepStatisticItemResponse.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList()
          : const [],
    );
  }
}
