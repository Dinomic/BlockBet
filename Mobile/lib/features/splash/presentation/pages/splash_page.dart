import 'package:flutter/material.dart';

import '../../../../core/widgets/brand_logo.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 72),
            const SizedBox(height: 16),
            Text('BlockBet', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}
