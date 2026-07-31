import 'category.dart';
import 'cocktail.dart';
import 'country.dart';
import 'drink.dart';

export 'category.dart';
export 'cocktail.dart';
export 'country.dart';
export 'drink.dart';

/// 이 앱 빌드가 해석할 수 있는 최대 스키마 버전.
///
/// 필드 추가는 하위호환이므로 이 값을 올리지 않는다.
/// 기존 필드의 의미가 바뀌는 변경이 생길 때만 올린다.
const int supportedSchemaVersion = 1;

/// `version.json`. 앱이 실행 시 이것만 먼저 받아 캐시와 비교한다.
class DataManifest {
  const DataManifest({
    required this.schemaVersion,
    required this.dataVersion,
    required this.dataUrl,
    this.minAppVersion,
  });

  /// 앱이 해석 가능한 구조인지 판단하는 값.
  final int schemaVersion;

  /// 콘텐츠 버전. 로컬 캐시보다 크면 [dataUrl]을 받는다.
  final int dataVersion;

  /// 실제 데이터 파일 주소.
  final String dataUrl;

  /// 이 데이터를 읽는 데 필요한 최소 앱 버전.
  /// 현재 앱이 이보다 낮으면 받지 않고 캐시를 유지한다. 비교는 repository가 한다.
  final String? minAppVersion;

  /// 구조를 해석할 수 있는지. false면 다운로드하지 말고 캐시/내장본을 쓴다.
  bool get isSchemaSupported => schemaVersion <= supportedSchemaVersion;

  factory DataManifest.fromJson(Map<String, dynamic> json) => DataManifest(
    schemaVersion: (json['schemaVersion'] as num).toInt(),
    dataVersion: (json['dataVersion'] as num).toInt(),
    dataUrl: json['dataUrl'] as String,
    minAppVersion: json['minAppVersion'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'dataVersion': dataVersion,
    'dataUrl': dataUrl,
    'minAppVersion': minAppVersion,
  };

  @override
  String toString() => 'DataManifest(schema $schemaVersion, data $dataVersion)';
}

/// `drinks.json` 전체. 네 배열과, 그 배열들을 id로 잇는 조회 인덱스를 함께 갖는다.
///
/// 객체를 중첩하지 않고 id로 연결하는 구조이므로, 화면에서 관계를 따라가려면
/// 매번 리스트를 훑는 대신 여기 메서드를 쓴다.
class LiquorData {
  LiquorData({
    required this.schemaVersion,
    required this.dataVersion,
    required List<Category> categories,
    required List<Country> countries,
    required List<Drink> drinks,
    required List<Cocktail> cocktails,
  }) : categories = sortByOrder(categories, (c) => c.sortOrder),
       countries = List.unmodifiable(countries),
       drinks = List.unmodifiable(drinks),
       cocktails = List.unmodifiable(cocktails),
       _categoryById = {for (final c in categories) c.id: c},
       _countryById = {for (final c in countries) c.id: c},
       _countryByIso = {for (final c in countries) c.isoNumeric: c},
       _drinkById = {for (final d in drinks) d.id: d},
       _cocktailById = {for (final c in cocktails) c.id: c};

  final int schemaVersion;
  final int dataVersion;

  /// 카테고리 탭이 이 순서 그대로 그려진다. `sortOrder`가 이미 적용돼 있다.
  final List<Category> categories;

  final List<Country> countries;

  /// JSON에 적힌 순서 그대로다. 정렬은 화면 단위 조회 메서드에서 한다.
  final List<Drink> drinks;

  final List<Cocktail> cocktails;

  final Map<String, Category> _categoryById;
  final Map<String, Country> _countryById;
  final Map<int, Country> _countryByIso;
  final Map<String, Drink> _drinkById;
  final Map<String, Cocktail> _cocktailById;

  Category? category(String id) => _categoryById[id];

  Country? country(String id) => _countryById[id];

  /// 지도에서 탭한 국가의 ISO numeric으로 국가를 찾는다.
  /// 데이터에 없는 나라(= 색칠되지 않은 나라)면 null.
  Country? countryByIsoNumeric(int isoNumeric) => _countryByIso[isoNumeric];

  Drink? drink(String id) => _drinkById[id];

  Cocktail? cocktail(String id) => _cocktailById[id];

  /// 해당 카테고리에 속한 술들. `sortOrder` 순.
  List<Drink> drinksInCategory(String categoryId) => sortByOrder([
    for (final d in drinks)
      if (d.categoryIds.contains(categoryId)) d,
  ], (d) => d.sortOrder);

  /// 카테고리를 골랐을 때 색칠할 국가들의 ISO numeric 집합.
  ///
  /// 흐름은 schema.md 그대로다:
  /// 카테고리에 걸린 술을 모으고 → 그 술들의 `countryIds`를 합치고 →
  /// 각 국가의 `isoNumeric`으로 지도 path를 찾는다.
  Set<int> highlightedIsoNumerics(String categoryId) => {
    for (final d in drinksInCategory(categoryId))
      for (final countryId in d.countryIds)
        if (_countryById[countryId] case final c?) c.isoNumeric,
  };

  /// 한 국가의 술 목록. `sortOrder` 순.
  ///
  /// [categoryId]를 주면 그 카테고리의 술만 남긴다. 카테고리가 선택된 상태에서
  /// 국가를 눌렀을 때 쓴다. 결과가 2개 이상이면 상세로 바로 가지 말고
  /// 선택 목록을 먼저 띄운다.
  List<Drink> drinksInCountry(String countryId, {String? categoryId}) =>
      sortByOrder([
        for (final d in drinks)
          if (d.countryIds.contains(countryId) &&
              (categoryId == null || d.categoryIds.contains(categoryId)))
            d,
      ], (d) => d.sortOrder);

  /// 술 상세에 표시할 칵테일들. `cocktailIds` 배열 순서 그대로이므로
  /// **첫 항목이 추천**이다. 없는 id는 조용히 건너뛴다.
  List<Cocktail> cocktailsFor(Drink drink) => [
    for (final id in drink.cocktailIds) ?_cocktailById[id],
  ];

  factory LiquorData.fromJson(Map<String, dynamic> json) => LiquorData(
    schemaVersion: (json['schemaVersion'] as num).toInt(),
    dataVersion: (json['dataVersion'] as num).toInt(),
    categories: [
      for (final e in (json['categories'] as List? ?? const []))
        Category.fromJson(e as Map<String, dynamic>),
    ],
    countries: [
      for (final e in (json['countries'] as List? ?? const []))
        Country.fromJson(e as Map<String, dynamic>),
    ],
    drinks: [
      for (final e in (json['drinks'] as List? ?? const []))
        Drink.fromJson(e as Map<String, dynamic>),
    ],
    cocktails: [
      for (final e in (json['cocktails'] as List? ?? const []))
        Cocktail.fromJson(e as Map<String, dynamic>),
    ],
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'dataVersion': dataVersion,
    'categories': [for (final c in categories) c.toJson()],
    'countries': [for (final c in countries) c.toJson()],
    'drinks': [for (final d in drinks) d.toJson()],
    'cocktails': [for (final c in cocktails) c.toJson()],
  };

  @override
  String toString() =>
      'LiquorData(v$dataVersion, 카테고리 ${categories.length} · '
      '국가 ${countries.length} · 술 ${drinks.length} · 칵테일 ${cocktails.length})';
}

/// `sortOrder` 기준 정렬.
///
/// 값이 같으면 원래 배열 순서를 유지하고, `sortOrder`가 없는 항목은 뒤로 보낸다.
/// (Dart의 `List.sort`는 안정 정렬이 아니라서 원래 인덱스를 직접 타이브레이커로 쓴다.)
List<T> sortByOrder<T>(List<T> items, int? Function(T) orderOf) {
  final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
  indexed.sort((a, b) {
    final ao = orderOf(a.$2);
    final bo = orderOf(b.$2);
    if (ao != bo) {
      if (ao == null) return 1;
      if (bo == null) return -1;
      return ao.compareTo(bo);
    }
    return a.$1.compareTo(b.$1);
  });
  return List.unmodifiable([for (final e in indexed) e.$2]);
}
