import 'package:flutter/material.dart';
import 'api_service.dart';
import 'add_edit_user_screen.dart';
import 'shimmer_loading.dart';


class UsersScreen extends StatefulWidget {
final String token;

const UsersScreen({
super.key,
required this.token,
});

@override
State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
late Future<List<dynamic>> _usersFuture;

final TextEditingController _searchController =
TextEditingController();

String _searchText = '';

@override
void initState() {
super.initState();

_usersFuture =
ApiService.getUsers(widget.token);

_searchController.addListener(() {
setState(() {
_searchText = _searchController.text.toLowerCase();
});
});
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

Future<void> _refresh() async {
setState(() {
_usersFuture =
ApiService.getUsers(widget.token);
});

await _usersFuture;
}

int _readId(Map<String, dynamic> row) {
final value =
row['Id'] ??
row['ID'] ??
row['id'];

return int.tryParse(value.toString()) ?? 0;
}

Future<void> _openAdd() async {
final saved = await Navigator.push<bool>(
context,
MaterialPageRoute(
builder: (_) =>
AddEditUserScreen(
token: widget.token,
),
),
);

if (saved == true) {
_refresh();
}
}

Future<void> _openEdit(int id) async {
final saved = await Navigator.push<bool>(
context,
MaterialPageRoute(
builder: (_) =>
AddEditUserScreen(
token: widget.token,
id: id,
),
),
);

if (saved == true) {
_refresh();
}
}

Future<void> _deleteUser(int id) async {
final confirmed = await showDialog<bool>(
context: context,
builder: (_) => AlertDialog(
title: const Text('Delete User'),

content: const Text(
'Are you sure you want to delete this user?',
),

actions: [
TextButton(
onPressed: () =>
Navigator.pop(context, false),
child: const Text('Cancel'),
),

FilledButton(
style: FilledButton.styleFrom(
backgroundColor: Colors.red,
),
onPressed: () =>
Navigator.pop(context, true),
child: const Text('Delete'),
),
],
),
);

if (confirmed != true) return;

try {
await ApiService.deleteUser(
widget.token,
id,
);

_refresh();

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'User deleted successfully',
),
),
);
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
e.toString().replaceFirst(
'Exception: ',
'',
),
),
),
);
}
}

Color _statusColor(
BuildContext context,
String status,
) {
switch (status.toLowerCase()) {
case 'active':
return Colors.green;

case 'invited':
case 'pending':
return Colors.orange;

case 'inactive':
case 'suspended':
return Colors.red;

default:
return Theme.of(context).colorScheme.primary;
}
}

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);
final scheme = theme.colorScheme;

return Scaffold(
appBar: AppBar(
title: const Text('Users'),

actions: [
Padding(
padding: const EdgeInsets.only(
right: 12,
),

child: FilledButton.icon(
onPressed: _openAdd,
icon: const Icon(Icons.add),
label: const Text('Add User'),
),
),
],
),

body: FutureBuilder<List<dynamic>>(
future: _usersFuture,

builder: (context, snapshot) {
// =========================
// LOADING
// =========================

if (snapshot.connectionState ==
ConnectionState.waiting) {
return const  ShimmerLoading();
}

// =========================
// ERROR
// =========================

if (snapshot.hasError) {
return Center(
child: Column(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
const Icon(
Icons.error_outline,
size: 60,
color: Colors.red,
),

const SizedBox(height: 10),

Text(
'Error: ${snapshot.error}',
textAlign: TextAlign.center,
),

const SizedBox(height: 15),

ElevatedButton.icon(
onPressed: _refresh,
icon: const Icon(Icons.refresh),
label: const Text('Try Again'),
),
],
),
);
}

final users = snapshot.data ?? [];

// =========================
// SEARCH FILTER
// =========================

final filteredUsers = users.where((item) {
final user =
item as Map<String, dynamic>;

final name =
'${user['FirstName'] ?? ''} '
'${user['LastName'] ?? ''}'
    .toLowerCase();

final email =
(user['Email'] ?? '')
    .toString()
    .toLowerCase();

final username =
(user['UserName'] ?? '')
    .toString()
    .toLowerCase();

return name.contains(_searchText) ||
email.contains(_searchText) ||
username.contains(_searchText);
}).toList();

// =========================
// MAIN UI
// =========================

return RefreshIndicator(
onRefresh: _refresh,

child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [

// =========================
// SEARCH BAR
// =========================

Padding(
padding:
const EdgeInsets.all(16),

child: TextField(
controller: _searchController,

decoration: InputDecoration(
hintText: 'Search users',

prefixIcon:
const Icon(Icons.search),

suffixIcon: _searchText.isNotEmpty
? IconButton(
icon:
const Icon(Icons.clear),

onPressed: () {
_searchController.clear();
},
)
    : null,

isDense: true,

border: OutlineInputBorder(
borderRadius:
BorderRadius.circular(12),
),
),
),
),

// =========================
// EMPTY STATE
// =========================

if (filteredUsers.isEmpty)
Expanded(
child: ListView(
children: const [
SizedBox(height: 120),

Center(
child: Icon(
Icons.people_outline,
size: 70,
color: Colors.grey,
),
),

SizedBox(height: 15),

Center(
child: Text(
'No users found',
style: TextStyle(
fontSize: 18,
fontWeight:
FontWeight.w500,
),
),
),
],
),
)

else

// =========================
// USERS TABLE
// =========================

Expanded(
child: SingleChildScrollView(
physics:
const AlwaysScrollableScrollPhysics(),

child: SingleChildScrollView(
scrollDirection:
Axis.horizontal,

child: DataTable(
headingRowColor:
WidgetStateProperty.all(
scheme.primaryContainer
    .withValues(alpha: 0.4),
),

columnSpacing: 30,

columns: const [

DataColumn(
label: Text(
'Name',
style: TextStyle(
fontWeight:
FontWeight.bold,
),
),
),

DataColumn(
label: Text(
'Email',
style: TextStyle(
fontWeight:
FontWeight.bold,
),
),
),

DataColumn(
label: Text(
'Phone',
style: TextStyle(
fontWeight:
FontWeight.bold,
),
),
),

DataColumn(
label: Text(
'Status',
style: TextStyle(
fontWeight:
FontWeight.bold,
),
),
),

DataColumn(
label: Text(
'Action',
style: TextStyle(
fontWeight:
FontWeight.bold,
),
),
),
],

rows: filteredUsers.map((item) {
final user =
item as Map<String, dynamic>;

final id =
_readId(user);

final firstName =
user['FirstName']
    ?.toString() ??
'';

final lastName =
user['LastName']
    ?.toString() ??
'';

final fullName =
'$firstName $lastName'
    .trim();

final userName =
user['UserName']
    ?.toString() ??
'-';

final name =
fullName.isEmpty
? userName
    : fullName;

final email =
user['Email']
    ?.toString() ??
'-';

final phone =
user['ContactNo']
    ?.toString() ??
user['Phone']
    ?.toString() ??
'-';

// Change these names
// according to your API response
final status =
user['Status']
    ?.toString() ??
'Active';

final statusColor =
_statusColor(
context,
status,
);

return DataRow(
cells: [

// =========================
// NAME
// =========================

DataCell(
InkWell(
onTap: () =>
_openEdit(id),

child: Row(
mainAxisSize:
MainAxisSize.min,

children: [

CircleAvatar(
radius: 18,

child: Text(
name.isNotEmpty
? name[0]
    .toUpperCase()
    : '?',
),
),

const SizedBox(
width: 10,
),

Text(
name,
style:
const TextStyle(
fontWeight:
FontWeight.w600,
),
),
],
),
),
),

// EMAIL
DataCell(
Text(email),
),

// PHONE
DataCell(
Text(phone),
),

// STATUS
DataCell(
Container(
padding:
const EdgeInsets
    .symmetric(
horizontal: 12,
vertical: 5,
),

decoration:
BoxDecoration(
color: statusColor
    .withValues(
alpha: 0.15,
),

borderRadius:
BorderRadius
    .circular(20),
),

child: Text(
status,

style: TextStyle(
color: statusColor,

fontSize: 12,

fontWeight:
FontWeight.w600,
),
),
),
),

// =========================
// ACTION MENU
// =========================

DataCell(
PopupMenuButton<String>(
icon: const Icon(
Icons.more_vert,
),

onSelected:
(value) {
if (value ==
'edit') {
_openEdit(id);
}

if (value ==
'delete') {
_deleteUser(id);
}
},

itemBuilder:
(context) => const [

PopupMenuItem(
value: 'edit',

child: Row(
children: [
Icon(
Icons.edit_outlined,
),

SizedBox(
width: 10,
),

Text('Edit'),
],
),
),

PopupMenuItem(
value: 'delete',

child: Row(
children: [
Icon(
Icons.delete_outline,
color:
Colors.red,
),

SizedBox(
width: 10,
),

Text(
'Delete',
style:
TextStyle(
color:
Colors.red,
),
),
],
),
),
],
),
),
],
);
}).toList(),
),
),
),
),

// =========================
// FOOTER
// =========================

Padding(
padding:
const EdgeInsets.all(16),

child: Text(
'Showing ${filteredUsers.length} of ${users.length} users',

style: TextStyle(
color:
scheme.onSurfaceVariant,
),
),
),
],
),
);
},
),
);
}
}

