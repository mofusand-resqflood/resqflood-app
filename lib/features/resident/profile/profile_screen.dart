import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatelessWidget {
const ProfileScreen({super.key});

Future _confirmSignOut(BuildContext context) async {
final confirmed = await showDialog(
context: context,
builder: (dialogContext) => AlertDialog(
title: const Text('Sign out?'),
content: const Text(
'You will need your phone number and an OTP to sign in again.',
),
actions: [
TextButton(
onPressed: () => Navigator.pop(dialogContext, false),
child: const Text('Cancel'),
),
FilledButton(
onPressed: () => Navigator.pop(dialogContext, true),
child: const Text('Sign out'),
),
],
),
);

if (confirmed != true) return;

// AuthGate listens to onAuthStateChange and returns to Welcome.
await Supabase.instance.client.auth.signOut();
}

@OverRide
Widget build(BuildContext context) {
final phone = Supabase.instance.client.auth.currentUser?.phone ?? '';

return Scaffold(
  appBar: AppBar(title: const Text('Profile')),
  body: ListView(
    padding: const EdgeInsets.all(8),
    children: [
      ListTile(
        leading: const Icon(Icons.phone_outlined),
        title: const Text('Phone number'),
        subtitle: Text(phone.isEmpty ? 'Not available' : phone),
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Sign out'),
        onTap: () => _confirmSignOut(context),
      ),
    ],
  ),
);
}
}