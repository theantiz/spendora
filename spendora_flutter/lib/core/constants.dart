import 'package:flutter/foundation.dart';

const int kApiPort = 8080;
const String _apiBaseUrlFromEnv = String.fromEnvironment('API_BASE_URL');

String? _apiToken;

String? get kApiToken => _apiToken;

void setApiToken(String? token) {
  final String trimmed = token?.trim() ?? '';
  _apiToken = trimmed.isEmpty ? null : trimmed;
}

String? get kApiBaseUrlOverride {
  final String trimmed = _apiBaseUrlFromEnv.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return _normalizeBaseUrl(trimmed);
}

String get kResolvedApiBaseUrl {
  final String? override = kApiBaseUrlOverride;
  if (override != null) {
    return override;
  }

  if (kIsWeb) {
    return 'http://localhost:$kApiPort';
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://10.0.2.2:$kApiPort';
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return 'http://localhost:$kApiPort';
    case TargetPlatform.fuchsia:
      return 'http://localhost:$kApiPort';
  }
}

List<String> get kApiBaseUrlCandidates {
  final String? override = kApiBaseUrlOverride;

  final Set<String> candidates = <String>{
    ?override,
    kResolvedApiBaseUrl,
    'http://localhost:$kApiPort',
    'http://127.0.0.1:$kApiPort',
  };

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    candidates.add('http://10.0.2.2:$kApiPort');
    candidates.add('http://10.0.3.2:$kApiPort');
  }

  return candidates.toList();
}

String _normalizeBaseUrl(String baseUrl) {
  final String normalized = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  return normalized;
}
