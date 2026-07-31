/// 지도 상단 카테고리 버튼의 원본 데이터.
///
/// 버튼 목록은 이 배열에서 생성한다. 하드코딩하지 않는다 — 새 카테고리는
/// JSON에 행을 추가하는 것만으로 버튼까지 생겨야 한다.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.mapColor,
    this.icon,
    this.sortOrder,
  });

  /// 영문 소문자 슬러그. 변경 금지 — `Drink.categoryIds`가 이 값을 참조한다.
  final String id;

  /// 화면 표시명.
  final String name;

  /// 이 카테고리 선택 시 국가를 칠할 색. `"#8E1E3B"` 형태의 hex 문자열.
  final String mapColor;

  /// Tabler 아이콘명.
  final String? icon;

  /// 버튼 정렬 순서. null이면 JSON 배열 순서를 따른다.
  final int? sortOrder;

  /// [mapColor]를 ARGB 정수로 바꾼 값. 화면에서는 `Color(c.mapColorValue!)`로 쓴다.
  ///
  /// 파싱에 실패하면 null이다. hex 하나가 잘못됐다고 앱이 죽으면 안 되므로
  /// 던지지 않고, 호출부에서 기본색으로 대체하게 둔다.
  int? get mapColorValue => parseHexColor(mapColor);

  /// 필수 필드가 없거나 타입이 다르면 던진다.
  /// 원격 데이터가 깨졌을 때는 repository가 이걸 잡아 내장 폴백으로 되돌린다.
  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    mapColor: json['mapColor'] as String,
    icon: json['icon'] as String?,
    sortOrder: (json['sortOrder'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mapColor': mapColor,
    'icon': icon,
    'sortOrder': sortOrder,
  };

  @override
  String toString() => 'Category($id)';
}

/// `"#8E1E3B"`, `"8E1E3B"`, `"#abc"`, `"#FF8E1E3B"` 을 ARGB 정수로 바꾼다.
/// 알파가 없으면 불투명(FF)으로 채운다. 해석할 수 없으면 null.
int? parseHexColor(String? hex) {
  if (hex == null) return null;
  var s = hex.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 3) {
    s = s.split('').map((c) => '$c$c').join();
  }
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return null;
  return int.tryParse(s, radix: 16);
}
