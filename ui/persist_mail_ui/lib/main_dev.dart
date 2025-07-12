import 'package:flutter/material.dart';

import 'base/enums.dart' show Flavor;
import 'base/models/flavour_config.dart' show FlavorConfig;
import 'base/models/flavour_values.dart' show FlavorValues;
import 'base/widgets/flavour_banner.dart';
import 'ui/pages/home/home_page.dart' show HomePage;

void main() {
  FlavorConfig(
    flavor: Flavor.DEV,
    color: Colors.blue,
    values: FlavorValues(baseUrl: 'https://persist.site/dev'),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: FlavorBanner(child: const HomePage()),
    );
  }
}
