import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Live Planify server. NOTE: the api/* endpoints only work here once
  // the updated backend (AuthApi/EventApi/DashboardApi controllers,
  // JWT auth) is actually published to this server -- see the deployment
  // steps discussed with the user before relying on this.
  // USB-connected phone: `adb reverse tcp:5055 tcp:5055` forwards this
  // localhost port to the PC's local API. Re-run that command after every
  // USB reconnect/reboot -- it doesn't persist. Switch to the live server
  // URL once the backend is deployed there and you're not tethered by USB.

  //// For Local

  //static const String serverOrigin = 'http://localhost:5055';

  ////For Live Server

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

  static Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/AuthApi/google-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'IdToken': idToken}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Google sign-in failed');
    }

    return data;
  }

  static Future<Map<String, dynamic>> register({
    required String firstName,
    String? lastName,
    required String userName,
    required String email,
    required String phone,
    required String password,
    required String address,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/AuthApi/register'),
      body: {
        'FirstName': firstName,
        'LastName': lastName ?? '',
        'UserName': userName,
        'Email': email,
        'Phone': phone,
        'Password': password,
        'Address': address,
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Registration failed');
    }

    return data;
  }

  static Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/AuthApi/profile'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load profile');
    }

    return data['data'] as Map<String, dynamic>;
  }

  static Future<String?> updateProfile(
    String token, {
    required String firstName,
    String? lastName,
    required String userName,
    required String phone,
    String? address,
    File? profileImage,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/AuthApi/profile'),
    );
    request.headers.addAll(_authHeaders(token));

    request.fields.addAll({
      'FirstName': firstName,
      'LastName': lastName ?? '',
      'UserName': userName,
      'Phone': phone,
      'Address': address ?? '',
    });

    if (profileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('profileImage', profileImage.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update profile');
    }

    final resultData = data['data'] as Map<String, dynamic>?;
    return resultData?['userImage'] as String?;
  }

  static Future<void> changePassword(
    String token, {
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/AuthApi/change-password'),
      headers: {..._authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'CurrentPassword': currentPassword,
        'NewPassword': newPassword,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to change password');
    }
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
  /// Leave [profileImage] null to keep the user's current photo.
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
    File? profileImage,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/UserApi'),
    );
    request.headers.addAll(_authHeaders(token));

    request.fields.addAll({
      if (id != null) 'Id': id.toString(),
      'FirstName': firstName,
      'LastName': lastName ?? '',
      'UserName': userName,
      'Phone': phone,
      if (password != null && password.isNotEmpty) 'Password': password,
      'Email': email,
      'Address': address ?? '',
      'UserTypeID': userTypeId.toString(),
    });

    if (profileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('profileImage', profileImage.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
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

  // ---- Mail Master ----

  static Future<void> sendMail(
    String token, {
    required String to,
    required String subject,
    required String message,
    List<File> attachments = const [],
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/MailApi/send'),
    );
    request.headers.addAll(_authHeaders(token));
    request.fields.addAll({
      'to': to,
      'subject': subject,
      'message': message,
    });
    for (final file in attachments) {
      request.files.add(
        await http.MultipartFile.fromPath('attachments', file.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to send mail');
    }
  }

  static Future<List<dynamic>> getMailSummary(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/MailApi/summary'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load mail summary');
    }

    return data['data'] as List<dynamic>;
  }

  static Future<String> getMailBody(String token, int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/MailApi/$id'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load mail body');
    }

    return data['body'] as String? ?? '';
  }

  // ---- Contact Import ----

  static Future<String> uploadContactFile(String token, File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/ContactApi/upload'),
    );
    request.headers.addAll(_authHeaders(token));
    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to upload contacts');
    }

    return data['message'] as String? ?? 'Contacts imported.';
  }

  static Future<List<dynamic>> getContactSummary(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ContactApi/summary'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load contacts');
    }

    return data['data'] as List<dynamic>;
  }

  // ---- Map / Live Location ----

  static Future<void> saveLiveLocation(String token, double lat, double lon) async {
    final response = await http.post(
      Uri.parse('$baseUrl/MapApi/live-location'),
      headers: {..._authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({'Lat': lat, 'Lon': lon}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update location');
    }
  }

  static Future<List<dynamic>> getLiveLocations(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/MapApi/live-locations'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load live locations');
    }
    return data['data'] as List<dynamic>;
  }

  static Future<List<dynamic>> getMyLocationTasks(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/MapApi/my-tasks'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load tasks');
    }
    return data['data'] as List<dynamic>;
  }

  static Future<List<dynamic>> getAllLocationTasks(
    String token, {
    String? status,
    int? userId,
  }) async {
    final query = <String, String>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (userId != null) query['userId'] = userId.toString();

    final uri = Uri.parse('$baseUrl/MapApi/all-tasks').replace(queryParameters: query.isEmpty ? null : query);
    final response = await http.get(uri, headers: _authHeaders(token));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load tasks');
    }
    return data['data'] as List<dynamic>;
  }

  static Future<void> updateLocationTaskStatus(String token, int taskId, String status) async {
    final response = await http.post(
      Uri.parse('$baseUrl/MapApi/update-status'),
      headers: {..._authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({'TaskId': taskId, 'Status': status}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update status');
    }
  }

  static Future<List<dynamic>> getLocationHistory(String token, {int? userId}) async {
    final uri = Uri.parse('$baseUrl/MapApi/history').replace(
      queryParameters: userId != null ? {'userId': userId.toString()} : null,
    );
    final response = await http.get(uri, headers: _authHeaders(token));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load history');
    }
    return data['data'] as List<dynamic>;
  }

  static Future<List<dynamic>> getMapUsersDropdown(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/MapApi/users-dropdown'),
      headers: _authHeaders(token),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load users');
    }
    return data['data'] as List<dynamic>;
  }

  static Future<void> assignLocationTask(
    String token, {
    required int userId,
    required double lat,
    required double lon,
    required String locationName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/MapApi/assign'),
      headers: {..._authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'UserID': userId,
        'Latitude': lat,
        'Longitude': lon,
        'LocationName': locationName,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to assign location');
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
