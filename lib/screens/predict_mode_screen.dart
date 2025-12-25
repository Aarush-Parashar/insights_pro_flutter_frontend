import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/dynamic_form.dart';

class PredictModeScreen extends StatefulWidget {
  final String fileId;
  final List<String> columns;

  const PredictModeScreen({
    super.key,
    required this.fileId,
    required this.columns,
  });

  @override
  State<PredictModeScreen> createState() => _PredictModeScreenState();
}

class _PredictModeScreenState extends State<PredictModeScreen> {
  int _currentStep = 0;
  List<PreprocessingQuestion>? _questions;
  Map<String, String> _preprocessingConfig = {};
  String? _targetVariable;

  ModelSelectionResponse? _modelSelectionResponse;
  String? _selectedModel;

  Map<String, dynamic> _predictionInputData = {};
  PredictionResult? _predictionResult;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = Provider.of<AppState>(context, listen: false).token;
      _questions = await ApiService().getPredictQuestions(token!);
    } catch (e) {
      _error = 'Failed to load questions: ${e.toString()}';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getModelSelection() async {
    if (_targetVariable == null) {
      setState(() => _error = 'Please select a target variable.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = Provider.of<AppState>(context, listen: false).token;
      final config = PreprocessingConfig(
        config: _preprocessingConfig,
        targetVariable: _targetVariable!,
      );

      _modelSelectionResponse = await ApiService().getModelSelection(
        widget.fileId,
        config,
        token!,
      );
      _selectedModel =
          _modelSelectionResponse!.modelNames.keys.first; // Default selection

      // Initialize prediction input data map
      for (var input in _modelSelectionResponse!.predictionInputData) {
        if (input.inputtype == 'Dropdown' &&
            input.values != null &&
            input.values!.isNotEmpty) {
          _predictionInputData[input.name] = input.values!.first;
        } else {
          _predictionInputData[input.name] = null;
        }
      }

      setState(() {
        _currentStep = 1;
      });
    } catch (e) {
      _error = 'Failed to get model selection: ${e.toString()}';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getPrediction() async {
    // Basic validation for prediction inputs
    for (var input in _modelSelectionResponse!.predictionInputData) {
      if (_predictionInputData[input.name] == null) {
        setState(() => _error = 'Please fill all prediction inputs.');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = Provider.of<AppState>(context, listen: false).token;
      _predictionResult = await ApiService().getPrediction(
        widget.fileId,
        _predictionInputData,
        token!,
      );

      setState(() {
        _currentStep = 2;
      });
    } catch (e) {
      _error = 'Failed to get prediction: ${e.toString()}';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0: // Configuration
        return _buildConfigurationStep();
      case 1: // Model Selection & Prediction Input
        return _buildPredictionInputStep();
      case 2: // Output
        return _buildOutputStep();
      default:
        return const Center(child: Text('Unknown Step'));
    }
  }

  Widget _buildConfigurationStep() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_questions == null) {
      return const Center(child: Text('Loading questions...'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Target Variable Selection
          const Text(
            '1. Select Target Variable',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _targetVariable,
            decoration: const InputDecoration(
              labelText: 'Target Column',
              border: OutlineInputBorder(),
            ),
            items: widget.columns.map((col) {
              return DropdownMenuItem(value: col, child: Text(col));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _targetVariable = value;
              });
            },
            validator: (value) => value == null ? 'Required' : null,
          ),
          const SizedBox(height: 30),

          // Preprocessing Configuration
          const Text(
            '2. Preprocessing Configuration',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          DynamicForm(
            questions: _questions!,
            onConfigChanged: (config) {
              _preprocessingConfig = config;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _getModelSelection,
            child: const Text('Proceed to Model Selection'),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionInputStep() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_modelSelectionResponse == null) {
      return const Center(child: Text('Model selection data not loaded.'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Model Selection
          const Text(
            '1. Model Selection (Sorted by Accuracy)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedModel,
            decoration: const InputDecoration(
              labelText: 'Select Model',
              border: OutlineInputBorder(),
            ),
            items: _modelSelectionResponse!.modelNames.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text('${entry.key} (${entry.value})'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedModel = value;
              });
            },
          ),
          const SizedBox(height: 30),

          // Prediction Input (Dynamic UI)
          const Text(
            '2. Enter Prediction Data',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ..._modelSelectionResponse!.predictionInputData.map((input) {
            if (input.inputtype == 'Dropdown') {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: DropdownButtonFormField<String>(
                  value: _predictionInputData[input.name] as String?,
                  decoration: InputDecoration(
                    labelText: input.name,
                    border: const OutlineInputBorder(),
                  ),
                  items: input.values!.map((value) {
                    return DropdownMenuItem(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _predictionInputData[input.name] = value;
                    }
                  },
                  validator: (value) => value == null ? 'Required' : null,
                ),
              );
            } else if (input.inputtype == 'Number') {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: input.name,
                    hintText: input.placeholder,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _predictionInputData[input.name] = double.tryParse(value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final numValue = double.tryParse(value);
                    if (numValue == null) return 'Must be a number';
                    if (input.min != null && numValue < input.min!)
                      return 'Min: ${input.min}';
                    if (input.max != null && numValue > input.max!)
                      return 'Max: ${input.max}';
                    return null;
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          }).toList(),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _getPrediction,
            child: const Text('Get Prediction'),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputStep() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_predictionResult == null) {
      return const Center(child: Text('No prediction result available.'));
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Prediction Result',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Text(
                    'Predicted Value:',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _predictionResult!.prediction,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Confidence: ${_predictionResult!.confidence}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _currentStep = 0;
                _modelSelectionResponse = null;
                _predictionResult = null;
                _targetVariable = null;
                _preprocessingConfig = {};
                _predictionInputData = {};
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Start New Prediction'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Predict Mode - Step ${_currentStep + 1}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Expanded(child: _buildStepContent(_currentStep)),
        ],
      ),
    );
  }
}
