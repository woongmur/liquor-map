import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'models/liquor_data.dart';

/// 임시 진입점이다.
///
/// 지도(`widgets/world_map.dart`)와 화면 4개가 붙으면 아래 [_BootstrapPage]는
/// `screens/map_screen.dart`로 교체된다. 지금은 pubspec의 assets 선언과 모델
/// 파싱이 실제로 맞물려 도는지 확인하는 용도만 한다.
///
/// 내장 JSON을 읽는 로직도 임시다. 원격 다운로드·캐시와 함께
/// `data/asset_loader.dart` + `data/repository.dart`로 옮겨간다.
void main() {
  runApp(const LiquorMapApp());
}

class LiquorMapApp extends StatelessWidget {
  const LiquorMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '세계 술 지도',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8E1E3B)),
      ),
      home: const _BootstrapPage(),
    );
  }
}

class _BootstrapPage extends StatefulWidget {
  const _BootstrapPage();

  @override
  State<_BootstrapPage> createState() => _BootstrapPageState();
}

class _BootstrapPageState extends State<_BootstrapPage> {
  late final Future<LiquorData> _data = _loadBundledData();

  static Future<LiquorData> _loadBundledData() async {
    final raw = await rootBundle.loadString('assets/data/drinks.json');
    return LiquorData.fromJson(json.decode(raw) as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('세계 술 지도')),
      body: FutureBuilder<LiquorData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('내장 데이터를 읽지 못했다\n${snapshot.error}'));
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('아직 지도 화면이 없다. 내장 데이터만 읽어 확인하는 중.'),
              const SizedBox(height: 16),
              Text(data.toString()),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in data.categories)
                    Chip(
                      label: Text(c.name),
                      backgroundColor: switch (c.mapColorValue) {
                        final v? => Color(v).withValues(alpha: 0.15),
                        null => null,
                      },
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
