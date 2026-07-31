/// 판매처. 실시간 재고·가격은 다루지 않는다.
/// "이런 앱에서 취급한다" 수준의 정적 정보와 링크만 있다.
class Retailer {
  const Retailer({required this.name, this.deepLink, this.storeUrl});

  /// 앱 또는 매장명.
  final String name;

  /// 앱 스킴. 없으면 null.
  final String? deepLink;

  /// 딥링크 실행에 실패했을 때 폴백할 스토어 주소.
  final String? storeUrl;

  factory Retailer.fromJson(Map<String, dynamic> json) => Retailer(
    name: json['name'] as String,
    deepLink: json['deepLink'] as String?,
    storeUrl: json['storeUrl'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'deepLink': deepLink,
    'storeUrl': storeUrl,
  };

  @override
  String toString() => 'Retailer($name)';
}

/// 핵심 엔티티. 카테고리와 국가를 **배열로** 참조해 다대다를 만든다.
///
/// 와인은 프랑스·이탈리아·칠레에 걸치고, 한 나라가 여러 술을 가질 수 있다.
/// MVP 데이터가 1:1이더라도 구조는 다대다를 유지한다.
class Drink {
  const Drink({
    required this.id,
    required this.categoryIds,
    required this.countryIds,
    required this.name,
    required this.history,
    required this.taste,
    required this.aroma,
    required this.beginnerTip,
    this.abv,
    this.imageUrl,
    this.retailers = const [],
    this.cocktailIds = const [],
    this.sortOrder,
  });

  /// 슬러그. 변경 금지.
  final String id;

  /// 한 술이 여러 카테고리에 속할 수 있다.
  final List<String> categoryIds;

  /// 국경을 넘는 술 대응. 어느 국가를 눌러도 같은 상세로 간다.
  final List<String> countryIds;

  final String name;

  /// 도수. `"12~14도"` 같은 범위 문자열이 온다. 숫자로 파싱하지 않는다.
  final String? abv;

  /// 아래 넷은 전부 초보자 기준 서술이다. 전문용어는 바로 풀어 쓴다.
  final String history;
  final String taste;
  final String aroma;

  /// 실제로 마실 때 도움이 되는 구체적 조언. 필수다.
  final String beginnerTip;

  /// 이미지 소싱 전이라 현재 전부 null이다.
  final String? imageUrl;

  final List<Retailer> retailers;

  /// **배열 순서가 곧 화면 표시 순서다.** 첫 항목이 추천으로 하이라이트된다.
  final List<String> cocktailIds;

  /// 한 국가에 술이 여러 개일 때의 정렬 순서. null이면 배열 순서.
  final int? sortOrder;

  /// 추천 칵테일의 id. 별도 플래그를 두지 않고 배열 첫 항목으로 정한다.
  /// 순서를 바꾸는 것만으로 추천이 교체된다.
  String? get recommendedCocktailId =>
      cocktailIds.isEmpty ? null : cocktailIds.first;

  factory Drink.fromJson(Map<String, dynamic> json) => Drink(
    id: json['id'] as String,
    categoryIds: _stringList(json['categoryIds']),
    countryIds: _stringList(json['countryIds']),
    name: json['name'] as String,
    abv: json['abv'] as String?,
    history: json['history'] as String,
    taste: json['taste'] as String,
    aroma: json['aroma'] as String,
    beginnerTip: json['beginnerTip'] as String,
    imageUrl: json['imageUrl'] as String?,
    retailers: [
      for (final r in (json['retailers'] as List? ?? const []))
        Retailer.fromJson(r as Map<String, dynamic>),
    ],
    cocktailIds: _stringList(json['cocktailIds']),
    sortOrder: (json['sortOrder'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'categoryIds': categoryIds,
    'countryIds': countryIds,
    'name': name,
    'abv': abv,
    'history': history,
    'taste': taste,
    'aroma': aroma,
    'beginnerTip': beginnerTip,
    'imageUrl': imageUrl,
    'retailers': [for (final r in retailers) r.toJson()],
    'cocktailIds': cocktailIds,
    'sortOrder': sortOrder,
  };

  @override
  String toString() => 'Drink($id)';
}

List<String> _stringList(Object? value) => [
  for (final e in (value as List? ?? const [])) e as String,
];
