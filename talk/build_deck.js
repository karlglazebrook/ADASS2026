// Build the ADASS 2026 talk deck.
//   NODE_PATH=<dir with pptxgenjs, react-icons, react, react-dom, sharp> node build_deck.js
// Numbers are relative times from ../report/run22.log (NEON assembler = 1.00).
// Outline and sources: Deck-outline.md.

const fs = require("fs");
const path = require("path");
const pptxgen = require("pptxgenjs");
const React = require("react");
const ReactDOMServer = require("react-dom/server");
const sharp = require("sharp");
const fa = require("react-icons/fa");
const { applyTheme } = require(process.env.PPTX_SKILL + "/scripts/apply_theme.js");

const HERE = __dirname;
const IMG = (f) => path.join(HERE, "img", f);
const OUT = path.join(HERE, "ADASS2026-talk.pptx");

// ---------------------------------------------------------------- theme
const THEME = {
  name: "ADASS 2026 Tiers",
  headFontFace: "Cambria",
  bodyFontFace: "Calibri",
  colors: {
    dk1: "1B1F2B", lt1: "FFFFFF", dk2: "14213D", lt2: "EEF1F6",
    accent1: "1A9850", accent2: "FDAE61", accent3: "D73027",
    accent4: "7A0177", accent5: "3B6FB6", accent6: "FEE08B",
    hlink: "3B6FB6", folHlink: "7A0177",
  },
};
const HEX = THEME.colors;
const MUTED = "5A6275";
const MUTED_ON_DARK = "AEB8CC";

// Tier scale from make_figures.py, boundaries from CLAUDE.md.
const TIER_COLORS = ["1A9850", "66BD63", "A6D96A", "FEE08B", "FDAE61", "F46D43", "D73027", "7A0177"];
const TIER_EDGES = [1.10, 2.50, 7.00, 15.00, 100.0, 600.0, 20000.0];
const tierOf = (v) => { let t = 0; while (t < TIER_EDGES.length && v >= TIER_EDGES[t]) t++; return t; };
const tierColor = (v) => TIER_COLORS[tierOf(v)];
const tierText = (v) => ([0, 6, 7].includes(tierOf(v)) ? "FFFFFF" : HEX.dk1);

// ---------------------------------------------------------------- run22
function readRun22() {
  const txt = fs.readFileSync(path.join(HERE, "..", "report", "run22.log"), "utf8");
  const start = txt.indexOf("Summary of relative speeds:");
  const vals = [];
  for (const line of txt.slice(start).split("\n")) {
    if (line.startsWith("Compiler,")) break;
    const m = line.match(/1K Iter:.*Relative time\s+([0-9.]+)/);
    if (m) vals.push(parseFloat(m[1]));
  }
  if (vals.length !== 131) throw new Error(`expected 131 results in run22.log, got ${vals.length}`);
  return vals;
}

// Test name -> relative time, from any Run.py "Summary of relative speeds" listing.
function readSummary(file) {
  const out = {};
  for (const line of fs.readFileSync(file, "utf8").split("\n")) {
    const m = line.match(/^\s*(.+?)\s+1K Iter:.*Relative time\s+([0-9.]+)/);
    if (m) out[m[1].replace(/\s+/g, " ")] = parseFloat(m[2]);
  }
  return out;
}

// pptxgenjs can't put a log scale on a scatter chart's x axis, and writes missing
// points as empty values; patch both in the chart XML after writing.
async function fixScatter(file) {
  const JSZip = require("jszip");
  const zip = await JSZip.loadAsync(fs.readFileSync(file));
  let n = 0;
  for (const name of Object.keys(zip.files).filter((f) => /^ppt\/charts\/chart\d+\.xml$/.test(f))) {
    let xml = await zip.file(name).async("string");
    if (!xml.includes("<c:scatterChart>")) continue;
    xml = xml.replace(/<c:pt idx="\d+"><c:v><\/c:v><\/c:pt>/g, "");
    xml = xml.replace(/<c:valAx>(\s*<c:axId val="\d+"\/>\s*)<c:scaling>(?!<c:logBase)/, '<c:valAx>$1<c:scaling><c:logBase val="10"/>');
    // x axis labels: same number format as the y axis
    xml = xml.replace(/<c:valAx>[\s\S]*?<\/c:valAx>/g, (ax) => ax.replace(/formatCode="General"/, 'formatCode="[&lt;1]0.0;#,##0"'));
    zip.file(name, xml);
    n++;
  }
  if (n !== 1) throw new Error(`expected one scatter chart, found ${n}`);
  fs.writeFileSync(file, await zip.generateAsync({ type: "nodebuffer", compression: "DEFLATE" }));
}

// pptxgenjs writes no animations; add a click-to-fade-in entrance for each named
// shape, one click each, in the order given.
async function addClickReveal(file, names) {
  const JSZip = require("jszip");
  const zip = await JSZip.loadAsync(fs.readFileSync(file));
  const slides = Object.keys(zip.files).filter((f) => /^ppt\/slides\/slide\d+\.xml$/.test(f));
  const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
  for (const name of slides) {
    let xml = await zip.file(name).async("string");
    const ids = names.map((n) => (xml.match(new RegExp(`<p:cNvPr id="(\\d+)" name="${esc(n)}"`)) || [])[1]);
    if (!ids.every(Boolean)) continue;
    if (xml.includes("<p:timing>")) throw new Error(`${name} already has a timing tree`);
    let id = 3;
    const step = (spid) => {
      const a = id++, b = id++, c = id++, d = id++, e = id++;
      const tgt = `<p:tgtEl><p:spTgt spid="${spid}"/></p:tgtEl>`;
      return `<p:par><p:cTn id="${a}" fill="hold"><p:stCondLst><p:cond delay="indefinite"/></p:stCondLst><p:childTnLst>` +
        `<p:par><p:cTn id="${b}" fill="hold"><p:stCondLst><p:cond delay="0"/></p:stCondLst><p:childTnLst>` +
        `<p:par><p:cTn id="${c}" presetID="10" presetClass="entr" presetSubtype="0" fill="hold" nodeType="clickEffect">` +
        `<p:stCondLst><p:cond delay="0"/></p:stCondLst><p:childTnLst>` +
        `<p:set><p:cBhvr><p:cTn id="${d}" dur="1" fill="hold"><p:stCondLst><p:cond delay="0"/></p:stCondLst></p:cTn>${tgt}` +
        `<p:attrNameLst><p:attrName>style.visibility</p:attrName></p:attrNameLst></p:cBhvr><p:to><p:strVal val="visible"/></p:to></p:set>` +
        `<p:animEffect transition="in" filter="fade"><p:cBhvr><p:cTn id="${e}" dur="400"/>${tgt}</p:cBhvr></p:animEffect>` +
        `</p:childTnLst></p:cTn></p:par></p:childTnLst></p:cTn></p:par></p:childTnLst></p:cTn></p:par>`;
    };
    const steps = ids.map(step).join("");
    const timing = `<p:timing><p:tnLst><p:par><p:cTn id="1" dur="indefinite" restart="never" nodeType="tmRoot"><p:childTnLst>` +
      `<p:seq concurrent="1" nextAc="seek"><p:cTn id="2" dur="indefinite" nodeType="mainSeq"><p:childTnLst>${steps}</p:childTnLst></p:cTn>` +
      `<p:prevCondLst><p:cond evt="onPrev" delay="0"><p:tgtEl><p:sldTgt/></p:tgtEl></p:cond></p:prevCondLst>` +
      `<p:nextCondLst><p:cond evt="onNext" delay="0"><p:tgtEl><p:sldTgt/></p:tgtEl></p:cond></p:nextCondLst></p:seq>` +
      `</p:childTnLst></p:cTn></p:par></p:tnLst>` +
      `<p:bldLst>${ids.map((i) => `<p:bldP spid="${i}" grpId="0" animBg="1"/>`).join("")}</p:bldLst></p:timing>`;
    xml = xml.replace("</p:clrMapOvr>", "</p:clrMapOvr>" + timing);
    zip.file(name, xml);
    fs.writeFileSync(file, await zip.generateAsync({ type: "nodebuffer", compression: "DEFLATE" }));
    return;
  }
  throw new Error(`no slide has all of: ${names.join(", ")}`);
}

// Tier colours as hard-edged bands along a log axis from lo to hi: [[position 0-1, hex], ...].
function tierBands(lo, hi) {
  const l0 = Math.log10(lo), span = Math.log10(hi) - l0, stops = [];
  const edges = [0, ...TIER_EDGES, Infinity];
  for (let k = 0; k < TIER_COLORS.length; k++) {
    const a = Math.max(edges[k], lo), b = Math.min(edges[k + 1], hi);
    if (a >= b) continue;
    stops.push([(Math.log10(a) - l0) / span, TIER_COLORS[k]], [(Math.log10(b) - l0) / span, TIER_COLORS[k]]);
  }
  return stops;
}

// pptxgenjs has no gradient fills; swap the solid fill of each named shape for a
// left-to-right gradient with the given stops.
async function shadeShapes(file, shades) {
  const JSZip = require("jszip");
  const zip = await JSZip.loadAsync(fs.readFileSync(file));
  let left = Object.keys(shades).length;
  for (const name of Object.keys(zip.files).filter((f) => /^ppt\/slides\/slide\d+\.xml$/.test(f))) {
    let xml = await zip.file(name).async("string");
    let hit = false;
    for (const [shape, stops] of Object.entries(shades)) {
      const re = new RegExp(`(<p:cNvPr id="\\d+" name="${shape}"[\\s\\S]*?<p:spPr>[\\s\\S]*?)<a:solidFill>[\\s\\S]*?</a:solidFill>`);
      if (!re.test(xml)) continue;
      const gs = stops.map(([p, c]) => `<a:gs pos="${Math.round(p * 100000)}"><a:srgbClr val="${c}"/></a:gs>`).join("");
      xml = xml.replace(re, `$1<a:gradFill rotWithShape="1"><a:gsLst>${gs}</a:gsLst><a:lin ang="0" scaled="0"/></a:gradFill>`);
      hit = true;
      left--;
    }
    if (hit) zip.file(name, xml);
  }
  if (left) throw new Error(`shadeShapes: ${left} shape(s) not found`);
  fs.writeFileSync(file, await zip.generateAsync({ type: "nodebuffer", compression: "DEFLATE" }));
}

// Highlighted kernels pulled from the repo sources by snippets.py.
const SNIPPETS = JSON.parse(fs.readFileSync(path.join(HERE, "snippets.json"), "utf8"));

// ---------------------------------------------------------------- icons
async function icon(Comp, color, px = 256) {
  const svg = ReactDOMServer.renderToStaticMarkup(React.createElement(Comp, { color: "#" + color, size: px }));
  const buf = await sharp(Buffer.from(svg)).png().toBuffer();
  return "image/png;base64," + buf.toString("base64");
}

// ---------------------------------------------------------------- deck
async function main() {
  const pres = new pptxgen();
  pres.layout = "LAYOUT_WIDE"; // 13.333 x 7.5
  pres.author = "Karl Glazebrook";
  pres.title = "Same Source, Three Orders of Magnitude";
  pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
  const C = pres.SchemeColor;
  const W = 13.333, M = 0.6, CW = W - 2 * M;

  // ----- layouts
  pres.defineSlideMaster({
    title: "Title Dark",
    background: { color: C.text2 },
    objects: [
      { placeholder: { options: { name: "title", type: "title", x: M, y: 0.9, w: CW, h: 1.5,
          fontFace: "+mj-lt", fontSize: 44, bold: true, color: C.background1, valign: "bottom", align: "left", margin: 0 },
          text: "Title" } },
      { placeholder: { options: { name: "body", type: "body", x: M, y: 2.5, w: CW, h: 1.6,
          fontSize: 20, color: C.background2, valign: "top", margin: 0 }, text: "Subtitle" } },
    ],
  });
  pres.defineSlideMaster({
    title: "Content",
    background: { color: C.background1 },
    margin: [0.5, 0.6, 0.6, 0.6],
    objects: [
      { placeholder: { options: { name: "title", type: "title", x: M, y: 0.35, w: CW, h: 0.85,
          fontFace: "+mj-lt", fontSize: 32, bold: true, color: C.text2, valign: "middle", margin: 0 },
          text: "Title" } },
      { text: { text: "Glazebrook · ADASS 2026 · Perth",
          options: { x: M, y: 7.0, w: 6, h: 0.3, fontSize: 10, color: MUTED, margin: 0 } } },
    ],
    slideNumber: { x: W - M - 0.6, y: 7.0, w: 0.6, h: 0.3, fontSize: 10, color: MUTED, align: "right" },
  });
  pres.defineSlideMaster({
    title: "Content Dark",
    background: { color: C.text2 },
    margin: [0.5, 0.6, 0.3, 0.6],
    objects: [
      { placeholder: { options: { name: "title", type: "title", x: M, y: 0.2, w: CW, h: 0.6,
          fontFace: "+mj-lt", fontSize: 26, bold: true, color: C.background1, valign: "middle", margin: 0 },
          text: "Title" } },
    ],
    slideNumber: { x: W - M - 0.6, y: 7.2, w: 0.6, h: 0.22, fontSize: 9, color: MUTED_ON_DARK, align: "right" },
  });

  // ----- helpers
  const T = (s, text, o) => s.addText(text, Object.assign({ isTextBox: true, margin: 0, fontSize: 16, color: C.text1, valign: "top" }, o));
  const chip = (s, x, y, w, h, v, label, fs = 14, name) => {
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, rectRadius: 0.08, fill: { color: tierColor(v) },
      line: { color: tierColor(v) }, objectName: name || `chip ${label}` });
    s.addText(label, { isTextBox: true, x, y, w, h, margin: 0, align: "center", valign: "middle",
      fontSize: fs, bold: true, color: tierText(v) });
  };
  const card = (s, x, y, w, h, name, fill = C.background2) =>
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, rectRadius: 0.1, fill: { color: fill }, line: { color: fill }, objectName: name });
  const content = (title, section, masterName = "Content") => {
    const s = pres.addSlide({ masterName, sectionTitle: section });
    s.addText(title, { placeholder: "title" });
    return s;
  };
  // Highlighted code from snippets.json; `recolour(lineIndex, run)` can override a run's colour.
  const code = (s, snip, x, y, w, h, fontSize, recolour) => {
    const runs = [];
    snip.rows.forEach((row, i) => {
      row.forEach((r, j) => {
        const o = { color: r.c, bold: r.b, italic: r.i };
        if (recolour) Object.assign(o, recolour(i, r) || {});
        if (j === row.length - 1 && i < snip.rows.length - 1) o.breakLine = true;
        runs.push({ text: r.t, options: o });
      });
    });
    s.addText(runs, { isTextBox: true, x, y, w, h, margin: 0, fontFace: "Courier New", fontSize,
      lineSpacing: fontSize * 1.05, valign: "top", objectName: `code ${snip.label}` });
  };

  // A wall of highlighted kernels, fastest first, from snippets.json.
  const codeWall = (title, section, list, notes, cols = 3, rows = 4) => {
    const s = content(title, section, "Content Dark");
    const mx = cols > 3 ? 0.3 : M, pad = cols > 3 ? 0.1 : 0.15;
    const gx = cols > 3 ? 0.1 : 0.16, gy = cols > 3 ? 0.1 : 0.12, top = 0.9, bottom = 7.15;
    const cw = (W - 2 * mx - (cols - 1) * gx) / cols, chh = (bottom - top - (rows - 1) * gy) / rows;
    const snips = list.slice().sort((a, b) => a.rel - b.rel);
    snips.forEach((sn, i) => {
      const x = mx + (i % cols) * (cw + gx), y = top + Math.floor(i / cols) * (chh + gy);
      card(s, x, y, cw, chh, `code card ${sn.label}`, sn.background);
      T(s, [{ text: sn.label, options: { bold: true, color: "E6EDF3" } }, { text: `   ${sn.file}`, options: { fontSize: 8, color: "8B949E" } }],
        { x: x + pad, y: y + 0.05, w: cw - 0.95 - pad, h: 0.24, fontSize: cols > 3 ? 11 : 12, valign: "middle" });
      const lab = sn.rel >= 100 ? Math.round(sn.rel).toLocaleString("en-US") : sn.rel.toFixed(2);
      chip(s, x + cw - 0.8 - pad, y + 0.05, 0.8, 0.24, sn.rel, lab, 10, `chip ${sn.label}`);
      // largest Courier size (<= 8 pt) that fits the card: 0.6 em per char, 1.05 em per line
      const iw = cw - 2 * pad, ih = chh - 0.4;
      const fsz = Math.min(8, (iw * 72) / (0.6 * sn.width), (ih * 72) / (1.05 * sn.rows.length + 0.3));
      code(s, sn, x + pad, y + 0.34, iw, ih, Math.floor(fsz * 2) / 2);
    });
    s.addNotes(notes);
  };

  const vals = readRun22();
  const arrowShades = {}; // shape name -> gradient stops, applied after writing

  // ===================================================== Part A: the story
  pres.addSection({ title: "The story" });

  // 1. Title, with all 131 results as a dot histogram
  {
    const s = pres.addSlide({ masterName: "Title Dark", sectionTitle: "The story" });
    s.addText("Same Source, Three Orders of Magnitude", { placeholder: "title" });
    s.addText([
      { text: "A 2026 reprise of Shortridge's compiler benchmark, co-authored with an LLM", options: { breakLine: true } },
      { text: " ", options: { fontSize: 10, breakLine: true } },
      { text: "Karl Glazebrook · Swinburne University of Technology", options: { bold: true, color: C.background1, breakLine: true } },
      { text: "with analysis assistance from Claude Sonnet 4.7 (Anthropic) · ADASS 2026, Perth", options: { fontSize: 16, color: MUTED_ON_DARK } },
    ], { placeholder: "body" });

    const x0 = M, x1 = W - M, lmax = 5.8, base = 6.55, d = 0.13, gap = 0.025;
    const bins = {};
    vals.slice().sort((a, b) => a - b).forEach((v, i) => {
      const b = Math.floor(Math.log10(v) / 0.1);
      const k = bins[b] = (bins[b] || 0) + 1;
      const x = x0 + (b + 0.5) * 0.1 / lmax * (x1 - x0) - d / 2;
      s.addShape(pres.shapes.OVAL, { x, y: base - k * (d + gap), w: d, h: d,
        fill: { color: tierColor(v) }, line: { color: tierColor(v), width: 0.5 }, objectName: `result ${i + 1}` });
    });
    const ticks = ["1×", "10×", "10²×", "10³×", "10⁴×", "10⁵×"];
    for (let e = 0; e <= 5; e++) {
      T(s, ticks[e],
        { x: x0 + e / lmax * (x1 - x0) - 0.4, y: base + 0.05, w: 0.8, h: 0.3, fontSize: 11, color: MUTED_ON_DARK, align: "center" });
    }
    T(s, "Each dot is one of the 131 test variants (run22), on a log scale of time relative to hand-written arm64 assembler",
      { x: x0, y: base + 0.38, w: CW, h: 0.3, fontSize: 11, color: MUTED_ON_DARK, italic: true });
    s.addNotes("~30 s. Title. Each dot on this slide is one of the 131 benchmark variants, coloured by tier, on a log axis — the whole talk is about why they spread across five and a half decades.");
  }

  // 2. Keith's 2019 study
  {
    const s = content("Where this started: Keith Shortridge, ADASS 2019", "The story");
    const bw = CW, bh = bw * 514 / 3307;
    s.addImage({ path: IMG("poster_banner.png"), x: M, y: 1.25, w: bw, h: bh, objectName: "2019 poster banner",
      altText: "Banner of Keith Shortridge's ADASS 2019 poster: 'This code is over 1,000,000 times faster than that code', with his photo" });
    const ty = 1.25 + bh + 0.3, th = 6.45 - ty, tw = th * 1649 / 1512;
    s.addText([
      { text: "Source: K. Shortridge, ADASS 2019, paper P9-17, poster and full write-up (Nov 2019) · " },
      { text: "github.com/KnaveAndVarlet/ADASS2019", options: { hyperlink: { url: "https://github.com/KnaveAndVarlet/ADASS2019" }, color: C.accent5 } },
    ], { isTextBox: true, x: M, y: 6.58, w: CW, h: 0.3, margin: 0, fontSize: 11, color: MUTED, valign: "middle" });
    s.addImage({ path: IMG("poster_table.png"), x: W - M - tw, y: ty, w: tw, h: th, objectName: "2019 results table",
      altText: "Keith Shortridge's 2019 colour-coded table of relative times by language and compiler option" });
    const lw = CW - tw - 0.4;
    s.addText([
      { text: "12 languages, one deliberately trivial kernel", options: { bullet: true, breakLine: true } },
      { text: "Fastest to slowest: more than a million-fold", options: { bullet: true, breakLine: true } },
      { text: "Compiler options alone: nearly 500× in one program", options: { bullet: true, breakLine: true } },
      { text: "Conference feedback went straight back in: numba, a Julia tweak, Rust idioms", options: { bullet: true } },
    ], { isTextBox: true, x: M, y: ty, w: lw, h: 1.75, fontSize: 16, color: C.text1, margin: 0, paraSpaceAfter: 6, valign: "top" });
    card(s, M, ty + 1.85, lw, th - 1.85, "kernel code card", C.text2);
    s.addText([
      { text: "for (int iy = 0; iy < ny; iy++)", options: { breakLine: true } },
      { text: "  for (int ix = 0; ix < nx; ix++)", options: { breakLine: true } },
      { text: "    Out[iy][ix] = In[iy][ix] + ix + iy;", options: { breakLine: true, color: HEX.accent6 } },
      { text: "// 2000 × 10 floats", options: { color: MUTED_ON_DARK } },
    ], { isTextBox: true, x: M + 0.25, y: ty + 1.85, w: lw - 0.5, h: th - 1.85, fontFace: "Courier New", fontSize: 14,
      color: C.background1, margin: 0, valign: "middle" });
    // the same kernel as maths, inset on the code card
    const ew = 3.15, eh = 0.75, ex = M + lw - ew - 0.2, ey = ty + 1.85 + (th - 1.85 - eh) / 2;
    card(s, ex, ey, ew, eh, "kernel equation inset");
    T(s, [
      { text: "B", options: { italic: true } }, { text: "(" }, { text: "x", options: { italic: true } }, { text: ", " },
      { text: "y", options: { italic: true } }, { text: ") = " },
      { text: "A", options: { italic: true } }, { text: "(" }, { text: "x", options: { italic: true } }, { text: ", " },
      { text: "y", options: { italic: true } }, { text: ") + " }, { text: "x", options: { italic: true } },
      { text: " + " }, { text: "y", options: { italic: true } },
    ], { x: ex, y: ey, w: ew, h: eh, fontFace: "Cambria Math", fontSize: 18, color: C.text2, align: "center", valign: "middle" });
    s.addNotes("~45 s. Keith's poster and paper (P9-17). The million-fold headline, with his own asterisk on the poster: 'a deliberately attention-grabbing headline claim'. One trivial kernel, so what you measure is how each language reaches an array element. Note how ADASS feedback improved his own study within weeks. Say thanks to Keith here, and again at the end.");
  }

  // 3. Where I came in (timeline)
  {
    const s = content("Where I came in: 2019 → 2024", "The story");
    const items = [
      { yr: "2019", head: "PDL and numpy one-liners",
        body: "I sent Keith one-line whole-array forms for both PDL and numpy (below); he credits both in the code. He already doubted his PDL element-lookup test." },
      { yr: "2022", head: "Keith writes arm64 assembler",
        body: "A hand-written NEON kernel for Apple Silicon (August 2022)." },
      { yr: "Jan 2024", head: "PDL::PP and compiler flags",
        body: "Setting the C flags on PDL::PP's compiled kernel: 9.3 s at -O0 → 2.2 s at -O2 on my M1. Keith replies with his assembler: “the improvements you get over C are marginal and not worth the effort.”" },
    ];
    const n = items.length, cw = (CW - (n - 1) * 0.4) / n, ly = 1.75;
    s.addShape(pres.shapes.LINE, { x: M + cw / 2, y: ly, w: CW - cw, h: 0, line: { color: MUTED, width: 1.5 }, objectName: "timeline axis" });
    items.forEach((it, i) => {
      const x = M + i * (cw + 0.4);
      s.addShape(pres.shapes.OVAL, { x: x + cw / 2 - 0.2, y: ly - 0.2, w: 0.4, h: 0.4, fill: { color: C.text2 }, line: { color: C.background1, width: 2 }, objectName: `milestone ${it.yr}` });
      T(s, it.yr, { x, y: ly + 0.3, w: cw, h: 0.4, fontSize: 18, bold: true, color: C.text2, align: "center", fontFace: "+mj-lt" });
      card(s, x, ly + 0.8, cw, 1.85, `milestone card ${it.yr}`);
      s.addText([
        { text: it.head, options: { bold: true, fontSize: 17, breakLine: true, color: C.text2 } },
        { text: it.body, options: { fontSize: 14 } },
      ], { isTextBox: true, x: x + 0.2, y: ly + 0.95, w: cw - 0.4, h: 1.6, margin: 0, color: C.text1, valign: "top", paraSpaceAfter: 6 });
    });
    // bottom row: what PDL is | the 2019 one-liner | Keith's quote
    const by = 4.6, bh = 2.2, pw = 4.7, kw = 4.15, qx = M + pw + 0.3 + kw + 0.3, qw = W - M - qx;
    card(s, M, by, pw, bh, "what is PDL card");
    s.addText([
      { text: "What is PDL?", options: { bold: true, fontSize: 17, color: C.text2, breakLine: true } },
      { text: "The Perl Data Language: fast n-dimensional numeric arrays for Perl, with the loops in compiled C. Perl's answer to IDL and numpy.", options: { breakLine: true } },
      { text: "Whole-array maths with broadcasting; PDL::PP for writing your own C kernels inline.", options: { breakLine: true } },
      { text: "Declared bias: I wrote it, in 1996.", options: { color: MUTED, italic: true } },
    ], { isTextBox: true, x: M + 0.2, y: by + 0.15, w: pw - 0.4, h: bh - 0.3, margin: 0, fontSize: 14, color: C.text1, valign: "top", paraSpaceAfter: 5 });
    card(s, M + pw + 0.3, by, kw, bh, "PDL one-liner card", C.text2);
    // both 2019 one-liners, as in csubpdlary.pl and csubnpna.py (run22 times)
    s.addText([
      { text: "# PDL, csubpdlary.pl: 25.1×", options: { color: MUTED_ON_DARK, breakLine: true } },
      { text: "$Output .= $Input", options: { breakLine: true } },
      { text: "  + sequence($Nx)", options: { breakLine: true } },
      { text: "  + sequence($Ny)->dummy(0,1);", options: { breakLine: true } },
      { text: " ", options: { fontSize: 6, breakLine: true } },
      { text: "# numpy, csubnpna.py: 17.8×", options: { color: MUTED_ON_DARK, breakLine: true } },
      { text: "out[:] = ina", options: { breakLine: true } },
      { text: "  + numpy.arange(nx)[NA,:]", options: { breakLine: true } },
      { text: "  + numpy.arange(ny)[:,NA]", options: {} },
    ], { isTextBox: true, x: M + pw + 0.45, y: by, w: kw - 0.5, h: bh, margin: 0, fontFace: "Courier New", fontSize: 12, color: C.background1, valign: "middle" });
    // xkcd 356, "Nerd Sniping", first panel (CC BY-NC 2.5)
    const xh = bh - 0.3, xw = xh * 624 / 588;
    s.addImage({ path: IMG("xkcd356_panel1.png"), x: qx + (qw - xw) / 2, y: by - 0.05, w: xw, h: xh, objectName: "xkcd nerd sniping",
      altText: "xkcd 356 first panel: there's a certain type of brain that's easily disabled; if you show it an interesting problem, it involuntarily drops everything else to work on it" });
    T(s, [{ text: "I got nerd-sniped.", options: { bold: true, color: C.text2, breakLine: true } }, { text: "xkcd.com/356 · Randall Munroe · CC BY-NC 2.5", options: { color: MUTED, fontSize: 9 } }],
      { x: qx, y: by + xh, w: qw, h: 0.42, fontSize: 13, align: "center", valign: "top" });
    s.addNotes("~1 min. The personal thread, and I got nerd-sniped (xkcd 356). PDL in one breath: the Perl Data Language, n-dimensional arrays for Perl with the loops in C — what numpy is to Python, started in 1996. 2019: the one-line arrays tricks Keith credits me for. He already wrote that ->slice element access was 'emphatically not the way PDL should be used' (hold that for later). 2022: Keith's arm64 assembler. Jan 2024: our emails about PDL::PP optimisation flags; he sent me the assembler, which became the 1.00 reference.");
  }

  // 4. Seven days in April
  {
    const s = content("Then Claude Code: seven days in April 2026", "The story");
    s.addChart(pres.charts.BAR, [{ name: "Tests passing", labels: ["25 Apr", "26 Apr", "27 Apr", "28–29 Apr", "+ Octave"], values: [58, 103, 111, 123, 131] }], {
      x: M, y: 1.3, w: 6.6, h: 3.45, barDir: "col", barGapWidthPct: 60,
      chartColors: [HEX.accent5], showValue: true, dataLabelPosition: "outEnd", dataLabelFontSize: 14, dataLabelColor: HEX.dk1,
      dataLabelFontFace: "+mn-lt", catAxisLabelFontFace: "+mn-lt", valAxisLabelFontFace: "+mn-lt",
      catAxisLabelColor: MUTED, valAxisLabelColor: MUTED, catAxisLabelFontSize: 12, valAxisLabelFontSize: 11,
      valAxisMinVal: 0, valAxisMaxVal: 140, valAxisMajorUnit: 20,
      valGridLine: { color: "D9DEE7", size: 0.5 }, catGridLine: { style: "none" }, showLegend: false,
      showTitle: true, title: "Tests passing in the suite", titleFontSize: 14, titleColor: HEX.dk2, titleFontFace: "+mn-lt",
      objectName: "tests passing by day",
    });
    T(s, "A test is one language with one compiler, runtime or option setting (e.g. C, clang -O3), built, run and timed by Keith's Run.py.",
      { x: M, y: 4.8, w: 6.6, h: 0.5, fontSize: 12, color: MUTED, italic: true });
    const stats = [["7", "days"], ["23", "benchmark runs"], ["~1,060", "of my prompts"], ["27", "languages"]];
    const sw = (6.6 - 3 * 0.2) / 4;
    stats.forEach(([n, l], i) => {
      const x = M + i * (sw + 0.2);
      card(s, x, 5.4, sw, 1.35, `stat ${l}`);
      T(s, n, { x, y: 5.5, w: sw, h: 0.7, fontSize: 30, bold: true, color: C.text2, align: "center", fontFace: "+mj-lt", valign: "middle" });
      T(s, l, { x, y: 6.2, w: sw, h: 0.4, fontSize: 12, color: MUTED, align: "center" });
    });
    const rx = M + 7.0, rw = CW - 7.0;
    s.addText([
      { text: "25 Apr", options: { bold: true, color: C.text2, breakLine: true } },
      { text: "Cloned the 2019 suite: 58 of its 103 tests pass. “The goal is maximum coverage.”", options: { breakLine: true } },
      { text: "26–27 Apr", options: { bold: true, color: C.text2, breakLine: true } },
      { text: "All 103 of Keith's tests pass. Then extend: assembler becomes 1.00; PDL::PP, Ruby (YJIT from source), Bun, Deno", options: { breakLine: true } },
      { text: "28–29 Apr: “a bit mad”", options: { bold: true, color: C.text2, breakLine: true } },
      { text: "Go, LuaJIT, C#, Crystal, OCaml, J, PyPy, Zig, Common Lisp, Haskell… INTERCAL: “PROGRAMMER IS OVERLY POLITE”", options: { breakLine: true } },
      { text: "Claude then offered a ranked list of what to add next. Me:", options: { breakLine: true } },
      { text: "“Do #1 to #7 please and then we will stop :)”", options: { italic: true, color: C.text2, breakLine: true } },
      { text: "#1–#7: F#, PyPy + numpy, C# ahead-of-time, D, Nim, Octave, Kotlin", options: { fontSize: 13, color: MUTED, breakLine: true } },
      { text: "29 Apr – 1 May", options: { bold: true, color: C.text2, breakLine: true } },
      { text: "Report, audit rounds, PDL fix, run22 frozen, one-command toolchain rebuild", options: {} },
    ], { isTextBox: true, x: rx, y: 1.35, w: rw, h: 5.4, margin: 0, fontSize: 15, color: C.text1, valign: "top", paraSpaceAfter: 5 });
    s.addNotes("~30 s, don't read the timeline out. Then Claude Code arrived and I used it to port the suite to a few more languages, for fun. Day one: 58 of Keith's 103 tests passing on this Mac; all 103 by the next day (run2), none ever dropped. Only the x86 assembler had to be swapped for Keith's arm64 one. Then we extended it: 28 new tests. By day five, 27 languages and 131 tests. My own message: 'Do #1 to #7 please and then we will stop'. We did not stop. Then the report, audits, the PDL fix and a reproducible toolchain. Prompt count is from the transcript to 30 April.");
  }

  // ===================================================== Part B: results
  pres.addSection({ title: "Results" });

  // 5. Suite at a glance
  {
    const s = content("The 2026 suite at a glance", "Results");
    const rows = [["27", "languages", "15 new (the abstract's 29 splits C/C++, Perl/PDL)"], ["131", "variants", "131 / 131 pass (run22)"],
                  ["4.8 × 10⁵", "range", "1.00 up to the R reference class at 481,009"]];
    rows.forEach(([n, l, sub], i) => {
      const y = 1.3 + i * 1.6;
      T(s, n, { x: M, y, w: 4.2, h: 0.9, fontSize: 48, bold: true, color: C.text2, fontFace: "+mj-lt", valign: "bottom" });
      T(s, [{ text: l, options: { bold: true, breakLine: true } }, { text: sub, options: { color: MUTED, fontSize: 14 } }],
        { x: M, y: y + 0.95, w: 4.2, h: 0.7, fontSize: 16 });
    });
    card(s, M, 6.1, 4.2, 0.78, "reference card");
    T(s, [{ text: "Reference: ", options: { bold: true, color: C.text2 } },
          { text: "1.00 = Keith's hand-written arm64 NEON assembler. Best C: 1.19 (clang -O3 -march=native).", options: {} }],
      { x: M + 0.15, y: 6.17, w: 3.9, h: 0.64, fontSize: 13, valign: "middle" });
    // histogram from make_talk_histogram.py, with its axes geometry, so the arrows sit on real values
    const G = JSON.parse(fs.readFileSync(IMG("talk_histogram.json"), "utf8"));
    const ix = M + 4.6, iw = CW - 4.6, ih = iw * G.fig[1] / G.fig[0], iy = 2.0;
    s.addImage({ path: IMG("talk_histogram.png"), x: ix, y: iy, w: iw, h: ih, objectName: "histogram",
      altText: "Histogram of all 131 relative times on a log scale, coloured by the eight tiers, with three peaks" });
    const lx0 = Math.log10(G.xlim[0]), lx1 = Math.log10(G.xlim[1]);
    const xAt = (v) => ix + iw * (G.ax[0] + G.ax[2] * (Math.log10(v) - lx0) / (lx1 - lx0));
    const groups = [
      { lo: 1, hi: 15, label: "native", color: TIER_COLORS[0], text: HEX.dk1,
        head: "Native code, 1–15×",
        body: "Compiled to machine code ahead of time or by a good JIT: C, Fortran, Julia, D, Zig, Java, C#, Go, LuaJIT, Haskell. Also numba and PDL::PP, which compile the loop for Python and Perl." },
      { lo: 15, hi: 100, label: "arrays", color: TIER_COLORS[4], text: HEX.dk1,
        head: "Whole arrays, half measures, 15–100×",
        body: "One whole-array expression in numpy, PDL, Numo or Octave; JavaScript engines; Swift -O; PyPy on lists; C or Fortran with no optimisation." },
      { lo: 100, hi: 20000, label: "interpreted", color: TIER_COLORS[6], text: "FFFFFF",
        head: "Interpreted element lookup, 100–20,000×",
        body: "An interpreter touching one element at a time: Python lists, Perl, Ruby, R, Tcl, numpy or PDL lookup. Purple: per-element cost explodes." },
      { lo: 20000, hi: G.xlim[1], label: "pathological", color: TIER_COLORS[7], text: "FFFFFF", nobox: true },
    ];
    const bw = (iw - 2 * 0.15) / 3, by = iy + ih + 0.1, bh = 6.85 - by;
    groups.forEach((g, i) => {
      const x0 = xAt(g.lo), x1 = xAt(g.hi);
      s.addText(g.label, { shape: pres.shapes.LEFT_RIGHT_ARROW, x: x0, y: 1.35, w: x1 - x0, h: 0.55, margin: 0,
        fill: { color: g.color }, line: { color: MUTED, width: 0.75 },
        fontSize: 13, bold: true, color: g.text, align: "center", valign: "middle", objectName: `group arrow ${i + 1}` });
      arrowShades[`group arrow ${i + 1}`] = tierBands(g.lo, g.hi);
      if (g.nobox) return;
      s.addText([{ text: g.head, options: { bold: true, fontSize: 14, color: C.text2, breakLine: true } }, { text: g.body, options: { fontSize: 12 } }],
        { x: ix + i * (bw + 0.15), y: by, w: bw, h: bh, margin: [6, 8, 6, 8], fill: { color: C.background2 },
          line: { color: g.color, width: 2.5 }, color: C.text1, valign: "top", paraSpaceAfter: 3, objectName: `group box ${i + 1}` });
    });
    s.addNotes("~1 min. Reference first: 1.00 is Keith's hand-written NEON assembler; the best C is 1.19, so a good C compiler gets within 20% of hand-written assembler (the 1.19 test is labelled g++ in Run.py, but g++ on macOS is Apple clang; the clang-named run is 1.20). 27 languages, 15 of them new, counted the way Keith counted his 12 (C/C++ as one, Perl/PDL as one). 131 variants, all passing in run22, the frozen reference. The range is 4.8e5 rather than Keith's million, partly from the new reference and partly the PDL correction. Three peaks. CLICK: native code, 1 to 15x, where tier 3 (2.5 to 7x) is the crowd, 41 of 131. CLICK: whole-array expressions and half measures, 15 to 100x. CLICK: an interpreter doing element lookup, the spike near 600 to 1,000x, and the last arrow, pathological, beyond 20,000x, where every element crosses a library boundary: PyPy + numpy, the Octave loop, R reference classes.");
  }

  // 5b. The code wall: one kernel in a dozen languages, straight from the repo sources
  codeWall("One kernel, the 15 new languages, and Keith's C for reference", "Results", SNIPPETS.wall,
    "~30 s, let it land. Each of the 15 languages new in 2026, plus Keith's own C kernel as the reference, pulled verbatim from its source file in the repo (file names on the cards) and highlighted; the chip is its run22 time relative to the assembler. The same element-lookup kernel throughout, except J, which says it as one whole-array expression. Ordered fastest first: D and Zig sit just behind C; Octave's loop is at the far end, 46,705. Most of the 2026 ports are 64-bit doubles against Keith's 32-bit floats (the precision caveat later). Keith's 12 languages are on a backup slide.",
    4, 4);

  // 6. Python ladder (headline)
  {
    const s = content("Same Python source, almost four orders of magnitude", "Results");
    const labels = ["PyPy + numpy, element lookup", "CPython + numpy, element lookup", "CPython, plain lists", "PyPy, plain lists", "numpy one-liner (rewrite)", "numba @jit, element loop"];
    const values = [22015.37, 2882.58, 644.02, 36.17, 17.80, 3.15];
    const colors = values.map((v, i) => (i === 4 ? "9AA3B2" : tierColor(v)));
    s.addChart(pres.charts.BAR, [{ name: "Relative time", labels, values }], {
      x: M, y: 1.3, w: 8.3, h: 3.65, barDir: "bar", barGapWidthPct: 40, chartColors: colors,
      catAxisOrientation: "maxMin", valAxisLogScaleBase: 10, valAxisMinVal: 1, valAxisMaxVal: 100000,
      showValue: true, dataLabelPosition: "outEnd", dataLabelFormatCode: "[>=100]#,##0;0.0#", dataLabelFontSize: 14,
      dataLabelColor: HEX.dk1, dataLabelFontBold: true,
      dataLabelFontFace: "+mn-lt", catAxisLabelFontFace: "+mn-lt", valAxisLabelFontFace: "+mn-lt",
      catAxisLabelColor: HEX.dk1, valAxisLabelColor: MUTED, catAxisLabelFontSize: 14, valAxisLabelFontSize: 11,
      valAxisLabelFormatCode: "#,##0", valGridLine: { color: "D9DEE7", size: 0.5 }, catGridLine: { style: "none" },
      showLegend: false, showTitle: true, title: "Time relative to assembler (log scale)", titleFontSize: 13,
      titleColor: MUTED, titleFontFace: "+mn-lt", objectName: "python runtime ladder",
    });
    // the decorated kernel itself, from csubnp-numba.py, decorator in red
    const nb = SNIPPETS.numba;
    card(s, M, 5.1, 8.3, 1.7, "numba code card", nb.background);
    code(s, nb, M + 0.3, 5.35, 5.6, 1.3, 14, (i) => (i === 0 ? { color: "FF6B6B", bold: true } : null));
    T(s, [{ text: "The whole change:", options: { bold: true, color: "E6EDF3", breakLine: true } },
          { text: "one line, \u201c@numba.jit\u201d", options: { color: "FF6B6B", breakLine: true } },
          { text: `${nb.file}, lines ${nb.lines}`, options: { fontSize: 11, color: MUTED_ON_DARK } }],
      { x: M + 5.9, y: 5.28, w: 2.2, h: 1.4, fontSize: 14, valign: "middle" });
    const rx = M + 8.7, rw = CW - 8.7;
    card(s, rx, 1.4, rw, 2.45, "decorator callout");
    T(s, "915×", { x: rx + 0.25, y: 1.5, w: rw - 0.5, h: 1.0, fontSize: 54, bold: true, color: HEX.accent1, fontFace: "+mj-lt", valign: "middle" });
    T(s, [{ text: "from one decorator: numpy element loop 2,883 → numba 3.15", options: { breakLine: true } },
           { text: "Keith found this in 2019: over 2,500× on x86.", options: { fontSize: 13, italic: true, color: MUTED } }],
      { x: rx + 0.25, y: 2.5, w: rw - 0.5, h: 1.25, fontSize: 16, valign: "top" });
    card(s, rx, 4.1, rw, 2.45, "interpreter callout");
    T(s, "17.8×", { x: rx + 0.25, y: 4.2, w: rw - 0.5, h: 1.0, fontSize: 54, bold: true, color: HEX.accent5, fontFace: "+mj-lt", valign: "middle" });
    T(s, "from swapping the interpreter: CPython lists 644 → PyPy 36.2", { x: rx + 0.25, y: 5.25, w: rw - 0.5, h: 1.1, fontSize: 16 });
    s.addNotes("~1.5 min. THE headline slide. Two pairs share source: the list loop (CPython 644, PyPy 36) and the numpy element loop (CPython 2,883, PyPy 22,015, numba 3.15); the grey bar is my whole-array one-liner from slide 3, for comparison. Credit Keith: numba was his 2019 finding (over 2,500x on x86); what 2026 adds is PyPy, and the PyPy + numpy trap. The default pattern for someone told 'use numpy' — looping over numpy elements — is 4.5x slower than plain lists. Worse still, the top bar: the same numpy loop under PyPy, 22,015, because every element access crosses PyPy's C-extension emulation layer (more on that in the surprises). One @numba.jit decorator, the red line on the slide, from Keith's own csubnp-numba.py: 915x. Swapping the interpreter for PyPy: 17.8x. The choice that matters most is the runtime, not the language.");
  }

  // 7. Within vs across
  {
    const s = content("Runtime and idiom matter more than language", "Results");
    T(s, "Within one language: 2–3 orders of magnitude", { x: M, y: 1.3, w: 6.0, h: 0.45, fontSize: 20, bold: true, color: C.text2, fontFace: "+mj-lt" });
    const pairs = [
      ["Octave", "loop", 46705.41, "46,705", "vectorised", 57.45, "57.5", "813×"],
      ["PDL", "lookup", 9206.51, "9,207", "PDL::PP", 5.47, "5.47", "1,683×"],
      ["Python", "numpy loop", 2882.58, "2,883", "numba", 3.15, "3.15", "915×"],
      ["Ruby", "3.3", 755.08, "755", "+ YJIT", 284.40, "284", "2.7×"],
    ];
    pairs.forEach(([lang, a, va, sa, b, vb, sb, f], i) => {
      const y = 2.0 + i * 1.15;
      card(s, M, y, 6.0, 0.95, `pair ${lang}`);
      T(s, lang, { x: M + 0.2, y, w: 1.1, h: 0.95, fontSize: 16, bold: true, color: C.text2, valign: "middle" });
      chip(s, M + 1.35, y + 0.15, 1.6, 0.65, va, `${a} ${sa}`, 13);
      T(s, "→", { x: M + 3.0, y, w: 0.35, h: 0.95, fontSize: 20, color: MUTED, align: "center", valign: "middle" });
      chip(s, M + 3.4, y + 0.15, 1.6, 0.65, vb, `${b} ${sb}`, 13);
      T(s, f, { x: M + 5.05, y, w: 0.85, h: 0.95, fontSize: 17, bold: true, color: C.text2, align: "right", valign: "middle" });
    });
    const rx = M + 6.5, rw = CW - 6.5;
    T(s, "Compiled languages: mostly under 10×", { x: rx, y: 1.3, w: rw, h: 0.45, fontSize: 20, bold: true, color: C.text2, fontFace: "+mj-lt" });
    const langs = ["Julia (int32)", "C (best)", "Fortran -O3 native", "D", "Zig", "Nim", "Crystal", "Java", "Go"];
    const lv = [1.17, 1.19, 2.05, 2.76, 2.84, 3.31, 3.67, 3.70, 6.91];
    s.addChart(pres.charts.BAR, [{ name: "Relative time", labels: langs, values: lv }], {
      x: rx, y: 1.85, w: rw, h: 4.35, barDir: "bar", barGapWidthPct: 40, chartColors: lv.map(tierColor),
      catAxisOrientation: "maxMin", valAxisMinVal: 0, valAxisMaxVal: 8, valAxisMajorUnit: 2,
      showValue: true, dataLabelPosition: "outEnd", dataLabelFormatCode: "0.00", dataLabelFontSize: 13, dataLabelColor: HEX.dk1,
      dataLabelFontFace: "+mn-lt", catAxisLabelFontFace: "+mn-lt", valAxisLabelFontFace: "+mn-lt",
      catAxisLabelColor: HEX.dk1, valAxisLabelColor: MUTED, catAxisLabelFontSize: 13, valAxisLabelFontSize: 11,
      valGridLine: { color: "D9DEE7", size: 0.5 }, catGridLine: { style: "none" }, showLegend: false,
      objectName: "compiled languages",
    });
    T(s, "Not shown: F# 7.2, Rust 6.8 (iterators), Haskell 9.2, OCaml 9.4, Swift 17.9. Caveat: Keith's C, Fortran, Julia and Java are 32-bit floats; the 2026 ports are 64-bit, half the values per NEON instruction.",
      { x: rx, y: 6.25, w: rw, h: 0.6, fontSize: 12, italic: true, color: MUTED });
    s.addNotes("~1 min. Precision caveat, say it briefly: Keith's compiled kernels and the assembler are single precision; the 2026 ports of D, Zig, Nim, Crystal and Go (and C#, F#, Kotlin, OCaml, Haskell, Lisp) are double. NEON holds 4 floats or 2 doubles per register, so part of the spread here may be precision, not language. To fix after the conference. Also: Octave vectorised builds its index vectors once, outside the timed loop; numpy and PDL arrays rebuild them per call. Left: inside one language, the runtime or idiom spans two to three orders of magnitude (Ruby's YJIT gain is the modest one). Right: across the compiled languages the whole spread is under 7x, on a linear axis. Pick your runtime and idiom carefully; the language matters less.");
  }

  // 8. Runtimes new to the suite
  {
    const s = content("Runtimes new to the suite (not new technology)", "Results");
    const cols = [
      { head: "In Keith's 2019 study", rows: [["Java (HotSpot JIT)", 3.70, "3.70"], ["Node.js (V8)", 25.88, "25.9"], ["Julia", 1.17, "1.17"], ["numba", 3.15, "3.15"]] },
      { head: "Old technology, first time here", rows: [["LuaJIT (2005)", 7.59, "7.59"], ["PyPy (2007)", 36.17, "36.2"], ["C# .NET JIT", 5.31, "5.31"], ["Lisp (SBCL), typed", 10.63, "10.6"], ["J", 8.24, "8.24"]] },
      { head: "Genuinely post-2019", rows: [["Deno (2020)", 24.43, "24.4"], ["Ruby YJIT (2021)", 284.40, "284"], ["Bun (2023)", 12.29, "12.3"], [".NET native AOT (2022)", 5.39, "5.39"]] },
    ];
    const cw = (CW - 2 * 0.3) / 3, top = 1.35, ch = 4.0;
    cols.forEach((c, i) => {
      const x = M + i * (cw + 0.3);
      card(s, x, top, cw, ch, `column ${c.head}`);
      T(s, c.head, { x: x + 0.2, y: top + 0.15, w: cw - 0.4, h: 0.45, fontSize: 17, bold: true, color: C.text2, fontFace: "+mj-lt" });
      c.rows.forEach(([name, v, lab], j) => {
        const y = top + 0.75 + j * 0.62;
        T(s, name, { x: x + 0.2, y, w: cw - 1.5, h: 0.5, fontSize: 15, valign: "middle" });
        chip(s, x + cw - 1.2, y + 0.05, 1.0, 0.42, v, lab, 13);
      });
    });
    const by = top + ch + 0.25;
    s.addText([
      { text: "A good JIT turns a dynamic language into a compiled one: ", options: { bold: true, color: C.text2 } },
      { text: "LuaJIT 7.59 beats safe Rust -O3 (12.0); PyPy is 18× CPython. Not all JITs are equal: YJIT gives Ruby only 2.7×.", options: { breakLine: true } },
      { text: "Age doesn't predict speed: ", options: { bold: true, color: C.text2 } },
      { text: "LuaJIT (2005) beats Deno, Bun and YJIT, all newer than 2019.", options: { breakLine: true } },
      { text: "For C#'s hot loop, JIT versus ahead-of-time makes no difference: ", options: { bold: true, color: C.text2 } },
      { text: "5.31 JIT, 5.39 AOT.", options: {} },
    ], { isTextBox: true, x: M, y: by, w: CW, h: 1.25, margin: 0, fontSize: 15, color: C.text1, valign: "top", paraSpaceAfter: 4, objectName: "runtime takeaways" });
    s.addNotes("~1.5 min. Why 'new'? New to this benchmark, not new technology. Java, V8, Julia and numba were all in Keith's 2019 study. LuaJIT and PyPy are old, just never measured here. Genuinely newer than 2019: Deno, Ruby YJIT, Bun, .NET native AOT. Don't claim V8's optimiser makes Node fast here: Node --no-opt is 26.5, almost the same. Takeaways: a good JIT is what separates fast dynamic languages from slow ones (LuaJIT, PyPy, V8, Bun), but YJIT shows not every JIT gets there on this kernel (Ruby 755 to 284). The oldest runtime here is the fastest. And C#'s JIT and native AOT are within 2%: for a hot loop, warm JIT code is as good as compiled. Bun is about 2x Node. If asked: CPython 3.13's experimental JIT isn't tested; run22 used Python 3.12.7.");
  }

  // 9. Three small surprises
  {
    const s = content("Three small surprises", "Results");
    const items = [
      { head: "PyPy + numpy", v: 22015.37, big: "22,015", meme: true,
        body: "Also 7.6× slower than CPython + numpy. Every numpy call crosses PyPy's C-extension layer: use one or the other." },
      { head: "PDL element lookup", v: 9206.51, big: "103,570 → 9,207",
        body: "->at / ->set instead of ->slice: about 11× faster. In 2019 Keith distrusted ->slice; ->at and ->set are the 2026 change. The LLM ran the old code and reported “PDL is just slow”." },
      { head: "Lisp type declarations", v: 10.63, big: "167 → 10.6",
        body: "Common Lisp, compiled by SBCL (Steel Bank Common Lisp): 15.7× from type declarations alone. Same lesson as numba: give the compiler the types." },
    ];
    const cw = (CW - 2 * 0.3) / 3, top = 1.35, ch = 4.5;
    items.forEach((it, i) => {
      const x = M + i * (cw + 0.3);
      card(s, x, top, cw, ch, `surprise ${it.head}`);
      T(s, `${i + 1}. ${it.head}`, { x: x + 0.25, y: top + 0.2, w: cw - 0.5, h: 0.5, fontSize: 20, bold: true, color: C.text2, fontFace: "+mj-lt" });
      chip(s, x + 0.25, top + 0.8, cw - 0.5, 0.7, it.v, it.big, 24);
      if (!it.meme) {
        T(s, it.body, { x: x + 0.25, y: top + 1.7, w: cw - 0.5, h: ch - 1.8, fontSize: 17 });
        return;
      }
      // photo meme: Gare Montparnasse, 22 Oct 1895 (public domain), cropped to the locomotive
      const px = x + 0.25, py = top + 1.65, pw = cw - 0.5, ph = 1.95;
      const sw = 1280, sh = 1536, sc = pw / sw, fullH = sh * sc;
      s.addImage({ path: IMG("montparnasse_1895.jpg"), x: px, y: py, w: pw, h: fullH,
        sizing: { type: "crop", x: 0, y: 0.42 * fullH, w: pw, h: ph }, objectName: "oops photo",
        altText: "1895 photograph of a steam locomotive that overran Gare Montparnasse and crashed nose-down into the street" });
      const meme = { isTextBox: true, x: px, w: pw, h: 0.42, margin: 0.04, align: "center", valign: "middle",
        fontFace: "Impact", fontSize: 17, color: "FFFFFF", outline: { size: 1.25, color: "000000" } };
      s.addText("FAST + FAST ≠ FASTER", Object.assign({}, meme, { y: py, objectName: "meme top" }));
      s.addText("609× SLOWER THAN PYPY ALONE", Object.assign({}, meme, { y: py + ph - 0.42, objectName: "meme bottom" }));
      T(s, "Also 7.6× slower than CPython + numpy. Use one or the other.",
        { x: x + 0.25, y: py + ph + 0.12, w: cw - 0.5, h: 0.6, fontSize: 15 });
      T(s, "Photo: Gare Montparnasse, 1895 (public domain)",
        { x: x + 0.25, y: top + ch - 0.28, w: cw - 0.5, h: 0.22, fontSize: 9, italic: true, color: MUTED });
    });
    T(s, "Each is a choice of configuration or idiom, not of language.",
      { x: M, y: top + ch + 0.15, w: CW, h: 0.5, fontSize: 22, bold: true, color: C.text2, fontFace: "+mj-lt", align: "center", valign: "middle" });
    T(s, "“Element lookup” is what Keith's harness calls “raw”: read and write the array one element at a time, A[iy][ix].",
      { x: M, y: top + ch + 0.65, w: CW, h: 0.3, fontSize: 12, italic: true, color: MUTED, align: "center" });
    s.addNotes("~1.5 min. 1: PyPy plus numpy is the slowest mainstream Python setup: 609x slower than PyPy on plain lists and 7.6x slower than CPython + numpy. Pick one. 2 (keep it brief): the PDL element-lookup test (Keith's 'raw') now uses PDL's element-access primitives. 103,570 was the 2019 code run on this machine (run19); 9,207 in run22. Keith himself flagged ->slice in 2019. The LLM didn't spot it. 3: Common Lisp with the SBCL compiler (Steel Bank Common Lisp, the main open-source native-code Lisp), 15.7x from type declarations.");
  }

  // ===================================================== Part C: the LLM
  pres.addSection({ title: "The LLM" });

  // 10. The LLM: what it did, and what it didn't
  {
    const s = content("What the LLM did, and what it didn't", "The LLM");
    const lw = 6.0, rx = M + lw + 0.4, rw = CW - lw - 0.4;
    T(s, "Did well", { x: M, y: 1.25, w: lw, h: 0.45, fontSize: 20, bold: true, color: C.text2, fontFace: "+mj-lt" });
    const rows = [
      [fa.FaCode, "Porting at scale", "15 new languages in about four days; J in 9 lines, unprompted."],
      [fa.FaTools, "Environment wrangling", "PyPy's python3 hijacked 7 numpy tests; GHC and Ruby baked paths into 235 files."],
      [fa.FaChartBar, "The whole pipeline", "Figures and the 131-row appendix, regenerated from one frozen log."],
      [fa.FaPenNib, "Decent first drafts", "Of the 21-page report and this deck. Not the abstract: it “would appeal only to an LLM not a human”."],
      [fa.FaRedo, "Reproducibility", "One script rebuilds every toolchain; a fresh re-run passed 131/131."],
    ];
    for (let i = 0; i < rows.length; i++) {
      const [Ic, head, body] = rows[i];
      const y = 1.85 + i * 1.0;
      s.addShape(pres.shapes.OVAL, { x: M, y: y + 0.08, w: 0.62, h: 0.62, fill: { color: C.text2 }, line: { color: C.text2 }, objectName: `icon circle ${head}` });
      s.addImage({ data: await icon(Ic, HEX.lt1), x: M + 0.16, y: y + 0.24, w: 0.3, h: 0.3, objectName: `icon ${head}`, altText: head });
      s.addText([
        { text: head, options: { bold: true, fontSize: 16, color: C.text2, breakLine: true } },
        { text: body, options: { fontSize: 13 } },
      ], { isTextBox: true, x: M + 0.85, y, w: lw - 0.85, h: 0.92, margin: 0, color: C.text1, valign: "top", paraSpaceAfter: 2 });
    }
    T(s, "Didn't do", { x: rx, y: 1.25, w: rw, h: 0.45, fontSize: 20, bold: true, color: C.text2, fontFace: "+mj-lt" });
    const fails = [
      ["Missed the PDL problem", "Ran the 2019 code faithfully and accepted 103,570 as “PDL is just slow”. I caught it."],
      ["Silent drift", "Mis-copied numbers from the logs into the prose and tables. About seven rounds of ChatGPT audits caught them (backup slides)."],
      ["No sense of what's interesting", "Asked what to add, it gave a long, flat list; choosing was my job."],
      ["I didn't write the ports", "Unlike Keith, I trusted the LLM's code. I can't vouch that each port is what an expert would write."],
    ];
    fails.forEach(([h, b], i) => {
      const y = 1.85 + i * 1.12, hh = 1.0;
      card(s, rx, y, rw, hh, `failure ${h}`, i === 3 ? "FDE7E4" : C.background2);
      s.addText([{ text: h, options: { bold: true, fontSize: 16, color: i === 3 ? HEX.accent3 : C.text2, breakLine: true } }, { text: b, options: { fontSize: 13 } }],
        { isTextBox: true, x: rx + 0.2, y: y + 0.08, w: rw - 0.4, h: hh - 0.12, margin: 0, color: C.text1, valign: "top", paraSpaceAfter: 2 });
    });
    T(s, "Future work: expert and multi-LLM review of the kernels themselves, not just the numbers.",
      { x: rx, y: 6.4, w: rw, h: 0.4, fontSize: 13, bold: true, color: C.text2 });
    s.addNotes("~2 min. A partner, not a search bar. Weeks of porting done in days. The unglamorous bulk was the environment: tools hijacking each other's python, perl and gfortran. It kept the report tied to one log and made the toolchain reproducible. Its first drafts of the report and of these slides were decent; its abstract was not, and I rewrote it. Then the limits. It did not catch the PDL problem: domain expertise did. Its worst habit is silent numerical drift, which is why we ran an audit loop with ChatGPT as critic, about seven rounds (the exact ChatGPT model wasn't recorded); the errors were transcriptions from the logs, not bugs in the kernels, each of which checks its own output. The big caveat: unlike Keith, I did not write the ported code; I trusted it. Keith's 53-page write-up is full of language-specific gotchas an expert would spot. One we know about: the 2026 ports use 64-bit doubles where Keith's kernels use 32-bit floats. Future work: have experts, and other LLMs, review the kernels themselves. If asked about INTERCAL: it compiled, but C-INTERCAL's runtime has an arm64 va_arg bug that breaks even hello.i.");
  }

  // 12. Take-home: five conclusions, set against Keith's 2019 ones
  {
    const s = content("What to take home", "The LLM");
    const recs = [
      ["Runtime, not language, sets your speed",
        "Python: reach for @njit before C (2,883 → 3.15); never PyPy with numpy; don't loop over numpy elements. Lists: CPython 644 → PyPy 36."],
      ["Compiled languages are close: choose for ergonomics",
        "Keith said it in 2019; 15 more languages agree. Best variants: D 2.8, Zig 2.8, Java 3.7, C# 5.3, Go 6.9, Rust 6.8; Swift the outlier at 17.9."],
      ["Cross the interpreter boundary once, not per element",
        "numpy element lookup 2,883 → vectorised 16. PDL 9,207 → PDL::PP 5.5. Octave loop 46,705 → vectorised 57."],
      ["Flags, types and idiom are free orders of magnitude",
        "Swift -Onone → -O: about 200×. Lisp type declarations: 16×. Rust iterators 6.8 against indexed loops 12.0."],
      ["LLMs port fast; humans must audit the numbers and own the code",
        "15 languages in 4 days, no bugs found in the ports; but 14 numbers mis-copied into the prose, and no expert has reviewed the kernels."],
    ];
    const rh = 0.92, top = 1.3;
    recs.forEach(([h, b], i) => {
      const y = top + i * (rh + 0.08);
      card(s, M, y, CW, rh, `conclusion ${i + 1}`);
      s.addShape(pres.shapes.OVAL, { x: M + 0.2, y: y + (rh - 0.58) / 2, w: 0.58, h: 0.58, fill: { color: C.text2 }, line: { color: C.text2 }, objectName: `number ${i + 1}` });
      T(s, String(i + 1), { x: M + 0.2, y: y + (rh - 0.58) / 2, w: 0.58, h: 0.58, fontSize: 20, bold: true, color: "FFFFFF", align: "center", valign: "middle" });
      s.addText([{ text: h, options: { bold: true, fontSize: 19, color: C.text2, fontFace: "+mj-lt", breakLine: true } }, { text: b, options: { fontSize: 14 } }],
        { isTextBox: true, x: M + 1.0, y: y + 0.06, w: CW - 1.2, h: rh - 0.12, margin: 0, color: C.text1, valign: "middle", paraSpaceAfter: 2 });
    });
    s.addText([
      { text: "2019: flags, idiom and JITs beat language. 2026: ", options: {} }, { text: "15 more languages agree", options: { italic: true } },
      { text: ". Check every number against the log.", options: {} },
    ], { isTextBox: true, x: M, y: top + 5 * (rh + 0.08) + 0.02, w: CW, h: 0.6, margin: 0, fontSize: 17, bold: true, color: C.text2,
      fontFace: "+mj-lt", align: "center", valign: "middle", objectName: "closing line" });
    s.addNotes("~1.5 min. Keith's 2019 conclusions, all of which still hold: the range is the result; optimisation flags are the cheapest win; compilers make hand-written assembler not worth it; element-at-a-time numpy or PDL is pathological; and 'the solution to long execution times is very rarely to change the implementation language'. Points 2 and 4 are Keith's, confirmed; Keith also said 'JIT compilers (Javascript, Python/Numba) can be very efficient'. What 2026 adds: PyPy, LuaJIT, YJIT and Bun, the PyPy + numpy trap, the PDL correction, and the LLM lesson. "
      + "1: numba is the one decorator on the Python ladder slide; never PyPy with numpy (22,015). "
      + "2: caveat, Keith's C and the assembler are 32-bit floats, the 2026 ports are 64-bit doubles, so part of this spread is precision. Swift's 17.9 is its arrays of arrays: each row a separate copy-on-write object; bounds checks are not the cost (-Ounchecked 17.9). "
      + "3: element-by-element numpy is 4.5x slower than plain Python lists; in PDL use ->at/->set or, better, broadcast or PP; Octave vectorised builds its index vectors outside the timed loop, so flag it. "
      + "4: Keith's 2019 point, still true on arm64. Boost without asserts, unoptimised 878 to 3.2 at -O3. "
      + "5: as far as we know the LLM's kernels are correct (each one verifies its output); the errors the ChatGPT audits caught were numbers mis-transcribed from the logs into the report prose and tables. This is the weakest-supported point: one project, and the kernels have not been reviewed by people expert in each language. "
      + "If asked about Apple Silicon: every toolchain ran natively on arm64 except Python 2.7, an x86_64 conda build running under Rosetta 2. If asked about reproducibility: fast tiers agree within a few percent between runs, slow entries move 25-45%: trust the tier, not the digit.");
  }

  // 13. Thanks
  {
    const s = pres.addSlide({ masterName: "Title Dark", sectionTitle: "The LLM" });
    s.addText("Thank you, Keith", { placeholder: "title" });
    s.addText([
      { text: "and thank you all. Questions?", options: { breakLine: true } },
      { text: " ", options: { fontSize: 10, breakLine: true } },
      { text: "Original suite: ", options: { fontSize: 16, color: MUTED_ON_DARK } },
      { text: "github.com/KnaveAndVarlet/ADASS2019", options: { fontSize: 16, color: MUTED_ON_DARK, breakLine: true,
          hyperlink: { url: "https://github.com/KnaveAndVarlet/ADASS2019" } } },
      { text: "2026 suite, report, logs and this talk: ", options: { fontSize: 16, color: MUTED_ON_DARK } },
      { text: "github.com/karlglazebrook/ADASS2026", options: { fontSize: 16, color: MUTED_ON_DARK,
          hyperlink: { url: "https://github.com/karlglazebrook/ADASS2026" } } },
    ], { placeholder: "body" });
    // xkcd-style invitation, from make_nerdsnipe.py
    const nw = 5.0, nh = nw * 4.4 / 6.4;
    s.addImage({ path: IMG("nerdsnipe.png"), x: W - M - nw, y: 7.5 - nh - 0.16, w: nw, h: nh, objectName: "nerd-snipe cartoon",
      altText: "Hand-drawn style chart of languages benchmarked: 12 in 2019 by Keith, 27 in 2026, a red dashed line to 'YOU?', and INTERCAL marked 'still undefeated'" });
    s.addNotes("The cartoon: consider yourself nerd-sniped. Pull requests welcome, and INTERCAL is still waiting for someone. Thank Keith first and by name. The 2026 material is in the ADASS2026 folder of the fork.");
  }

  // ===================================================== Backup
  pres.addSection({ title: "Backup" });
  // 5a. Every language, best to worst variant (make_language_ranges.py)
  {
    const s = content("Backup: every language, from its best variant to its worst", "Backup");
    const iw = CW, ih = iw * 1082 / 2562;
    s.addImage({ path: IMG("fig7_language_ranges.png"), x: M, y: 1.25, w: iw, h: ih, objectName: "language ranges",
      altText: "Run22 relative times for each of the 27 languages, one column each, sorted by best variant; the 15 new languages in red" });
    T(s, [
      { text: "Red labels: the 15 languages new in 2026, mostly one variant each. ", options: { bold: true, color: HEX.accent3 } },
      { text: "The long bars are Keith's option sweeps (C/C++ alone has 60 variants) and changes of idiom: Python, PDL, Octave, R. Bars and dots are coloured by tier, green 1 to purple 8; (n) is the number of variants.", options: {} },
    ], { x: M, y: 1.35 + ih, w: CW, h: 0.8, fontSize: 15 });
    s.addNotes("Backup. One column per language, counted the way Keith counted his 12, sorted by each language's best variant. Dots are variants; the bar spans best to worst. The new languages mostly have a single, optimised variant, so they sit as single dots in tiers 3 and 4: D and Zig right behind C and Fortran. The tall bars are where the story is: the same language spanning three to five decades depending on compiler flags, runtime or idiom. Figure from talk/make_language_ranges.py, reading run22.");
  }

  {
    const s = content("Backup: reproducibility, run22 vs run23", "Backup");
    const iw = CW, ih = iw * 1100 / 2400;
    s.addImage({ path: IMG("run22_vs_run23.png"), x: M, y: 1.3, w: iw, h: Math.min(ih, 4.9), sizing: { type: "contain", w: iw, h: 4.9 },
      objectName: "run22 vs run23", altText: "Comparison of relative times between run22 (April) and run23 (May, after a full toolchain rebuild)" });
    T(s, "After a full toolchain rebuild all 131 tests passed again. The fast tiers agree within noise; slow entries moved (Octave loop −44%, Rust unoptimised +30%, Ruby Numo +22–25%).",
      { x: M, y: 6.3, w: CW, h: 0.6, fontSize: 14, color: MUTED });
  }
  {
    // Keith's own Run.py summary (FullWriteUp, Nov 2019) against run22, test by test.
    const s = content("Backup: Keith's 2019 times against 2026, test by test", "Backup");
    const K = readSummary(path.join(HERE, "..", "report", "shortridge2019_summary.txt"));
    const R = readSummary(path.join(HERE, "..", "report", "run22.log"));
    const REF = "C : raw clang -O3 native", PDLRAW = "Perl/PDL : raw Perl/PDL";
    const common = Object.keys(K).filter((n) => n in R && n !== PDLRAW);
    const xs = common.map((n) => K[n] / K[REF]), ys = common.map((n) => R[n] / R[REF]);
    const px = K[PDLRAW] / K[REF], pyv = R[PDLRAW] / R[REF];
    const diag = Array.from({ length: 36 }, (_, i) => Math.pow(10, -1 + i * 8 / 35));
    const nA = xs.length, X = [...xs, px, ...diag];
    const pad = (arr, start) => X.map((_, i) => (i >= start && i < start + arr.length ? arr[i - start] : null));
    s.addChart(pres.charts.SCATTER, [
      { name: "x", values: X },
      { name: `Same code, 2019 and 2026 (${nA} tests)`, values: pad(ys, 0) },
      { name: "PDL element lookup: ->slice in 2019, ->at/->set in 2026", values: pad([pyv], nA) },
      { name: "Equal relative time", values: pad(diag, nA + 1) },
    ], {
      x: M, y: 1.25, w: 7.6, h: 5.6, lineSize: 0, lineDataSymbol: "circle", lineDataSymbolSize: 7,
      chartColors: [HEX.accent5, HEX.accent3, "B0B7C3"],
      valAxisLogScaleBase: 10, valAxisMinVal: 0.1, valAxisMaxVal: 10000000, catAxisMinVal: 0.1, catAxisMaxVal: 10000000,
      valAxisLabelFormatCode: "[<1]0.0;#,##0", valAxisCrossesAt: 0.1, catAxisCrossesAt: 0.1,
      valAxisTitleFontFace: "+mn-lt", catAxisTitleFontFace: "+mn-lt",
      catAxisLabelFontFace: "+mn-lt", valAxisLabelFontFace: "+mn-lt", catAxisLabelColor: MUTED, valAxisLabelColor: MUTED,
      catAxisLabelFontSize: 10, valAxisLabelFontSize: 10,
      showCatAxisTitle: true, catAxisTitle: "Shortridge 2019 (x86), relative to C element lookup, clang -O3 native",
      showValAxisTitle: true, valAxisTitle: "run22 (arm64), relative to C element lookup, clang -O3 native",
      catAxisTitleFontSize: 11, valAxisTitleFontSize: 11, catAxisTitleColor: MUTED, valAxisTitleColor: MUTED,
      valGridLine: { color: "E3E7EE", size: 0.5 }, catGridLine: { color: "E3E7EE", size: 0.5 },
      showLegend: true, legendPos: "b", legendFontSize: 11, legendFontFace: "+mn-lt", legendColor: HEX.dk1,
      objectName: "2019 vs 2026 scatter",
    });
    const below = common.filter((n, i) => ys[i] < xs[i]).length;
    const rx = M + 7.9, rw = CW - 7.9;
    s.addText([
      { text: `${below} of ${nA} tests sit below the line: relatively faster in 2026 than in 2019.`, options: { bullet: true, breakLine: true } },
      { text: "Both studies rescaled to the same test, C element lookup with clang -O3 native, because the 2019 reference was x86 AVX and the 2026 one is arm64 NEON.", options: { bullet: true, breakLine: true } },
      { text: "PDL element lookup (red) changed code, so it is not a like-for-like point.", options: { bullet: true, breakLine: true } },
      { text: "2019 values: Keith's own Run.py summary in his Nov 2019 write-up (report/shortridge2019_summary.txt).", options: { bullet: true } },
    ], { isTextBox: true, x: rx, y: 1.4, w: rw, h: 5.3, margin: 0, fontSize: 15, color: C.text1, paraSpaceAfter: 10, valign: "top" });
    s.addNotes("Each point is one test that exists in both studies, matched by its Run.py name. Caveats if asked: different hardware (x86 AVX in 2019, arm64 NEON now); the reference drifts about 10% between runs; Python 2.7 runs under Rosetta 2 here.");
  }
  // 11b. What the ChatGPT audits caught
  {
    const s = content("Backup: what the ChatGPT red team caught", "Backup");
    const catches = [
      ["Stale numbers", "About 25 numbers in the prose came from older runs after the reference moved: Crystal 3.21 → 3.67, numba 2.91 → 3.15. F# 6.85 → 7.21 even crossed into tier 4."],
      ["Mis-tiering", "D, Zig, Crystal, Nim, Rust and OCaml listed in tier 2: none are. “Tier 6 is the most populous”: it had 5 entries against tier 3's 38."],
      ["Wrong ratios", "“PyPy is 650× slower than CPython”: it is about 8×. The 650× was PyPy + numpy against PyPy lists. An OCaml “18×” was 13×."],
      ["Overclaims", "A “million-fold spread” in 2026 that is under half a million (4.8 × 10⁵)."],
      ["Wrong comparisons", "“J beats every array library”: PDL::PP was faster. “Octave has the biggest gap within one language”: PDL's was bigger."],
      ["Counting", "“Eleven new languages” that were sixteen. (Fifteen, counted strictly as Keith did: that one we only noticed this week.)"],
    ];
    const cw = (CW - 0.3) / 2, ch = 1.45;
    catches.forEach(([h, b], i) => {
      const x = M + (i % 2) * (cw + 0.3), y = 1.3 + Math.floor(i / 2) * (ch + 0.15);
      card(s, x, y, cw, ch, `catch ${h}`);
      s.addText([{ text: h, options: { bold: true, fontSize: 17, color: C.text2, breakLine: true } }, { text: b, options: { fontSize: 16 } }],
        { isTextBox: true, x: x + 0.25, y: y + 0.12, w: cw - 0.5, h: ch - 0.2, margin: 0, color: C.text1, valign: "top", paraSpaceAfter: 2 });
    });
    T(s, "About 7 rounds, 14 errors in the first four: claims that didn't match the log. Nobody reviewed the code.",
      { x: M, y: 6.2, w: CW, h: 0.6, fontSize: 17, bold: true, color: C.text2, fontFace: "+mj-lt", align: "center", valign: "middle" });
    s.addNotes("I pasted each draft of the report into ChatGPT (model not recorded) and asked it to attack it; Claude then fixed and re-checked every number against run22.log. Typical catches: numbers left over from older runs after the reference moved by ~10%, tier assignments that contradicted the tier table, ratios computed against the wrong baseline, and rhetorical overclaims. Some of these claims are from earlier runs and drafts; the numbers on this slide are what the audits flagged at the time. The pattern: the LLM is fluent and confident, and checking against the raw log is not optional. And the audits only checked claims against the log; nobody checked the kernels.");
  }

  codeWall("Backup: Keith's 12 languages from 2019", "Backup", SNIPPETS.wall2,
    "One kernel from each of Keith's 12 languages (C/C++ and Perl/PDL as one each), pulled verbatim from the 2019 sources and timed in run22. The PDL element-lookup card is the corrected ->at/->set form. R uses outer(), one whole-array expression.");
  {
    const s = content("Backup: every family at a glance", "Backup");
    const ih = 5.5, iw = ih * 1977 / 1962;
    s.addImage({ path: IMG("fig3_top30.png"), x: M, y: 1.3, w: iw, h: ih, objectName: "fig3 families",
      altText: "Per-family best variant with min-max range and geometric mean; families new in 2026 labelled in red" });
    T(s, "Bar = best variant; whisker = range across that family's variants; diamond = geometric mean. Red labels: languages new in 2026.",
      { x: M + iw + 0.4, y: 1.4, w: CW - iw - 0.4, h: 1.5, fontSize: 16, color: MUTED });
  }

  await pres.writeFile({ fileName: OUT });
  await fixScatter(OUT);
  await addClickReveal(OUT, ["group box 1", "group box 2", "group box 3"]);
  await shadeShapes(OUT, arrowShades);
  await applyTheme(OUT, THEME);
  console.log("wrote", OUT);
}

main().catch((e) => { console.error(e); process.exit(1); });
