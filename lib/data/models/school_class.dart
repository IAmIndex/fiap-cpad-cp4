enum SchoolClassType {
  classroom('Turma'),
  studyGroup('Grupo de estudos');

  const SchoolClassType(this.label);

  final String label;
}

class SchoolClass {
  const SchoolClass({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.creatorName,
    required this.joinCode,
    required this.type,
    required this.memberIds,
  });

  final String id;
  final String name;
  final String creatorId;
  final String creatorName;
  final String joinCode;
  final SchoolClassType type;
  final List<String> memberIds;

  bool isCreatedBy(String userId) {
    return creatorId == userId;
  }

  SchoolClass copyWith({
    String? id,
    String? name,
    String? creatorId,
    String? creatorName,
    String? joinCode,
    SchoolClassType? type,
    List<String>? memberIds,
  }) {
    return SchoolClass(
      id: id ?? this.id,
      name: name ?? this.name,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      joinCode: joinCode ?? this.joinCode,
      type: type ?? this.type,
      memberIds: memberIds ?? this.memberIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'joinCode': joinCode,
      'type': type.name,
      'memberIds': memberIds,
    };
  }

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    return SchoolClass(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Turma sem nome',
      creatorId: json['creatorId'] as String? ?? '',
      creatorName: json['creatorName'] as String? ?? 'Criador desconhecido',
      joinCode: json['joinCode'] as String? ?? '',
      type: SchoolClassType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => SchoolClassType.classroom,
      ),
      memberIds: List<String>.from(json['memberIds'] as List<dynamic>? ?? []),
    );
  }
}
