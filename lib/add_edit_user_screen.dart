import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class AddEditUserScreen extends StatefulWidget {
final String token;
final int? id;

const AddEditUserScreen({
super.key,
required this.token,
this.id,
});

@override
State<AddEditUserScreen> createState() =>
_AddEditUserScreenState();
}

class _AddEditUserScreenState
extends State<AddEditUserScreen> {
final _formKey = GlobalKey<FormState>();

final _firstNameController =
TextEditingController();

final _lastNameController =
TextEditingController();

final _userNameController =
TextEditingController();

final _phoneController =
TextEditingController();

final _emailController =
TextEditingController();

final _addressController =
TextEditingController();

final _passwordController =
TextEditingController();

int? _roleId;

String? _existingImagePath;
File? _newProfileImage;

late Future<List<dynamic>> _rolesFuture;

bool _loadingUser = false;
bool _saving = false;

bool _obscurePassword = true;

Future<void> _pickImage() async {
final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
if (picked == null) return;
setState(() => _newProfileImage = File(picked.path));
}

bool get _isEdit => widget.id != null;

@override
void initState() {
super.initState();

_rolesFuture =
ApiService.getRoles(widget.token);

if (_isEdit) {
_loadUser();
}
}

// =========================
// LOAD USER
// =========================

Future<void> _loadUser() async {
setState(() => _loadingUser = true);

try {
final user = await ApiService.getUserById(
widget.token,
widget.id!,
);

_firstNameController.text =
user['FirstName']?.toString() ?? '';

_lastNameController.text =
user['LastName']?.toString() ?? '';

_userNameController.text =
user['UserName']?.toString() ?? '';

_phoneController.text =
user['ContactNo']?.toString() ?? '';

_emailController.text =
user['Email']?.toString() ?? '';

_addressController.text =
user['Address']?.toString() ?? '';

final userType =
user['UserType'] ??
user['UserTypeID'];

if (userType != null) {
_roleId =
int.tryParse(userType.toString());
}

final imagePath =
user['UserImage']?.toString();

if (imagePath != null && imagePath.isNotEmpty) {
_existingImagePath = imagePath;
}
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
} finally {
if (mounted) {
setState(() => _loadingUser = false);
}
}
}

// =========================
// DISPOSE
// =========================

@override
void dispose() {
_firstNameController.dispose();
_lastNameController.dispose();
_userNameController.dispose();
_phoneController.dispose();
_emailController.dispose();
_addressController.dispose();
_passwordController.dispose();

super.dispose();
}

// =========================
// SAVE USER
// =========================

Future<void> _submit() async {
if (!_formKey.currentState!.validate()) {
return;
}

if (_roleId == null) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'Please select a role.',
),
),
);

return;
}

setState(() => _saving = true);

try {
await ApiService.saveUser(
widget.token,

id: widget.id,

firstName:
_firstNameController.text.trim(),

lastName:
_lastNameController.text.trim(),

userName:
_userNameController.text.trim(),

phone:
_phoneController.text.trim(),

password:
_passwordController.text,

email:
_emailController.text.trim(),

address:
_addressController.text.trim(),

userTypeId: _roleId!,

profileImage: _newProfileImage,
);

if (!mounted) return;

Navigator.pop(context, true);
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
} finally {
if (mounted) {
setState(() => _saving = false);
}
}
}

// =========================
// SECTION TITLE
// =========================

Widget _sectionLabel(
BuildContext context,
String text,
) {
return Padding(
padding: const EdgeInsets.only(
bottom: 12,
),

child: Text(
text.toUpperCase(),

style: Theme.of(context)
    .textTheme
    .labelSmall
    ?.copyWith(
letterSpacing: 1,

fontWeight: FontWeight.bold,

color: Theme.of(context)
    .colorScheme
    .onSurfaceVariant,
),
),
);
}

// =========================
// BUILD
// =========================

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);
final scheme = theme.colorScheme;

return Scaffold(
appBar: AppBar(
title: Text(
_isEdit
? 'Edit User'
    : 'Add User',
),

actions: [

TextButton(
onPressed: _saving
? null
    : _submit,

child: Text(
'Save',

style: TextStyle(
color: scheme.primary,

fontWeight: FontWeight.bold,
),
),
),

const SizedBox(width: 8),
],
),

body: _loadingUser

// =========================
// LOADING USER
// =========================

? const Center(
child:
CircularProgressIndicator(),
)

// =========================
// LOAD ROLES
// =========================

    : FutureBuilder<List<dynamic>>(
future: _rolesFuture,

builder: (
context,
snapshot,
) {

if (snapshot.connectionState ==
ConnectionState.waiting) {
return const Center(
child:
CircularProgressIndicator(),
);
}

if (snapshot.hasError) {
return Center(
child: Text(
'Error: ${snapshot.error}',
),
);
}

final roles =
snapshot.data ?? [];

return Form(
key: _formKey,

child: ListView(
padding:
const EdgeInsets.all(16),

children: [

// =========================
// PROFILE AVATAR
// =========================

Center(
child: GestureDetector(
onTap: _pickImage,
child: Stack(
children: [

CircleAvatar(
radius: 42,

backgroundColor:
scheme.primaryContainer,

backgroundImage: _newProfileImage != null
? FileImage(_newProfileImage!)
    : (_existingImagePath != null
? NetworkImage(
'${ApiService.serverOrigin}$_existingImagePath',
)
    : null) as ImageProvider?,

child: (_newProfileImage == null &&
_existingImagePath == null)
? Text(
_firstNameController
    .text
    .isNotEmpty
? _firstNameController
    .text[0]
    .toUpperCase()
    : 'U',

style: TextStyle(
fontSize: 30,

fontWeight:
FontWeight.bold,

color:
scheme.primary,
),
)
    : null,
),

Positioned(
right: 0,
bottom: 0,

child: CircleAvatar(
radius: 15,

backgroundColor:
scheme.primary,

child: Icon(
Icons.camera_alt,

size: 16,

color:
scheme.onPrimary,
),
),
),
],
),
),
),

const SizedBox(height: 28),

// =========================
// PROFILE SECTION
// =========================

_sectionLabel(
context,
'Profile',
),

// FIRST NAME

TextFormField(
controller:
_firstNameController,

decoration:
const InputDecoration(
labelText:
'First Name',

prefixIcon:
Icon(Icons.person_outline),

border:
OutlineInputBorder(),
),

validator: (v) =>
(v == null ||
v.trim().isEmpty)
? 'First name is required'
    : null,
),

const SizedBox(height: 16),

// LAST NAME

TextFormField(
controller:
_lastNameController,

decoration:
const InputDecoration(
labelText:
'Last Name',

prefixIcon:
Icon(Icons.person_outline),

border:
OutlineInputBorder(),
),
),

const SizedBox(height: 16),

// USERNAME

TextFormField(
controller:
_userNameController,

decoration:
const InputDecoration(
labelText:
'Username',

prefixIcon:
Icon(Icons.alternate_email),

border:
OutlineInputBorder(),
),

validator: (v) =>
(v == null ||
v.trim().isEmpty)
? 'Username is required'
    : null,
),

const SizedBox(height: 16),

// EMAIL

TextFormField(
controller:
_emailController,

keyboardType:
TextInputType.emailAddress,

decoration:
const InputDecoration(
labelText:
'Email',

prefixIcon:
Icon(Icons.email_outlined),

border:
OutlineInputBorder(),
),

validator: (v) {
if (v == null ||
v.trim().isEmpty) {
return 'Email is required';
}

if (!v.contains('@')) {
return 'Enter a valid email';
}

return null;
},
),

const SizedBox(height: 16),

// PHONE

TextFormField(
controller:
_phoneController,

keyboardType:
TextInputType.phone,

decoration:
const InputDecoration(
labelText:
'Phone Number',

prefixIcon:
Icon(Icons.phone_outlined),

border:
OutlineInputBorder(),
),

validator: (v) =>
(v == null ||
v.trim().isEmpty)
? 'Phone number is required'
    : null,
),

const SizedBox(height: 16),

// ADDRESS

TextFormField(
controller:
_addressController,

maxLines: 3,

decoration:
const InputDecoration(
labelText:
'Address',

alignLabelWithHint:
true,

prefixIcon:
Icon(Icons.location_on_outlined),

border:
OutlineInputBorder(),
),
),

const SizedBox(height: 28),

// =========================
// ACCESS SECTION
// =========================

_sectionLabel(
context,
'Access',
),

// ROLE

DropdownButtonFormField<int>(
value: _roleId,

decoration:
const InputDecoration(
labelText: 'Role',

prefixIcon:
Icon(Icons.admin_panel_settings_outlined),

border:
OutlineInputBorder(),
),

items: roles.map((r) {

final roleId =
int.tryParse(
(r['id'] ??
r['ID'] ??
r['Id'])
    .toString(),
);

final roleName =
r['name'] ??
r['Name'] ??
'Role';

if (roleId == null) {
return null;
}

return DropdownMenuItem<int>(
value: roleId,

child: Text(
roleName.toString(),
),
);

}).whereType<DropdownMenuItem<int>>().toList(),

onChanged: (value) {
setState(() {
_roleId = value;
});
},

validator: (value) {
if (value == null) {
return 'Please select a role';
}

return null;
},
),

const SizedBox(height: 16),

// PASSWORD

TextFormField(
controller:
_passwordController,

obscureText:
_obscurePassword,

decoration:
InputDecoration(
labelText: _isEdit
? 'New Password (Optional)'
    : 'Password',

prefixIcon:
const Icon(Icons.lock_outline),

border:
const OutlineInputBorder(),

suffixIcon:
IconButton(
icon: Icon(
_obscurePassword
? Icons.visibility_outlined
    : Icons.visibility_off_outlined,
),

onPressed: () {
setState(() {
_obscurePassword =
!_obscurePassword;
});
},
),
),

validator: (v) {
if (_isEdit &&
(v == null ||
v.isEmpty)) {
return null;
}

if (v == null ||
v.length < 6) {
return 'Password must be at least 6 characters';
}

return null;
},
),

const SizedBox(height: 32),

// =========================
// BUTTONS
// =========================

Row(
children: [

Expanded(
child: OutlinedButton(
onPressed: _saving
? null
    : () {
Navigator.pop(
context,
);
},

style:
OutlinedButton.styleFrom(
padding:
const EdgeInsets
    .symmetric(
vertical: 16,
),
),

child:
const Text('Cancel'),
),
),

const SizedBox(width: 12),

Expanded(
child: FilledButton(
onPressed: _saving
? null
    : _submit,

style:
FilledButton.styleFrom(
padding:
const EdgeInsets
    .symmetric(
vertical: 16,
),
),

child: _saving
? SizedBox(
height: 20,
width: 20,

child:
CircularProgressIndicator(
strokeWidth: 2,

color:
scheme.onPrimary,
),
)

    : Text(
_isEdit
? 'Save Changes'
    : 'Add User',
),
),
),
],
),

const SizedBox(height: 20),
],
),
);
},
),
);
}
}

