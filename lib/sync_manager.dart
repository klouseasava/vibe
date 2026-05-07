import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'sync_db.dart';

class VibeSyncManager {
  void startListening(String backendUrl) {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      if (result != ConnectivityResult.none) {
        _processSyncQueue(backendUrl);
      }
    });
  }

  Future<void> _processSyncQueue(String backendUrl) async {
    final pendingSigns = await SyncDatabase.instance.getPendingSigns();
    if (pendingSigns.isEmpty) return;

    print("Vibe: Internet detected. Syncing ${pendingSigns.length} signs...");

    for (var sign in pendingSigns) {
      try {
        final response = await http.post(
          Uri.parse('$backendUrl/educate'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "user_id": "offline_user", // Recovered ID
            "sign_name": sign['sign_name'],
            "country": sign['country'],
            "landmarks": jsonDecode(sign['landmarks_json']),
          }),
        );

        if (response.statusCode == 200) {
          await SyncDatabase.instance.deleteSign(sign['id']);
          print("Successfully synced: ${sign['sign_name']}");
        }
      } catch (e) {
        print("Sync failed for sign ${sign['id']}, retrying later.");
      }
    }
  }
}
