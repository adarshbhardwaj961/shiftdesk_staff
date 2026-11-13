class Staff {
  const Staff({
    required this.role,
    required this.active,
    required this.licenceExpiry,
  });
  final String role;
  final bool active;
  final DateTime licenceExpiry;
}
