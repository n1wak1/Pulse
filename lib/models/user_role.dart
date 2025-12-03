enum UserRole {
  admin('Администратор'),
  developer('Разработчик'),
  designer('Дизайнер'),
  manager('Менеджер'),
  viewer('Наблюдатель');

  const UserRole(this.label);
  final String label;

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return UserRole.admin;
      case 'developer':
      case 'разработчик':
        return UserRole.developer;
      case 'designer':
      case 'дизайнер':
        return UserRole.designer;
      case 'manager':
      case 'менеджер':
        return UserRole.manager;
      case 'viewer':
      case 'наблюдатель':
        return UserRole.viewer;
      default:
        return UserRole.viewer;
    }
  }
}

