// HarborDot Figma Color Scheme Plugin
// This plugin allows you to experiment with color schemes for the HarborDot app

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
  }
};

function applyColorsToSelection(colors: any) {
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

  figma.notify(`Applied colors to ${count} elements`);
}

function createColorPalette(colors: any) {
  const frame = figma.createFrame();
  frame.name = 'HarborDot Color Palette';
  frame.resize(800, 200);
  frame.x = figma.viewport.center.x - 400;
  frame.y = figma.viewport.center.y - 100;
  
  const colorKeys = Object.keys(colors);
  const swatchSize = 100;
  const gap = 10;

  colorKeys.forEach((key, index) => {
    const color = colors[key];
    const rect = figma.createRectangle();
    rect.name = key.charAt(0).toUpperCase() + key.slice(1);
    rect.resize(swatchSize, swatchSize);
    rect.x = index * (swatchSize + gap);
    rect.y = 50;
    rect.fills = [{
      type: 'SOLID',
      color: { r: color.r, g: color.g, b: color.b }
    }];
    rect.cornerRadius = 8;
    
    // Add label
    const label = figma.createText();
    label.characters = key.charAt(0).toUpperCase() + key.slice(1);
    label.fontSize = 12;
    label.x = rect.x;
    label.y = rect.y + swatchSize + 10;
    
    frame.appendChild(rect);
    
    // Load font before adding text
    figma.loadFontAsync({ family: "Inter", style: "Regular" }).then(() => {
      frame.appendChild(label);
    });
  });

  figma.currentPage.selection = [frame];
  figma.viewport.scrollAndZoomIntoView([frame]);
  figma.notify('Created color palette!');
}

function generateTaskCards(colors: any) {
  const frame = figma.createFrame();
  frame.name = 'HarborDot Task Cards Preview';
  frame.resize(400, 800);
  frame.x = figma.viewport.center.x - 200;
  frame.y = figma.viewport.center.y - 400;
  frame.fills = [{
    type: 'SOLID',
    color: { r: 0.98, g: 0.98, b: 0.98 }
  }];

  const colorKeys = Object.keys(colors);
  const cardHeight = 60;
  const gap = 10;
  const padding = 20;

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
      color: { r: 0, g: 0, b: 0, a: 0.1 },
      offset: { x: 0, y: 2 },
      radius: 4,
      visible: true,
      blendMode: 'NORMAL'
    }];
    
    // Create color dot
    const dot = figma.createEllipse();
    dot.resize(16, 16);
    dot.x = card.x + 15;
    dot.y = card.y + 22;
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
      text.x = dot.x + 26;
      text.y = card.y + 18;
      text.fills = [{
        type: 'SOLID',
        color: { r: 0.2, g: 0.2, b: 0.2 }
      }];
      frame.appendChild(text);
    });
  });

  figma.currentPage.selection = [frame];
  figma.viewport.scrollAndZoomIntoView([frame]);
  figma.notify('Created task card previews!');
}

function exportToSwift(colors: any) {
  let swiftCode = `// HarborDot Color Palette
// Generated from Figma plugin

import SwiftUI

extension Color {
    // Task color palette
`;

  Object.keys(colors).forEach(key => {
    const color = colors[key];
    const r = Math.round(color.r * 255);
    const g = Math.round(color.g * 255);
    const b = Math.round(color.b * 255);
    
    swiftCode += `    static let task${key.charAt(0).toUpperCase() + key.slice(1)} = Color(red: ${color.r.toFixed(3)}, green: ${color.g.toFixed(3)}, blue: ${color.b.toFixed(3)})\n`;
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
}`;

  figma.ui.postMessage({
    type: 'swift-code',
    code: swiftCode
  });
}

function analyzeSelection() {
  const selection = figma.currentPage.selection;
  
  if (selection.length === 0) {
    figma.notify('Please select elements to analyze');
    return;
  }

  const colors: any[] = [];
  
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
}