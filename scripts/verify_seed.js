const https = require('https');

const PROJECT_ID = 'fixit-2a354';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

function makeRequest(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => resolve(JSON.parse(body)));
    }).on('error', reject);
  });
}

async function verify() {
  const collections = ['professionals', 'users', 'jobs'];
  for (const col of collections) {
    const res = await makeRequest(`${BASE_URL}/${col}`);
    console.log(`Collection '${col}': ${(res.documents || []).length} document(s) present.`);
  }
}

verify().catch(console.error);
