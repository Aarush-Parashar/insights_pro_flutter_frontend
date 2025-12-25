import 'package:flutter/material.dart';
import '../models/models.dart';

class DynamicForm extends StatefulWidget {
  final List<PreprocessingQuestion> questions;
  final ValueChanged<Map<String, String>> onConfigChanged;

  const DynamicForm({
    super.key,
    required this.questions,
    required this.onConfigChanged,
  });

  @override
  State<DynamicForm> createState() => _DynamicFormState();
}

class _DynamicFormState extends State<DynamicForm> {
  final Map<String, String> _currentConfig = {};

  @override
  void initState() {
    super.initState();
    // Initialize config with default values (first option)
    for (var q in widget.questions) {
      _currentConfig[q.key] = q.options.first;
    }
    // Notify parent with initial config
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onConfigChanged(_currentConfig);
    });
  }

  void _updateConfig(String key, String value) {
    setState(() {
      _currentConfig[key] = value;
    });
    widget.onConfigChanged(_currentConfig);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.questions.map((q) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                q.question,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (q.type == 'dropdown')
                DropdownButtonFormField<String>(
                  value: _currentConfig[q.key],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                  ),
                  items: q.options.map((option) {
                    return DropdownMenuItem(value: option, child: Text(option));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _updateConfig(q.key, value);
                    }
                  },
                )
              else if (q.type == 'radio')
                Row(
                  children: q.options.map((option) {
                    return Expanded(
                      child: RadioListTile<String>(
                        title: Text(option),
                        value: option,
                        groupValue: _currentConfig[q.key],
                        onChanged: (value) {
                          if (value != null) {
                            _updateConfig(q.key, value);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
