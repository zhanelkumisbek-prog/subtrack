import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/user_model.dart';

class AuthService {
  static const _usersKey = 'auth_users';
  static const _passwordsKey = 'auth_passwords';
  static const _currentUidKey = 'auth_current_uid';
  static const _passwordResetKey = 'auth_password_reset_requests';
  static final StreamController<AppUser?> _authController =
      StreamController<AppUser?>.broadcast();
  static const Uuid _uuid = Uuid();
  static final Random _random = Random();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<AppUser?> authStateChanges() async* {
    yield await getCurrentUser();
    yield* _authController.stream;
  }

  Future<AppUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_currentUidKey);
    if (uid == null) return null;

    final users = await _loadUsers();
    return users[uid];
  }

  Future<AppUser?> signInWithGoogle() async {
    GoogleSignInAccount? googleUser;

    try {
      googleUser = await _googleSignIn.signIn();
    } catch (_) {
      throw 'Не удалось открыть вход через Google. Проверьте настройку Google Sign-In в Android.';
    }

    if (googleUser == null) {
      return null;
    }

    final users = await _loadUsers();
    final normalizedEmail = googleUser.email.trim().toLowerCase();
    final existing = users.values.where(
      (user) => user.email.toLowerCase() == normalizedEmail,
    );

    final user = existing.isNotEmpty
        ? existing.first.copyWith(
            displayName: googleUser.displayName,
            photoURL: googleUser.photoUrl,
          )
        : AppUser(
            uid: googleUser.id.isNotEmpty ? googleUser.id : _uuid.v4(),
            email: normalizedEmail,
            displayName: googleUser.displayName,
            photoURL: googleUser.photoUrl,
            createdAt: DateTime.now(),
          );

    users[user.uid] = user;
    await _saveUsers(users);
    await _setCurrentUser(user.uid);
    _authController.add(user);
    return user;
  }

  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = _normalizePhone(phoneNumber);
    final users = await _loadUsers();

    final alreadyExists = users.values.any(
      (user) => user.email.toLowerCase() == normalizedEmail,
    );
    if (alreadyExists) {
      throw 'Аккаунт с таким email уже существует.';
    }

    final phoneExists = users.values.any(
      (user) => user.phoneNumber == normalizedPhone,
    );
    if (phoneExists) {
      throw 'Аккаунт с таким номером уже существует.';
    }

    if (password.length < 6) {
      throw 'Пароль слишком слабый. Минимум 6 символов.';
    }

    final user = AppUser(
      uid: _uuid.v4(),
      email: normalizedEmail,
      displayName: name.trim(),
      phoneNumber: normalizedPhone,
      createdAt: DateTime.now(),
    );

    users[user.uid] = user;
    final passwords = await _loadPasswords();
    passwords[user.uid] = password;

    await _saveUsers(users);
    await _savePasswords(passwords);
    await _setCurrentUser(user.uid);
    _authController.add(user);
    return user;
  }

  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final users = await _loadUsers();
    final passwords = await _loadPasswords();

    AppUser? matchedUser;
    for (final user in users.values) {
      if (user.email.toLowerCase() == normalizedEmail) {
        matchedUser = user;
        break;
      }
    }

    if (matchedUser == null) {
      throw 'Пользователь не найден.';
    }

    if (passwords[matchedUser.uid] != password) {
      throw 'Неверный пароль.';
    }

    await _setCurrentUser(matchedUser.uid);
    _authController.add(matchedUser);
    return matchedUser;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore Google session cleanup errors and continue local sign-out.
    }
    await prefs.remove(_currentUidKey);
    _authController.add(null);
  }

  Future<AppUser> updateProfile({
    required String uid,
    required String displayName,
    required String phoneNumber,
    required String currency,
    required bool notificationsEnabled,
  }) async {
    final users = await _loadUsers();
    final existing = users[uid];
    if (existing == null) {
      throw 'Пользователь не найден.';
    }

    final normalizedPhone = _normalizePhone(phoneNumber);
    final phoneTaken = users.values.any(
      (user) => user.uid != uid && user.phoneNumber == normalizedPhone,
    );
    if (phoneTaken) {
      throw 'Этот номер уже используется в другом аккаунте.';
    }

    final updated = existing.copyWith(
      displayName: displayName.trim(),
      phoneNumber: normalizedPhone,
      currency: currency,
      notificationsEnabled: notificationsEnabled,
    );

    users[uid] = updated;
    await _saveUsers(users);

    final currentUser = await getCurrentUser();
    if (currentUser?.uid == uid) {
      _authController.add(updated);
    }

    return updated;
  }

  Future<String> sendPasswordResetCode({
    required String phoneNumber,
  }) async {
    final users = await _loadUsers();
    final normalizedPhone = _normalizePhone(phoneNumber);
    final matchedUser = _findUserByPhone(users, normalizedPhone);

    if (matchedUser == null) {
      throw 'Пользователь с таким номером не найден.';
    }

    final passwords = await _loadPasswords();
    if (!passwords.containsKey(matchedUser.uid)) {
      throw 'Для этого аккаунта используйте вход через Google.';
    }

    final code = (100000 + _random.nextInt(900000)).toString();
    final resetRequests = await _loadResetRequests();
    resetRequests[normalizedPhone] = {
      'uid': matchedUser.uid,
      'code': code,
      'expiresAt':
          DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
    };
    await _saveResetRequests(resetRequests);
    return code;
  }

  Future<void> resetPassword({
    required String phoneNumber,
    required String code,
    required String newPassword,
  }) async {
    final normalizedPhone = _normalizePhone(phoneNumber);
    final resetRequests = await _loadResetRequests();
    final request = resetRequests[normalizedPhone];

    if (request == null) {
      throw 'Сначала запросите код восстановления.';
    }

    final expiresAt = DateTime.tryParse(request['expiresAt'] ?? '');
    if (expiresAt == null || expiresAt.isBefore(DateTime.now())) {
      resetRequests.remove(normalizedPhone);
      await _saveResetRequests(resetRequests);
      throw 'Срок действия кода истёк. Запросите новый код.';
    }

    if ((request['code'] ?? '').trim() != code.trim()) {
      throw 'Неверный код подтверждения.';
    }

    if (newPassword.length < 6) {
      throw 'Новый пароль должен содержать минимум 6 символов.';
    }

    final passwords = await _loadPasswords();
    final uid = request['uid'];
    if (uid == null || !passwords.containsKey(uid)) {
      throw 'Не удалось обновить пароль для этого аккаунта.';
    }

    passwords[uid] = newPassword;
    await _savePasswords(passwords);

    resetRequests.remove(normalizedPhone);
    await _saveResetRequests(resetRequests);
  }

  Future<void> ensureResettableAccount(String phoneNumber) async {
    final users = await _loadUsers();
    final normalizedPhone = _normalizePhone(phoneNumber);
    final matchedUser = _findUserByPhone(users, normalizedPhone);
    if (matchedUser == null) {
      throw 'Пользователь с таким номером не найден.';
    }

    final passwords = await _loadPasswords();
    if (!passwords.containsKey(matchedUser.uid)) {
      throw 'Для этого аккаунта используйте вход через Google.';
    }
  }

  Future<Map<String, AppUser>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return {};

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        AppUser.fromMap(Map<String, dynamic>.from(value)),
      ),
    );
  }

  Future<Map<String, String>> _loadPasswords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_passwordsKey);
    if (raw == null || raw.isEmpty) return {};

    return Map<String, String>.from(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<Map<String, Map<String, String>>> _loadResetRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_passwordResetKey);
    if (raw == null || raw.isEmpty) return {};

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        Map<String, String>.from(value as Map),
      ),
    );
  }

  Future<void> _saveUsers(Map<String, AppUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      users.map((key, value) => MapEntry(key, value.toMap())),
    );
    await prefs.setString(_usersKey, encoded);
  }

  Future<void> _savePasswords(Map<String, String> passwords) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passwordsKey, jsonEncode(passwords));
  }

  Future<void> _saveResetRequests(
    Map<String, Map<String, String>> requests,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passwordResetKey, jsonEncode(requests));
  }

  Future<void> _setCurrentUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUidKey, uid);
  }

  AppUser? _findUserByPhone(
    Map<String, AppUser> users,
    String normalizedPhone,
  ) {
    for (final user in users.values) {
      if (user.phoneNumber == normalizedPhone) {
        return user;
      }
    }
    return null;
  }

  String _normalizePhone(String phoneNumber) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10) {
      throw 'Введите корректный номер телефона.';
    }
    return digitsOnly;
  }
}
