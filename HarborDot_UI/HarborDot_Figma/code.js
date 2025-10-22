
// HarborDot Theme Builder — Figma Plugin (JavaScript)
figma.showUI(__html__, { width: 420, height: 180 });

function hexToRGB(hex) {
  const clean = hex.replace('#','');
  const bigint = parseInt(clean, 16);
  const r = (bigint >> 16) & 255;
  const g = (bigint >> 8) & 255;
  const b = bigint & 255;
  return { r: r/255, g: g/255, b: b/255 };
}

const THEMES = [
  { name: "Harbor Calm", colors: { background:"#FAFAF8", text:"#1F2937", accentPrimary:"#FF6B6B", accentSecondary:"#2DD4BF", taskNeutral:"#E5E7EB", taskDone:"#FF6B6B" } },
  { name: "Ink & Dot", colors: { background:"#111827", text:"#F3F4F6", accentPrimary:"#22D3EE", accentSecondary:"#84CC16", taskNeutral:"#374151", taskDone:"#22D3EE" } },
  { name: "Dopamine Pop", colors: { background:"#F5F5F4", text:"#0F172A", accentPrimary:"#FF8A5B", accentSecondary:"#FBBF24", taskNeutral:"#CBD5E1", taskDone:"#FF8A5B" } }
];

const FRAME_W = 390;
const FRAME_H = 844;
const RADIUS = 16;

async function loadFonts() {
  try { await figma.loadFontAsync({ family: "Inter", style: "Regular" }); } catch (e) {}
  try { await figma.loadFontAsync({ family: "Inter", style: "Bold" }); } catch (e) {}
}

function createPaintStyle(themeName, name, hex) {
  const style = figma.createPaintStyle();
  style.name = `HarborDot/${themeName}/${name}`;
  style.paints = [{ type: 'SOLID', color: hexToRGB(hex) }];
  return style;
}

function addHeader(parent, title, textStyleId, textColorPaints) {
  const header = figma.createFrame();
  header.name = "HeaderBar";
  header.resize(FRAME_W - 32, 44);
  header.x = 16; header.y = 16;
  header.fills = [{type:'SOLID', color: hexToRGB("#000000"), opacity: 0 }];
  header.strokes = [];
  parent.appendChild(header);

  const t = figma.createText();
  t.characters = title;
  t.fontName = { family: "Inter", style: "Bold" };
  if (textStyleId) t.textStyleId = textStyleId;
  t.fills = textColorPaints;
  t.x = 0; t.y = 8;
  header.appendChild(t);
}

function addFAB(parent, accentPaints) {
  const fab = figma.createEllipse();
  fab.resize(56,56);
  fab.x = FRAME_W - 56 - 20;
  fab.y = FRAME_H - 56 - 20;
  fab.fills = accentPaints;
  parent.appendChild(fab);
  const plus = figma.createText();
  plus.characters = "+";
  plus.fontName = { family: "Inter", style: "Bold" };
  plus.fills = [{ type:'SOLID', color: {r:1, g:1, b:1} }];
  plus.x = fab.x + 19;
  plus.y = fab.y + 8;
  parent.appendChild(plus);
}

function makeScreen(name, x, backgroundPaints, group) {
  const f = figma.createFrame();
  f.name = name;
  f.resize(FRAME_W, FRAME_H);
  f.cornerRadius = RADIUS;
  f.x = x;
  f.y = 60;
  f.fills = backgroundPaints;
  f.strokes = [];
  f.effects = [{ type: 'DROP_SHADOW', color: {r:0, g:0, b:0, a:0.08}, offset: {x:0, y:2}, radius: 6, visible: true, blendMode: "NORMAL"}];
  group.appendChild(f);
  return f;
}

function taskCard(parent, y, state, textStyleId, textPaints, neutralPaints, progressPaints, donePaints) {
  const card = figma.createFrame();
  card.name = "TaskCard";
  card.resize(FRAME_W - 32, 68);
  card.x = 16; card.y = y;
  card.cornerRadius = RADIUS;
  card.fills = [{ type:'SOLID', color: hexToRGB("#FFFFFF") }];
  card.strokes = [{ type:'SOLID', color: { r:0, g:0, b:0 }, opacity: 0.06 }];
  card.effects = [{ type: 'DROP_SHADOW', color: {r:0, g:0, b:0, a:0.06}, offset: {x:0, y:1}, radius: 3, visible: true }];
  parent.appendChild(card);

  // Checkbox / dot
  const dot = figma.createEllipse();
  dot.resize(20,20);
  dot.x = 14; dot.y = 24;
  let dotPaint = neutralPaints;
  if (state === "progress") dotPaint = progressPaints;
  if (state === "complete") dotPaint = donePaints;
  if (state === "not") dotPaint = [{ type:'SOLID', color: {r:0, g:0, b:0}, opacity:0.3 }];
  dot.fills = dotPaint;
  card.appendChild(dot);

  // Title
  const text = figma.createText();
  text.characters = ({
    normal: "Write summary for science homework",
    progress: "Clean inbox to zero",
    complete: "20‑min workout",
    not: "Return library books"
  })[state];
  text.fontName = { family: "Inter", style: "Regular" };
  if (textStyleId) text.textStyleId = textStyleId;
  text.fills = textPaints;
  text.x = 44; text.y = 20;
  card.appendChild(text);

  // Tag chip
  const tag = figma.createFrame();
  tag.resize(68, 24);
  tag.cornerRadius = 12;
  tag.x = card.width - 68 - 14;
  tag.y = 22;
  tag.fills = progressPaints;
  card.appendChild(tag);

  const tagText = figma.createText();
  tagText.characters = "Focus";
  tagText.fontName = { family: "Inter", style: "Bold" };
  tagText.fills = [{ type:'SOLID', color: { r:1, g:1, b:1 } }];
  tagText.fontSize = 12;
  tagText.x = tag.x + 16;
  tagText.y = tag.y + 4;
  card.appendChild(tagText);

  if (state === "not") {
    const line = figma.createLine();
    line.strokes = [{type:'SOLID', color: {r:0, g:0, b:0}}];
    line.opacity = 0.4;
    line.x = 44; line.y = 34;
    line.resize(card.width - 44 - 80, 0);
    card.appendChild(line);
  }
}

function annotate(target, text, x, y, color) {
  const n = figma.createFrame();
  n.name = "Annotation";
  n.resize(220, 64);
  n.x = x; n.y = y;
  n.cornerRadius = 8;
  const bg = color === "purple" ? {r:0.6, g:0.4, b:0.9} : {r:1.0, g:0.6, b:0.0};
  n.fills = [{type:'SOLID', color: bg, opacity: 0.18}];
  n.strokes = [{type:'SOLID', color: bg, opacity: 0.8}];
  target.appendChild(n);
  const t = figma.createText();
  t.characters = text;
  t.fontName = { family: "Inter", style: "Regular" };
  t.fontSize = 12;
  t.fills = [{ type:'SOLID', color: {r:0, g:0, b:0} }];
  t.x = n.x + 8; t.y = n.y + 8;
  target.appendChild(t);
  return n;
}

figma.ui.onmessage = async (msg) => {
  if (msg.type !== 'build') return;

  await loadFonts();

  const page = figma.createPage();
  page.name = "HarborDot_Themes";
  figma.currentPage = page;

  let xOffset = 0;
  for (const theme of THEMES) {
    const group = figma.createFrame();
    group.name = theme.name;
    group.resize(FRAME_W*3 + 160, FRAME_H + 120);
    group.x = xOffset;
    group.y = 0;
    group.clipsContent = false;
    page.appendChild(group);

    group.fills = [{ type: 'SOLID', color: hexToRGB(theme.colors.background) }];

    // Color styles per theme
    const sBackground = createPaintStyle(theme.name, "Base/Background", theme.colors.background);
    const sText = createPaintStyle(theme.name, "Base/Text", theme.colors.text);
    const sAccentPrimary = createPaintStyle(theme.name, "Accent/Primary", theme.colors.accentPrimary);
    const sAccentSecondary = createPaintStyle(theme.name, "Accent/Secondary", theme.colors.accentSecondary);
    const sTaskNeutral = createPaintStyle(theme.name, "Task/Neutral", theme.colors.taskNeutral);
    const sTaskDone = createPaintStyle(theme.name, "Task/Done", theme.colors.taskDone);

    function screen(name, x) {
      const f = figma.createFrame();
      f.name = name;
      f.resize(FRAME_W, FRAME_H);
      f.cornerRadius = RADIUS;
      f.x = x;
      f.y = 60;
      f.fills = sBackground.paints;
      f.strokes = [];
      f.effects = [{ type: 'DROP_SHADOW', color: {r:0, g:0, b:0, a:0.08}, offset: {x:0, y:2}, radius: 6, visible: true, blendMode: "NORMAL"}];
      group.appendChild(f);
      return f;
    }

    const today = screen(`${theme.name} — Today`, 20);
    addHeader(today, "Today", null, sText.paints);
    taskCard(today, 84, "progress", null, sText.paints, sTaskNeutral.paints, sAccentSecondary.paints, sTaskDone.paints);
    taskCard(today, 160, "normal", null, sText.paints, sTaskNeutral.paints, sAccentSecondary.paints, sTaskDone.paints);
    taskCard(today, 236, "complete", null, sText.paints, sTaskNeutral.paints, sAccentSecondary.paints, sTaskDone.paints);
    taskCard(today, 312, "not", null, sText.paints, sTaskNeutral.paints, sAccentSecondary.paints, sTaskDone.paints);
    addFAB(today, sAccentPrimary.paints);

    const calendar = screen(`${theme.name} — Calendar`, 20 + FRAME_W + 60);
    addHeader(calendar, "October", null, sText.paints);
    // Dot grid 7x5
    let gridX = 24, gridY = 84;
    for (let i=0; i<35; i++) {
      const d = figma.createEllipse();
      d.resize(12,12);
      const paints = (i % 5 === 0) ? sAccentPrimary.paints : (i % 3 === 0) ? sAccentSecondary.paints : sTaskNeutral.paints;
      d.fills = paints;
      d.x = gridX; d.y = gridY;
      calendar.appendChild(d);
      gridX += 44;
      if ((i+1) % 7 === 0) { gridX = 24; gridY += 32; }
    }
    // Selected day sheet
    const sheet = figma.createFrame();
    sheet.resize(FRAME_W, 240);
    sheet.x = 0; sheet.y = FRAME_H - 240;
    sheet.cornerRadius = 16;
    sheet.fills = [{type:'SOLID', color: hexToRGB("#FFFFFF")}];
    sheet.effects = [{ type: 'DROP_SHADOW', color: {r:0, g:0, b:0, a:0.12}, offset: {x:0, y:-2}, radius: 10, visible: true }];
    calendar.appendChild(sheet);
    taskCard(sheet, 12, "normal", null, sText.paints, sTaskNeutral.paints, sAccentSecondary.paints, sTaskDone.paints);
    taskCard(sheet, 88, "progress", null, sText.paints, sTaskNeutral.paints, sAccentSecondary.paints, sTaskDone.paints);
    taskCard(sheet, 164, "complete", null, sText.paints, sTaskNeutral.paints, sAccentSecondary.paints, sTaskDone.paints);

    const notes = screen(`${theme.name} — Notes`, 20 + (FRAME_W + 60)*2);
    addHeader(notes, "Notes", null, sText.paints);
    const editor = figma.createFrame();
    editor.resize(FRAME_W - 32, FRAME_H - 120);
    editor.x = 16; editor.y = 72;
    editor.cornerRadius = 12;
    editor.fills = [{type:'SOLID', color: hexToRGB("#FFFFFF")}];
    notes.appendChild(editor);
    const md = figma.createText();
    md.characters = "# Study Sprint\n- Read ch. 4\n- Summarize in 5 bullets\n- Timer: 25m focus";
    md.fontName = { family: "Inter", style: "Regular" };
    md.fills = sText.paints;
    md.x = editor.x + 12; md.y = editor.y + 12;
    notes.appendChild(md);
    addFAB(notes, sAccentPrimary.paints);

    // Annotations
    annotate(today, "🟠 Tap task → cycles state", 24, 400, "orange");
    annotate(today, "🟣 Completion pop: 160ms spring", 200, 120, "purple");
    annotate(calendar, "🟣 Day reveal: slide-up 180ms easeOut", 24, 580, "purple");
    annotate(notes, "🟣 Markdown toggle: cross-fade 160ms + slide 8pt", 24, 540, "purple");

    xOffset += group.width + 120;
  }

  figma.notify("HarborDot themes generated ✔");
  figma.closePlugin();
};
