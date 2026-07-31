# 지도 빌드 스크립트

TopoJSON 국가 경계를 SVG path 문자열로 미리 변환한다.
앱은 d3나 topojson을 포함하지 않고, 여기서 나온 결과물만 그린다.

## 실행

```bash
cd scripts
npm install
node build-map.mjs
```

`assets/map/country_paths.json`이 생성된다. 인터넷 연결이 필요하지만 최초 1회뿐이고,
이후 투영법이나 캔버스 크기를 바꿀 때만 다시 돌리면 된다.

## 출력 형태

```json
{
  "projection": "geoNaturalEarth1",
  "width": 640,
  "height": 340,
  "paths": {
    "250": "M120.4,45.1L121.2,46.8Z",
    "392": "M..."
  }
}
```

키는 ISO 3166-1 numeric 문자열이다. `data/drinks.json`의 `countries[].isoNumeric`과 이걸로 매칭한다.

## Flutter 쪽 연결

`pubspec.yaml`:

```yaml
dependencies:
  path_drawing: ^1.0.1

flutter:
  assets:
    - assets/map/country_paths.json
    - assets/data/drinks.json
```

앱 시작 시 한 번만 파싱해서 캐시한다. 매 프레임 재파싱하면 안 된다.

```dart
final raw = json.decode(await rootBundle.loadString('assets/map/country_paths.json'));
final Map<int, Path> countryPaths = {
  for (final e in (raw['paths'] as Map).entries)
    int.parse(e.key): parseSvgPathData(e.value as String),
};
```

`width`/`height`는 이 path들이 그려진 기준 좌표계다. 실제 화면 크기에 맞추려면
`canvas.scale(size.width / raw['width'])`처럼 변환하고, 탭 좌표는 역변환해서
`Path.contains()`에 넘긴다.

## 주의

북키프로스, 코소보, 소말릴란드처럼 ISO numeric 코드가 없는 feature는 자동으로 제외된다.
실행 후 콘솔에 건너뛴 목록과 필수 국가 5개 포함 여부가 출력되니 확인할 것.
