import 'package:flutter/material.dart';

class LoadingWrapper extends StatelessWidget {
  const LoadingWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black45, // dimmed background
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: Colors.deepPurple),
              SizedBox(height: 16),
              Text(
                "Loading...",
                style: TextStyle(
                  color: Colors.white, // visible on dark bg
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
