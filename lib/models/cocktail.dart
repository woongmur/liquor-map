/// 만들기 난이도. JSON에서는 `"easy"` / `"medium"` / `"hard"` 문자열이다.
enum CocktailDifficulty {
  easy,
  medium,
  hard;

  /// 모르는 값이면 null을 준다. 나중에 JSON에 `"expert"` 같은 값이 추가돼도
  /// 구버전 앱이 죽지 않아야 하므로 던지지 않는다.
  static CocktailDifficulty? fromJson(Object? value) {
    if (value is! String) return null;
    for (final d in CocktailDifficulty.values) {
      if (d.name == value) return d;
    }
    return null;
  }
}

/// 술 상세 하단에 붙는 칵테일.
///
/// "추천" 여부는 이 클래스에 없다. `Drink.cocktailIds`의 첫 항목이 추천이다
/// (플래그를 쓰면 두 개가 true이거나 하나도 없는 상태가 생긴다).
class Cocktail {
  const Cocktail({
    required this.id,
    required this.name,
    required this.hint,
    required this.recipe,
    required this.taste,
    this.difficulty,
    this.imageUrl,
    this.recipeVerified = false,
  });

  /// 슬러그. 변경 금지 — `Drink.cocktailIds`가 이 값을 참조한다.
  final String id;

  final String name;

  /// 목록에 한 줄로 표시되는 설명.
  final String hint;

  /// 계량이 포함된 레시피.
  final String recipe;

  final String taste;

  /// 값이 없거나 해석할 수 없으면 null.
  final CocktailDifficulty? difficulty;

  /// 이미지 소싱 전이라 현재 전부 null이다. 소싱 후 JSON만 갱신하면 된다.
  final String? imageUrl;

  /// 계량을 실제로 검증했는지. 샘플 데이터는 전부 false다.
  final bool recipeVerified;

  factory Cocktail.fromJson(Map<String, dynamic> json) => Cocktail(
    id: json['id'] as String,
    name: json['name'] as String,
    hint: json['hint'] as String,
    recipe: json['recipe'] as String,
    taste: json['taste'] as String,
    difficulty: CocktailDifficulty.fromJson(json['difficulty']),
    imageUrl: json['imageUrl'] as String?,
    recipeVerified: json['recipeVerified'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'hint': hint,
    'recipe': recipe,
    'taste': taste,
    'difficulty': difficulty?.name,
    'imageUrl': imageUrl,
    'recipeVerified': recipeVerified,
  };

  @override
  String toString() => 'Cocktail($id)';
}
