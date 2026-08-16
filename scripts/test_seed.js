const https = require('https');

const PROJECT_ID = 'fixit-2a354';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

function toFirestoreValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    if (Number.isInteger(val)) return { integerValue: val.toString() };
    return { doubleValue: val };
  }
  if (typeof val === 'string') return { stringValue: val };
  if (Array.isArray(val)) {
    return {
      arrayValue: {
        values: val.map(toFirestoreValue)
      }
    };
  }
  if (typeof val === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(val)) {
      fields[k] = toFirestoreValue(v);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

function createFirestoreDoc(data) {
  const fields = {};
  for (const [k, v] of Object.entries(data)) {
    fields[k] = toFirestoreValue(v);
  }
  return { fields };
}

function makeRequest(url, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const options = {
      hostname: u.hostname,
      path: u.pathname + u.search,
      method: method,
      headers: { 'Content-Type': 'application/json' }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try { resolve(body ? JSON.parse(body) : {}); } catch (e) { resolve(body); }
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

async function testSeed() {
  const testWorker = {
    id: "test_worker_1",
    name: "Yohannes Tekle",
    profession: "Electrician",
    skills: ["Wiring", "Breakers"],
    rating: 4.9,
    completedJobs: 45,
    location: "Bole, Addis Ababa",
    priceRange: 500.0,
    about: "Professional electrician in Addis Ababa.",
    phoneNumber: "+251911223344",
    profileImage: "https://images.unsplash.com/photo-1522529599102-193c0d76b5b6?w=500&auto=format&fit=crop&q=80",
    profileComplete: true,
    userType: "professional",
    role: "worker",
    experience: 7
  };

  const doc = createFirestoreDoc(testWorker);
  console.log("Sending test document to Firestore...");
  const res = await makeRequest(`${BASE_URL}/professionals?documentId=test_worker_1`, 'POST', doc);
  console.log("Response:", res.name ? "CREATED SUCCESS!" : res);
}

testSeed().catch(console.error);
