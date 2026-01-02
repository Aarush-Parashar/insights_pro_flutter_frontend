import 'package:flutter/material.dart';
import 'package:insights_pro_flutter_frontend/models/models.dart';
import 'package:insights_pro_flutter_frontend/services/api_service.dart';

class AppState extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // --- Auth State ---
  String? _userId;
  String? _token;
  bool _isFirstTimeUser = false;

  bool get isAuthenticated => _userId != null;
  String? get token => _token;
  bool get isFirstTimeUser => _isFirstTimeUser;

  // --- Data State ---
  UploadResponse? _currentDataset;

  UploadResponse? get currentDataset => _currentDataset;

  // --- Auth Methods (Mocking Supabase) ---

  Future<void> signup(String email, String password) async {
    try {
      final response = await _apiService.signup(email, password);
      _userId = response.userId;
      _token = response.token;
      _isFirstTimeUser = response.isFirstTimeUser;
      notifyListeners();
    } catch (e) {
      // In a real app, you'd handle Supabase exceptions here
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      _userId = response.userId;
      _token = response.token;
      _isFirstTimeUser = response.isFirstTimeUser;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void logout() {
    _userId = null;
    _token = null;
    _isFirstTimeUser = false;
    _currentDataset = null;
    notifyListeners();
  }

  // --- Data Methods ---

  void markOnboardingComplete() {
    _isFirstTimeUser = false;
    notifyListeners();
  }

  void setCurrentDataset(UploadResponse dataset) {
    _currentDataset = dataset;
    notifyListeners();
  }

  void clearCurrentDataset() {
    _currentDataset = null;
    notifyListeners();
  }

  Future<void> switchDataset(String filename) async {
    if (_token == null) return;

    try {
      // Fetch columns/ID for the selected file
      final response = await _apiService.loadFileMetadata(filename, _token!);
      _currentDataset = response;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
