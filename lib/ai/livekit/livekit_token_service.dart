import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> fetchLiveKitToken({
  required String room,
  required String identity,
}) async {
  final response = await http.post(
    Uri.parse("https://optima-livekit-token-server.onrender.com/getToken"),
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "room": room,
      "identity": identity,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['token'];
  } else {
    throw Exception("Failed to fetch token: ${response.body}");
  }
}
