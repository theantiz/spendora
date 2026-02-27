import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ai_service.dart';

class AiAssistantWidget extends StatefulWidget {
  const AiAssistantWidget({super.key});

  @override
  State<AiAssistantWidget> createState() => _AiAssistantWidgetState();
}

class _AiAssistantWidgetState extends State<AiAssistantWidget> {
  final AiService _aiService = AiService();
  final TextEditingController _controller = TextEditingController();
  final List<String> _categories = <String>[
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Bills',
    'Health',
    'Other',
    'Uncategorized',
  ];
  final List<String> _examples = <String>[
    'Butter chicken lunch',
    'Interstellar movie ticket',
    'Spotify monthly plan',
  ];

  bool _loading = false;
  bool _submittingFeedback = false;
  bool _trainingLoading = false;
  String? _error;
  String? _trainingError;
  AiCategorySuggestion? _suggestion;
  AiTrainingDataResult? _trainingData;
  String _selectedCategory = 'Food';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _predictCategory() async {
    final String input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() {
        _error = 'Enter a transaction note first.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final AiCategorySuggestion suggestion = await _aiService.suggestCategory(
        description: input,
      );

      if (!mounted) {
        return;
      }

      final String normalizedCategory = _normalizeCategoryName(
        suggestion.category,
      );
      if (!_categories.contains(normalizedCategory)) {
        _categories.add(normalizedCategory);
      }

      setState(() {
        _suggestion = suggestion;
        _selectedCategory = normalizedCategory;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _sendFeedback() async {
    final int? suggestionId = _suggestion?.suggestionId;
    if (suggestionId == null) {
      return;
    }

    setState(() {
      _submittingFeedback = true;
    });

    try {
      await _aiService.submitFeedback(
        suggestionId: suggestionId,
        finalCategory: _selectedCategory,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI feedback saved.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save feedback: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submittingFeedback = false;
        });
      }
    }
  }

  Future<void> _loadTrainingData() async {
    setState(() {
      _trainingLoading = true;
      _trainingError = null;
    });

    try {
      final AiTrainingDataResult result = await _aiService.loadTrainingData();
      if (!mounted) {
        return;
      }
      setState(() {
        _trainingData = result;
        _trainingLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _trainingError = error.toString();
        _trainingLoading = false;
      });
    }
  }

  Future<void> _copyTrainingData() async {
    final AiTrainingDataResult? training = _trainingData;
    if (training == null || training.lines.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: training.asJsonl));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Training JSONL copied to clipboard.')),
    );
  }

  String _normalizeCategoryName(String input) {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) {
      return 'Uncategorized';
    }

    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  void _applyExample(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AiCategorySuggestion? suggestion = _suggestion;
    final String confidence = suggestion == null
        ? ''
        : '${(suggestion.confidence * 100).toStringAsFixed(0)}%';
    final AiTrainingDataResult? training = _trainingData;
    final List<String> sampleLines = training == null
        ? <String>[]
        : training.lines.take(2).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'AI Category Assistant',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Describe transaction',
                hintText: 'e.g. biryani dinner 420 or dune ticket 500',
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _examples
                  .map(
                    (String item) => ActionChip(
                      label: Text(item),
                      onPressed: () => _applyExample(item),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _loading ? null : _predictCategory,
              icon: _loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: const Text('Detect Category (AI)'),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            if (suggestion != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                'Prediction: ${_normalizeCategoryName(suggestion.category)}'
                ' ($confidence • ${suggestion.source})',
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Correct category',
                ),
                items: _categories
                    .map(
                      (String category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _submittingFeedback ? null : _sendFeedback,
                child: Text(
                  _submittingFeedback ? 'Saving...' : 'Send Feedback to AI',
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Model Training Dataset',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _trainingLoading ? null : _loadTrainingData,
                  icon: _trainingLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_download_outlined),
                  label: const Text('Load'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_trainingError != null) ...<Widget>[
              Text(
                'Training data error: $_trainingError',
                style: const TextStyle(color: Colors.red),
              ),
            ] else if (training != null) ...<Widget>[
              Text(
                'Format: ${training.format.toUpperCase()}  •  '
                'Rows: ${training.count}',
              ),
              if (training.note.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  training.note,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: training.lines.isEmpty
                        ? null
                        : _copyTrainingData,
                    icon: const Icon(Icons.copy_all_rounded),
                    label: const Text('Copy JSONL'),
                  ),
                ],
              ),
              if (sampleLines.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  'Sample rows:',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                ...sampleLines.map(
                  (String line) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      line,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ] else ...<Widget>[
              Text(
                'Load validated AI feedback as JSONL for model fine-tuning.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
