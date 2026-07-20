class PetNameResponse {
  const PetNameResponse({required this.petId, required this.petName});

  final String petId;
  final String petName;

  factory PetNameResponse.fromJson(Map<String, dynamic> json) {
    return PetNameResponse(
      petId: json['petId']?.toString() ?? '',
      petName: json['petName']?.toString() ?? '',
    );
  }

  bool get hasName => petName.trim().isNotEmpty;
}
