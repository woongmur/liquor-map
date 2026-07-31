// TopoJSON 국가 경계를 SVG path 문자열로 미리 변환한다.
//
// 앱은 d3나 topojson을 포함하지 않는다. 이 스크립트를 로컬에서 한 번만 돌려서
// 나온 country_paths.json을 assets에 넣고, Flutter는 path 문자열만 파싱해 그린다.
//
// 실행:
//   cd scripts && npm install && node build-map.mjs
//
// 투영법이나 캔버스 크기를 바꾸고 싶으면 아래 상수만 고치고 다시 돌리면 된다.

import { writeFileSync, mkdirSync, existsSync } from "node:fs";
import { geoNaturalEarth1, geoPath } from "d3-geo";
import { feature } from "topojson-client";

const TOPO_URL = "https://cdn.jsdelivr.net/npm/world-atlas@2/countries-110m.json";
const OUT_DIR = "../assets/map";
const OUT_FILE = `${OUT_DIR}/country_paths.json`;

// Flutter CustomPainter가 기준으로 삼을 캔버스. 실제 화면 크기에 맞춰
// 앱에서 스케일 변환하므로, 여기서는 논리 좌표계만 정해두면 된다.
const WIDTH = 640;
const HEIGHT = 340;

// 소수점 자리수. 1이면 충분하고 파일 크기가 눈에 띄게 줄어든다.
const PRECISION = 1;

const res = await fetch(TOPO_URL);
if (!res.ok) throw new Error(`토폴로지 다운로드 실패: ${res.status}`);
const topology = await res.json();

const geo = feature(topology, topology.objects.countries);
const projection = geoNaturalEarth1().fitSize([WIDTH, HEIGHT], geo);
const pathGen = geoPath(projection);

const paths = {};
const skipped = [];

for (const f of geo.features) {
  // id는 ISO 3166-1 numeric. 없는 feature(북키프로스, 코소보 등)는 건너뛴다.
  if (f.id == null) {
    skipped.push(f.properties?.name ?? "(이름 없음)");
    continue;
  }
  const d = pathGen(f);
  if (!d) {
    skipped.push(f.properties?.name ?? String(f.id));
    continue;
  }
  // 좌표 소수점 줄이기
  paths[String(Number(f.id))] = d.replace(/-?\d+\.\d+/g, (n) =>
    String(Number(Number(n).toFixed(PRECISION)))
  );
}

if (!existsSync(OUT_DIR)) mkdirSync(OUT_DIR, { recursive: true });

writeFileSync(
  OUT_FILE,
  JSON.stringify({
    projection: "geoNaturalEarth1",
    width: WIDTH,
    height: HEIGHT,
    source: "Natural Earth via world-atlas@2 (public domain)",
    paths,
  })
);

const sizeKb = (Buffer.byteLength(JSON.stringify(paths)) / 1024).toFixed(0);
console.log(`생성 완료: ${OUT_FILE}`);
console.log(`  국가 ${Object.keys(paths).length}개, 약 ${sizeKb}KB`);
if (skipped.length) console.log(`  건너뜀 (ISO 코드 없음): ${skipped.join(", ")}`);

// 앱에서 쓰는 국가들이 실제로 포함됐는지 확인
const REQUIRED = { 250: "프랑스", 826: "영국", 392: "일본", 410: "대한민국", 484: "멕시코" };
const missing = Object.entries(REQUIRED).filter(([iso]) => !(iso in paths));
console.log(
  missing.length
    ? `  경고 — 누락된 필수 국가: ${missing.map(([, n]) => n).join(", ")}`
    : `  필수 국가 5개 모두 포함됨`
);
