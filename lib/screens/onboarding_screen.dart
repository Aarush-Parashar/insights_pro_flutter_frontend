import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../state/app_state.dart';
import '../../services/api_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isUploading = false;
  String? _uploadError;

  Future<void> _uploadCsv(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.token == null) {
      // Should not happen if navigation logic is correct
      appState.logout();
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
        withData: true, // Crucial for web/mobile upload to backend
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        final response = await ApiService().uploadFile(file, appState.token!);

        // Store the dataset info in the app state
        appState.setCurrentDataset(response);

        // Mark onboarding as complete to trigger navigation to Dashboard
        appState.markOnboardingComplete();
      } else {
        // User canceled the picker
      }
    } catch (e) {
      setState(() {
        _uploadError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Insights Pro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                Provider.of<AppState>(context, listen: false).logout(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Insights Pro: Your Personal Data Analyst',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'This is your first time logging in. To get started, you need to upload a dataset. Insights Pro is designed to help you quickly analyze, visualize, predict, and forecast based on your data.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (_uploadError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Upload Error: $_uploadError',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              _isUploading
                  ? const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text('Uploading and processing CSV...'),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: () => _uploadCsv(context),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload CSV Dataset'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
