import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import 'predict_mode_screen.dart';
import 'analysis_mode_screen.dart';
import 'package:insights_pro_flutter_frontend/widgets/app_drawer.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final dataset = appState.currentDataset;

    if (dataset == null) {
      // Should not happen if navigation logic is correct, but good for safety
      return Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: const Text('Insights Pro Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => appState.logout(),
            ),
          ],
        ),
        body: const Center(
          child: Text(
            'No Dataset Loaded. Please upload one.',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: Text('Insights Pro - ${dataset.filename}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => appState.logout(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.insights), text: 'Predict'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Visualize'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Predict Mode
            PredictModeScreen(fileId: dataset.fileId, columns: dataset.columns),

            // Visualize Mode
            AnalysisModeScreen(
              mode: AnalysisMode.visualize,
              fileId: dataset.fileId,
              columns: dataset.columns,
            ),
          ],
        ),
      ),
    );
  }
}
