# 세계 술 지도 (World Liquor Map)

세계지도에서 술 카테고리를 골라 나라별 전통주를 탐험하는 앱. 서버 없이 동작하며 광고로 수익화한다.

## 이 문서의 목적

이전 기획 대화의 결론을 옮겨온 것이다. 여기 적힌 결정사항은 이미 합의된 것이므로,
다시 제안하거나 뒤집지 말고 이 위에서 이어서 작업한다.

---

## 핵심 컨셉

1. 세계지도에서 카테고리(와인/위스키/사케/막걸리/데킬라...)를 선택하면 해당 술을 만드는 국가가 색칠된다
2. 색칠된 국가를 누르면 그 나라 술의 역사·맛·향·초보자 팁을 보여준다
3. 술 상세 하단에 구매 가능한 앱 목록과 칵테일 리스트가 붙는다
4. 칵테일 리스트의 첫 항목은 "베스트 추천"으로 노란빛 하이라이트 처리
5. 칵테일을 누르면 레시피와 맛 설명 페이지로 이동

타겟은 술 초보자다. 모든 설명은 전문용어를 풀어서, 처음 접하는 사람이 이해할 수 있게 쓴다.

---

## 확정된 기술 결정

### 서버 없음 (정적 JSON 원격 호스팅)

백엔드도 DB도 만들지 않는다. 대신:

```
앱 실행
  → version.json 체크 (작은 파일)
  → 원격 버전 > 로컬 버전이면 drinks.json 다운로드
  → 로컬 캐시에 저장
  → 이후 오프라인에서도 캐시로 동작
```

- 콘텐츠 수정/추가는 JSON 파일 교체만으로 즉시 반영 (스토어 재심사 불필요)
- 기능·레이아웃 변경 시에만 재빌드
- 호스팅은 Cloudflare Pages 또는 Firebase Hosting 무료 티어

### 앱 내장 JSON 폴백 필수

`data/drinks.json`을 앱 번들에 항상 포함한다. 첫 실행과 오프라인 상황의 폴백이다.
이게 없으면 "인터넷 없으면 빈 화면"이 되므로 생략 금지.

### 카테고리 하드코딩 금지

카테고리 버튼 목록은 JSON에서 생성한다. 새 카테고리(예: 브랜디) 추가 시
JSON에 행만 추가하면 버튼까지 자동으로 생기게 한다.

### 스키마 하위호환

필드 추가는 자유. 기존 필드명 변경·삭제는 금지 (구버전 앱 크래시).
`schemaVersion` 필드로 버전을 관리한다.

### 프레임워크: Flutter

이 앱은 화면 대부분이 "불규칙한 벡터 도형 170여 개를 그리고, 확대/축소하고, 탭을 판정하는" 일이다.
`CustomPainter` + `InteractiveViewer` + `Path.contains()`가 정확히 이 문제를 위한 도구이므로 Flutter를 쓴다.

주요 패키지:

| 용도 | 패키지 |
|---|---|
| 광고 | `google_mobile_ads` |
| 로컬 캐시 | `shared_preferences` (버전 정보) + `path_provider` (JSON 본문) |
| 네트워크 | `http` |
| 딥링크 실행 | `url_launcher` |

상태관리는 화면이 4개뿐이라 `Provider`나 `ValueNotifier` 정도면 충분하다. Riverpod/Bloc은 과하다.

### 지도: 런타임에 D3를 쓰지 않는다

지도는 고정이고 사용자마다 다르지 않다. 투영 계산을 앱에서 매번 할 이유가 없다.
**빌드 시점에 한 번만 계산해서 SVG path 문자열로 저장하고, 앱은 그것만 그린다.**

```
Natural Earth TopoJSON (world-atlas@2/countries-110m.json)
  → scripts/build-map.mjs 를 로컬에서 1회 실행 (d3-geo + topojson-client)
  → assets/map/country_paths.json  { "250": "M120,45L121,46Z", ... }
  → Flutter가 parseSvgPathData()로 Path 객체 생성 후 CustomPainter로 렌더
```

이 방식의 이점:
- 앱에 d3/topojson 불필요, 런타임 파싱 비용 없음, 용량 감소
- 투영법을 바꾸고 싶으면 스크립트만 다시 돌리면 된다

투영법은 `geoNaturalEarth1()`, 기준 캔버스는 640×340.
국가 매칭 키는 **ISO 3166-1 numeric** (프랑스 250, 영국 826, 일본 392, 대한민국 410, 멕시코 484).
TopoJSON feature의 `id`가 이 값이다.

path 문자열 파싱은 `path_drawing` 패키지의 `parseSvgPathData()`를 쓴다.
앱 시작 시 한 번만 파싱해서 `Map<int, Path>`로 캐시하고, 매 프레임 재파싱하지 않는다.

---

## 알려진 미해결 이슈

작업 시 반드시 고려할 것들:

### 작은 국가 터치 문제 (최우선)

모바일에서 룩셈부르크, 몰타, 싱가포르 같은 작은 나라는 손가락으로 못 누른다.
Flutter에서는 2단계 판정으로 푼다:

1. `Path.contains(offset)` 으로 정확히 안에 들어간 국가를 찾는다
2. 없으면 탭 지점 반경 약 20논리픽셀 내에서 가장 가까운 활성 국가를 찾아 폴백한다
   (`path.getBounds()`로 1차 필터 후 거리 비교)

여기에 `InteractiveViewer`로 핀치 줌/팬을 더한다. 확대 상태에서는 폴백 반경을
스케일로 나눠서 줄인다 (확대했는데도 엉뚱한 나라가 잡히면 안 된다).

그래도 부족하면 지도 아래 국가 리스트 뷰를 병행 제공한다.

### 이미지 소싱

현재 프로토타입은 아이콘으로 대체돼 있다. 술 앱은 비주얼이 핵심이므로
실제 사진이 필요하다. 스키마에 `imageUrl` 자리는 만들어뒀으니 비워두고 진행,
소싱 후 JSON만 갱신하면 되도록 짠다. (직접 촬영 또는 스톡 라이선스 구매)

### 판매처 정보

실시간 재고·가격 연동은 하지 않는다 (서버 + 제휴 필요).
"이런 앱에서 취급한다" 수준의 정적 정보 + 딥링크만 제공한다.
딥링크 실패 시 스토어 링크로 폴백.

### 광고 영역

- 지도 화면: 하단 배너만. 지도 위에 절대 겹치지 않게 한다
- 술 상세 진입 시: 전면광고 (빈도 제한 필요)
- 칵테일 상세: 배너만
- 제휴 링크(어필리에이트) 수익도 판매처 링크에 검토

---

## MVP 범위

처음부터 전세계를 채우려 하면 못 끝낸다. 아래로 시작한다.

- 카테고리 5개: 와인, 위스키, 사케, 막걸리, 데킬라
- 국가 5개: 프랑스, 영국, 일본, 대한민국, 멕시코
- 국가당 술 1종, 술당 칵테일 4종

**단, 데이터 구조는 처음부터 다대다를 지원해야 한다.**
와인은 프랑스·이탈리아·칠레·스페인 등 여러 나라에 걸치고,
한 나라가 여러 술을 가질 수 있다. 프로토타입은 1:1로 단순화돼 있지만
실제 구현은 `data/schema.md` 구조를 따른다.

---

## 미구현 (MVP 이후)

- 검색
- 즐겨찾기 / 마셔본 술 체크 (게이미피케이션 — 재방문율 확보용으로 우선순위 높음)
- 설정 화면
- 데이터 백업/복원 (파일 내보내기)

## 명시적 비목표

아래는 서버가 필요해지므로 당분간 하지 않는다:
- 계정 / 기기간 동기화
- 사용자 리뷰·평점
- 실시간 가격·재고

---

## 콘텐츠 작성 원칙

- 어떤 출처의 문장도 그대로 복사하지 않는다. 전부 새로 쓴다 (저작권 리스크)
- 초보자 기준. "탄닌", "도정률" 같은 용어는 쓰더라도 바로 풀어 설명한다
- 각 술에 `beginnerTip` 필수 — 실제로 마실 때 도움이 되는 구체적 조언
- 칵테일 레시피 계량은 검증 후 반영 (프로토타입 값은 대략치)

---

## 파일 안내

- `data/schema.md` — JSON 스키마 정의. 구현 전 반드시 읽을 것
- `data/drinks.sample.json` — 스키마를 따르는 샘플 데이터
- `scripts/build-map.mjs` — TopoJSON을 SVG path JSON으로 변환. 자세한 건 `scripts/README.md`
- `prototype/map-prototype.html` — 동작하는 프로토타입. 브라우저에서 바로 열림.
  플로우 확인용이며 프로덕션 코드가 아니다. **스키마 해석 로직과 화면 전환 흐름만** 참고한다.
  (여기 쓰인 런타임 d3 로딩 방식은 앱에서 쓰지 않는다 — 위 "지도" 항목 참고)

## 목표 프로젝트 구조

```
lib/
  main.dart
  models/          drink.dart, cocktail.dart, category.dart, country.dart
  data/
    repository.dart      version.json 체크 → 다운로드 → 캐시 → 폴백
    asset_loader.dart    번들 내장 JSON 로드
  screens/
    map_screen.dart
    drink_picker_screen.dart   한 국가에 술이 여러 개일 때
    drink_detail_screen.dart
    cocktail_detail_screen.dart
  widgets/
    world_map.dart       CustomPainter + InteractiveViewer + 탭 판정
    category_tabs.dart   JSON에서 생성. 하드코딩 금지
    ad_banner.dart
assets/
  data/drinks.json           내장 폴백
  map/country_paths.json     빌드 스크립트 산출물
scripts/
  build-map.mjs
```

## 작업 순서 제안

1. `flutter create` + 모델 클래스 (스키마 그대로)
2. `scripts/build-map.mjs` 실행해서 `country_paths.json` 생성
3. `world_map.dart` — 지도 렌더 + 탭 판정. **여기가 이 앱에서 가장 어려운 부분이니 먼저 끝낸다**
4. 화면 4개 연결 (프로토타입 흐름 그대로)
5. repository (원격 JSON + 캐시 + 폴백)
6. AdMob 배치
