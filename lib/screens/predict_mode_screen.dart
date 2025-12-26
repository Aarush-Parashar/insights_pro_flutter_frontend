import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

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

  // We removed the complex questions. Now we just need the target.
  String? _targetVariable;
  final Map<String, String> _preprocessingConfig =
      {}; // Sends empty config (Backend uses defaults)

  ModelSelectionResponse? _modelSelectionResponse;
  String? _selectedModel;

  final Map<String, dynamic> _predictionInputData = {};
  PredictionResult? _predictionResult;

  bool _isLoading = false;
  String? _error;

  // --- Step 1: Train Models ---
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

      // We send an empty config, letting the Backend use its "Best Practice" defaults
      final config = PreprocessingConfig(
        config: _preprocessingConfig,
        targetVariable: _targetVariable!,
      );

      _modelSelectionResponse = await ApiService().getModelSelection(
        widget.fileId,
        config,
        token!,
      );

      // Auto-select the best model (first one in the list)
      _selectedModel = _modelSelectionResponse!.modelNames.keys.first;

      // Initialize inputs for the next step
      _predictionInputData.clear();
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
      _error = 'Model training failed: ${e.toString()}';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Step 2: Get Prediction ---
  Future<void> _getPrediction() async {
    // Validate inputs
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
      _error = 'Prediction failed: ${e.toString()}';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- UI Builders ---

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return _buildConfigurationStep();
      case 1:
        return _buildPredictionInputStep();
      case 2:
        return _buildOutputStep();
      default:
        return const Center(child: Text('Unknown Step'));
    }
  }

  Widget _buildConfigurationStep() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),

          const Text(
            'Select Target Variable',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Choose the column you want to predict. The AI will automatically handle missing values and encoding.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            value: _targetVariable,
            decoration: const InputDecoration(
              labelText: 'Target Column',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.track_changes),
            ),
            items: widget.columns.map((col) {
              return DropdownMenuItem(value: col, child: Text(col));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _targetVariable = value;
                _error = null;
              });
            },
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _getModelSelection,
              icon: const Icon(Icons.model_training),
              label: const Text(
                'Train Auto-ML Models',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionInputStep() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_modelSelectionResponse == null)
      return const Center(child: Text('Error loading model.'));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),

          // Model Dropdown
          const Text(
            'Model Performance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedModel,
            decoration: const InputDecoration(
              labelText: 'Selected Model',
              border: OutlineInputBorder(),
            ),
            items: _modelSelectionResponse!.modelNames.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text('${entry.key} (${entry.value})'),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedModel = value),
          ),
          const SizedBox(height: 30),

          // Dynamic Inputs
          const Text(
            'Enter Values to Predict',
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
                    if (value != null) _predictionInputData[input.name] = value;
                  },
                ),
              );
            } else {
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
                ),
              );
            }
          }).toList(),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _getPrediction,
              icon: const Icon(Icons.bolt),
              label: const Text(
                'Predict Result',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputStep() {
    if (_predictionResult == null)
      return const Center(child: Text('No result.'));

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 60),
          const SizedBox(height: 20),
          const Text(
            'Prediction Result',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 32.0,
                horizontal: 48.0,
              ),
              child: Column(
                children: [
                  Text(
                    _predictionResult!.prediction,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Confidence: ${_predictionResult!.confidence}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _currentStep = 0;
                _modelSelectionResponse = null;
                _predictionResult = null;
                _targetVariable = null;
                _predictionInputData.clear();
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Predict Mode',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Chip(
                label: Text("Step ${_currentStep + 1}/3"),
                backgroundColor: Colors.blue.shade50,
              ),
            ],
          ),
          const Divider(),
          Expanded(child: _buildStepContent(_currentStep)),
        ],
      ),
    );
  }
}
