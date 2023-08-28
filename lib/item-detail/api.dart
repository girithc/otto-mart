import 'dart:typed_data';

import 'package:gcloud/storage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:mime/mime.dart';

class CloudApi {
  final auth.ServiceAccountCredentials _credentials;
  late auth.AutoRefreshingAuthClient _client;

  CloudApi(String json)
      : _credentials = auth.ServiceAccountCredentials.fromJson(json) {
    _initializeClient();
  }

  Future<void> _initializeClient() async {
    _client = await auth.clientViaServiceAccount(_credentials, Storage.SCOPES);
  }

  Future<ObjectInfo> save(String name, Uint8List imgBytes) async {
    await _initializeClient();

    var storage = Storage(_client, 'Image Upload Google Storage');
    var bucket = storage.bucket('pronto-bucket');

    final type = lookupMimeType(name);

    return await bucket.writeBytes(name, imgBytes,
        metadata: ObjectMetadata(contentType: type));
  }
}
