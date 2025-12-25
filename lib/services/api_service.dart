import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:insights_pro_flutter_frontend/models/models.dart';
import 'package:insights_pro_flutter_frontend/secrets.dart';

class ApiService {
  final String _baseUrl = backendBaseUrl;

  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Auth Endpoints ---

  Future<AuthResponse> signup(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/signup'),
      headers: _getHeaders(null),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return AuthResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to sign up: ${jsonDecode(response.body)['detail']}',
      );
    }
  }

  Future<AuthResponse> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: _getHeaders(null),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return AuthResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to log in: ${jsonDecode(response.body)['detail']}',
      );
    }
  }

  // --- Data Upload Endpoint ---

  Future<UploadResponse> uploadFile(PlatformFile file, String token) async {
    var uri = Uri.parse('$_baseUrl/data/upload');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name),
      );

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return UploadResponse.fromJson(jsonDecode(responseBody));
    } else {
      throw Exception(
        'Failed to upload file: ${jsonDecode(responseBody)['detail']}',
      );
    }
  }

  // --- File Management ---

  Future<List<String>> getUserFiles(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/data/files'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['files']);
    } else {
      throw Exception('Failed to load files');
    }
  }

  Future<UploadResponse> loadFileMetadata(String filename, String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/data/load/$filename'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return UploadResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load file metadata');
    }
  }

  // --- Predict Endpoints ---

  Future<List<PreprocessingQuestion>> getPredictQuestions(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/predict/questions'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((json) => PreprocessingQuestion.fromJson(json))
          .toList();
    } else {
      throw Exception(
        'Failed to load prediction questions: ${jsonDecode(response.body)['detail']}',
      );
    }
  }

  Future<ModelSelectionResponse> getModelSelection(
    String fileId,
    PreprocessingConfig config,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/predict/model_selection/$fileId'),
      headers: _getHeaders(token),
      body: jsonEncode(config.toJson()),
    );

    if (response.statusCode == 200) {
      // FIX: The backend returns a single Map, NOT a List.
      // We pass the body directly to fromJson.
      final Map<String, dynamic> jsonMap = jsonDecode(response.body);

      return ModelSelectionResponse.fromJson(jsonMap);
    } else {
      throw Exception(
        'Failed to get model selection: ${jsonDecode(response.body)['detail']}',
      );
    }
  }

  Future<PredictionResult> getPrediction(
    String fileId,
    Map<String, dynamic> predictionData,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/predict/result/$fileId'),
      headers: _getHeaders(token),
      body: jsonEncode(predictionData),
    );

    if (response.statusCode == 200) {
      return PredictionResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to get prediction: ${jsonDecode(response.body)['detail']}',
      );
    }
  }

  // --- Visualize Endpoint ---

  Future<VisualizationData> getVisualization(
    String fileId,
    PreprocessingConfig config,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/visualize/$fileId'),
      headers: _getHeaders(token),
      body: jsonEncode(config.toJson()),
    );

    if (response.statusCode == 200) {
      return VisualizationData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to get visualization: ${jsonDecode(response.body)['detail']}',
      );
    }
  }

  // --- Forecast Endpoint ---

  Future<ForecastData> getForecast(
    String fileId,
    PreprocessingConfig config,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/forecast/$fileId'),
      headers: _getHeaders(token),
      body: jsonEncode(config.toJson()),
    );

    if (response.statusCode == 200) {
      return ForecastData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to get forecast: ${jsonDecode(response.body)['detail']}',
      );
    }
  }
}
