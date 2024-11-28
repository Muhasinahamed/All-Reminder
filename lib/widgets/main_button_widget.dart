import 'package:flutter/material.dart';

Widget buildNavigationButton(
  BuildContext context,
  String label,
  IconData icon,
  Color color,
  VoidCallback onPressed,
) {
  return ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
      backgroundColor: color.withOpacity(0.95),
      minimumSize: const Size(300, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
      elevation: 8,
      shadowColor: color.withOpacity(0.4),
    ),
    onPressed: onPressed,
    icon: Icon(
      icon,
      size: 28,
      color: Colors.black87,
    ),
    label: Text(
      label,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    ),
  );
}
