#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const readline = require('readline');

// Constants
const COMPACTION_THRESHOLD = 200000 * 0.8

// Read JSON from stdin
let input = '';
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', async () => {
  try {
    const data = JSON.parse(input);

    // Extract values
    const model = data.model?.display_name || 'Unknown';
    const currentDir = path.basename(data.workspace?.current_dir || data.cwd || '.');
    const sessionId = data.session_id;

    // Calculate token usage for current session
    let totalTokens = 0;

    if (sessionId) {
      // Find all transcript files
      const projectsDir = path.join(process.env.HOME, '.claude', 'projects');

      if (fs.existsSync(projectsDir)) {
        // Get all project directories
        const projectDirs = fs.readdirSync(projectsDir)
          .map(dir => path.join(projectsDir, dir))
          .filter(dir => fs.statSync(dir).isDirectory());

        // Search for the current session's transcript file
        for (const projectDir of projectDirs) {
          const transcriptFile = path.join(projectDir, `${sessionId}.jsonl`);

          if (fs.existsSync(transcriptFile)) {
            totalTokens = await calculateTokensFromTranscript(transcriptFile);
            break;
          }
        }
      }
    }

    // Calculate percentage
    const percentage = Math.min(100, Math.round((totalTokens / COMPACTION_THRESHOLD) * 100));

    // Format token display
    const tokenDisplay = formatTokenCount(totalTokens);

    // Color coding for percentage
    let percentageColor = '\x1b[32m'; // Green
    if (percentage >= 70) percentageColor = '\x1b[33m'; // Yellow
    if (percentage >= 90) percentageColor = '\x1b[31m'; // Red

    // Pattern 5: Braille Dots for rate limits
    const RESET = '\x1b[0m';
    const DIM = '\x1b[2m';
    const BRAILLE = ' ⣀⣄⣤⣦⣶⣷⣿';

    function gradient(pct) {
      if (pct < 50) {
        const r = Math.round(pct * 5.1);
        return `\x1b[38;2;${r};200;80m`;
      } else {
        const g = Math.max(0, Math.round(200 - (pct - 50) * 4));
        return `\x1b[38;2;255;${g};60m`;
      }
    }

    function brailleBar(pct, width = 8) {
      pct = Math.min(Math.max(pct, 0), 100);
      const level = pct / 100;
      let bar = '';
      for (let i = 0; i < width; i++) {
        const segStart = i / width;
        const segEnd = (i + 1) / width;
        if (level >= segEnd) {
          bar += BRAILLE[7];
        } else if (level <= segStart) {
          bar += BRAILLE[0];
        } else {
          const frac = (level - segStart) / (segEnd - segStart);
          bar += BRAILLE[Math.min(Math.floor(frac * 7), 7)];
        }
      }
      return bar;
    }

    function fmt(label, pct) {
      const p = Math.round(pct);
      return `${DIM}${label}${RESET} ${gradient(pct)}${brailleBar(pct)}${RESET} ${p}%`;
    }

    const rateParts = [];
    const ctx = data.context_window?.used_percentage;
    if (ctx != null) rateParts.push(fmt('ctx', ctx));
    const five = data.rate_limits?.five_hour?.used_percentage;
    if (five != null) rateParts.push(fmt('5h', five));
    const week = data.rate_limits?.seven_day?.used_percentage;
    if (week != null) rateParts.push(fmt('7d', week));

    const rateStr = rateParts.length > 0 ? ` | ${rateParts.join(` ${DIM}│${RESET} `)}` : '';

    // Build status line
    const statusLine = `[${model}] 📁 ${currentDir} | 🪙 ${tokenDisplay} | ${percentageColor}${percentage}%\x1b[0m${rateStr}`;

    console.log(statusLine);
  } catch (error) {
    // Fallback status line on error
    console.log('[Error] 📁 . | 🪙 0 | 0%');
  }
});

async function calculateTokensFromTranscript(filePath) {
  return new Promise((resolve, reject) => {
    let lastUsage = null;

    const fileStream = fs.createReadStream(filePath);
    const rl = readline.createInterface({
      input: fileStream,
      crlfDelay: Infinity
    });

    rl.on('line', (line) => {
      try {
        const entry = JSON.parse(line);

        // Check if this is an assistant message with usage data
        if (entry.type === 'assistant' && entry.message?.usage) {
          lastUsage = entry.message.usage;
        }
      } catch (e) {
        // Skip invalid JSON lines
      }
    });

    rl.on('close', () => {
      if (lastUsage) {
        // The last usage entry contains cumulative tokens
        const totalTokens = (lastUsage.input_tokens || 0) +
          (lastUsage.output_tokens || 0) +
          (lastUsage.cache_creation_input_tokens || 0) +
          (lastUsage.cache_read_input_tokens || 0);
        resolve(totalTokens);
      } else {
        resolve(0);
      }
    });

    rl.on('error', (err) => {
      reject(err);
    });
  });
}

function formatTokenCount(tokens) {
  if (tokens >= 1000000) {
    return `${(tokens / 1000000).toFixed(1)}M`;
  } else if (tokens >= 1000) {
    return `${(tokens / 1000).toFixed(1)}K`;
  }
  return tokens.toString();
}
