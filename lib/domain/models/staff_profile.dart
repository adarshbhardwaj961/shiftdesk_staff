enum StaffRole { doctor, nurse, technician }

extension StaffRoleLabel on StaffRole {
  String get label => switch (this) {
    StaffRole.doctor => 'Doctor',
    StaffRole.nurse => 'Nurse',
    StaffRole.technician => 'Technician',
  };
}

class StaffProfile {
  const StaffProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.active,
    required this.licenceExpiry,
  });

  final String id;
  final String name;
  final StaffRole role;
  final bool active;
  final DateTime licenceExpiry;
}
