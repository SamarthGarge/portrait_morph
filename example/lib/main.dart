import 'package:flutter/material.dart';
import 'package:portrait_morph/portrait_morph.dart';

void main() => runApp(const PortraitMorphExampleApp());

class PortraitMorphExampleApp extends StatelessWidget {
  const PortraitMorphExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portrait Morph',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      home: const PortraitMorphDemoPage(),
    );
  }
}

class PortraitMorphDemoPage extends StatelessWidget {
  const PortraitMorphDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    // Swap these for your own portraits — same aspect
                    // ratio works best. Replace with AssetImage(...) for
                    // bundled assets.
                    child: const PortraitMorph(
                      imageA: AssetImage('assets/day_landscape.png'),
                      imageB: AssetImage('assets/night_landscape.png'),
                      alt: 'Day to Night Landscape',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Hover (desktop/web) or press + drag (mobile) to morph.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
