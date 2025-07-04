class User {
  final int id;
  final String username;
  final String role;
  final String name;
  final String email;
  final int balance;
  final int debt;
  final int maxDebt;
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.name,
    required this.email,
    required this.balance,
    required this.debt,
    required this.maxDebt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      role: json['role'],
      name: json['name'],
      email: json['email'],
      balance: json['balance'],
      debt: json['debt'],
      maxDebt: json['max_debt'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}