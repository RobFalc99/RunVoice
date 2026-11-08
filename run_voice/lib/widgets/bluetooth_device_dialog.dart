import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../utils/constants.dart';

class BluetoothDeviceDialog extends StatefulWidget {
  const BluetoothDeviceDialog({super.key});

  @override
  State<BluetoothDeviceDialog> createState() => _BluetoothDeviceDialogState();
}

class _BluetoothDeviceDialogState extends State<BluetoothDeviceDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bt = context.read<BluetoothProvider>();
        if (!bt.isConnected && !bt.isScanning) {
          bt.startScan();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothProvider>(
      builder: (context, btProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Sensori Bluetooth',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (btProvider.isConnected)
                    TextButton(
                      onPressed: () async {
                        await btProvider.disconnect();
                      },
                      child: const Text(
                        'Disconnetti',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (btProvider.isConnected) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bluetooth_connected,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              btProvider.connectedDeviceName ?? 'Connesso',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${btProvider.heartRate} BPM',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                if (btProvider.isScanning)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ricerca sensori Bluetooth in corso...',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (btProvider.savedDevices.isNotEmpty) ...[
                  const Text(
                    'DISPOSITIVI MEMORIZZATI',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...btProvider.savedDevices.map((device) {
                    final isDiscovered =
                        btProvider.isDeviceDiscovered(device.id);
                    final isConnecting =
                        btProvider.isDeviceConnecting(device.id);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isDiscovered
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.surfaceHighlight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        leading: Icon(
                          Icons.bluetooth,
                          color: isDiscovered
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                        title: Text(
                          device.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${device.id}${isDiscovered ? ' • Nelle vicinanze' : ''}',
                          style: TextStyle(
                            color: isDiscovered
                                ? AppColors.success
                                : AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        trailing: isConnecting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  elevation: 0,
                                ),
                                onPressed: () async {
                                  final ok = await btProvider
                                      .connectToSavedDevice(device);
                                  if (ok && context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: const Text(
                                  'Connetti',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  const Divider(
                    height: 20,
                    color: AppColors.surfaceHighlight,
                  ),
                  const SizedBox(height: 4),
                ],
                const SizedBox(height: 8),

                if (btProvider.scanResults.isNotEmpty)
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      itemCount: btProvider.scanResults.length,
                      itemBuilder: (ctx, index) {
                        final result = btProvider.scanResults[index];
                        final name = result.device.platformName.isNotEmpty
                            ? result.device.platformName
                            : 'Dispositivo sconosciuto';
                        return ListTile(
                          leading: const Icon(
                            Icons.bluetooth,
                            color: AppColors.info,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'RSSI: ${result.rssi} dBm',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onTap: () async {
                            await btProvider.connectToDevice(result);
                          },
                        );
                      },
                    ),
                  )
                else if (!btProvider.isScanning)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nessun sensore trovato nelle vicinanze.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => btProvider.startScan(),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Riprova scansione'),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
