import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/dynamic_form.dart';

enum AnalysisMode { visualize, forecast }

class AnalysisModeScreen extends StatefulWidget {
  final AnalysisMode mode;
  final String fileId;
  final List<String> columns;

  const AnalysisModeScreen({
    super.key,
    required this.mode,
    required this.fileId,
    required this.columns,
  });

  @override
  State<AnalysisModeScreen> createState() => _AnalysisModeScreenState();
}

class _AnalysisModeScreenState extends State<AnalysisModeScreen> {
  List<PreprocessingQuestion>? _questions;
  Map<String, String> _preprocessingConfig = {};
  String? _targetVariable;

  dynamic _analysisResult; // VisualizationData or ForecastData

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
      // Reusing the same questions as Predict mode for simplicity
      _questions = await ApiService().getPredictQuestions(token!);
    } catch (e) {
      _error = 'Failed to load questions: ${e.toString()}';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runAnalysis() async {
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

      if (widget.mode == AnalysisMode.visualize) {
        _analysisResult = await ApiService().getVisualization(
          widget.fileId,
          config,
          token!,
        );
      } else {
        _analysisResult = await ApiService().getForecast(
          widget.fileId,
          config,
          token!,
        );
      }
    } catch (e) {
      _error = 'Failed to run analysis: ${e.toString()}';
    } finally {
      setState(() {
        _isLoading = false;
      });
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
            onPressed: _runAnalysis,
            child: Text(
              'Run ${widget.mode == AnalysisMode.visualize ? 'Visualization' : 'Forecast'}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizationChart(VisualizationData data) {
    // Simple Scatter Chart using fl_chart
    final spots = data.data.map((point) {
      return FlSpot(point['x']!, point['y']!);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            data.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 400,
            child: ScatterChart(
              ScatterChartData(
                scatterSpots: spots.map((e) => ScatterSpot(e.x, e.y)).toList(),
                minX: spots.map((e) => e.x).reduce((a, b) => a < b ? a : b) - 1,
                maxX: spots.map((e) => e.x).reduce((a, b) => a > b ? a : b) + 1,
                minY: spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 1,
                maxY: spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(data.yLabel),
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text(data.xLabel),
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                gridData: const FlGridData(show: true),
                scatterTouchData: ScatterTouchData(enabled: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastChart(ForecastData data) {
    // Simple Line Chart for historical and forecast data
    final historicalSpots = data.historical.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['value'] as double);
    }).toList();

    final forecastSpots = data.forecast.asMap().entries.map((entry) {
      return FlSpot(
        data.historical.length.toDouble() + entry.key.toDouble(),
        entry.value['value'] as double,
      );
    }).toList();

    final allSpots = [...historicalSpots, ...forecastSpots];

    double minVal = allSpots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    double maxVal = allSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            data.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 400,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: allSpots.length.toDouble() - 1,
                minY: minVal - 10,
                maxY: maxVal + 10,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(data.valueLabel),
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text(data.timeLabel),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        // Display date labels for historical and forecast points
                        int index = value.toInt();
                        if (index < 0 || index >= allSpots.length)
                          return const Text('');

                        String dateString;
                        if (index < data.historical.length) {
                          dateString = data.historical[index]['date']
                              .toString()
                              .substring(5); // MM-DD
                        } else {
                          dateString = data
                              .forecast[index - data.historical.length]['date']
                              .toString()
                              .substring(5); // MM-DD
                        }

                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            dateString,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                gridData: const FlGridData(show: true),
                lineBarsData: [
                  // Historical Data
                  LineChartBarData(
                    spots: historicalSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Forecast Data
                  LineChartBarData(
                    spots: forecastSpots,
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                    dashArray: [5, 5],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_analysisResult == null) {
      return _buildConfigurationStep();
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          if (widget.mode == AnalysisMode.visualize)
            _buildVisualizationChart(_analysisResult as VisualizationData)
          else
            _buildForecastChart(_analysisResult as ForecastData),

          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _analysisResult = null;
                _targetVariable = null;
                _preprocessingConfig = {};
              });
            },
            icon: const Icon(Icons.refresh),
            label: Text(
              'Start New ${widget.mode == AnalysisMode.visualize ? 'Visualization' : 'Forecast'}',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _analysisResult == null
          ? _buildConfigurationStep()
          : _buildResultView(),
    );
  }
}
