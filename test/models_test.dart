import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:liquor_map/models/liquor_data.dart';

void main() {
  // rootBundle을 쓰므로 바인딩이 필요하다. 이 테스트는 pubspec의 assets 선언이
  // 실제로 먹히는지까지 같이 검증한다 — 선언이 빠지면 여기서 먼저 깨진다.
  TestWidgetsFlutterBinding.ensureInitialized();

  late LiquorData data;

  setUpAll(() async {
    final raw = await rootBundle.loadString('assets/data/drinks.json');
    data = LiquorData.fromJson(json.decode(raw) as Map<String, dynamic>);
  });

  group('내장 데이터', () {
    test('MVP 범위대로 읽힌다', () {
      expect(data.schemaVersion, supportedSchemaVersion);
      expect(data.categories, hasLength(5));
      expect(data.countries, hasLength(5));
      expect(data.drinks, hasLength(5));
      expect(data.cocktails, hasLength(20));
    });

    test('카테고리는 sortOrder 순으로 정렬돼 나온다', () {
      expect(
        [for (final c in data.categories) c.id],
        ['wine', 'whisky', 'sake', 'makgeolli', 'tequila'],
      );
    });

    test('참조하는 id가 전부 실재한다', () {
      for (final d in data.drinks) {
        for (final id in d.categoryIds) {
          expect(data.category(id), isNotNull, reason: '${d.id} → 카테고리 $id');
        }
        for (final id in d.countryIds) {
          expect(data.country(id), isNotNull, reason: '${d.id} → 국가 $id');
        }
        for (final id in d.cocktailIds) {
          expect(data.cocktail(id), isNotNull, reason: '${d.id} → 칵테일 $id');
        }
      }
    });

    test('필수 서술 필드가 비어있지 않다', () {
      for (final d in data.drinks) {
        expect(d.history, isNotEmpty, reason: d.id);
        expect(d.taste, isNotEmpty, reason: d.id);
        expect(d.aroma, isNotEmpty, reason: d.id);
        expect(d.beginnerTip, isNotEmpty, reason: d.id);
      }
    });

    test('mapColor가 전부 해석 가능한 hex다', () {
      for (final c in data.categories) {
        expect(c.mapColorValue, isNotNull, reason: '${c.id}: ${c.mapColor}');
      }
    });
  });

  group('조회', () {
    test('카테고리 → 색칠할 국가의 ISO numeric', () {
      expect(data.highlightedIsoNumerics('wine'), {250});
      expect(data.highlightedIsoNumerics('tequila'), {484});
      // 데이터에 없는 카테고리는 빈 집합. 던지지 않는다.
      expect(data.highlightedIsoNumerics('brandy'), isEmpty);
    });

    test('지도에서 탭한 ISO numeric으로 국가를 찾는다', () {
      expect(data.countryByIsoNumeric(410)?.id, 'kr');
      // 색칠되지 않은 나라를 눌렀을 때.
      expect(data.countryByIsoNumeric(276), isNull);
    });

    test('국가의 술 목록은 카테고리로 좁힐 수 있다', () {
      expect(
        [for (final d in data.drinksInCountry('fr')) d.id],
        ['bordeaux-wine'],
      );
      expect(data.drinksInCountry('fr', categoryId: 'whisky'), isEmpty);
    });

    test('칵테일은 cocktailIds 배열 순서 그대로 나온다', () {
      final bordeaux = data.drink('bordeaux-wine')!;
      expect([
        for (final c in data.cocktailsFor(bordeaux)) c.id,
      ], bordeaux.cocktailIds);
    });

    test('추천 칵테일은 배열 첫 항목이다', () {
      expect(data.drink('bordeaux-wine')!.recommendedCocktailId, 'sangria');
      expect(
        const Drink(
          id: 'x',
          categoryIds: [],
          countryIds: [],
          name: 'x',
          history: '',
          taste: '',
          aroma: '',
          beginnerTip: '',
        ).recommendedCocktailId,
        isNull,
      );
    });

    test('없는 칵테일 id는 조용히 건너뛴다', () {
      const drink = Drink(
        id: 'x',
        categoryIds: [],
        countryIds: [],
        name: 'x',
        history: '',
        taste: '',
        aroma: '',
        beginnerTip: '',
        cocktailIds: ['sangria', 'nope', 'kir'],
      );
      expect(
        [for (final c in data.cocktailsFor(drink)) c.id],
        ['sangria', 'kir'],
      );
    });
  });

  group('파싱 규칙', () {
    test('hex 색 변환', () {
      expect(parseHexColor('#8E1E3B'), 0xFF8E1E3B);
      expect(parseHexColor('8E1E3B'), 0xFF8E1E3B);
      expect(parseHexColor('#abc'), 0xFFAABBCC);
      expect(parseHexColor('#808E1E3B'), 0x808E1E3B);
      expect(parseHexColor('#nope'), isNull);
      expect(parseHexColor(null), isNull);
    });

    test('모르는 difficulty는 null로 떨어진다', () {
      // 나중에 JSON에 새 값이 추가돼도 구버전 앱이 죽으면 안 된다.
      expect(CocktailDifficulty.fromJson('easy'), CocktailDifficulty.easy);
      expect(CocktailDifficulty.fromJson('expert'), isNull);
      expect(CocktailDifficulty.fromJson(null), isNull);
    });

    test('모르는 필드가 있어도 파싱된다', () {
      final c = Category.fromJson({
        'id': 'brandy',
        'name': '브랜디',
        'mapColor': '#C77A2E',
        'somethingAddedLater': 42,
      });
      expect(c.id, 'brandy');
      expect(c.sortOrder, isNull);
    });

    test('sortOrder가 없는 항목은 뒤로, 동률은 원래 순서 유지', () {
      const items = [
        (id: 'a', o: 2),
        (id: 'b', o: null),
        (id: 'c', o: 1),
        (id: 'd', o: 2),
      ];
      expect(
        [for (final e in sortByOrder(items, (e) => e.o)) e.id],
        ['c', 'a', 'd', 'b'],
      );
    });

    test('version.json 파싱', () {
      final m = DataManifest.fromJson({
        'schemaVersion': 1,
        'dataVersion': 12,
        'dataUrl': 'https://cdn.example.com/drinks_v12.json',
        'minAppVersion': '1.0.0',
      });
      expect(m.dataVersion, 12);
      expect(m.isSchemaSupported, isTrue);
      expect(
        DataManifest.fromJson({
          'schemaVersion': 99,
          'dataVersion': 1,
          'dataUrl': 'https://example.com/x.json',
        }).isSchemaSupported,
        isFalse,
      );
    });

    test('필수 필드가 없으면 던진다 — repository가 잡아 폴백한다', () {
      expect(
        () => Country.fromJson({'id': 'fr', 'name': '프랑스'}),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
