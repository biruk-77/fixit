const https = require('https');

const PROJECT_ID = 'fixit-2a354';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

const agent = new https.Agent({ keepAlive: true, maxSockets: 100 });

function makeRequest(url, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const options = {
      hostname: u.hostname,
      path: u.pathname + u.search,
      method: method,
      agent: agent,
      headers: {
        'Content-Type': 'application/json',
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            resolve(body ? JSON.parse(body) : {});
          } catch (e) {
            resolve(body);
          }
        } else {
          reject({ statusCode: res.statusCode, body });
        }
      });
    });

    req.on('error', reject);
    if (data) req.write(JSON.stringify(data));
    req.end();
  });
}

async function mapConcurrent(items, limit, fn) {
  const results = [];
  const executing = [];
  for (const item of items) {
    const p = Promise.resolve().then(() => fn(item));
    results.push(p);
    if (limit <= items.length) {
      const e = p.then(() => executing.splice(executing.indexOf(e), 1));
      executing.push(e);
      if (executing.length >= limit) {
        await Promise.race(executing);
      }
    }
  }
  return Promise.all(results);
}

async function deleteDoc(docPath) {
  try {
    const deleteUrl = `https://firestore.googleapis.com/v1/${docPath}`;
    await makeRequest(deleteUrl, 'DELETE');
    return 1;
  } catch (e) {
    return 0;
  }
}

async function clearCollection(colName) {
  console.log(`🧹 Clearing '${colName}'...`);
  let totalDeleted = 0;
  
  while (true) {
    try {
      const url = `${BASE_URL}/${colName}?pageSize=300`;
      const res = await makeRequest(url);
      const docs = res.documents || [];
      if (docs.length === 0) break;

      console.log(`  Found ${docs.length} document(s) in '${colName}'. Purging...`);
      
      const counts = await mapConcurrent(docs, 30, async (doc) => {
        const relativePath = doc.name.substring(doc.name.indexOf('projects/'));
        return await deleteDoc(relativePath);
      });

      const batchDeleted = counts.reduce((a, b) => a + b, 0);
      totalDeleted += batchDeleted;

      if (batchDeleted === 0) break;
    } catch (err) {
      if (err.statusCode === 404) {
        console.log(`  Collection '${colName}' empty/does not exist.`);
      } else {
        console.error(`  Error on '${colName}':`, err.statusCode || err.message);
      }
      break;
    }
  }

  console.log(`✅ Collection '${colName}' purged (${totalDeleted} document(s) removed).`);
}

async function clearDatabase() {
  console.log("==========================================");
  console.log("🔥 FIRESTORE ULTRA-FAST DATABASE PURGE 🔥");
  console.log("==========================================");
  
  const allCollections = [
    'professionals',
    'jobs',
    'users',
    'presence',
    'transactions',
    'chat_rooms',
    'chats',
    'notifications',
    'reviews',
    'ratings',
    'workers',
    'categories',
    'messages'
  ];

  // Run multiple rounds to handle nested structures / subcollections
  for (let round = 1; round <= 2; round++) {
    console.log(`\n--- PURGE ROUND ${round} ---`);
    for (const col of allCollections) {
      await clearCollection(col);
    }
  }

  console.log("\n==========================================");
  console.log("🎉 DATABASE IS NOW 100% EMPTY & CLEAN! 🎉");
  console.log("==========================================");
}

clearDatabase().catch(err => {
  console.error("Fatal error during database purge:", err);
});
