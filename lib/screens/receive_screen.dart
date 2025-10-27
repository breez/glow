import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/config/breez_config.dart';
import 'package:glow/logging/logger_mixin.dart';
import 'package:glow/providers/sdk_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> with LoggerMixin {
  bool _showInvoiceInput = false;
  final _amountController = TextEditingController();
  BigInt? _amountSats;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _generateInvoice() {
    final amount = BigInt.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount != null && amount > BigInt.zero) {
      setState(() {
        _amountSats = amount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If generating invoice with amount
    if (_amountSats != null) {
      return _buildInvoiceScreen(context);
    }

    // If showing invoice input
    if (_showInvoiceInput) {
      return _buildAmountInput(context);
    }

    // Default: Show Lightning Address
    return _buildLightningAddressScreen(context);
  }

  Widget _buildLightningAddressScreen(BuildContext context) {
    final lightningAddress = ref.watch(lightningAddressProvider(true)); // Enable auto-registration
    final sdkAsync = ref.watch(sdkProvider);

    // Show bottom sheet for editing Lightning Address (delete or change username)
    void showEditBottomSheet(BreezSdk sdk, String currentUsername) {
      final usernameController = TextEditingController(text: currentUsername);
      String? errorText;
      bool isChecking = false;
      bool isProcessing = false;
      bool showDeleteConfirmation = false;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (bottomSheetContext) => StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> handleSave() async {
              final value = usernameController.text.trim().toLowerCase().replaceAll(' ', '');

              // If username unchanged, just close
              if (value == currentUsername) {
                Navigator.of(bottomSheetContext).pop();
                return;
              }

              if (value.isEmpty) {
                setModalState(() {
                  errorText = 'Username cannot be empty';
                });
                return;
              }

              String result = value;
              // Remove leading dots
              while (result.isNotEmpty && result.startsWith('.')) {
                result = result.substring(1);
              }

              // Remove trailing dots
              while (result.isNotEmpty && result.endsWith('.')) {
                result = result.substring(0, result.length - 1);
              }

              // Check availability
              setModalState(() {
                isChecking = true;
                errorText = null;
              });

              try {
                final available = await sdk.checkLightningAddressAvailable(
                  request: CheckLightningAddressRequest(username: result),
                );

                if (!available) {
                  setModalState(() {
                    isChecking = false;
                    errorText = 'Username not available';
                  });
                  return;
                }

                // Delete old and register new
                setModalState(() {
                  isChecking = false;
                  isProcessing = true;
                });

                await sdk.deleteLightningAddress();
                await sdk.registerLightningAddress(
                  request: RegisterLightningAddressRequest(username: result),
                );

                if (mounted) {
                  Navigator.of(bottomSheetContext).pop();
                  ref.invalidate(lightningAddressProvider(true));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lightning Address updated: $value@${BreezConfig.lnurlDomain}')),
                  );
                }
              } catch (e) {
                setModalState(() {
                  isChecking = false;
                  isProcessing = false;
                  errorText = 'Error: ${e.toString()}';
                });
              }
            }

            Future<void> handleDelete() async {
              setModalState(() {
                isProcessing = true;
              });

              try {
                await sdk.deleteLightningAddress();

                if (mounted) {
                  Navigator.of(bottomSheetContext).pop();

                  // Mark as manually deleted to prevent auto-registration
                  ref.read(lightningAddressManuallyDeletedProvider.notifier).markAsDeleted();

                  ref.invalidate(lightningAddressProvider(true));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Lightning Address deleted')));
                }
              } catch (e) {
                setModalState(() {
                  isProcessing = false;
                  errorText = 'Failed to delete: ${e.toString()}';
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!showDeleteConfirmation) ...[
                    Text('Edit Lightning Address', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Change your username or delete your Lightning Address',
                      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: usernameController,
                      autofocus: true,
                      enabled: !isProcessing && !isChecking,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        errorText: errorText,
                        suffixText: '@${BreezConfig.lnurlDomain}',
                        suffixStyle: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // Clear error when user types
                        if (errorText != null) {
                          setModalState(() {
                            errorText = null;
                          });
                        }
                      },
                      onSubmitted: (_) => handleSave(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: isChecking || isProcessing ? null : handleSave,
                      child: isChecking || isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Changes'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () {
                              setModalState(() {
                                showDeleteConfirmation = true;
                              });
                            },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Lightning Address'),
                      style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                    ),
                  ] else ...[
                    Text('Delete Lightning Address?', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'This will permanently delete your Lightning Address. You can register a new one later.',
                      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: isProcessing ? null : handleDelete,
                      icon: isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: isProcessing
                          ? null
                          : () {
                              setModalState(() {
                                showDeleteConfirmation = false;
                                errorText = null;
                              });
                            },
                      child: const Text('Cancel'),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      );
    }

    // Show bottom sheet for registering new Lightning Address
    void showRegisterBottomSheet(BreezSdk sdk) {
      final usernameController = TextEditingController();
      String? errorText;
      bool isChecking = false;
      bool isRegistering = false;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (bottomSheetContext) => StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> handleRegistration() async {
              final value = usernameController.text.trim().toLowerCase().replaceAll(' ', '');
              if (value.isEmpty) {
                setModalState(() {
                  errorText = 'Username cannot be empty';
                });
                return;
              }

              String result = value;
              // Remove leading dots
              while (result.isNotEmpty && result.startsWith('.')) {
                result = result.substring(1);
              }

              // Remove trailing dots
              while (result.isNotEmpty && result.endsWith('.')) {
                result = result.substring(0, result.length - 1);
              }

              // Check availability
              setModalState(() {
                isChecking = true;
                errorText = null;
              });

              try {
                final available = await sdk.checkLightningAddressAvailable(
                  request: CheckLightningAddressRequest(username: result),
                );

                if (!available) {
                  setModalState(() {
                    isChecking = false;
                    errorText = 'Username not available';
                  });
                  return;
                }

                // Register the address
                setModalState(() {
                  isChecking = false;
                  isRegistering = true;
                });

                await sdk.registerLightningAddress(request: RegisterLightningAddressRequest(username: value));

                if (mounted) {
                  Navigator.of(bottomSheetContext).pop();

                  // Reset manual deletion flag since user is registering again
                  ref.read(lightningAddressManuallyDeletedProvider.notifier).reset();

                  ref.invalidate(lightningAddressProvider(true));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lightning Address registered: $value@${BreezConfig.lnurlDomain}'),
                    ),
                  );
                }
              } catch (e) {
                setModalState(() {
                  isChecking = false;
                  isRegistering = false;
                  errorText = 'Error: ${e.toString()}';
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Register Lightning Address', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a unique username for your Lightning Address',
                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: usernameController,
                    autofocus: true,
                    enabled: !isRegistering && !isChecking,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      errorText: errorText,
                      suffixText: '@${BreezConfig.lnurlDomain}',
                      suffixStyle: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // Clear error when user types
                      if (errorText != null) {
                        setModalState(() {
                          errorText = null;
                        });
                      }
                    },
                    onSubmitted: (_) => handleRegistration(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: isChecking || isRegistering ? null : handleRegistration,
                    child: isChecking || isRegistering
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Register'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      );
    }

    // Show bottom sheet for editing Lightning Address (delete + register)
    return Scaffold(
      appBar: AppBar(title: const Text('Receive')),
      body: lightningAddress.when(
        data: (address) {
          if (address == null) {
            // Show manual registration option
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.alternate_email, size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 24),
                    Text('No Lightning Address', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Register a Lightning Address to receive payments easily',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () async {
                        final sdk = await sdkAsync.whenOrNull(data: (sdk) async => sdk);
                        if (sdk != null && mounted) {
                          showRegisterBottomSheet(sdk);
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Register Lightning Address'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        setState(() {
                          _showInvoiceInput = true;
                        });
                      },
                      icon: const Icon(Icons.bolt),
                      label: const Text('Generate Invoice'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // QR Code
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: PrettyQrView.data(
                    data: address.lightningAddress,
                    decoration: const PrettyQrDecoration(shape: PrettyQrSmoothSymbol(color: Colors.black)),
                  ),
                ),
                const SizedBox(height: 32),

                // Lightning Address
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Lightning Address',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: address.lightningAddress));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        address.lightningAddress,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Edit Lightning Address button
                      Center(
                        child: FilledButton.tonalIcon(
                          onPressed: () async {
                            final sdk = await sdkAsync.whenOrNull(data: (sdk) async => sdk);
                            if (sdk != null && mounted) {
                              // Extract username from full Lightning Address
                              final username = address.lightningAddress.split('@')[0];
                              showEditBottomSheet(sdk, username);
                            }
                          },
                          icon: const Icon(Icons.edit, size: 20),
                          label: const Text('Edit Lightning Address'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Debug & Testing section
                      ExpansionTile(
                        title: Text(
                          'Debug & Testing',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: FilledButton.icon(
                              onPressed: () async {
                                final sdk = await sdkAsync.whenOrNull(data: (sdk) async => sdk);
                                if (sdk != null) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(child: CircularProgressIndicator()),
                                  );
                                  try {
                                    await sdk.deleteLightningAddress();
                                    if (context.mounted) {
                                      Navigator.of(context).pop(); // Remove progress
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Lightning Address deleted!')),
                                      );

                                      // Mark as manually deleted to prevent auto-registration
                                      ref
                                          .read(lightningAddressManuallyDeletedProvider.notifier)
                                          .markAsDeleted();

                                      ref.invalidate(lightningAddressProvider(true));
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
                                    }
                                  }
                                }
                              },
                              icon: const Icon(Icons.delete_outline, size: 20),
                              label: const Text('Delete (Testing Only)'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Request with amount button
                FilledButton.tonal(
                  onPressed: () {
                    setState(() {
                      _showInvoiceInput = true;
                    });
                  },
                  child: const Text('Request with Amount'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load Lightning Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _showInvoiceInput = false;
              _amountController.clear();
            });
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              'Amount',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300, letterSpacing: -2),
              decoration: InputDecoration(
                hintText: '0',
                suffix: Text(
                  'sats',
                  style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                border: InputBorder.none,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _generateInvoice(),
            ),
            const Spacer(),
            FilledButton(onPressed: _generateInvoice, child: const Text('Generate Invoice')),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceScreen(BuildContext context) {
    final receiveResponse = ref.watch(
      receivePaymentProvider(
        ReceivePaymentRequest(
          paymentMethod: ReceivePaymentMethod.bolt11Invoice(description: 'Payment', amountSats: _amountSats),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _showInvoiceInput = false;
              _amountSats = null;
            });
          },
        ),
      ),
      body: receiveResponse.when(
        data: (response) => _buildInvoiceContent(context, response),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to generate invoice',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _amountSats = null;
                    });
                  },
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceContent(BuildContext context, ReceivePaymentResponse response) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Amount display
          Text(
            _formatSats(_amountSats!),
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w300, letterSpacing: -2),
          ),
          const Text('sats', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 32),

          // QR Code
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: PrettyQrView.data(
              data: response.paymentRequest,
              decoration: const PrettyQrDecoration(shape: PrettyQrSmoothSymbol(color: Colors.black)),
            ),
          ),
          const SizedBox(height: 32),

          // Invoice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Lightning Invoice',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: response.paymentRequest));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  response.paymentRequest,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          if (response.feeSats > BigInt.zero) ...[
            const SizedBox(height: 16),
            Text(
              'Fee: ${_formatSats(response.feeSats)} sats',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  String _formatSats(BigInt sats) {
    final str = sats.toString();
    final buffer = StringBuffer();
    final length = str.length;

    for (int i = 0; i < length; i++) {
      buffer.write(str[i]);
      final position = length - i - 1;
      if (position > 0 && position % 3 == 0) {
        buffer.write(',');
      }
    }

    return buffer.toString();
  }
}
