class ProjectSummary {
  const ProjectSummary({
    required this.id,
    required this.name,
    required this.client,
    required this.location,
    required this.createdAt,
    this.description,
  });

  final String id;
  final String name;
  final String client;
  final String location;
  final String? description;
  final DateTime createdAt;

  factory ProjectSummary.fromNewProject({
    required String name,
    required String client,
    required String location,
    String? description,
  }) {
    return ProjectSummary(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      client: client,
      location: location,
      description: description,
      createdAt: DateTime.now(),
    );
  }
}
