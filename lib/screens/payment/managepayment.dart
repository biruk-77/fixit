import 'package:flutter/material.dart';

// Theme and Localization (Ensure these are imported)
import '../../services/app_string.dart';
// Import your Firebase service and potentially a PaymentMethod model
// import '../services/firebase_service.dart';
// import '../models/payment_method.dart';

class ManagePaymentMethodsScreen extends StatefulWidget {
  // NO Job parameter here
  const ManagePaymentMethodsScreen({super.key});

  @override
  State<ManagePaymentMethodsScreen> createState() =>
      _ManagePaymentMethodsScreenState();
}

class _ManagePaymentMethodsScreenState
    extends State<ManagePaymentMethodsScreen> {
  // final FirebaseService _firebaseService = FirebaseService();
  // bool _isLoading = false;
  // List<PaymentMethod> _savedMethods = []; // Example state

  @override
  void initState() {
    super.initState();
    // TODO: Load saved payment methods from Firebase/backend
    // _loadSavedMethods();
  }

  // Future<void> _loadSavedMethods() async { ... }
  // Future<void> _addMethod() async { ... } // Navigate to an add card/method screen
  // Future<void> _deleteMethod(String methodId) async { ... }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context);
    // final themeProvider = Provider.of<ThemeProvider>(context); // If needed for toggles

    if (strings == null) {
      return Scaffold(
          appBar: AppBar(title: const Text("Loading...")),
          body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        // !! Use localization !!
        title: Text(strings.paymentScreenTitle ?? 'Manage Payment Methods'),
      ),
      body: /* _isLoading ? Center(...) : */ Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_off_outlined,
                size: 60, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            // TODO: Replace with actual list of saved methods or empty state
            Text(
              "No saved methods.", // Use localization
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {/* TODO: Implement _addMethod logic */},
              icon: const Icon(Icons.add_card_outlined),
              label: Text(
                  strings.paymentAddMethod ?? "Add Method"), // Use localization
            )
          ],
        ),
      ),
      // Optional FloatingActionButton to add methods
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () { /* TODO: Implement _addMethod logic */ },
      //   label: Text(strings.paymentAddMethod ?? "Add Method"),
      //   icon: const Icon(Icons.add_card_outlined),
      // ),
    );
  }
}
