import 'dart:convert';
import 'package:flutter/foundation.dart';

// --- Auth Models ---

class AuthResponse {
  final String userId;
  final String token;
  final bool isFirstTimeUser;

  AuthResponse({
    required this.userId,
    required this.token,
    required this.isFirstTimeUser,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      userId: json['user_id'] as String,
      token: json['token'] as String,
      isFirstTimeUser: json['is_first_time_user'] as bool,
    );
  }
}

// --- Data Upload Model ---

class UploadResponse {
  final String fileId;
  final String filename;
  final List<String> columns;

  UploadResponse({
    required this.fileId,
    required this.filename,
    required this.columns,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      fileId: json['file_id'] as String,
      filename: json['filename'] as String,
      columns: List<String>.from(json['columns'] as List),
    );
  }
}

// --- Preprocessing Config Model ---

class PreprocessingConfig {
  // FIX: Changed from List<Map<String, String>> to Map<String, String>
  final Map<String, String> config;
  final String targetVariable;

  PreprocessingConfig({required this.config, required this.targetVariable});

  Map<String, dynamic> toJson() {
    return {'config': config, 'target_variable': targetVariable};
  }
}

// --- Dynamic Input Model (for Prediction) ---

class PredictionInputData {
  final String name;
  final String inputtype; // "Dropdown" or "Number"
  final String placeholder;
  final List<String>? values; // For Dropdown
  final double? min; // For Number
  final double? max; // For Number

  PredictionInputData({
    required this.name,
    required this.inputtype,
    required this.placeholder,
    this.values,
    this.min,
    this.max,
  });

  factory PredictionInputData.fromJson(Map<String, dynamic> json) {
    return PredictionInputData(
      name: json['name'] as String,
      inputtype: json['inputtype'] as String,
      placeholder: json['placeholder'] as String,
      values: json['values'] != null
          ? List<String>.from(json['values'] as List)
          : null,
      min: json['min'] != null ? (json['min'] as num).toDouble() : null,
      max: json['max'] != null ? (json['max'] as num).toDouble() : null,
    );
  }
}

// --- Model Selection Model ---

class ModelSelectionResponse {
  final Map<String, String> modelNames;
  final List<PredictionInputData> predictionInputData;

  ModelSelectionResponse({
    required this.modelNames,
    required this.predictionInputData,
  });

  factory ModelSelectionResponse.fromJson(Map<String, dynamic> json) {
    // FIX: Backend returns a single JSON object with snake_case keys

    // 1. Extract Model Names safely
    final modelNamesJson = json['model_names'] as Map<String, dynamic>? ?? {};
    final modelNames = modelNamesJson.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    // 2. Extract Prediction Input Data safely
    final predictionInputDataJson =
        json['prediction_input_data'] as List<dynamic>? ?? [];
    final predictionInputData = predictionInputDataJson
        .map((e) => PredictionInputData.fromJson(e as Map<String, dynamic>))
        .toList();

    return ModelSelectionResponse(
      modelNames: modelNames,
      predictionInputData: predictionInputData,
    );
  }
}
// --- Prediction Result Model ---

class PredictionResult {
  final String prediction;
  final String confidence;

  PredictionResult({required this.prediction, required this.confidence});

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      prediction: json['prediction'] as String,
      confidence: json['confidence'] as String,
    );
  }
}

// --- Visualization Data Model ---

class VisualizationData {
  final String chartType;
  final String title;
  final List<Map<String, double>> data; // [{"x": 1.0, "y": 2.5}, ...]
  final String xLabel;
  final String yLabel;

  VisualizationData({
    required this.chartType,
    required this.title,
    required this.data,
    required this.xLabel,
    required this.yLabel,
  });

  factory VisualizationData.fromJson(Map<String, dynamic> json) {
    return VisualizationData(
      chartType: json['chart_type'] as String,
      title: json['title'] as String,
      data: (json['data'] as List)
          .map(
            (e) => Map<String, double>.from(
              e.map((k, v) => MapEntry(k, (v as num).toDouble())),
            ),
          )
          .toList(),
      xLabel: json['x_label'] as String,
      yLabel: json['y_label'] as String,
    );
  }
}

// --- Forecast Data Model ---

class ForecastData {
  final String chartType;
  final String title;
  final List<Map<String, dynamic>>
  historical; // [{"date": "...", "value": 1.0}, ...]
  final List<Map<String, dynamic>>
  forecast; // [{"date": "...", "value": 1.0}, ...]
  final String timeLabel;
  final String valueLabel;

  ForecastData({
    required this.chartType,
    required this.title,
    required this.historical,
    required this.forecast,
    required this.timeLabel,
    required this.valueLabel,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    return ForecastData(
      chartType: json['chart_type'] as String,
      title: json['title'] as String,
      historical: List<Map<String, dynamic>>.from(json['historical'] as List),
      forecast: List<Map<String, dynamic>>.from(json['forecast'] as List),
      timeLabel: json['time_label'] as String,
      valueLabel: json['value_label'] as String,
    );
  }
}

// --- Preprocessing Question Model ---

class PreprocessingQuestion {
  final String key;
  final String question;
  final String type; // "radio" or "dropdown"
  final List<String> options;

  PreprocessingQuestion({
    required this.key,
    required this.question,
    required this.type,
    required this.options,
  });

  factory PreprocessingQuestion.fromJson(Map<String, dynamic> json) {
    return PreprocessingQuestion(
      key: json['key'] as String,
      question: json['question'] as String,
      type: json['type'] as String,
      options: List<String>.from(json['options'] as List),
    );
  }
}
