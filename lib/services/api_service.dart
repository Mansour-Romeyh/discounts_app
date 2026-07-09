import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coupon.dart';
import '../models/api_models.dart';

class ApiService {
  static const String baseUrl = 'https://couponey.net';
  static bool isOfflineMode = false;

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // ─── Cache Helpers ──────────────────────────────────────────────
  static Future<void> _setCache(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }

  static Future<String?> _getCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  // ─── Full bundle /api/home ────────────────────────────────────────
  static Future<HomeBundle> fetchHome() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/home'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        isOfflineMode = false;
        await _setCache('cached_home', res.body);
        return HomeBundle.fromJson(jsonDecode(res.body));
      }
      throw Exception('fetchHome failed (${res.statusCode})');
    } catch (e) {
      final cached = await _getCache('cached_home');
      if (cached != null) {
        isOfflineMode = true;
        return HomeBundle.fromJson(jsonDecode(cached));
      }
      rethrow;
    }
  }

  // ─── /api/site ────────────────────────────────────────────────────
  static Future<SiteInfo> fetchSite() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/site'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        isOfflineMode = false;
        await _setCache('cached_site', res.body);
        final data = jsonDecode(res.body);
        return SiteInfo.fromJson(data is Map ? (data['data'] ?? data) : {});
      }
      throw Exception('fetchSite failed (${res.statusCode})');
    } catch (e) {
      final cached = await _getCache('cached_site');
      if (cached != null) {
        isOfflineMode = true;
        final data = jsonDecode(cached);
        return SiteInfo.fromJson(data is Map ? (data['data'] ?? data) : {});
      }
      rethrow;
    }
  }

  // ─── /api/hero (also used for footer) ────────────────────────────
  static Future<HeroData> fetchHero() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/hero'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        isOfflineMode = false;
        await _setCache('cached_hero', res.body);
        final data = jsonDecode(res.body);
        return HeroData.fromJson(data is Map ? (data['data'] ?? data) : {});
      }
      throw Exception('fetchHero failed (${res.statusCode})');
    } catch (e) {
      final cached = await _getCache('cached_hero');
      if (cached != null) {
        isOfflineMode = true;
        final data = jsonDecode(cached);
        return HeroData.fromJson(data is Map ? (data['data'] ?? data) : {});
      }
      rethrow;
    }
  }

  // ─── /api/offers ─────────────────────────────────────────────────
  static Future<List<Store>> fetchOffers() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/offers'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        isOfflineMode = false;
        await _setCache('cached_offers', res.body);
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['data'] ?? data['offers'] ?? []);
        return (list as List).map((e) => Store.fromJson(e)).toList();
      }
      throw Exception('fetchOffers failed (${res.statusCode})');
    } catch (e) {
      final cached = await _getCache('cached_offers');
      if (cached != null) {
        isOfflineMode = true;
        final data = jsonDecode(cached);
        final list = data is List ? data : (data['data'] ?? data['offers'] ?? []);
        return (list as List).map((e) => Store.fromJson(e)).toList();
      }
      rethrow;
    }
  }

  // ─── /api/stores ─────────────────────────────────────────────────
  static Future<List<Store>> fetchStores() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/stores'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        isOfflineMode = false;
        await _setCache('cached_stores', res.body);
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['data'] ?? data['stores'] ?? []);
        return (list as List).map((e) => Store.fromJson(e)).toList();
      }
      throw Exception('fetchStores failed (${res.statusCode})');
    } catch (e) {
      final cached = await _getCache('cached_stores');
      if (cached != null) {
        isOfflineMode = true;
        final data = jsonDecode(cached);
        final list = data is List ? data : (data['data'] ?? data['stores'] ?? []);
        return (list as List).map((e) => Store.fromJson(e)).toList();
      }
      rethrow;
    }
  }

  // ─── /api/stores/for-filters ─────────────────────────────────────
  static Future<List<String>> fetchStoresForFilters() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/stores/for-filters'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        isOfflineMode = false;
        await _setCache('cached_stores_filters', res.body);
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['data'] ?? []);
        return (list as List)
            .map((e) => e['name']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }
      throw Exception('fetchStoresForFilters failed (${res.statusCode})');
    } catch (e) {
      final cached = await _getCache('cached_stores_filters');
      if (cached != null) {
        isOfflineMode = true;
        final data = jsonDecode(cached);
        final list = data is List ? data : (data['data'] ?? []);
        return (list as List)
            .map((e) => e['name']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }
      rethrow;
    }
  }

  // ─── /api/labels ─────────────────────────────────────────────────
  static Future<AppLabels> fetchLabels() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/labels'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        isOfflineMode = false;
        await _setCache('cached_labels', res.body);
        final data = jsonDecode(res.body);
        return AppLabels.fromJson(data is Map ? (data['data'] ?? data) : {});
      }
      throw Exception('fetchLabels failed (${res.statusCode})');
    } catch (e) {
      final cached = await _getCache('cached_labels');
      if (cached != null) {
        isOfflineMode = true;
        final data = jsonDecode(cached);
        return AppLabels.fromJson(data is Map ? (data['data'] ?? data) : {});
      }
      rethrow;
    }
  }

  // ─── /api/coupons/{type} ─────────────────────────────────────────
  static Future<List<Coupon>> fetchCoupons({String type = 'latest'}) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/coupons/$type'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        isOfflineMode = false;
        await _setCache('cached_coupons_$type', res.body);
        final data = jsonDecode(res.body);
        final list =
            data is List ? data : (data['data'] ?? data['coupons'] ?? []);
        return (list as List).map((e) => Coupon.fromJson(e)).toList();
      }
      throw Exception('fetchCoupons($type) failed (${res.statusCode})');
    } catch (e) {
      final cached = await _getCache('cached_coupons_$type');
      if (cached != null) {
        isOfflineMode = true;
        final data = jsonDecode(cached);
        final list =
            data is List ? data : (data['data'] ?? data['coupons'] ?? []);
        return (list as List).map((e) => Coupon.fromJson(e)).toList();
      }
      rethrow;
    }
  }

  // ─── كل الكوبونات من الـ 3 endpoints ────────────────────────────
  static Future<List<Coupon>> fetchAllCoupons() async {
    final results = await Future.wait([
      fetchCoupons(type: 'latest').catchError((_) => <Coupon>[]),
      fetchCoupons(type: 'most-used').catchError((_) => <Coupon>[]),
      fetchCoupons(type: 'high-discount').catchError((_) => <Coupon>[]),
    ]);
    final all = <Coupon>[];
    final seen = <String>{};
    for (final list in results) {
      for (final c in list) {
        if (seen.add(c.id)) all.add(c);
      }
    }
    return all;
  }

  // ─── /api/app-download ───────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchAppDownload() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/app-download'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        isOfflineMode = false;
        await _setCache('cached_app_download', res.body);
        final data = jsonDecode(res.body);
        return data is Map<String, dynamic> ? data : {};
      }
      return {};
    } catch (e) {
      final cached = await _getCache('cached_app_download');
      if (cached != null) {
        isOfflineMode = true;
        final data = jsonDecode(cached);
        return data is Map<String, dynamic> ? data : {};
      }
      return {};
    }
  }

  // ─── /api/footer ─────────────────────────────────────────────────
  static Future<FooterData> fetchFooter() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/footer'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        isOfflineMode = false;
        await _setCache('cached_footer', res.body);
        final data = jsonDecode(res.body);
        return FooterData.fromJson(data is Map ? (data['data'] ?? data) : {});
      }
      throw Exception('fetchFooter failed (${res.statusCode})');
    } catch (e) {
      final cached = await _getCache('cached_footer');
      if (cached != null) {
        isOfflineMode = true;
        final data = jsonDecode(cached);
        return FooterData.fromJson(data is Map ? (data['data'] ?? data) : {});
      }
      rethrow;
    }
  }

  // ─── Newsletter Subscribe ─────────────────────────────────────────
  static Future<bool> subscribeNewsletter(String email) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/newsletter/subscribe'),
    );
    request.headers['Accept'] = 'application/json';
    request.fields['email'] = email;

    final streamed = await request.send().timeout(const Duration(seconds: 10));
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200 || res.statusCode == 201) return true;

    try {
      final data = jsonDecode(res.body);
      final msg = data['message']?.toString() ?? '';
      throw Exception(
          msg.isNotEmpty ? msg : 'فشل الاشتراك (${res.statusCode})');
    } catch (_) {
      throw Exception('فشل الاشتراك (${res.statusCode})');
    }
  }
}
