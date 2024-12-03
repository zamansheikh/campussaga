import 'package:googleapis_auth/auth_io.dart';

class GetServerKey {
  Future<String> getServerKey() async {
    final scopes = [
      'https://www.googleapis.com/auth/firebase.messaging',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/userinfo.email',
    ];

    final client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson({
        'private_key_id': 'your_private_key_id',
        'private_key': 'your_private_key',
        'client_email': 'your_client_email',
        'client_id': 'your_client_id',
        'type': 'service_account',
      }),
      scopes,
    );

    // This is a dummy server key, replace it with your own
    return 'AAAA1B2C3D4E:5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T0U';
  }
}
