import { WebSocketServer, WebSocket } from 'ws';
import { Stagehand } from '@browserbasehq/stagehand';
import { z } from 'zod';
import dotenv from 'dotenv';
import fs from 'fs';

dotenv.config();

// Configuration
const PORT = process.env.PORT ? parseInt(process.env.PORT) : 3000;

// Initialize WebSocket Server
const wss = new WebSocketServer({ port: PORT });
console.log(`GovAgent Backend running on port ${PORT}`);

// Global Stagehand instance (for this hackathon demo, we use one shared browser)
let stagehand: Stagehand | null = null;
let page: any = null;

async function initBrowser() {
  if (stagehand) return;
  
  console.log('Initializing Stagehand...');
  stagehand = new Stagehand({
    env: "LOCAL", // Change to "BROWSERBASE" if deploying to cloud
    apiKey: process.env.OPENAI_API_KEY,
    modelName: "gpt-4o",
  });
  
  await stagehand.init();
  page = stagehand.page;
  console.log('Stagehand ready.');
}

// Helper to send messages back to Flutter
function sendMessage(ws: WebSocket, type: string, data: any) {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify({ type, ...data }));
  }
}

wss.on('connection', async (ws) => {
  console.log('New client connected');
  await initBrowser();

  // Start screenshot streaming loop
  const screenshotInterval = setInterval(async () => {
    if (page) {
      try {
        const screenshotBuffer = await page.screenshot({ type: 'jpeg', quality: 50 });
        const base64Image = screenshotBuffer.toString('base64');
        sendMessage(ws, 'screenshot', { data: base64Image });
      } catch (e) {
        console.error('Error taking screenshot:', e);
      }
    }
  }, 500); // 2 FPS

  ws.on('message', async (message) => {
    try {
      const parsed = JSON.parse(message.toString());
      
      if (parsed.type === 'tool_call') {
        const { id, name, args } = parsed;
        console.log(`Executing tool: ${name}`, args);

        let resultData: any = {};
        
        try {
          // --- TOOL IMPLEMENTATION ---
          switch (name) {
            case 'open_page':
              await page.goto(args.url);
              resultData = { success: true, url: args.url };
              break;

            case 'fill_field':
              // Using Stagehand's 'act' to intelligently fill fields based on description
              await page.act(`Fill the field "${args.selector}" with value "${args.value}"`);
              resultData = { success: true };
              break;

            case 'click_element':
              // Using Stagehand's 'act' to intelligently click
              await page.act(`Click on the element described as "${args.selector}"`);
              resultData = { success: true };
              break;

            case 'submit_form':
              await page.act(`Submit the form described as "${args.selector}"`);
              resultData = { success: true };
              break;

            case 'read_page':
              // Using Stagehand's 'extract' to get data
              const instruction = args.selector 
                ? `Extract the text content from the section "${args.selector}"`
                : "Summarize the main content of this page";
              
              const extraction = await page.extract({
                instruction: instruction,
                schema: z.object({ content: z.string() })
              });
              resultData = { content: extraction.content };
              break;

            default:
              console.warn(`Unknown tool: ${name}`);
              resultData = { error: 'Unknown tool' };
          }
        } catch (toolError: any) {
          console.error(`Tool execution failed: ${toolError.message}`);
          resultData = { error: toolError.message };
        }

        // Send result back to Flutter
        sendMessage(ws, 'tool_result', {
          id: id,
          name: name,
          result: resultData
        });
      }
    } catch (e) {
      console.error('Error parsing message:', e);
    }
  });

  ws.on('close', () => {
    console.log('Client disconnected');
    clearInterval(screenshotInterval);
    // Optional: Close browser on disconnect
    // await stagehand?.close(); 
  });
});