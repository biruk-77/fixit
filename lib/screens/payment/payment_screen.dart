import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
// Your app's files that this screen depends on
import '../../models/job.dart';
import '../../services/firebase_service.dart';
import 'telebirr_api_service.dart';
import 'config.dart';

class PaymentScreen extends StatefulWidget {
  final Job job;
  const PaymentScreen({super.key, required this.job});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Services and Data Controllers
  final FirebaseService _firebaseService = FirebaseService();
  late final TelebirrApiService _apiService;
  final _phoneNumberController = TextEditingController();

  // UI State Control
  bool _isLoading = false;
  bool _isScanning = false;
  String _selectedPaymentMethod = 'Telebirr';
  String? _scannedCbeQrData;

  // PIN Keypad State
  bool _isEnteringPin = false;
  String _pin = '';

  @override
  void initState() {
    super.initState();
    _apiService = TelebirrApiService(trustBadCertificate: true);
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  // --- Core Payment Logic ---

  Future<void> _initiatePayment() async {
    FocusScope.of(context).unfocus();
    if (_selectedPaymentMethod == 'CBE Birr' && _scannedCbeQrData == null) {
      _showErrorSnackBar("Please scan a CBE Birr QR code first.");
      return;
    }
    if (_selectedPaymentMethod == 'Telebirr') {
      if (_phoneNumberController.text.isEmpty ||
          !RegExp(r'^09[0-9]{8}$').hasMatch(_phoneNumberController.text)) {
        _showErrorSnackBar("Please enter a valid Telebirr phone number.");
        return;
      }
      setState(() {
        _pin = '';
        _isEnteringPin = true;
      });
    } else {
      _processPayment();
    }
  }

  Future<void> _processPayment() async {
    if ((await Connectivity().checkConnectivity()) == ConnectivityResult.none) {
      if (mounted) _showErrorSnackBar('No internet connection.');
      return;
    }
    setState(() {
      _isLoading = true;
      _isEnteringPin = false;
    });

    try {
      if (_selectedPaymentMethod == 'Telebirr') {
        await _processTelebirrPayment();
      } else if (_selectedPaymentMethod == 'CBE Birr')
        await _processCbeBirrPayment();

      if (mounted) {
        await _firebaseService.createPaymentRecord(
            jobId: widget.job.id,
            amount: widget.job.budget * 1.1,
            paymentMethod: _selectedPaymentMethod,
            status: 'success',
            transactionId:
                '${_selectedPaymentMethod}_${DateTime.now().millisecondsSinceEpoch}',
            workerID: widget.job.seekerId);
        _showSuccessSnackBar('Payment Successful!');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      final errorMessage = e.toString().replaceFirst("Exception: ", "");
      if (mounted) _showErrorSnackBar(errorMessage);
      debugPrint('Error processing payment: $errorMessage');
      debugPrint("$e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processTelebirrPayment() async {
    await _apiService.generateAppToken();
    final String currentMerchOrderId =
        'TB${DateTime.now().millisecondsSinceEpoch}';

    final prepayId = await _apiService.createOrder(
      totalAmount: (widget.job.budget * 1.1).toStringAsFixed(0),
      merchOrderId: currentMerchOrderId,
      title: widget.job.title,
      notifyUrl: AppConfig.notifyUrl,
      payeeIdentifier: AppConfig.consumerMsisdn,
    );
    await _apiService.payOrder(
        prepayId: prepayId!,
        payerIdentifier: _phoneNumberController.text.trim(),
        consumerPin: _pin);
    await Future.delayed(const Duration(seconds: 3));
    final statusResult =
        await _apiService.queryOrder(merchOrderId: currentMerchOrderId);
    final tradeStatus = statusResult['biz_content']?['trade_status'];
    if (tradeStatus != 'SUCCESS' && tradeStatus != 'Finished') {
      throw Exception(
          "Telebirr Error: Payment status was ${tradeStatus ?? 'Unknown'}");
    }
  }

  Future<void> _processCbeBirrPayment() async {
    debugPrint("Simulating CBE Birr payment with QR Data: $_scannedCbeQrData");
    await Future.delayed(const Duration(seconds: 2));
    debugPrint("Simulated CBE Birr success.");
  }

  // --- UI Build & Helper Methods ---

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(children: [
      Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Confirm & Pay'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            _buildOrderSummaryCard(theme),
            const SizedBox(height: 24),
            _buildPaymentSelection(theme),
          ]),
        ),
        bottomNavigationBar: _buildPayButton(theme),
      ),
      if (_isScanning) _buildScannerOverlay(),
      if (_isEnteringPin) _buildPinEntryOverlay(theme),
      if (_isLoading) _buildLoadingOverlay(),
    ]);
  }

  Widget _buildOrderSummaryCard(ThemeData theme) {
    return Card(
      color: theme.cardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            _buildOrderItem(theme, 'Job Title', widget.job.title),
            const Divider(height: 24),
            _buildOrderItem(theme, 'Service Fee (10%)',
                'ETB ${(widget.job.budget * 0.1).toStringAsFixed(0)}'),
            const Divider(height: 24),
            _buildOrderItem(theme, 'Total Amount',
                'ETB ${(widget.job.budget * 1.1).toStringAsFixed(0)}',
                isTotal: true),
          ])),
    );
  }

  Widget _buildPaymentSelection(ThemeData theme) {
    return Column(children: [
      _buildPaymentMethodTile('Telebirr', theme,
          isSelected: _selectedPaymentMethod == 'Telebirr'),
      const SizedBox(height: 12),
      _buildPaymentMethodTile('CBE Birr', theme,
          isSelected: _selectedPaymentMethod == 'CBE Birr'),
      const SizedBox(height: 20),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 30),
        child: _selectedPaymentMethod == 'Telebirr'
            ? _buildTelebirrInput(theme)
            : _buildCbeBirrInput(theme),
      ),
    ]);
  }

  Widget _buildPaymentMethodTile(String name, ThemeData theme,
      {required bool isSelected}) {
    final primaryColor = theme.colorScheme.primary;
    final surfaceColor = theme.colorScheme.surface;
    final onSurfaceColor = theme.colorScheme.onSurface;

    return GestureDetector(
        onTap: () => setState(() => _selectedPaymentMethod = name),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: isSelected ? primaryColor.withOpacity(0.05) : surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                  width: isSelected ? 2.0 : 1.5)),
          child: Row(children: [
            Icon(
                name == 'Telebirr'
                    ? Icons.phone_android_rounded
                    : Icons.qr_code_2_rounded,
                color: isSelected
                    ? primaryColor
                    : onSurfaceColor.withOpacity(0.6)),
            const SizedBox(width: 16),
            Text(name,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? primaryColor : onSurfaceColor)),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: primaryColor),
          ]),
        ));
  }

  Widget _buildTelebirrInput(ThemeData theme) {
    return TextFormField(
      key: const ValueKey('TelebirrInput'),
      controller: _phoneNumberController,
      keyboardType: TextInputType.phone,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: "Your Phone Number (Payer)",
        border: const OutlineInputBorder(),
        prefixIcon: Icon(Icons.phone, color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildCbeBirrInput(ThemeData theme) {
    return OutlinedButton.icon(
        key: const ValueKey('CbeInput'),
        onPressed: () async {
          var status = await Permission.camera.request();
          if (status.isGranted) {
            setState(() => _isScanning = true);
          } else {
            _showErrorSnackBar("Camera Permission needed for QR Scan.");
          }
        },
        icon: Icon(_scannedCbeQrData != null
            ? Icons.check_circle_rounded
            : Icons.qr_code_scanner_rounded),
        label: Text(_scannedCbeQrData != null
            ? "QR Code Scanned"
            : "Scan CBE Birr Code"),
        style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 50),
            foregroundColor: _scannedCbeQrData != null
                ? Colors.green
                : theme.colorScheme.primary));
  }

  Widget _buildPayButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _initiatePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text('Authorize Payment',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  // --- PIN Entry, Overlays, and Other Helpers ---

  void _onKeypadTap(String value) {
    HapticFeedback.lightImpact();
    if (value == 'backspace') {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
    } else if (_pin.length < 6) {
      setState(() => _pin += value);
    }
  }

  Widget _buildPinEntryOverlay(ThemeData theme) {
    return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Scaffold(
          backgroundColor: Colors.black.withOpacity(0.3),
          body: Center(
              child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text("Authorize Payment",
                  style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text("Enter your Telebirr PIN to continue",
                  style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7))),
              const SizedBox(height: 24),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      6,
                      (index) =>
                          _buildPinDot(theme, isFilled: index < _pin.length))),
              const SizedBox(height: 24),
              _buildPinKeypad(theme),
              const SizedBox(height: 12),
              TextButton(
                  onPressed: () {
                    setState(() => _isEnteringPin = false);
                  },
                  child: Text("Cancel",
                      style: TextStyle(color: theme.colorScheme.primary))),
            ]),
          )),
        ));
  }

  Widget _buildPinDot(ThemeData theme, {required bool isFilled}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 20),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: isFilled
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildPinKeypad(ThemeData theme) {
    return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8),
        itemCount: 12,
        itemBuilder: (context, index) {
          final keys = [
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
            '8',
            '9',
            '',
            '0',
            'backspace'
          ];
          final key = keys[index];
          if (key.isEmpty) return const SizedBox.shrink();

          return InkWell(
            onTap: () {
              _onKeypadTap(key);
              if (_pin.length == 6) _processPayment();
            },
            borderRadius: BorderRadius.circular(100),
            child: Center(
              child: key == 'backspace'
                  ? Icon(Icons.backspace_outlined,
                      color: theme.colorScheme.onSurface.withOpacity(0.8))
                  : Text(key,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface)),
            ),
          );
        });
  }

  Widget _buildOrderItem(ThemeData theme, String label, String value,
      {bool isTotal = false}) {
    final style = theme.textTheme.bodyLarge?.copyWith(
        fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
        color: isTotal
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withOpacity(0.7));
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: style),
          Flexible(
              child: Text(
            value,
            style: style?.copyWith(color: theme.colorScheme.onSurface),
            textAlign: TextAlign.end,
          )),
        ]));
  }

  Widget _buildLoadingOverlay() {
    return Container(
        color: Colors.black.withOpacity(0.5),
        child: const Center(child: CircularProgressIndicator()));
  }

  Widget _buildScannerOverlay() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(alignment: Alignment.center, children: [
        MobileScanner(onDetect: (capture) {
          if (!mounted ||
              capture.barcodes.isEmpty ||
              capture.barcodes.first.rawValue == null) {
            return;
          }
          setState(() {
            _scannedCbeQrData = capture.barcodes.first.rawValue!;
            _isScanning = false;
          });
          _showSuccessSnackBar("QR Code Scanned Successfully!");
        }),
        Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16))),
        Positioned(
            top: 50,
            right: 20,
            child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() => _isScanning = false)))
      ]),
    );
  }
}
