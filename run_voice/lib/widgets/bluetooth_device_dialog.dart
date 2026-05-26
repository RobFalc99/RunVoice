import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../utils/constants.dart';

class BluetoothDeviceDialog extends StatelessWidget {
  const BluetoothDeviceDialog({super.key});

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
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: btProvider.isScanning
                        ? null
                        : () async {
                            await btProvider.startScan();
                          },
                    icon: btProvider.isScanning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.bluetooth_searching),
                    label: Text(
                      btProvider.isScanning
                          ? 'Ricerca in corso...'
                          : 'Cerca sensori',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

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
                    padding: const EdgeInsets.all(24),
                    child: const Center(
                      child: Text(
                        'Nessun sensore trovato.\nPremi "Cerca sensori" per iniziare.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
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
