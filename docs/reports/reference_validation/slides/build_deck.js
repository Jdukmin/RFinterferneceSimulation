const pptxgen = require("pptxgenjs");
const pres = new pptxgen();
pres.layout = "LAYOUT_WIDE";           // 13.3 x 7.5
pres.author = "RF Coexistence Screening Tool";
pres.title  = "KARI 논문 교차검증";

// ---------- palette ----------
const NAVY = "1E2761", DEEP = "141B3D", ICE = "CADCFC", WHITE = "FFFFFF";
const TEAL = "02C39A";   // verified / match
const AMBER= "E8A33D";   // Tier-4 boundary
const RED  = "C74B50";   // defect
const INK  = "1F2430", MUTED = "6B7280", PAPER = "F4F6FA";
const HEAD = "Cambria", BODY = "Calibri";

const A = "/tmp/claude-0/-home-user-RFinterferneceSimulation/375a6333-fc2a-58be-9078-2eaaa5b8d97c/scratchpad/deck/assets/";

// ---------- helpers ----------
function dark(){ const s = pres.addSlide(); s.background = { color: DEEP }; return s; }
function light(){ const s = pres.addSlide(); s.background = { color: WHITE }; return s; }

let pageNo = 1;
function title(s, t, sub, onDark){
  pageNo++;
  s.addText(t, { x:0.6, y:0.42, w:12.1, h:0.62, isTextBox:true, margin:0,
    fontFace:HEAD, fontSize:32, bold:true, color: onDark?WHITE:NAVY });
  if (sub) s.addText(sub, { x:0.6, y:1.06, w:12.1, h:0.34, isTextBox:true, margin:0,
    fontFace:BODY, fontSize:13, color: onDark?ICE:MUTED });
  s.addText(String(pageNo), { x:12.5, y:6.95, w:0.4, h:0.3, isTextBox:true, margin:0,
    fontFace:BODY, fontSize:10, color: onDark?"56607F":"AFB6C4", align:"right" });
}

// numbered badge (the deck's repeating motif)
function badge(s, x, y, n, col){
  s.addShape(pres.ShapeType.ellipse, { x, y, w:0.4, h:0.4, fill:{color:col} });
  s.addText(String(n), { x, y, w:0.4, h:0.4, isTextBox:true, margin:0, align:"center",
    valign:"middle", fontFace:BODY, fontSize:14, bold:true, color:WHITE });
}

// small status chip
function chip(s, x, y, txt, col, w){
  w = w || 1.5;
  s.addShape(pres.ShapeType.roundRect, { x, y, w, h:0.3, rectRadius:0.14, fill:{color:col} });
  s.addText(txt, { x, y, w, h:0.3, isTextBox:true, margin:0, align:"center", valign:"middle",
    fontFace:BODY, fontSize:10, bold:true, color:WHITE });
}

// panel label above an image
function panel(s, x, y, w, h, img, cap, capCol){
  s.addShape(pres.ShapeType.roundRect, { x:x-0.08, y:y-0.08, w:w+0.16, h:h+0.16,
    rectRadius:0.06, fill:{color:PAPER} });
  s.addImage({ path:img, x, y, w, h });
  s.addText(cap, { x:x-0.08, y:y+h+0.12, w:w+0.16, h:0.26, isTextBox:true, margin:0,
    fontFace:BODY, fontSize:10, italic:true, color:capCol||MUTED });
}

function tbl(s, rows, opts){
  s.addTable(rows, Object.assign({
    border:{ type:"solid", pt:0.5, color:"DDE2EC" },
    fontFace:BODY, fontSize:11, color:INK, valign:"middle", autoPage:false
  }, opts));
}
function hdr(t){ return { text:t, options:{ bold:true, color:WHITE, fill:{color:NAVY}, fontSize:11 } }; }

/* ============================ 1. TITLE ============================ */
{
  const s = dark();
  s.addShape(pres.ShapeType.ellipse, { x:9.6, y:-1.7, w:6.2, h:6.2, fill:{color:NAVY} });
  s.addShape(pres.ShapeType.ellipse, { x:11.1, y:4.3, w:3.4, h:3.4, fill:{color:"1A2350"} });
  s.addText("교차검증 보고", { x:0.85, y:1.5, w:8.6, h:0.4, isTextBox:true, margin:0,
    fontFace:BODY, fontSize:14, bold:true, color:TEAL, charSpacing:3 });
  s.addText("KARI 논문 vs 시뮬레이션 도구", { x:0.85, y:2.15, w:9.35, h:0.95, isTextBox:true, margin:0,
    fontFace:HEAD, fontSize:37, bold:true, color:WHITE });
  s.addText("논문 원문 Figure·Table과 도구 분석 결과의 정량 대조\n분석조건 · 분석방법 · 재현범위 · 재현불가 경계",
    { x:0.85, y:3.6, w:8.4, h:0.9, isTextBox:true, margin:0, fontFace:BODY, fontSize:15,
      color:ICE, lineSpacing:24 });

  const stats = [["4","검증 논문"],["3","전문 확보"],["628","회귀 통과"],["2","결함 발견"]];
  stats.forEach((v,i)=>{
    const x = 0.85 + i*2.15;
    s.addText(v[0], { x, y:5.15, w:1.9, h:0.62, isTextBox:true, margin:0,
      fontFace:HEAD, fontSize:34, bold:true, color: i===3?RED:TEAL });
    s.addText(v[1], { x, y:5.8, w:1.9, h:0.3, isTextBox:true, margin:0,
      fontFace:BODY, fontSize:11, color:ICE });
  });
  s.addText("Spacecraft RF Coexistence & Antenna Interference Screening Tool  ·  Phase 6b",
    { x:0.85, y:6.75, w:9, h:0.3, isTextBox:true, margin:0, fontFace:BODY, fontSize:10, color:"7A85A8" });
  s.addNotes("교차검증 목적: 논문이 실제로 무엇을 어떤 조건에서 계산했는지 확인하고, 도구가 그중 무엇을 정확히 재현하고 무엇을 재현할 수 없는지 정량 대조한다.");
}

/* ============================ 2. 검증 대상 ============================ */
{
  const s = light();
  title(s, "검증 대상 논문", "전문 확보 3편 + 초록 확보 1편 — 인용 정보는 원문 대조로 전면 수정됨");

  const rows = [[hdr("ID"),hdr("논문"),hdr("출처 (원문 대조 확정)"),hdr("확보"),hdr("핵심 결과물")],
    ["RC-01","위성 구조체의 FOV 간섭에 의한 S대역 안테나 방사 특성 영향성 분석\n임원규, 권기호, 김중표, 이선익 외","한국항공우주학회 2015 춘계, pp.832-835","전문","P-ANT 각도폭 4/8/12° 스윕, 1 dB 판정"],
    ["RC-02","S대역 안테나의 위성 설치상태에서의 성능 연구\n이선익, 임원규, 김중표","한국항공우주학회 2023 추계, pp.1261-1263","전문","해석기법 유효성, 이득·축비 리플 1~3 dB"],
    ["RC-03","위성항법 정지궤도위성 원격측정명령계 S대역 안테나\n설치위치에서의 전자장 해석  ·  이선익, 임원규","항공우주시스템공학회(SASE)\n2025 춘계","전문","FEKO 산란해석, 영향 미미 / 커버리지 만족"],
    ["RF-01","S 대역 신호에 의한 위성항법수신기의 RF 신호간섭\n권병문, 신용설, 마근수, 주정갑, 지기만","한국항공우주학회지 47(5)\npp.388-396, 2019","초록","LNA 포화 + GNSS 대역 상호변조, C/N0 열화"]];
  tbl(s, rows, { x:0.6, y:1.62, w:12.1, colW:[0.75,4.35,2.85,0.7,3.45], rowH:[0.34,0.78,0.68,0.78,0.78], fontSize:9.5 });

  s.addShape(pres.ShapeType.roundRect, { x:0.6, y:5.72, w:12.1, h:1.15, rectRadius:0.08, fill:{color:"FDF3F3"} });
  badge(s, 0.85, 5.95, "!", RED);
  s.addText("인용 정보 4건 모두 오류였음 — 원문 대조로 정정", { x:1.4, y:5.9, w:11, h:0.28, isTextBox:true,
    margin:0, fontFace:BODY, fontSize:12, bold:true, color:RED });
  s.addText("RC-01 → 춘계·페이지 확정   ·   RC-02 → 추계(추계학술대회)·페이지 확정   ·   RC-03 → “KARI research stream”이 아니라 항공우주시스템공학회(SASE), 학회 자체가 다름   ·   RF-01 → 위성이 아닌 시험발사체 사례",
    { x:1.4, y:6.22, w:11.05, h:0.5, isTextBox:true, margin:0, fontFace:BODY, fontSize:10, color:INK, lineSpacing:15 });
  s.addNotes("RC-03은 검색으로 존재 확인조차 못 했던 논문. 원문을 받고 나서 학회가 완전히 다르다는 것이 확인됨.");
}

/* ============================ 3. 검증 방법론 ============================ */
{
  const s = light();
  title(s, "교차검증 방법", "논문에서 조건을 추출 → 도구로 동일 조건 실행 → 수치 대조 → 재현등급 분류");

  const steps = [
    ["1","조건 추출","논문 본문·Figure에서\n형상·거리·주파수·판정기준을\n그대로 읽어냄 (PUBLIC_REPORTED)"],
    ["2","동일 조건 구성","같은 구조·같은 거리로\n도구 시나리오를 구성.\n논문에 없는 값만 ASSUMED 표기"],
    ["3","실행 · 대조","스크립트 실행 결과를\n논문 Figure/Table 수치와\n직접 비교 (fitting 금지)"],
    ["4","등급 분류","EXACT / SAME_TREND /\nNOT_COMPARABLE +\nTier 1~4 로 분류"]];
  steps.forEach((v,i)=>{
    const x = 0.6 + i*3.13;
    s.addShape(pres.ShapeType.roundRect, { x, y:1.75, w:2.9, h:1.95, rectRadius:0.08, fill:{color:PAPER} });
    badge(s, x+0.24, 1.99, v[0], NAVY);
    s.addText(v[1], { x:x+0.78, y:2.02, w:2, h:0.32, isTextBox:true, margin:0,
      fontFace:BODY, fontSize:13, bold:true, color:NAVY });
    s.addText(v[2], { x:x+0.24, y:2.55, w:2.45, h:1.05, isTextBox:true, margin:0,
      fontFace:BODY, fontSize:10, color:INK, lineSpacing:14 });
    if (i<3) s.addText("▶", { x:x+2.93, y:2.55, w:0.24, h:0.3, isTextBox:true, margin:0,
      fontFace:BODY, fontSize:12, color:ICE, align:"center" });
  });

  s.addText("재현등급 (Tier)", { x:0.6, y:4.05, w:5.6, h:0.32, isTextBox:true, margin:0,
    fontFace:BODY, fontSize:14, bold:true, color:NAVY });
  const t = [[hdr("Tier"),hdr("의미"),hdr("예")],
    ["1","도구 영역 내에서 정확·결정론적","각도폭, 거리, 곱 주파수"],
    ["2","경향·메커니즘 재현","FOV 진입, 대역 내 여부"],
    ["3","워크플로 재현, 크기는 입력에 의존","패턴 비교 지표"],
    ["4","외부 EM 근거 없이 재현 불가 (선언된 경계)","dB 이득 변형, 축비, C/N0"]];
  tbl(s, t, { x:0.6, y:4.45, w:6.1, colW:[0.65,2.85,2.6], rowH:[0.3,0.36,0.36,0.36,0.42], fontSize:9.5 });

  s.addShape(pres.ShapeType.roundRect, { x:7.05, y:4.05, w:5.65, h:2.5, rectRadius:0.08, fill:{color:"F2FBF8"} });
  s.addText("검증 원칙", { x:7.35, y:4.2, w:5, h:0.3, isTextBox:true, margin:0,
    fontFace:BODY, fontSize:14, bold:true, color:"0B7A63" });
  s.addText([
    { text:"논문 수치에 맞추는 보정을 절대 넣지 않음 (no fitting)", options:{bullet:true, breakLine:true} },
    { text:"논문이 공개하지 않은 값은 ASSUMED로 명시, 날조 금지", options:{bullet:true, breakLine:true} },
    { text:"재현 불가는 숨기지 않고 Tier 4 경계로 선언", options:{bullet:true, breakLine:true} },
    { text:"불일치가 나오면 보정 대신 원인을 분류 — 결함이면 코드를 고침", options:{bullet:true} }
  ], { x:7.35, y:4.62, w:5.1, h:1.8, isTextBox:true, margin:0, fontFace:BODY, fontSize:11,
       color:INK, paraSpaceAfter:8 });
  s.addNotes("핵심은 4단계: 조건추출 → 동일조건 구성 → 실행/대조 → 등급분류. fitting 금지가 전제.");
}

/* ============================ 4. RC-01 분석조건 ============================ */
{
  const s = light();
  title(s, "RC-01 · 분석조건", "논문 Fig.1 간섭 모델과 Fig.2 시뮬레이션 모델에서 조건을 그대로 추출");

  panel(s, 0.7, 1.75, 5.2, 3.4, A+"rc01_p2_0.png", "논문 Fig.1 — S-ANT / P-ANT 구조 간섭 모델 (x°, y°, shaded area, reflected)");
  panel(s, 6.55, 1.75, 6.1, 2.18, A+"rc01_p2_2.png", "논문 Fig.2 — 시뮬레이션 모델 (변수 1~4, 15°, ~1000 mm, ~4000 mm)");

  const rows = [[hdr("항목"),hdr("논문 값 (PUBLIC_REPORTED)")],
    ["S대역 안테나","Quadrifilar (inverted-F ×4, 90° 위상차), 원편파, 반구면 ±90°"],
    ["축비","3 dB @ 약 ±55°"],
    ["차폐 구조물","탑재체 안테나 반사판 P-ANT (붐 장착 디쉬)"],
    ["위성체","시뮬레이션에서 의도적으로 제외"],
    ["실제 규모 / 고각","이격 ~4 m, P-ANT 높이 ~1000 mm → 고각 약 15°"],
    ["스윕 변수 4종","지름 · 두께 · 간격 · 붐 유무"],
    ["판정 기준","주빔 대비 90° 부근에서 ≤ 1 dB 변화 (TC/TM 링크버짓 경험)"]];
  tbl(s, rows, { x:6.55, y:4.5, w:6.15, colW:[1.75,4.4], rowH:[0.28,0.32,0.26,0.28,0.26,0.32,0.26,0.32], fontSize:9.5 });
  s.addNotes("Fig.2에서 15도 고각을 읽어냈다. 초기 스크립트는 P-ANT를 90도에 뒀는데 실제로는 15도 고각 = 보어사이트 기준 75도. 이 조건을 반영해 수정했다.");
}

/* ============================ 5. RC-01 분석방법 ============================ */
{
  const s = light();
  title(s, "RC-01 · 분석방법 대비", "논문은 전자파 시뮬레이션, 도구는 기하 해석 — 겹치는 영역이 검증 대상");

  // paper side
  s.addShape(pres.ShapeType.roundRect, { x:0.6, y:1.7, w:5.9, h:4.6, rectRadius:0.1, fill:{color:PAPER} });
  s.addText("논문의 분석방법", { x:0.95, y:1.9, w:5.2, h:0.34, isTextBox:true, margin:0,
    fontFace:BODY, fontSize:15, bold:true, color:NAVY });
  const pflow = ["Quadrifilar 안테나 설계 (S대역 중심주파수)",
    "축소 모델 구성 (실제 4 m → 약 50 mm)",
    "P-ANT 를 15° 고각·기준 이격에 배치",
    "변수 4종 스윕하며 전자파 시뮬레이션",
    "무(無) P-ANT 대비 방사패턴 dB 변화 산출",
    "90° 부근 1 dB 마진 충족 여부 판정"];
  pflow.forEach((t,i)=>{
    s.addText((i+1)+".", { x:0.95, y:2.42+i*0.6, w:0.3, h:0.28, isTextBox:true, margin:0,
      fontFace:BODY, fontSize:11, bold:true, color: i>=4?AMBER:NAVY });
    s.addText(t, { x:1.3, y:2.42+i*0.6, w:4.9, h:0.5, isTextBox:true, margin:0,
      fontFace:BODY, fontSize:11, color: i>=4?"8A6520":INK, lineSpacing:14 });
  });
  chip(s, 4.55, 5.95, "④⑤ = Tier 4", AMBER, 1.6);

  // tool side
  s.addShape(pres.ShapeType.roundRect, { x:6.8, y:1.7, w:5.9, h:4.6, rectRadius:0.1, fill:{color:"F2FBF8"} });
  s.addText("도구의 분석방법", { x:7.15, y:1.9, w:5.2, h:0.34, isTextBox:true, margin:0,
    fontFace:BODY, fontSize:15, bold:true, color:"0B7A63" });
  const tflow = ["동일 조건 입력 (4 m, 15° 고각, 지름 D)",
    "DiskGeometry 로 P-ANT 반사판 생성 (rim 32점)",
    "AntennaToStructureFOV — 정점 샘플 각도 풋프린트",
    "각도폭 = 2·maxAngularRadius 산출",
    "논문 Fig.5 스윕값 4/8/12° 와 직접 대조",
    "dB 변형은 계산하지 않고 Tier 4 로 선언"];
  tflow.forEach((t,i)=>{
    s.addText((i+1)+".", { x:7.15, y:2.42+i*0.6, w:0.3, h:0.28, isTextBox:true, margin:0,
      fontFace:BODY, fontSize:11, bold:true, color: i===5?AMBER:"0B7A63" });
    s.addText(t, { x:7.5, y:2.42+i*0.6, w:4.9, h:0.5, isTextBox:true, margin:0,
      fontFace:BODY, fontSize:11, color: i===5?"8A6520":INK, lineSpacing:14 });
  });
  chip(s, 10.75, 5.95, "①~⑤ = Tier 1", TEAL, 1.6);
  s.addNotes("논문의 1~3단계(형상/배치/각도폭)는 도구가 그대로 재현한다. 4~5단계(dB 변화)가 Tier 4 경계.");
}

/* ============================ 6. RC-01 핵심 대조 (figure vs figure) ============================ */
{
  const s = light();
  title(s, "RC-01 · 교차검증 결과", "논문 Fig.5 의 스윕 파라미터(각도폭)를 도구가 직접 계산 — 정량 일치");

  panel(s, 0.7, 1.7, 5.9, 2.75, A+"rc01_p3_3.png",
    "논문 Fig.5 — P-ANT 각도폭 스윕 (w/o, 4°, 8°, 12°) vs Theta");
  panel(s, 6.9, 1.7, 5.75, 2.75, A+"rc_kari_01_subtense.png",
    "도구 — 각도폭 = 2·atan(D/2/R), 논문 보고점(적색 ○) 중첩");

  s.addShape(pres.ShapeType.roundRect, { x:0.7, y:4.85, w:11.95, h:1.95, rectRadius:0.08, fill:{color:"F2FBF8"} });
  s.addText("논문이 스윕한 “각도폭”은 도구가 기하만으로 정확히 계산하는 양이다", { x:1.05, y:5.0, w:11.2, h:0.3,
    isTextBox:true, margin:0, fontFace:BODY, fontSize:13, bold:true, color:"0B7A63" });
  const rows = [[hdr("P-ANT 지름"),hdr("논문 보고 각도폭"),hdr("도구 azSpan"),hdr("도구 2·각반경"),hdr("차이"),hdr("판정")],
    ["0.30 m @ 4 m","약 4°","4.30°","4.30°","+0.30°",{text:"일치",options:{color:"0B7A63",bold:true}}],
    ["0.83 m @ 4 m","12°","11.85°","11.85°","−0.15°",{text:"일치",options:{color:"0B7A63",bold:true}}],
    ["0.80 m (허용한계)","허용 가능","11.42°","11.42°","—",{text:"일치",options:{color:"0B7A63",bold:true}}]];
  tbl(s, rows, { x:1.05, y:5.38, w:11.25, colW:[2.1,2.1,1.85,1.9,1.5,1.8], rowH:[0.3,0.32,0.32,0.32], fontSize:10.5 });
  s.addNotes("논문은 '약 4도', '12도'로 반올림해 서술한다. 도구는 4.30, 11.85. 반올림 범위 내 일치이며 fitting은 없다.");
}

/* ============================ 7. RC-01 수치 차트 ============================ */
{
  const s = light();
  title(s, "RC-01 · 정량 대조", "논문 보고값과 도구 계산값 — 보정 없이 기하식만으로");

  s.addChart(pres.ChartType.bar, [
    { name:"논문 보고값", labels:["지름 30 cm","지름 83 cm"], values:[4.0, 12.0] },
    { name:"도구 계산값", labels:["지름 30 cm","지름 83 cm"], values:[4.30, 11.85] }
  ], { x:0.6, y:1.72, w:6.5, h:4.0, barDir:"col", chartColors:[ICE, TEAL],
       showTitle:true, title:"P-ANT 각도폭 [deg]  (이격 4 m)", titleFontSize:13, titleColor:NAVY,
       showValue:true, dataLabelPosition:"outEnd", dataLabelFontSize:11, dataLabelColor:INK,
       dataLabelFormatCode:"0.00",
       showLegend:true, legendPos:"b", legendFontSize:10, legendColor:INK,
       catAxisLabelColor:MUTED, valAxisLabelColor:MUTED, catAxisLabelFontSize:11,
       valAxisLabelFontSize:10, valGridLine:{ color:"E6EAF2", size:1 },
       catGridLine:{ style:"none" }, valAxisMaxVal:14, barGapWidthPct:60 });

  s.addText("Fig.5 스윕 전체 대조", { x:7.45, y:1.78, w:5.3, h:0.32, isTextBox:true, margin:0,
    fontFace:BODY, fontSize:15, bold:true, color:NAVY });
  const rows = [[hdr("논문 Fig.5 스윕"),hdr("도구 환산 지름 @ 4 m"),hdr("논문 서술")],
    ["4°","0.279 m  (28 cm)","약 30 cm"],
    ["8°","0.559 m  (56 cm)","(중간값)"],
    ["12°","0.841 m  (84 cm)","약 83 cm"]];
  tbl(s, rows, { x:7.45, y:2.2, w:5.25, colW:[1.5,2.15,1.6], rowH:[0.32,0.34,0.34,0.34], fontSize:10.5 });

  s.addShape(pres.ShapeType.roundRect, { x:7.45, y:3.72, w:5.25, h:1.0, rectRadius:0.08, fill:{color:PAPER} });
  s.addText("검증식", { x:7.7, y:3.85, w:2, h:0.26, isTextBox:true, margin:0,
    fontFace:BODY, fontSize:11, bold:true, color:NAVY });
  s.addText("각도폭 = 2 · atan( D / 2R )   —   보정항 없음", { x:7.7, y:4.14, w:4.8, h:0.28, isTextBox:true,
    margin:0, fontFace:BODY, fontSize:12, color:INK });
  s.addText("논문 서술값 28 cm / 84 cm 환산은 논문의 30 cm / 83 cm 와\n반올림 범위 내에서 일치",
    { x:7.7, y:4.42, w:4.8, h:0.32, isTextBox:true, margin:0, fontFace:BODY, fontSize:9.5, color:MUTED, lineSpacing:13 });

  s.addShape(pres.ShapeType.roundRect, { x:7.45, y:4.92, w:5.25, h:1.75, rectRadius:0.08, fill:{color:"FEF8EE"} });
  badge(s, 7.7, 5.1, "4", AMBER);
  s.addText("Tier 4 — 재현 불가 영역", { x:8.22, y:5.13, w:4.2, h:0.28, isTextBox:true, margin:0,
    fontFace:BODY, fontSize:12, bold:true, color:"8A6520" });
  s.addText("논문 Fig.5 의 세로축인 dB 이득 변형 자체(산란·반사)는 도구가 계산하지 않는다. 1 dB 마진 판정도 전자파 해석 결과이므로 Tier 4. 도구는 그 판정의 입력이 되는 각도폭까지만 정확히 제공한다.",
    { x:7.7, y:5.5, w:4.75, h:1.05, isTextBox:true, margin:0, fontFace:BODY, fontSize:10, color:INK, lineSpacing:14 });
  s.addNotes("도구가 재현하는 것은 논문 Fig.5의 가로 파라미터(각도폭)이지 세로축(dB)이 아니다.");
}

/* ============================ 8. RC-02 조건·방법 ============================ */
{
  const s = light();
  title(s, "RC-02 · 분석조건과 방법", "해석기법 선정 연구 — 이격거리에 따라 어떤 기법이 유효한가");

  panel(s, 0.7, 1.72, 5.6, 2.18, A+"rc02_p2_1.png", "논문 Fig.2 — GEO Nadir 플랫폼 (S대역 안테나, 태양전지판, Ka 반사판)");

  s.addText("논문이 비교한 해석기법", { x:6.65, y:1.75, w:6, h:0.3, isTextBox:true, margin:0,
    fontFace:BODY, fontSize:14, bold:true, color:NAVY });
  const m = [[hdr("기법"),hdr("내용"),hdr("소스")],
    ["Full-wave","MoM / FEM (예: HFSS)","구조 전체 해석"],
    ["High-frequency","GTD / UTD","far-field (*.ffe)\nspherical mode (*.sph)"]];
  tbl(s, m, { x:6.65, y:2.12, w:6.05, colW:[1.6,2.35,2.1], rowH:[0.3,0.32,0.55], fontSize:10 });

  s.addShape(pres.ShapeType.roundRect, { x:6.65, y:3.42, w:6.05, h:0.72, rectRadius:0.08, fill:{color:"F2FBF8"} });
  s.addText("최소 유효 반경 (minimum validity radius)  =  30 ~ 40 cm", { x:6.95, y:3.55, w:5.5, h:0.28,
    isTextBox:true, margin:0, fontFace:BODY, fontSize:12, bold:true, color:"0B7A63" });
  s.addText("반구형 S대역 안테나 기준 — 이 거리 미만이면 소스 기반 해석이 불안정", { x:6.95, y:3.83, w:5.5, h:0.24,
    isTextBox:true, margin:0, fontFace:BODY, fontSize:9.5, color:MUTED });

  s.addText("해석기법 유효성 — 논문 3개 Case vs 도구 판정", { x:0.7, y:4.5, w:8, h:0.3, isTextBox:true,
    margin:0, fontFace:BODY, fontSize:14, bold:true, color:NAVY });
  const rows = [[hdr("Case"),hdr("이격거리"),hdr("논문 결과"),hdr("도구 판정 (기하만으로)"),hdr("일치")],
    ["Case 1","40 cm 붐","3개 기법 모두 일치","HF 기법 유효 (≥ 40 cm)",{text:"○",options:{color:"0B7A63",bold:true,fontSize:14}}],
    ["Case 2","4~5 cm 붐","spherical mode 소스 불안정","HF 기법 무효 (< 30 cm)",{text:"○",options:{color:"0B7A63",bold:true,fontSize:14}}],
    ["Case 3","40 cm + 박스","3개 기법 모두 일치","HF 기법 유효 (≥ 40 cm)",{text:"○",options:{color:"0B7A63",bold:true,fontSize:14}}]];
  tbl(s, rows, { x:0.7, y:4.88, w:11.95, colW:[1.1,1.85,3.5,4.0,1.5], rowH:[0.3,0.36,0.36,0.36], fontSize:10.5 });
  s.addText("논문이 실험으로 얻은 기법 선정 결론을, 도구는 이격거리 기하만으로 3건 모두 동일하게 판정 — Tier 1 EXACT",
    { x:0.7, y:6.42, w:11.95, h:0.3, isTextBox:true, margin:0, fontFace:BODY, fontSize:11, bold:true, color:"0B7A63" });
  s.addNotes("이 항목은 초기 검증에서 완전히 놓쳤던 부분. 논문의 핵심 기여가 기법 선정 기준이라는 걸 전문을 보고 알았다.");
}

/* ============================ 9. RC-02 결과 대조 + 축비 ============================ */
{
  const s = light();
  title(s, "RC-02 · 결과 대조와 재현 경계", "이득 리플은 지표로 확인 가능, 축비는 도구에 채널 자체가 없음");

  panel(s, 0.7, 1.72, 4.35, 2.5, A+"rc02_p2_2.png", "논문 Fig.3 — 이득 (2.091 GHz, RHC/LHC)");
  panel(s, 5.4, 1.72, 3.95, 2.15, A+"rc02_p2_3.png", "논문 Fig.4 — 축비 (2.091 GHz)");
  panel(s, 9.65, 1.72, 3.0, 2.25, A+"rc_kari_02_delta.png", "도구 — 리플 지표 읽기");

  s.addShape(pres.ShapeType.roundRect, { x:0.7, y:4.55, w:5.95, h:2.25, rectRadius:0.08, fill:{color:"F2FBF8"} });
  badge(s, 0.98, 4.75, "2", TEAL);
  s.addText("이득 리플 — 지표 검증 가능 (Tier 2)", { x:1.5, y:4.78, w:4.9, h:0.28, isTextBox:true, margin:0,
    fontFace:BODY, fontSize:13, bold:true, color:"0B7A63" });
  s.addText("논문 보고: 요구 커버리지 내 이득 리플 1~3 dB 이하.\n도구의 PatternComparison 에 이 리플 포락선을 입력하면 max |Δ| = 3.00 dB, RMS = 1.47 dB 로 정확히 읽어낸다.\n\n단, 이는 비교 지표(계측기)의 정확도 확인이지 리플 자체를 계산한 것이 아니다. 설치 패턴은 반드시 외부에서 공급받아야 한다.",
    { x:1.05, y:5.12, w:5.3, h:1.55, isTextBox:true, margin:0, fontFace:BODY, fontSize:10, color:INK, lineSpacing:14 });

  s.addShape(pres.ShapeType.roundRect, { x:6.95, y:4.55, w:5.7, h:2.25, rectRadius:0.08, fill:{color:"FEF8EE"} });
  badge(s, 7.23, 4.75, "4", AMBER);
  s.addText("축비 — 재현 불가 (Tier 4)", { x:7.75, y:4.78, w:4.7, h:0.28, isTextBox:true, margin:0,
    fontFace:BODY, fontSize:13, bold:true, color:"8A6520" });
  s.addText("논문 Fig.4 의 축비는 이 연구의 헤드라인 결과 중 하나다. 그러나 도구 아키텍처에는 편파·축비 채널이 아예 존재하지 않는다.\n\nMODEL_GAP_AXIAL_RATIO 로 선언하며, 근사치를 만들어내지 않는다. 설치 패턴을 공급받아도 축비는 나오지 않는다.",
    { x:7.3, y:5.12, w:5.05, h:1.55, isTextBox:true, margin:0, fontFace:BODY, fontSize:10, color:INK, lineSpacing:14 });
  s.addNotes("Fig.3/Fig.4에서 실제 해석 주파수 2.091 GHz를 확인했다. GK3_FFE_NAD_RHCP_U 파일명에서 far-field source, nadir, RHCP임도 알 수 있다.");
}

/* ============================ 10. RC-03 ============================ */
{
  const s = light();
  title(s, "RC-03 · 도구의 역할이 논문에 그대로 명시됨", "SASE 2025 — 배치는 “안테나간 RF 간섭 분석을 기초로” 정해지고 FEKO가 검증");

  s.addShape(pres.ShapeType.roundRect, { x:0.7, y:1.72, w:11.95, h:1.15, rectRadius:0.08, fill:{color:PAPER} });
  s.addText("논문 원문 인용", { x:1.0, y:1.85, w:3, h:0.26, isTextBox:true, margin:0,
    fontFace:BODY, fontSize:10, bold:true, color:MUTED });
  s.addText("“이들 안테나간 RF 간섭 분석을 기초로 배치가 고려된 조건에서 원격측정 S대역 안테나의 방사 특성(성능)을 해석하였으며 … 상용 해석 툴(FEKO)에 안테나 소스 파일을 입력하여 해석하였다.”",
    { x:1.0, y:2.14, w:11.4, h:0.62, isTextBox:true, margin:0, fontFace:BODY, fontSize:12,
      italic:true, color:NAVY, lineSpacing:17 });

  // two-stage flow
  const stage = [
    ["앞단 — 배치 결정","안테나간 RF 간섭 분석","도구가 수행하는 영역", TEAL, "F2FBF8", "0B7A63",
     "S대역 TC&R ↔ 항법 안테나 3기\n거리 · 상호 off-boresight · 로브 영역\n플랫폼 차폐 · 이격거리 유효성"],
    ["뒷단 — 검증","FEKO 산란 해석","도구가 넘기는 영역", AMBER, "FEF8EE", "8A6520",
     "구조물·주변 안테나 영향 “미미” 판정\n이득 및 축비 열화 특성\n커버리지 요구사항 충족 확인"]];
  stage.forEach((v,i)=>{
    const x = 0.7 + i*6.25;
    s.addShape(pres.ShapeType.roundRect, { x, y:3.1, w:5.7, h:2.55, rectRadius:0.1, fill:{color:v[4]} });
    chip(s, x+0.3, 3.32, v[2], v[3], 1.9);
    s.addText(v[0], { x:x+0.3, y:3.75, w:5.1, h:0.3, isTextBox:true, margin:0,
      fontFace:BODY, fontSize:12, bold:true, color:v[5] });
    s.addText(v[1], { x:x+0.3, y:4.05, w:5.1, h:0.36, isTextBox:true, margin:0,
      fontFace:HEAD, fontSize:17, bold:true, color:NAVY });
    s.addText(v[6], { x:x+0.3, y:4.5, w:5.1, h:1.0, isTextBox:true, margin:0,
      fontFace:BODY, fontSize:10.5, color:INK, lineSpacing:15 });
  });
  s.addText("▶", { x:6.5, y:4.2, w:0.4, h:0.32, isTextBox:true, margin:0, fontFace:BODY,
    fontSize:16, color:ICE, align:"center" });

  s.addText("이 사례는 도구의 설계 의도를 논문이 그대로 확인해 준다 — 스크리닝이 배치를 고르고, 풀웨이브가 그것을 증명한다. 여기서의 Tier 4는 실패가 아니라 올바른 경계다.",
    { x:0.7, y:5.9, w:11.95, h:0.6, isTextBox:true, margin:0, fontFace:BODY, fontSize:12,
      bold:true, color:NAVY, lineSpacing:17 });
  s.addNotes("RC-03이 아키텍처 정당성을 가장 명확히 보여주는 사례.");
}

/* ============================ 11. RF-01 + 결함 ============================ */
{
  const s = light();
  title(s, "RF-01 · 검증 중 발견한 실제 결함 2건", "논문이 다루는 영역이 바로 도구 모델이 무효인 영역이었다");

  panel(s, 8.9, 1.72, 3.75, 2.7, A+"rc_kari_rf_01_im3.png", "도구 — IM3가 L1에 떨어지는 S대역 톤 조합");

  const d = [
    ["A","포화 영역에 소신호 IM3 식 적용 후 VALID 보고",
     "톤이 P1dB보다 17 dB 위인데 P_IM3 = +6 dBm 을 반환 — 기본파(−8 dBm)보다 14 dB 높은 물리적 불가능값. 경고 0건.",
     "P1dB 대비 여유(기본 10 dB) 검사 + 기본파 초과 검사 추가. OUTSIDE_MODEL_DOMAIN 으로 레벨을 보류(withhold)하며 날조하지 않는다."],
    ["B","“S대역” 간섭원이 실제로는 L대역 — 결론에 맞춘 역산",
     "1.600 / 1.625 GHz 사용. S대역은 2~4 GHz이므로 둘 다 L대역이며, 이미 L1 근처라 2f1−f2 가 L1에 떨어지는 것은 사실상 자동이었다.",
     "f2 = 2·f1 − f_L1 로 유도하고 두 톤 모두 S대역 여부를 검사. 결과적으로 425 MHz 이상 넓게 이격된 쌍에서만 성립함을 도출."]];
  d.forEach((v,i)=>{
    const y = 1.72 + i*2.45;
    s.addShape(pres.ShapeType.roundRect, { x:0.7, y, w:7.95, h:2.25, rectRadius:0.08, fill:{color:"FDF3F3"} });
    badge(s, 0.95, y+0.2, v[0], RED);
    s.addText(v[1], { x:1.47, y:y+0.22, w:6.95, h:0.3, isTextBox:true, margin:0,
      fontFace:BODY, fontSize:12.5, bold:true, color:RED });
    s.addText("증상", { x:1.02, y:y+0.62, w:0.6, h:0.24, isTextBox:true, margin:0,
      fontFace:BODY, fontSize:9, bold:true, color:MUTED });
    s.addText(v[2], { x:1.65, y:y+0.6, w:6.75, h:0.62, isTextBox:true, margin:0,
      fontFace:BODY, fontSize:10, color:INK, lineSpacing:14 });
    s.addText("수정", { x:1.02, y:y+1.34, w:0.6, h:0.24, isTextBox:true, margin:0,
      fontFace:BODY, fontSize:9, bold:true, color:"0B7A63" });
    s.addText(v[3], { x:1.65, y:y+1.32, w:6.75, h:0.68, isTextBox:true, margin:0,
      fontFace:BODY, fontSize:10, color:INK, lineSpacing:14 });
  });

  s.addShape(pres.ShapeType.roundRect, { x:8.9, y:4.98, w:3.75, h:1.7, rectRadius:0.08, fill:{color:PAPER} });
  s.addText("논문 메커니즘 (초록)", { x:9.15, y:5.11, w:3.3, h:0.26, isTextBox:true, margin:0,
    fontFace:BODY, fontSize:10, bold:true, color:MUTED });
  s.addText("“능동형 위성항법안테나의 LNA는 … S 대역 신호에 의해 포화되었으며, 2개의 S 대역 신호가 … 수신될 때마다 GNSS 대역에 해당하는 상호변조신호가 LNA에서 발생”",
    { x:9.15, y:5.43, w:3.3, h:1.18, isTextBox:true, margin:0, fontFace:BODY, fontSize:9.5,
      italic:true, color:NAVY, lineSpacing:13 });
  s.addNotes("결함 A가 특히 중요: 논문 주제 자체가 LNA 포화인데, 바로 그 영역에서 도구가 물리적으로 불가능한 값을 VALID로 내놓고 있었다.");
}

/* ============================ 12. 스코어카드 ============================ */
{
  const s = light();
  title(s, "종합 스코어카드", "도구가 정확히 재현하는 것 vs 논문의 헤드라인 결과");

  const rows = [[hdr("케이스"),hdr("논문 보고 수치"),hdr("도구 계산 결과"),hdr("비교 등급"),hdr("Tier"),hdr("논문 헤드라인 = Tier 4")],
    ["RC-01","4° ↔ 30 cm\n12° ↔ 83 cm (@4 m)","4.30°\n11.85°",{text:"EXACT_NUMERICAL",options:{color:"0B7A63",bold:true}},"1","≤1 dB 이득 변형 (산란·반사)"],
    ["RC-02","최소 유효반경 30~40 cm\n3개 Case 판정","유효 / 무효 / 유효\n3건 전부 일치",{text:"EXACT_NUMERICAL",options:{color:"0B7A63",bold:true}},"1","1~3 dB 이득 리플 + 축비"],
    ["RC-03","안테나간 RF 간섭 분석\n기반 배치","간섭 스크리닝 매트릭스\n(거리·각도·로브)",{text:"SAME_TREND",options:{color:"0B7A63",bold:true}},"2","FEKO “영향 미미” 판정, 축비"],
    ["RF-01","2개 S대역 톤 → GNSS\n대역 상호변조","2f1−f2 = 1.57542 GHz\n필요 이격 ≳ 425 MHz",{text:"EXACT_NUMERICAL",options:{color:"0B7A63",bold:true}},"1","C/N0 열화 (채널 부재)"]];
  tbl(s, rows, { x:0.6, y:1.68, w:12.1, colW:[1.1,2.75,2.75,2.3,0.6,2.6],
    rowH:[0.32,0.62,0.62,0.62,0.62], fontSize:9.5 });

  s.addShape(pres.ShapeType.roundRect, { x:0.6, y:4.6, w:5.9, h:2.15, rectRadius:0.08, fill:{color:"F2FBF8"} });
  s.addText("재현된 것", { x:0.9, y:4.75, w:5.2, h:0.3, isTextBox:true, margin:0,
    fontFace:BODY, fontSize:14, bold:true, color:"0B7A63" });
  s.addText("각 논문의 스윕이 파라미터로 삼은 기하학적·산술적 전제조건 — 각도폭, 유효 이격거리, 배치 스크리닝, 상호변조 곱 주파수. 4건 중 3건이 EXACT_NUMERICAL 이며 보정항은 하나도 들어가지 않았다.",
    { x:0.9, y:5.15, w:5.35, h:1.4, isTextBox:true, margin:0, fontFace:BODY, fontSize:11, color:INK, lineSpacing:15 });

  s.addShape(pres.ShapeType.roundRect, { x:6.8, y:4.6, w:5.9, h:2.15, rectRadius:0.08, fill:{color:"FEF8EE"} });
  s.addText("재현되지 않은 것", { x:7.1, y:4.75, w:5.2, h:0.3, isTextBox:true, margin:0,
    fontFace:BODY, fontSize:14, bold:true, color:"8A6520" });
  s.addText("네 논문의 헤드라인 결과가 전부 Tier 4 다 — dB 이득 변형, 이득·축비 리플, FEKO 판정, C/N0 열화. 모두 dB 단위 전자파 또는 수신기 성능 결과이며, 외부 EM 근거 없이는 원리적으로 산출 불가하다.",
    { x:7.1, y:5.15, w:5.35, h:1.4, isTextBox:true, margin:0, fontFace:BODY, fontSize:11, color:INK, lineSpacing:15 });
  s.addNotes("정직한 결론: 4건 중 3건 EXACT지만, 재현되는 것은 전제조건이지 논문의 최종 결과물이 아니다.");
}

/* ============================ 13. 결론 ============================ */
{
  const s = dark();
  s.addShape(pres.ShapeType.ellipse, { x:10.2, y:-2.0, w:5.6, h:5.6, fill:{color:NAVY} });
  title(s, "결론", null, true);

  const items = [
    ["1", TEAL, "논문의 전제조건은 정확히 재현된다",
     "각도폭 4.30°/11.85° (논문 4°/12°), 유효반경 판정 3건 전부 일치, IM3 곱 주파수 1.57542 GHz 정확. 보정항 없음."],
    ["2", RED, "검증이 실제 결함 2건을 드러냈다",
     "포화 영역 IM3 오적용(물리적 불가능값을 VALID로 보고), S대역 톤의 L대역 오기 및 결론 역산. 둘 다 수정 완료."],
    ["3", AMBER, "논문의 헤드라인 결과는 전부 Tier 4 다",
     "dB 이득 변형 · 축비 · FEKO 판정 · C/N0 열화. 도구가 계산하지 않으며 근사치도 만들지 않는다. 이것이 정직한 상한이다."],
    ["4", ICE, "다음 단계는 EM 솔버 내장이 아니다",
     "측정·외부 해석 결과를 provenance와 함께 주입하는 데이터 경계를 만드는 것. HFSS/CST 내장은 별도 판단 사항."]];
  items.forEach((v,i)=>{
    const y = 1.72 + i*1.28;
    badge(s, 0.75, y+0.06, v[0], v[1]);
    s.addText(v[2], { x:1.35, y, w:11.2, h:0.36, isTextBox:true, margin:0,
      fontFace:BODY, fontSize:16, bold:true, color:WHITE });
    s.addText(v[3], { x:1.35, y: y+0.4, w:11.2, h:0.68, isTextBox:true, margin:0,
      fontFace:BODY, fontSize:11.5, color:"A9B5D6", lineSpacing:16 });
  });

  s.addShape(pres.ShapeType.roundRect, { x:0.75, y:6.55, w:11.8, h:0.55, rectRadius:0.08, fill:{color:"1A2350"} });
  s.addText("회귀 검증 628 assertions / 36 files 전부 통과 (GNU Octave 8.4)  ·  MATLAB 미실행 (환경 부재, 주장하지 않음)",
    { x:1.05, y:6.65, w:11.3, h:0.34, isTextBox:true, margin:0, fontFace:BODY, fontSize:11, color:ICE });
  s.addNotes("다음 단계 권고는 EM 솔버 내장이 아니라 외부 EM 근거를 provenance와 함께 받는 데이터 경계.");
}

pres.writeFile({ fileName: "/tmp/claude-0/-home-user-RFinterferneceSimulation/375a6333-fc2a-58be-9078-2eaaa5b8d97c/scratchpad/deck/KARI_cross_validation.pptx" })
  .then(f => console.log("WROTE", f));
