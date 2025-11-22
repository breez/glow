import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RestorePhraseGrid extends StatefulWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final List<String> Function(String query) getSuggestions;
  final Function(int index, String selection) onWordSelected;
  final VoidCallback onPaste;

  const RestorePhraseGrid({
    required this.controllers,
    required this.focusNodes,
    required this.getSuggestions,
    required this.onWordSelected,
    required this.onPaste,
    super.key,
  });

  @override
  State<RestorePhraseGrid> createState() => _RestorePhraseGridState();
}

class _RestorePhraseGridState extends State<RestorePhraseGrid> {
  final List<TextEditingController> _fieldControllers = <TextEditingController>[];
  final List<FocusNode> _autocompleteFocusNodes = <FocusNode>[];
  final List<int> _lastTextLengths = List<int>.filled(12, 0);
  final List<bool> _isAutoFilling = List<bool>.filled(12, false);

  @override
  void initState() {
    super.initState();
    // Initialize lists with null placeholders - will be filled by Autocomplete
    _fieldControllers.addAll(List<TextEditingController>.filled(12, TextEditingController()));
    _autocompleteFocusNodes.addAll(List<FocusNode>.filled(12, FocusNode()));
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleWordSelected(int index, String selection) {
    _isAutoFilling[index] = true;
    widget.controllers[index].text = selection;
    if (_fieldControllers[index].text != selection) {
      _fieldControllers[index].text = selection;
    }
    _lastTextLengths[index] = selection.length;
    widget.onWordSelected(index, selection);

    // Move to next empty field after selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _isAutoFilling[index] = false;
        _moveToNextEmptyField(index);
      }
    });
  }

  void _moveToNextEmptyField(int currentIndex) {
    int nextIndex = currentIndex + 1;
    while (nextIndex < 12 && widget.controllers[nextIndex].text.trim().isNotEmpty) {
      nextIndex++;
    }

    if (nextIndex < 12) {
      _autocompleteFocusNodes[nextIndex].requestFocus();
    } else {
      _autocompleteFocusNodes[currentIndex].unfocus();
    }
  }

  void _handlePaste() {
    // Call the parent's onPaste callback first to update controllers
    widget.onPaste();

    // Sync all field controllers with main controllers after paste
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        for (int i = 0; i < 12; i++) {
          if (_fieldControllers[i].text != widget.controllers[i].text) {
            _fieldControllers[i].text = widget.controllers[i].text;
            _lastTextLengths[i] = widget.controllers[i].text.length;
          }
        }
        // Unfocus all fields
        for (final FocusNode node in _autocompleteFocusNodes) {
          if (node.hasFocus) {
            node.unfocus();
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Backup Phrase', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.paste, size: 20),
                  onPressed: () async {
                    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      _handlePaste();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 12,
              itemBuilder: (BuildContext context, int index) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 26,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, right: 8),
                        child: Text(
                          '${index + 1}.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Autocomplete<String>(
                        key: ValueKey<int>(index),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<String>.empty();
                          }

                          final String currentText = textEditingValue.text;
                          final List<String> suggestions = widget.getSuggestions(currentText);

                          // Check if user is typing (adding characters) vs deleting
                          final bool isTyping = currentText.length > _lastTextLengths[index];
                          _lastTextLengths[index] = currentText.length;

                          // Auto-fill when there's exactly one match AND user is typing forward AND not already auto-filling
                          if (!_isAutoFilling[index] &&
                              isTyping &&
                              suggestions.length == 1 &&
                              suggestions.first != currentText &&
                              currentText.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted &&
                                  !_isAutoFilling[index] &&
                                  _fieldControllers[index].text == currentText) {
                                _handleWordSelected(index, suggestions.first);
                              }
                            });
                          }

                          return suggestions;
                        },
                        onSelected: (String selection) {
                          _handleWordSelected(index, selection);
                        },
                        fieldViewBuilder:
                            (
                              BuildContext context,
                              TextEditingController fieldController,
                              FocusNode fieldFocusNode,
                              VoidCallback onFieldSubmitted,
                            ) {
                              // Sync the Autocomplete's fieldController with our main controller
                              _fieldControllers[index] = fieldController;
                              // Store the focus node so we can move focus later
                              _autocompleteFocusNodes[index] = fieldFocusNode;

                              if (fieldController.text != widget.controllers[index].text) {
                                fieldController.text = widget.controllers[index].text;
                              }

                              return TextField(
                                controller: fieldController,
                                focusNode: fieldFocusNode,
                                onChanged: (String value) {
                                  widget.controllers[index].text = value;
                                  // Reset auto-filling flag when user manually types
                                  if (_isAutoFilling[index]) {
                                    _isAutoFilling[index] = false;
                                  }
                                },
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(),
                                ),
                                style: const TextStyle(fontFamily: 'monospace'),
                                textInputAction: index < 11 ? TextInputAction.next : TextInputAction.done,
                                onSubmitted: (String value) {
                                  _moveToNextEmptyField(index);
                                },
                              );
                            },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
