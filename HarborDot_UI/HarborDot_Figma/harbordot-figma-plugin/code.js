// HarborDot Figma Color Scheme Plugin
// Main plugin code (JavaScript version - no compilation needed)

// Show the plugin UI
figma.showUI(__html__, { width: 400, height: 700 });

// Current color palette from your app
const currentColors = {
  red: { r: 1, g: 0, b: 0 },
  orange: { r: 1, g: 0.6, b: 0 },
  yellow: { r: 1, g: 1, b: 0 },
  green: { r: 0, g: 1, b: 0 },
  blue: { r: 0, g: 0.5, b: 1 },
  purple: { r: 0.5, g: 0, b: 0.5 },
  pink: { r: 1, g: 0.75, b: 0.8 },
  gray: { r: 0.5, g: 0.5, b: 0.5 }
};

// Handle messages from the UI
figma.ui.onmessage = msg => {
  if (msg.type === 'apply-colors') {
    applyColorsToSelection(msg.colors);
  } else if (msg.type === 'create-palette') {
    createColorPalette(msg.colors);
  } else if (msg.type === 'generate-task-cards') {
    generateTaskCards(msg.colors);
  } else if (msg.type === 'export-swift') {
    exportToSwift(msg.colors);
  } else if (msg.type === 'analyze-selection') {
    analyzeSelection();
  } else if (msg.type === 'close') {
    figma.closePlugin();
  }
};

function applyColorsToSelection(colors) {
  const selection = figma.currentPage.selection;
  
  if (selection.length === 0) {
    figma.notify('Please select at least one element');
    return;
  }

  let count = 0;
  const colorKeys = Object.keys(colors);

  selection.forEach((node, index) => {
    if ('fills' in node) {
      const colorKey = colorKeys[index % colorKeys.length];
      const color = colors[colorKey];
      
      node.fills = [{
        type: 'SOLID',
        color: { r: color.r, g: color.g, b: color.b }
      }];
      count++;
    }
  });

  figma.notify(`✅ Applied colors to ${count} elements`);
}

function createColorPalette(colors) {
  const frame = figma.createFrame();
  frame.name = 'HarborDot Color Palette';
  frame.resize(800, 200);
  frame.x = figma.viewport.center.x - 400;
  frame.y = figma.viewport.center.y - 100;
  frame.fills = [{
    type: 'SOLID',
    color: { r: 0.98, g: 0.98, b: 0.98 }
  }];
  
  const colorKeys = Object.keys(colors);
  const swatchSize = 80;
  const gap = 15;
  const startX = 20;

  let loadedFonts = 0;
  
  colorKeys.forEach((key, index) => {
    const color = colors[key];
    const rect = figma.createRectangle();
    rect.name = key.charAt(0).toUpperCase() + key.slice(1);
    rect.resize(swatchSize, swatchSize);
    rect.x = startX + index * (swatchSize + gap);
    rect.y = 50;
    rect.fills = [{
      type: 'SOLID',
      color: { r: color.r, g: color.g, b: color.b }
    }];
    rect.cornerRadius = 12;
    rect.effects = [{
      type: 'DROP_SHADOW',
      color: { r: 0, g: 0, b: 0, a: 0.15 },
      offset: { x: 0, y: 2 },
      radius: 6,
      visible: true,
      blendMode: 'NORMAL'
    }];
    
    frame.appendChild(rect);
    
    // Add label
    figma.loadFontAsync({ family: "Inter", style: "Medium" }).then(() => {
      const label = figma.createText();
      label.characters = key.charAt(0).toUpperCase() + key.slice(1);
      label.fontSize = 14;
      label.fontName = { family: "Inter", style: "Medium" };
      label.x = rect.x + (swatchSize - label.width) / 2;
      label.y = rect.y + swatchSize + 12;
      label.fills = [{
        type: 'SOLID',
        color: { r: 0.2, g: 0.2, b: 0.2 }
      }];
      frame.appendChild(label);
      
      loadedFonts++;
      if (loadedFonts === colorKeys.length) {
        figma.currentPage.selection = [frame];
        figma.viewport.scrollAndZoomIntoView([frame]);
      }
    }).catch(() => {
      // Fallback if Inter font not available
      loadedFonts++;
      if (loadedFonts === colorKeys.length) {
        figma.currentPage.selection = [frame];
        figma.viewport.scrollAndZoomIntoView([frame]);
      }
    });
  });

  figma.notify('🎨 Created color palette!');
}

function generateTaskCards(colors) {
  const frame = figma.createFrame();
  frame.name = 'HarborDot Task Cards Preview';
  frame.resize(400, 800);
  frame.x = figma.viewport.center.x - 200;
  frame.y = figma.viewport.center.y - 400;
  frame.fills = [{
    type: 'SOLID',
    color: { r: 0.95, g: 0.95, b: 0.97 }
  }];
  frame.cornerRadius = 16;

  const colorKeys = Object.keys(colors);
  const cardHeight = 70;
  const gap = 12;
  const padding = 20;

  let loadedFonts = 0;

  colorKeys.forEach((key, index) => {
    const color = colors[key];
    
    // Create card background
    const card = figma.createRectangle();
    card.name = `Task Card - ${key}`;
    card.resize(360, cardHeight);
    card.x = padding;
    card.y = padding + index * (cardHeight + gap);
    card.fills = [{
      type: 'SOLID',
      color: { r: 1, g: 1, b: 1 }
    }];
    card.cornerRadius = 12;
    card.effects = [{
      type: 'DROP_SHADOW',
      color: { r: 0, g: 0, b: 0, a: 0.08 },
      offset: { x: 0, y: 2 },
      radius: 8,
      visible: true,
      blendMode: 'NORMAL'
    }];
    
    // Create color dot
    const dot = figma.createEllipse();
    dot.resize(20, 20);
    dot.x = card.x + 20;
    dot.y = card.y + 25;
    dot.fills = [{
      type: 'SOLID',
      color: { r: color.r, g: color.g, b: color.b }
    }];
    
    frame.appendChild(card);
    frame.appendChild(dot);
    
    // Add task text
    figma.loadFontAsync({ family: "Inter", style: "Medium" }).then(() => {
      const text = figma.createText();
      text.characters = `Sample ${key.charAt(0).toUpperCase() + key.slice(1)} Task`;
      text.fontSize = 16;
      text.fontName = { family: "Inter", style: "Medium" };
      text.x = dot.x + 30;
      text.y = card.y + 23;
      text.fills = [{
        type: 'SOLID',
        color: { r: 0.2, g: 0.2, b: 0.2 }
      }];
      frame.appendChild(text);
      
      // Add subtitle
      const subtitle = figma.createText();
      subtitle.characters = 'Tap to view details';
      subtitle.fontSize = 12;
      subtitle.fontName = { family: "Inter", style: "Regular" };
      subtitle.x = text.x;
      subtitle.y = text.y + 22;
      subtitle.fills = [{
        type: 'SOLID',
        color: { r: 0.5, g: 0.5, b: 0.5 }
      }];
      frame.appendChild(subtitle);
      
      loadedFonts++;
      if (loadedFonts === colorKeys.length) {
        figma.currentPage.selection = [frame];
        figma.viewport.scrollAndZoomIntoView([frame]);
      }
    }).catch(() => {
      loadedFonts++;
      if (loadedFonts === colorKeys.length) {
        figma.currentPage.selection = [frame];
        figma.viewport.scrollAndZoomIntoView([frame]);
      }
    });
  });

  figma.notify('🎴 Created task card previews!');
}

function exportToSwift(colors) {
  let swiftCode = `// HarborDot Color Palette
// Generated from Figma Plugin
// ${new Date().toLocaleDateString()}

import SwiftUI

extension Color {
    // Task color palette (generated colors)
`;

  Object.keys(colors).forEach(key => {
    const color = colors[key];
    const r = color.r.toFixed(3);
    const g = color.g.toFixed(3);
    const b = color.b.toFixed(3);
    
    swiftCode += `    static let task${key.charAt(0).toUpperCase() + key.slice(1)} = Color(red: ${r}, green: ${g}, blue: ${b})\n`;
  });

  swiftCode += `    
    // Array of available task colors
    static let taskColors: [(name: String, color: Color)] = [
`;

  Object.keys(colors).forEach((key, index) => {
    const comma = index < Object.keys(colors).length - 1 ? ',' : '';
    swiftCode += `        ("${key}", task${key.charAt(0).toUpperCase() + key.slice(1)})${comma}\n`;
  });

  swiftCode += `    ]
    
    // Convert string to Color
    static func fromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
`;

  Object.keys(colors).forEach(key => {
    swiftCode += `        case "${key}": return task${key.charAt(0).toUpperCase() + key.slice(1)}\n`;
  });

  swiftCode += `        default: return taskBlue
        }
    }
}`;

  figma.ui.postMessage({
    type: 'swift-code',
    code: swiftCode
  });

  figma.notify('💾 Swift code generated! Check the plugin UI.');
}

function analyzeSelection() {
  const selection = figma.currentPage.selection;
  
  if (selection.length === 0) {
    figma.notify('⚠️ Please select elements to analyze');
    return;
  }

  const colors = [];
  
  selection.forEach(node => {
    if ('fills' in node && Array.isArray(node.fills)) {
      node.fills.forEach(fill => {
        if (fill.type === 'SOLID' && 'color' in fill) {
          colors.push({
            r: fill.color.r,
            g: fill.color.g,
            b: fill.color.b,
            name: node.name
          });
        }
      });
    }
  });

  figma.ui.postMessage({
    type: 'analyzed-colors',
    colors: colors
  });

  figma.notify(`🔍 Analyzed ${colors.length} colors from ${selection.length} elements`);
}