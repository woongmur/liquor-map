/// 지도에서 색칠 대상이 되는 국가.
///
/// 스코틀랜드처럼 별도 지도 feature가 없는 지역은 국가로 만들지 않는다.
/// 영국(826)에 매핑하고 [displayNote]에 지역명을 적는다.
class Country {
  const Country({
    required this.id,
    required this.isoNumeric,
    required this.name,
    this.displayNote,
  });

  /// ISO 3166-1 alpha-2 소문자. `Drink.countryIds`가 이 값을 참조한다.
  final String id;

  /// **지도 매칭 키.** `assets/map/country_paths.json`의 키(= TopoJSON feature id)와
  /// 대조되는 ISO 3166-1 numeric 값이다. 프랑스 250, 영국 826, 일본 392,
  /// 대한민국 410, 멕시코 484.
  final int isoNumeric;

  /// 화면 표시명.
  final String name;

  /// 부제. 특정 산지를 강조할 때 쓴다 (예: "보르도·부르고뉴").
  final String? displayNote;

  factory Country.fromJson(Map<String, dynamic> json) => Country(
    id: json['id'] as String,
    isoNumeric: (json['isoNumeric'] as num).toInt(),
    name: json['name'] as String,
    displayNote: json['displayNote'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'isoNumeric': isoNumeric,
    'name': name,
    'displayNote': displayNote,
  };

  @override
  String toString() => 'Country($id/$isoNumeric)';
}
