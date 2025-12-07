import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

const MONGO_URI = 'mongodb+srv://cartLink_mongodb:CartLink123@cartlink.edvcqv6.mongodb.net/Cart_Link?appName=CartLink';
const SHOPS_COLLECTION = 'Shops';

// Backend base URLs for different platforms.
const String kBackendLocalhost = 'http://localhost:5000';
const String kBackendAndroidEmulator = 'http://10.0.2.2:5000';

/// Base URL for the backend depending on the current platform.
String get backendBaseUrl {
	if (kIsWeb) return kBackendLocalhost;
	if (defaultTargetPlatform == TargetPlatform.android) {
		return kBackendAndroidEmulator;
	}
	return kBackendLocalhost;
}

/// Build a full backend URL from a path (with optional query parameters).
String backendUrl(String path, {Map<String, dynamic>? queryParameters}) =>
		backendUri(path, queryParameters: queryParameters).toString();

/// Build a backend Uri from a path (ensures leading slash and query params as strings).
Uri backendUri(String path, {Map<String, dynamic>? queryParameters}) {
	final normalizedPath = path.startsWith('/') ? path : '/$path';
	final qp = queryParameters?.map(
		(k, v) => MapEntry(k, v?.toString()),
	);
	return Uri.parse('$backendBaseUrl$normalizedPath')
			.replace(queryParameters: qp);
}

// Common API paths
const String kApiAuth = '/api/auth';
const String kApiCustomerAuth = '/api/customersAuth';
const String kApiCustomers = '/api/customers';
const String kApiShops = '/api/Shops';
const String kApiProducts = '/api/products';
const String kApiCart = '/api/cart';