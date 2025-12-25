import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  List<String> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.token == null) return;

    try {
      final files = await ApiService().getUserFiles(appState.token!);
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Fail silently or show toast
    }
  }

  Future<void> _handleFileSwitch(String filename) async {
    final appState = Provider.of<AppState>(context, listen: false);

    // Close drawer immediately
    Navigator.pop(context);

    // Show loading indicator on main screen if you like, or just wait
    try {
      await appState.switchDataset(filename);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Switched to $filename")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading file: $e")));
    }
  }

  Future<void> _uploadNewFile() async {
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null) {
        // Show loading snackbar
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Uploading...")));

        final response = await ApiService().uploadFile(
          result.files.single,
          appState.token!,
        );
        appState.setCurrentDataset(response);

        // Refresh list
        await _fetchFiles();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Upload Successful!")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFile = Provider.of<AppState>(context).currentDataset?.filename;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Insights Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Your Datasets',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _files.isEmpty
                ? const Center(child: Text("No files found."))
                : ListView.builder(
                    itemCount: _files.length,
                    itemBuilder: (context, index) {
                      final file = _files[index];
                      final isSelected = file == currentFile;
                      return ListTile(
                        leading: Icon(
                          Icons.description,
                          color: isSelected ? Colors.blue : Colors.grey,
                        ),
                        title: Text(
                          file,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.blue : Colors.black,
                          ),
                        ),
                        selected: isSelected,
                        onTap: () => _handleFileSwitch(file),
                      );
                    },
                  ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _uploadNewFile,
              icon: const Icon(Icons.upload_file),
              label: const Text("Upload New CSV"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.close, color: Colors.orange),
            title: const Text(
              "Close Current File",
              style: TextStyle(color: Colors.orange),
            ),
            onTap: () {
              // Close the drawer
              Navigator.pop(context);
              // Clear dataset to go back to "No Dataset" screen
              Provider.of<AppState>(
                context,
                listen: false,
              ).clearCurrentDataset();
            },
          ),

          const Divider(),

          // Logout at the very bottom
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () {
              Provider.of<AppState>(context, listen: false).logout();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
