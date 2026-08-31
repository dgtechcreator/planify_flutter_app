import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Live Planify server. NOTE: the api/* endpoints only work here once
  // the updated backend (AuthApi/EventApi/DashboardApi controllers,
  // JWT auth) is actually published to this server -- see the deployment
  // steps discussed with the user before relying on this.
  static const String serverOrigin = 'https://planify.jmmportal.com';
  static const String baseUrl = '$serverOrigin/api';

  static Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
      };

  static Future<Map<String, dynamic>> login(
      String emailUsername, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/AuthApi/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'EmailUsername': emailUsername,
        'Password': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Login failed');
    }

    return data;
  }

  static Future<List<dynamic>> getEvents(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/EventApi/list'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load events');
    }

    return data['data'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getEventById(String token, int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/EventApi/$id'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load event');
    }

    return data['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getEventDropdowns(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/EventApi/dropdowns'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load dropdown data');
    }

    return data;
  }

  /// Creates a new event, or updates an existing one when [eventId] is passed.
  static Future<void> saveEvent(
    String token, {
    int? eventId,
    required String eventName,
    required int eventTypeId,
    required int? organizedBy,
    String? description,
    required DateTime startDate,
    required DateTime endDate,
    required String venue,
    required int cityId,
    required int stateId,
    required int countryId,
    double? ticketPrice,
    String? contactNumber,
    String? email,
    File? bannerImage,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/EventApi'),
    );
    request.headers.addAll(_authHeaders(token));

    request.fields.addAll({
      'EventID': (eventId ?? 0).toString(),
      'EventName': eventName,
      'EventTypeID': eventTypeId.toString(),
      if (organizedBy != null) 'OrganizedBy': organizedBy.toString(),
      if (description != null) 'Description': description,
      'StartDate': startDate.toIso8601String(),
      'EndDate': endDate.toIso8601String(),
      'Venue': venue,
      'CityID': cityId.toString(),
      'StateID': stateId.toString(),
      'CountryID': countryId.toString(),
      if (ticketPrice != null) 'TicketPrice': ticketPrice.toString(),
      if (contactNumber != null) 'ContactNumber': contactNumber,
      if (email != null) 'Email': email,
    });

    if (bannerImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('bannerImage', bannerImage.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to save event');
    }
  }

  static Future<void> deleteEvent(String token, int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/EventApi/$id'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete event');
    }
  }

  static Future<Map<String, dynamic>> getDashboardSummary(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/DashboardApi/summary'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load dashboard');
    }

    return data['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> getTopEvent(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/DashboardApi/top-event'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load top event');
    }

    return data['data'] as Map<String, dynamic>?;
  }

  // ---- User Activity (To-Do) ----

  static Future<List<dynamic>> getTodos(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/UserActivityApi/list'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load tasks');
    }

    return data['data'] as List<dynamic>;
  }

  static Future<void> saveTodo(
    String token, {
    int? id,
    required String task,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/UserActivityApi'),
      headers: {..._authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'ID': id ?? 0,
        'Task': task,
        'Description': description ?? '',
        'AddedBy': 0,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to save task');
    }
  }

  static Future<void> setTodoDone(String token, int id, bool done) async {
    final response = await http.post(
      Uri.parse('$baseUrl/UserActivityApi/$id/${done ? 'done' : 'notdone'}'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update task');
    }
  }

  // ---- User Management (admin) ----

  static Future<List<dynamic>> getUsers(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/UserApi/list'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load users');
    }

    return data['data'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getUserById(String token, int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/UserApi/$id'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load user');
    }

    return data['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getRoles(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/UserApi/roles'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load roles');
    }

    return data['data'] as List<dynamic>;
  }

  /// Creates a new user, or updates an existing one when [id] is passed.
  /// Leave [password] null/empty on edit to keep the user's current password.
  static Future<void> saveUser(
    String token, {
    int? id,
    required String firstName,
    String? lastName,
    required String userName,
    required String phone,
    String? password,
    required String email,
    String? address,
    required int userTypeId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/UserApi'),
      headers: {..._authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'Id': id,
        'FirstName': firstName,
        'LastName': lastName ?? '',
        'UserName': userName,
        'Phone': phone,
        if (password != null && password.isNotEmpty) 'Password': password,
        'Email': email,
        'Address': address ?? '',
        'UserTypeID': userTypeId,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to save user');
    }
  }

  static Future<void> activateUser(String token, int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/UserApi/$id/activate'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to activate user');
    }
  }

  static Future<void> deleteUser(String token, int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/UserApi/$id/delete'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete user');
    }
  }

  // ---- Notifications ----

  static Future<List<dynamic>> getNotifications(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/MasterApi/notifications'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load notifications');
    }

    return data['data'] as List<dynamic>;
  }

  static Future<List<dynamic>> getNotificationRecipients(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/MasterApi/users-dropdown'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load users');
    }

    return data['data'] as List<dynamic>;
  }

  static Future<void> sendNotification(
    String token, {
    required int sendToId,
    required String title,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/MasterApi/notification'),
      headers: {..._authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'SendToID': sendToId,
        'NotificationTitle': title,
        'NotificationDescription': description ?? '',
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to send notification');
    }
  }
}
