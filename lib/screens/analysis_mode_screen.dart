import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';
import '../models/models.dart';

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
  String? _targetVariable;
  final Map<String, String> _preprocessingConfig = {};

  dynamic _analysisResult; // VisualizationData or ForecastData

  bool _isLoading = false;
  String? _error;

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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),

          Text(
            widget.mode == AnalysisMode.visualize
                ? 'Select Value to Visualize'
                : 'Select Value to Forecast',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Choose the numeric column you want to analyze. The AI will automatically detect the best way to plot it.",
            style: TextStyle(color: Colors.grey),
          ),

          // --- NEW WARNING NOTE ---
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED), // Light orange background
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFDBA74),
              ), // Orange border
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Important: Do NOT select a Date/Time column here. Select the value you want to predict (e.g., Sales, Price, Score).",
                    style: TextStyle(
                      color: Color(0xFFC2410C), // Dark orange text
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ------------------------
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            value: _targetVariable,
            decoration: const InputDecoration(
              labelText: 'Target Column',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.show_chart),
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

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _runAnalysis,
              icon: Icon(
                widget.mode == AnalysisMode.visualize
                    ? Icons.analytics
                    : Icons.timeline,
              ),
              label: Text(
                widget.mode == AnalysisMode.visualize
                    ? 'Generate Visualization'
                    : 'Run Forecast',
                style: const TextStyle(fontSize: 16),
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

  Widget _buildVisualizationChart(VisualizationData data) {
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 400,
            child: ScatterChart(
              ScatterChartData(
                scatterSpots: spots.map((e) => ScatterSpot(e.x, e.y)).toList(),
                minX: spots.isEmpty
                    ? 0
                    : spots.map((e) => e.x).reduce((a, b) => a < b ? a : b) *
                          0.9,
                maxX: spots.isEmpty
                    ? 10
                    : spots.map((e) => e.x).reduce((a, b) => a > b ? a : b) *
                          1.1,
                minY: spots.isEmpty
                    ? 0
                    : spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) *
                          0.9,
                maxY: spots.isEmpty
                    ? 10
                    : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) *
                          1.1,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(data.yLabel),
                    sideTitles: const SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text(data.xLabel),
                    sideTitles: const SideTitles(
                      showTitles: true,
                      reservedSize: 30,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastChart(ForecastData data) {
    final historicalSpots = data.historical.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['value'] as double);
    }).toList();

    final forecastSpots = data.forecast.asMap().entries.map((entry) {
      return FlSpot(
        (data.historical.length + entry.key).toDouble(),
        entry.value['value'] as double,
      );
    }).toList();

    final allSpots = [...historicalSpots, ...forecastSpots];

    if (allSpots.isEmpty) {
      return const Center(child: Text("Not enough data to plot."));
    }

    double minY = allSpots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    double maxY = allSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            data.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 400,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (allSpots.length - 1).toDouble(),
                minY: minY * 0.9,
                maxY: maxY * 1.1,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(data.valueLabel),
                    sideTitles: const SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text(data.timeLabel),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (allSpots.length / 5).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= allSpots.length)
                          return const Text('');

                        String dateString = "";
                        if (index < data.historical.length) {
                          dateString = data.historical[index]['date']
                              .toString();
                        } else {
                          int fIndex = index - data.historical.length;
                          if (fIndex < data.forecast.length) {
                            dateString = data.forecast[fIndex]['date']
                                .toString();
                          }
                        }

                        if (dateString.length > 5) {
                          dateString = dateString.substring(5);
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
                  LineChartBarData(
                    spots: historicalSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: forecastSpots,
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    dashArray: [5, 5],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 12, height: 12, color: Colors.blue),
              const SizedBox(width: 4),
              const Text("History"),
              const SizedBox(width: 20),
              Container(width: 12, height: 12, color: Colors.red),
              const SizedBox(width: 4),
              const Text("Forecast"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
      child: Column(
        children: [
          Text(
            widget.mode == AnalysisMode.visualize
                ? 'Visualize Data'
                : 'Forecast Trends',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Divider(),
          Expanded(
            child: _analysisResult == null
                ? _buildConfigurationStep()
                : _buildResultView(),
          ),
        ],
      ),
    );
  }
}
