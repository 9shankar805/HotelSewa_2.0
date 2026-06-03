import 'package:flutter/material.dart';
import '../models/offer_model.dart';

class OfferFormModal extends StatelessWidget {
  final Offer? offer;
  final Future<bool> Function(Offer) onSave;

  const OfferFormModal({super.key, this.offer, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(offer == null ? 'Create Offer' : 'Edit Offer',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          const Text('Offer management coming soon'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
