import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore always hands date fields back as [Timestamp]. Models call this
/// instead of `DateTime.tryParse` so a null/missing field just comes back
/// null instead of throwing.
DateTime? dateTimeFromFirestore(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
