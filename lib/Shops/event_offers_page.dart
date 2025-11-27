import 'package:flutter/material.dart';

class EventOffersPage extends StatelessWidget {
  const EventOffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Offers')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Event Offers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Create and manage offers that apply to complete product sets or specific products.',
            ),
            SizedBox(height: 8),
            Text('This is a placeholder page — implement details as needed.'),
          ],
        ),
      ),
    );
  }
}
