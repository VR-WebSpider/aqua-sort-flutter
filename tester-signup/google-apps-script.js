/**
 * Aqua Sort Beta Tester Sign-up — Google Apps Script Backend
 * 
 * HOW TO DEPLOY:
 * 1. Go to https://script.google.com
 * 2. Create a new project, paste this code
 * 3. Click "Deploy" > "New Deployment"
 * 4. Type: "Web App", Execute as: "Me", Who has access: "Anyone"
 * 5. Copy the Web App URL
 * 6. Paste the URL into index.html where it says YOUR_GOOGLE_APPS_SCRIPT_URL_HERE
 */

const SHEET_NAME = 'Beta Testers';
const SPREADSHEET_ID = ''; // Leave empty to auto-create, or paste your Google Sheet ID here

function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    const ss = SPREADSHEET_ID
      ? SpreadsheetApp.openById(SPREADSHEET_ID)
      : SpreadsheetApp.getActiveSpreadsheet();
    
    let sheet = ss.getSheetByName(SHEET_NAME);
    
    // Create sheet with headers if it doesn't exist
    if (!sheet) {
      sheet = ss.insertSheet(SHEET_NAME);
      sheet.appendRow([
        'Timestamp', 'Name', 'Email', 'WhatsApp', 'Device',
        'Play Frequency', 'Hours/Week', 'Source', 'Genres',
        'Excitement (1-5)', 'Favorite Feature', 'Motivation', 'Suggestions'
      ]);
      sheet.getRange(1, 1, 1, 13).setFontWeight('bold').setBackground('#00d4e8');
    }
    
    // Append the row
    sheet.appendRow([
      data.ts || new Date().toISOString(),
      data.name || '',
      data.email || '',
      data.phone || '',
      data.device || '',
      data.freq || '',
      data.hours || '',
      data.source || '',
      data.genres || '',
      data.excitement || '',
      data.feature || '',
      data.motivation || '',
      data.suggestions || ''
    ]);

    // Optional: Send welcome email
    if (data.email) {
      sendWelcomeEmail(data.email, data.name);
    }

    return ContentService
      .createTextOutput(JSON.stringify({ success: true }))
      .setMimeType(ContentService.MimeType.JSON);

  } catch (err) {
    return ContentService
      .createTextOutput(JSON.stringify({ success: false, error: err.message }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

function doGet(e) {
  return ContentService
    .createTextOutput(JSON.stringify({ status: 'Aqua Sort Beta Signup API is running 🎮' }))
    .setMimeType(ContentService.MimeType.JSON);
}

function sendWelcomeEmail(email, name) {
  const firstName = name ? name.split(' ')[0] : 'Tester';
  const subject = '🎉 You\'re in the Aqua Sort Beta Squad!';
  const body = `
Hi ${firstName}! 👋

Welcome to the Aqua Sort Beta Squad! 🎮💧

Your application has been received and you're on our tester list. Here's what happens next:

✅ We'll send your Google Play testing invite link within 24-48 hours
✅ You'll be added to our private Beta Testers WhatsApp group
✅ Your Beta Tester badge will be waiting in your profile

In the meantime, warm up your puzzle-solving brain — the tubes won't sort themselves! 😄

The game launches soon and you'll be among the FIRST to play it.

Thank you for your support!

With water-themed enthusiasm 💧,
The WebSpider Studios Team

P.S. Know a friend who'd love to test? Share this link: [YOUR_FORM_URL]
  `;

  try {
    MailApp.sendEmail({ to: email, subject: subject, body: body });
  } catch (e) {
    console.log('Email send failed:', e.message);
  }
}
