import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContactService {
  Map<String, String> _contactsMap = {};
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await syncContacts();
  }

  Future<bool> requestPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  Future<void> syncContacts() async {
    try {
      if (await requestPermission()) {
        final contacts = await FlutterContacts.getContacts(withProperties: true);
        Map<String, String> tempMap = {};

        for (var contact in contacts) {
          final displayName = contact.displayName;
          for (var phone in contact.phones) {
            String normalized = _normalizeNumber(phone.number);
            if (normalized.isNotEmpty) {
              tempMap[normalized] = displayName;
            }
          }
        }
        _contactsMap = tempMap;
        _isInitialized = true;
        print("Contacts synced: ${_contactsMap.length} numbers mapped.");
      }
    } catch (e) {
      print("Error syncing contacts: $e");
    }
  }

  String getContactName(String phoneNumber) {
    if (!_isInitialized) return phoneNumber;

    String normalizedSearch = _normalizeNumber(phoneNumber);
    if (normalizedSearch.isEmpty) return phoneNumber;
    
    // 1. Try exact match on normalized (last 9 digits)
    if (_contactsMap.containsKey(normalizedSearch)) {
      return _contactsMap[normalizedSearch]!;
    }

    return phoneNumber;
  }

  String _normalizeNumber(String number) {
    String digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 9) {
      return digits.substring(digits.length - 9);
    }
    return digits;
  }
}

// A future provider that ensures contacts are initialized
final contactInitializationProvider = FutureProvider<ContactService>((ref) async {
  final service = ContactService();
  await service.initialize();
  return service;
});

// A simple provider to access the service once initialized
final contactServiceProvider = Provider<ContactService>((ref) {
  return ref.watch(contactInitializationProvider).maybeWhen(
    data: (service) => service,
    orElse: () => ContactService(), // Return uninitialized service as fallback
  );
});
