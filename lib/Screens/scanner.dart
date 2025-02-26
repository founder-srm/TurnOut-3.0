import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_service.dart';
import 'about.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool isFlashOn = false;
  bool isScanning = true;
  MobileScannerController controller = MobileScannerController();
  final QrService qrService = QrService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.all(16),
              child: MobileScanner(
                controller: controller,
                onDetect: (capture) async {
                  if (!isScanning) return;

                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      setState(() {
                        isScanning = false;
                      });

                      await controller.stop();
                      await qrService.markAttendance(
                          barcode.rawValue!, context);
                      await controller.start();

                      setState(() {
                        isScanning = true;
                      });
                      break;
                    }
                  }
                },
              ),
            ),
          ),
          // Flash button at bottom
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    setState(() {
                      isFlashOn = !isFlashOn;
                      controller.toggleTorch();
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
