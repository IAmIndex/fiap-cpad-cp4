import 'package:flutter/material.dart';

import '../../app/theme.dart';

enum PublicationType {
  notice('Aviso', AppColors.foreground),
  material('Material didatico', AppColors.success),
  activity('Atividade', AppColors.accent),
  exam('Prova', AppColors.warning);

  const PublicationType(this.label, this.color);

  final String label;
  final Color color;

  static List<PublicationType> get creationOptions {
    return const [
      PublicationType.notice,
      PublicationType.material,
      PublicationType.activity,
    ];
  }
}

class Publication {
  const Publication({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    required this.type,
    required this.authorName,
    required this.createdAt,
  });

  final String id;
  final String classId;
  final String title;
  final String description;
  final PublicationType type;
  final String authorName;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'title': title,
      'description': description,
      'type': type.name,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Publication.fromJson(Map<String, dynamic> json) {
    return Publication(
      id: json['id'] as String? ?? '',
      classId: json['classId'] as String? ?? '',
      title: json['title'] as String? ?? 'Publicacao sem titulo',
      description: json['description'] as String? ?? '',
      type: PublicationType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => PublicationType.notice,
      ),
      authorName: json['authorName'] as String? ?? 'Autor desconhecido',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
