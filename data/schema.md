# 데이터 스키마

## 설계 원칙

1. **다대다 지원** — 카테고리는 여러 국가에, 국가는 여러 술에 걸린다.
   프로토타입의 1:1 구조를 그대로 쓰면 안 된다.
2. **ID 참조** — 객체를 중첩하지 않고 ID로 연결한다. 중복 없이 관계만 늘릴 수 있다.
3. **확장 자리 미리 확보** — 지금 안 쓰는 필드도 자리를 만들어둔다.
   나중에 필드를 추가하는 건 안전하지만, 이름을 바꾸거나 없애면 구버전 앱이 깨진다.

---

## version.json

앱이 실행 시 이것만 먼저 받아 버전을 비교한다. 작게 유지한다.

```json
{
  "schemaVersion": 1,
  "dataVersion": 12,
  "dataUrl": "https://cdn.example.com/drinks_v12.json",
  "minAppVersion": "1.0.0"
}
```

| 필드 | 설명 |
|---|---|
| `schemaVersion` | 스키마 구조 버전. 앱이 해석 가능한지 판단 |
| `dataVersion` | 콘텐츠 버전. 로컬 캐시보다 크면 다운로드 |
| `dataUrl` | 실제 데이터 파일 주소 |
| `minAppVersion` | 이 데이터를 읽으려면 필요한 최소 앱 버전. 미만이면 다운로드하지 않고 캐시 유지 |

---

## drinks.json

최상위는 4개의 배열로 나뉜다.

```json
{
  "schemaVersion": 1,
  "dataVersion": 12,
  "categories": [],
  "countries": [],
  "drinks": [],
  "cocktails": []
}
```

### categories

지도 상단 버튼이 이 배열에서 생성된다. 하드코딩하지 않는다.

```json
{
  "id": "wine",
  "name": "와인",
  "mapColor": "#8E1E3B",
  "icon": "ti-glass-full",
  "sortOrder": 1
}
```

| 필드 | 필수 | 설명 |
|---|---|---|
| `id` | O | 영문 소문자 슬러그. 변경 금지 |
| `name` | O | 화면 표시명 |
| `mapColor` | O | 이 카테고리 선택 시 국가를 칠할 색 (hex) |
| `icon` | | Tabler 아이콘명 |
| `sortOrder` | | 버튼 정렬 순서. 없으면 배열 순서 |

### countries

```json
{
  "id": "fr",
  "isoNumeric": 250,
  "name": "프랑스",
  "displayNote": "보르도·부르고뉴"
}
```

| 필드 | 필수 | 설명 |
|---|---|---|
| `id` | O | ISO 3166-1 alpha-2 소문자 |
| `isoNumeric` | O | **지도 매칭 키.** TopoJSON feature의 `id`와 대조된다 |
| `name` | O | 화면 표시명 |
| `displayNote` | | 부제 (예: 특정 산지 강조) |

> 스코틀랜드처럼 국가가 아닌 지역은 별도 feature가 없다.
> 영국(826)에 매핑하고 `displayNote`로 지역을 표기한다.

### drinks

핵심 엔티티. 카테고리와 국가를 **배열로** 참조해 다대다를 만든다.

```json
{
  "id": "bordeaux-wine",
  "categoryIds": ["wine"],
  "countryIds": ["fr"],
  "name": "보르도 와인",
  "abv": "12~14도",
  "history": "...",
  "taste": "...",
  "aroma": "...",
  "beginnerTip": "...",
  "imageUrl": null,
  "retailers": [
    { "name": "데일리샷", "deepLink": null, "storeUrl": null }
  ],
  "cocktailIds": ["sangria", "kir", "mulled-wine", "wine-spritz"],
  "sortOrder": 1
}
```

| 필드 | 필수 | 설명 |
|---|---|---|
| `id` | O | 슬러그. 변경 금지 |
| `categoryIds` | O | 배열. 한 술이 여러 카테고리에 속할 수 있다 |
| `countryIds` | O | 배열. 국경을 넘는 술 대응 |
| `name` | O | |
| `abv` | | 도수. 범위 문자열 허용 |
| `history` / `taste` / `aroma` | O | 초보자 기준 서술 |
| `beginnerTip` | O | 실제로 마실 때의 구체적 조언 |
| `imageUrl` | | **현재 전부 null.** 소싱 후 채운다 |
| `retailers` | | 판매처. 실시간 정보 아님 |
| `cocktailIds` | | **배열 순서가 화면 표시 순서.** 첫 항목이 추천으로 하이라이트된다 |
| `sortOrder` | | 한 국가에 여러 술이 있을 때 정렬 |

**retailers 하위**

| 필드 | 설명 |
|---|---|
| `name` | 앱/매장명 |
| `deepLink` | 앱 스킴. 없으면 null |
| `storeUrl` | 딥링크 실패 시 폴백할 스토어 주소 |

### cocktails

```json
{
  "id": "sangria",
  "name": "상그리아",
  "hint": "과일과 레드와인의 상큼한 조합",
  "recipe": "...",
  "taste": "...",
  "difficulty": "easy",
  "imageUrl": null,
  "recipeVerified": false
}
```

| 필드 | 필수 | 설명 |
|---|---|---|
| `id` | O | 슬러그 |
| `name` | O | |
| `hint` | O | 리스트에 표시되는 한 줄 |
| `recipe` | O | 계량 포함 |
| `taste` | O | |
| `difficulty` | | `easy` / `medium` / `hard` |
| `imageUrl` | | 현재 null |
| `recipeVerified` | | 계량 검증 여부. 샘플 데이터는 전부 false |

---

## 추천 칵테일 결정 방식

별도 `recommended` 플래그를 두지 않는다.
`drinks[].cocktailIds` 배열의 **첫 번째 항목**이 추천이다.

이유: 플래그를 쓰면 실수로 두 개가 true가 되거나 하나도 없는 상태가 생긴다.
배열 순서로 정하면 구조적으로 "정확히 하나"가 보장되고, 순서를 바꾸는 것만으로
추천을 교체할 수 있다.

---

## 렌더링 시 주의

카테고리 선택 시 색칠할 국가를 찾는 흐름:

```
선택된 categoryId
  → drinks에서 categoryIds에 포함된 것들 필터
  → 그 drinks의 countryIds를 모두 수집 (중복 제거)
  → 각 국가의 isoNumeric으로 지도 path 찾아 mapColor 적용
```

**한 국가가 여러 술을 가질 때**: 국가를 눌렀을 때 술이 2개 이상이면
바로 상세로 가지 말고 선택 목록을 먼저 띄운다.
현재 카테고리가 선택된 상태라면 해당 카테고리의 술만 추린다.

**한 술이 여러 국가에 걸릴 때**: 어느 국가를 눌러도 같은 상세 화면으로 간다.
