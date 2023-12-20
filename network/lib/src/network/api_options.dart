part of 'rest_client.dart';

/// Enum representing the type of API, either public or protected.
enum APIType { public, protected }

enum TokenType { bearer, basic }

/// Abstract class representing options for making API requests.
abstract class ApiOptions {
  /// Options object with default configurations for API requests.
  Options options = Options();
}

/// Class representing API options for public endpoints.
class PublicApiOptions extends ApiOptions {
  /// Constructor initializes [options] with headers for public API requests.
  PublicApiOptions() {
    super.options.headers = <String, dynamic>{
      'Accept': 'application/json',
      'Content-type': 'application/json',
    };
  }
}

/// Class representing API options for protected endpoints.
class ProtectedApiOptions extends ApiOptions {
  /// Constructor initializes [options] with headers for protected API requests.
  /// [apiToken] - The authorization token for accessing protected endpoints.
  ProtectedApiOptions(String apiToken) {
    super.options.headers = <String, dynamic>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': apiToken,
    };
  }
}
