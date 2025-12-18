// views/qr_scanner_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediatech/Controllers/loan_controller.dart';
import 'package:mobile_scanner/mobile_scanner.dart';


class QRScannerPage extends ConsumerStatefulWidget {
  final ScannerMode mode;
  
  const QRScannerPage({super.key, required this.mode});

  @override
  ConsumerState<QRScannerPage> createState() => _QRScannerPageState();
}

enum ScannerMode { borrow, returning }

class _QRScannerPageState extends ConsumerState<QRScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == ScannerMode.borrow ? 'Scanner pour emprunter' : 'Scanner pour retourner'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (_isProcessing) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                _processBarcode(barcodes.first.rawValue ?? '');
              }
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Traitement en cours...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _processBarcode(String barcode) async {
    setState(() => _isProcessing = true);

    try {
      bool success = false;
      
      if (widget.mode == ScannerMode.borrow) {
        // Assuming barcode format: "mediaId:userId"
        final parts = barcode.split(':');
        if (parts.length == 2) {
          success = await ref.read(loanControllerProvider.notifier)
              .borrowMediaWithScan(parts[1], parts[0], barcode);
        }
      } else {
        // For return, barcode is the loan ID
        success = await ref.read(loanControllerProvider.notifier)
            .returnMediaWithScan(barcode, barcode);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Opération réussie' : 'Échec de l\'opération'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}