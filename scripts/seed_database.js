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

async function deleteDoc(docPath) {
  try {
    const deleteUrl = `https://firestore.googleapis.com/v1/${docPath}`;
    await makeRequest(deleteUrl, 'DELETE');
  } catch (e) {}
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

async function clearCollection(colName) {
  try {
    const url = `${BASE_URL}/${colName}?pageSize=300`;
    const res = await makeRequest(url);
    const docs = res.documents || [];
    if (docs.length > 0) {
      await mapConcurrent(docs, 25, async (doc) => {
        const relativePath = doc.name.substring(doc.name.indexOf('projects/'));
        return await deleteDoc(relativePath);
      });
    }
  } catch (e) {}
}

// Authentic Ethiopian Habesha Workers
const habeshaWorkers = [
  {
    id: "pro_yohannes_tekle",
    name: "Yohannes Tekle",
    profession: "Electrician",
    skills: ["House Wiring", "Circuit Breakers", "Generator Repair", "Lighting Installation"],
    rating: 4.92,
    completedJobs: 48,
    location: "Bole, Addis Ababa",
    priceRange: 550.0,
    about: "Certified electrical technician in Addis Ababa with over 8 years of experience in residential and commercial wiring, panel upgrades, and emergency generator setups.",
    phoneNumber: "+251911234567",
    email: "yohannes.tekle@gmail.com",
    profileImage: "https://images.unsplash.com/photo-1531384441138-2736e62e0919?w=500&auto=format&fit=crop&q=80",
    userType: "professional",
    role: "worker",
    profileComplete: true,
    experience: 8,
    latitude: 8.9950,
    longitude: 38.7845,
    serviceRadius: 15.0,
    isAvailable: true,
    galleryImages: {
      "Electrical Projects": [
        "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500&auto=format&fit=crop&q=80",
        "https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=500&auto=format&fit=crop&q=80"
      ]
    },
    certificationImages: [
      "https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=500&auto=format&fit=crop&q=80"
    ],
    availabilityData: {
      "Monday": { "start": "08:00", "end": "18:00", "isActive": true },
      "Tuesday": { "start": "08:00", "end": "18:00", "isActive": true },
      "Wednesday": { "start": "08:00", "end": "18:00", "isActive": true },
      "Thursday": { "start": "08:00", "end": "18:00", "isActive": true },
      "Friday": { "start": "08:00", "end": "18:00", "isActive": true },
      "Saturday": { "start": "09:00", "end": "16:00", "isActive": true }
    }
  },
  {
    id: "pro_bethlehem_tadesse",
    name: "Bethlehem Tadesse",
    profession: "Solar & Electrical Engineer",
    skills: ["Solar Panel Setup", "Inverter Systems", "Battery Backup", "Energy Auditing"],
    rating: 4.95,
    completedJobs: 52,
    location: "Kazanchis, Addis Ababa",
    priceRange: 650.0,
    about: "Specialized green energy and solar system engineer. I design and install off-grid solar power systems and UPS backups for homes and offices.",
    phoneNumber: "+251912345678",
    email: "bethlehem.t@gmail.com",
    profileImage: "https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=500&auto=format&fit=crop&q=80",
    userType: "professional",
    role: "worker",
    profileComplete: true,
    experience: 6,
    latitude: 9.0180,
    longitude: 38.7660,
    serviceRadius: 20.0,
    isAvailable: true,
    galleryImages: {
      "Solar Installations": [
        "https://images.unsplash.com/photo-1509391365360-2e959784a276?w=500&auto=format&fit=crop&q=80"
      ]
    },
    certificationImages: [],
    availabilityData: {
      "Monday": { "start": "08:30", "end": "17:30", "isActive": true },
      "Tuesday": { "start": "08:30", "end": "17:30", "isActive": true },
      "Wednesday": { "start": "08:30", "end": "17:30", "isActive": true }
    }
  },
  {
    id: "pro_dawit_kebede",
    name: "Dawit Kebede",
    profession: "Plumber",
    skills: ["Pipe Fitting", "Water Tank Installation", "Leak Repair", "Drainage Systems"],
    rating: 4.84,
    completedJobs: 64,
    location: "Sarbet, Addis Ababa",
    priceRange: 450.0,
    about: "Master plumber with 10 years experience solving water pressure issues, installing rotomold water tanks, and fixing emergency pipe leaks.",
    phoneNumber: "+251913456789",
    email: "dawit.plumber@gmail.com",
    profileImage: "https://images.unsplash.com/photo-1506277886164-e25aa3f4ef7f?w=500&auto=format&fit=crop&q=80",
    userType: "professional",
    role: "worker",
    profileComplete: true,
    experience: 10,
    latitude: 8.9890,
    longitude: 38.7420,
    serviceRadius: 12.0,
    isAvailable: true,
    galleryImages: {},
    certificationImages: [],
    availabilityData: {}
  },
  {
    id: "pro_tigist_assefa",
    name: "Tigist Assefa",
    profession: "Painter",
    skills: ["Wall Painting", "Waterproofing", "Decorative Finishes", "Gypsum Works"],
    rating: 4.88,
    completedJobs: 39,
    location: "Megenagna, Addis Ababa",
    priceRange: 400.0,
    about: "Creative wall decorator and professional painter. High quality interior and exterior painting with moisture protection for homes.",
    phoneNumber: "+251914567890",
    email: "tigist.design@gmail.com",
    profileImage: "https://images.unsplash.com/photo-1567532939604-b6b5b0db2604?w=500&auto=format&fit=crop&q=80",
    userType: "professional",
    role: "worker",
    profileComplete: true,
    experience: 5,
    latitude: 9.0195,
    longitude: 38.8010,
    serviceRadius: 15.0,
    isAvailable: true,
    galleryImages: {},
    certificationImages: [],
    availabilityData: {}
  },
  {
    id: "pro_abebe_bikila",
    name: "Abebe Bikila",
    profession: "Carpenter",
    skills: ["Custom Furniture", "Kitchen Cabinets", "Door Fitting", "Hardwood Repair"],
    rating: 4.96,
    completedJobs: 87,
    location: "Piassa, Addis Ababa",
    priceRange: 700.0,
    about: "Veteran craftsman specializing in handcrafted Wanza wood furniture, kitchen cabinets, wardrobes, and custom doors in Addis Ababa.",
    phoneNumber: "+251915678901",
    email: "abebe.carpentry@gmail.com",
    profileImage: "https://images.unsplash.com/photo-1522529599102-193c0d76b5b6?w=500&auto=format&fit=crop&q=80",
    userType: "professional",
    role: "worker",
    profileComplete: true,
    experience: 12,
    latitude: 9.0340,
    longitude: 38.7520,
    serviceRadius: 18.0,
    isAvailable: true,
    galleryImages: {},
    certificationImages: [],
    availabilityData: {}
  },
  {
    id: "pro_meron_worku",
    name: "Meron Worku",
    profession: "Appliance Technician",
    skills: ["Washing Machines", "Refrigerators", "Microwaves", "Oven Repair"],
    rating: 4.79,
    completedJobs: 31,
    location: "CMC, Addis Ababa",
    priceRange: 450.0,
    about: "Expert home appliance repair technician. Fast diagnosis and genuine spare parts for Samsung, LG, and Bosch appliances.",
    phoneNumber: "+251916789012",
    email: "meron.tech@gmail.com",
    profileImage: "https://images.unsplash.com/photo-1589156280159-27698a70f29e?w=500&auto=format&fit=crop&q=80",
    userType: "professional",
    role: "worker",
    profileComplete: true,
    experience: 4,
    latitude: 9.0250,
    longitude: 38.8250,
    serviceRadius: 10.0,
    isAvailable: true,
    galleryImages: {},
    certificationImages: [],
    availabilityData: {}
  },
  {
    id: "pro_solomon_haile",
    name: "Solomon Haile",
    profession: "Mechanic",
    skills: ["Engine Overhaul", "Brake Repair", "Auto Electrical", "AC Service"],
    rating: 4.89,
    completedJobs: 95,
    location: "Mexico, Addis Ababa",
    priceRange: 600.0,
    about: "Experienced auto mechanic providing mobile breakdown repair and full mechanical servicing for Toyota, Nissan, and Hyundai vehicles.",
    phoneNumber: "+251917890123",
    email: "solomon.auto@gmail.com",
    profileImage: "https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=500&auto=format&fit=crop&q=80",
    userType: "professional",
    role: "worker",
    profileComplete: true,
    experience: 14,
    latitude: 9.0110,
    longitude: 38.7460,
    serviceRadius: 25.0,
    isAvailable: true,
    galleryImages: {},
    certificationImages: [],
    availabilityData: {}
  },
  {
    id: "pro_helen_berhane",
    name: "Helen Berhane",
    profession: "Cleaner",
    skills: ["Deep House Cleaning", "Carpet Washing", "Sofa Cleaning", "Move-in Cleaning"],
    rating: 4.97,
    completedJobs: 110,
    location: "Old Airport, Addis Ababa",
    priceRange: 350.0,
    about: "Professional cleaning service provider. Trusted by expatriates and families for thorough, hygienic home cleaning and sofa care.",
    phoneNumber: "+251918901234",
    email: "helen.clean@gmail.com",
    profileImage: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=500&auto=format&fit=crop&q=80",
    userType: "professional",
    role: "worker",
    profileComplete: true,
    experience: 6,
    latitude: 8.9820,
    longitude: 38.7350,
    serviceRadius: 15.0,
    isAvailable: true,
    galleryImages: {},
    certificationImages: [],
    availabilityData: {}
  },
  {
    id: "pro_yonas_girma",
    name: "Yonas Girma",
    profession: "Technician",
    skills: ["Laptop Repair", "Wi-Fi Networks", "CCTV Camera Setup", "Data Recovery"],
    rating: 4.91,
    completedJobs: 43,
    location: "Bole Atlas, Addis Ababa",
    priceRange: 550.0,
    about: "IT hardware & network specialist. I repair laptops, set up mesh Wi-Fi for homes/offices, and install HD security camera systems.",
    phoneNumber: "+251919012345",
    email: "yonas.it@gmail.com",
    profileImage: "https://images.unsplash.com/photo-1542190891-2093d38760f2?w=500&auto=format&fit=crop&q=80",
    userType: "professional",
    role: "worker",
    profileComplete: true,
    experience: 7,
    latitude: 8.9980,
    longitude: 38.7790,
    serviceRadius: 15.0,
    isAvailable: true,
    galleryImages: {},
    certificationImages: [],
    availabilityData: {}
  },
  {
    id: "pro_frehiwot_tesfaye",
    name: "Frehiwot Tesfaye",
    profession: "Tailor",
    skills: ["Habesha Kemis", "Suit Tailoring", "Dress Alterations", "Curtains"],
    rating: 4.98,
    completedJobs: 135,
    location: "Shiro Meda, Addis Ababa",
    priceRange: 500.0,
    about: "Traditional Ethiopian Habesha Kemis designer & master tailor. Exquisite hand embroidery and custom fit wedding attire.",
    phoneNumber: "+251920123456",
    email: "frehiwot.fashion@gmail.com",
    profileImage: "https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=500&auto=format&fit=crop&q=80",
    userType: "professional",
    role: "worker",
    profileComplete: true,
    experience: 15,
    latitude: 9.0600,
    longitude: 38.7620,
    serviceRadius: 20.0,
    isAvailable: true,
    galleryImages: {},
    certificationImages: [],
    availabilityData: {}
  },
  {
    id: "pro_samuel_alemu",
    name: "Samuel Alemu",
    profession: "Mason",
    skills: ["Tile Laying", "Cobblestone Paving", "Brickwork", "Concrete Plastering"],
    rating: 4.77,
    completedJobs: 58,
    location: "Gotera, Addis Ababa",
    priceRange: 500.0,
    about: "Experienced mason and stone Paver. Specializing in Italian tiles, granite floor installation, compound paving, and wall plastering.",
    phoneNumber: "+251921234567",
    email: "samuel.mason@gmail.com",
    profileImage: "https://images.unsplash.com/photo-1507152832244-10d45c7eda57?w=500&auto=format&fit=crop&q=80",
    userType: "professional",
    role: "worker",
    profileComplete: true,
    experience: 9,
    latitude: 8.9770,
    longitude: 38.7600,
    serviceRadius: 15.0,
    isAvailable: true,
    galleryImages: {},
    certificationImages: [],
    availabilityData: {}
  },
  {
    id: "pro_rahel_zewde",
    name: "Rahel Zewde",
    profession: "Chef & Caterer",
    skills: ["Doro Wat & Injera", "Private Catering", "Buffet Setup", "Baking"],
    rating: 4.99,
    completedJobs: 78,
    location: "Gerji, Addis Ababa",
    priceRange: 800.0,
    about: "Renowned culinary chef for traditional Ethiopian feasts and international dining. Specializing in holiday Doro Wat, Beyaynetu, and event catering.",
    phoneNumber: "+251922345678",
    email: "rahel.chef@gmail.com",
    profileImage: "https://images.unsplash.com/photo-1607746882042-944635dde10e?w=500&auto=format&fit=crop&q=80",
    userType: "professional",
    role: "worker",
    profileComplete: true,
    experience: 8,
    latitude: 8.9880,
    longitude: 38.8050,
    serviceRadius: 20.0,
    isAvailable: true,
    galleryImages: {},
    certificationImages: [],
    availabilityData: {}
  },
  {
    id: "pro_fitsum_gebre",
    name: "Fitsum Gebre",
    profession: "Welder",
    skills: ["Compound Gates", "Window Grills", "Metal Staircases", "Structural Welding"],
    rating: 4.83,
    completedJobs: 62,
    location: "Kera, Addis Ababa",
    priceRange: 600.0,
    about: "Heavy metal fabricator and welder. I design custom steel compound gates, security window grills, and iron handrails.",
    phoneNumber: "+251923456789",
    email: "fitsum.metal@gmail.com",
    profileImage: "https://images.unsplash.com/photo-1530268729831-4b0b9e170218?w=500&auto=format&fit=crop&q=80",
    userType: "professional",
    role: "worker",
    profileComplete: true,
    experience: 11,
    latitude: 8.9800,
    longitude: 38.7480,
    serviceRadius: 15.0,
    isAvailable: true,
    galleryImages: {},
    certificationImages: [],
    availabilityData: {}
  },
  {
    id: "pro_kassahun_desta",
    name: "Kassahun Desta",
    profession: "HVAC Technician",
    skills: ["AC Installation", "Cold Room Repair", "Ventilation", "Ductwork"],
    rating: 4.86,
    completedJobs: 40,
    location: "Bisrate Gabriel, Addis Ababa",
    priceRange: 650.0,
    about: "HVAC climate control & refrigeration technician for supermarkets, restaurants, and residential homes in Addis Ababa.",
    phoneNumber: "+251924567890",
    email: "kassahun.hvac@gmail.com",
    profileImage: "https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=500&auto=format&fit=crop&q=80",
    userType: "professional",
    role: "worker",
    profileComplete: true,
    experience: 7,
    latitude: 8.9850,
    longitude: 38.7380,
    serviceRadius: 18.0,
    isAvailable: true,
    galleryImages: {},
    certificationImages: [],
    availabilityData: {}
  },
  {
    id: "pro_hanna_tilahun",
    name: "Hanna Tilahun",
    profession: "Gardener",
    skills: ["Landscape Design", "Lawn Mowing", "Tree Pruning", "Drip Irrigation"],
    rating: 4.93,
    completedJobs: 29,
    location: "Ayat, Addis Ababa",
    priceRange: 400.0,
    about: "Passionate landscape designer and gardener. Transform garden spaces with fresh turf, flowers, indigenous trees, and automatic drip irrigation.",
    phoneNumber: "+251925678901",
    email: "hanna.garden@gmail.com",
    profileImage: "https://images.unsplash.com/photo-1534751516642-a171e3914978?w=500&auto=format&fit=crop&q=80",
    userType: "professional",
    role: "worker",
    profileComplete: true,
    experience: 5,
    latitude: 9.0120,
    longitude: 38.8600,
    serviceRadius: 12.0,
    isAvailable: true,
    galleryImages: {},
    certificationImages: [],
    availabilityData: {}
  }
];

// Authentic Habesha Clients/Users
const habeshaUsers = [
  {
    uid: "user_alazar_molla",
    id: "user_alazar_molla",
    name: "Alazar Molla",
    email: "alazar.molla@gmail.com",
    phoneNumber: "+251911554433",
    role: "client",
    profileImage: "https://images.unsplash.com/photo-1531384441138-2736e62e0919?w=500&auto=format&fit=crop&q=80",
    location: "Bole, Addis Ababa",
    favoriteWorkers: [],
    postedJobs: ["job_water_pump_1", "job_cctv_1"],
    appliedJobs: [],
    profileComplete: true,
    jobsPosted: 2,
    paymentsComplete: 2
  },
  {
    uid: "user_hiwot_mengistu",
    id: "user_hiwot_mengistu",
    name: "Hiwot Mengistu",
    email: "hiwot.m@gmail.com",
    phoneNumber: "+251912665544",
    role: "client",
    profileImage: "https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=500&auto=format&fit=crop&q=80",
    location: "Kazanchis, Addis Ababa",
    favoriteWorkers: [],
    postedJobs: ["job_solar_1"],
    appliedJobs: [],
    profileComplete: true,
    jobsPosted: 1,
    paymentsComplete: 1
  },
  {
    uid: "user_abel_mulugeta",
    id: "user_abel_mulugeta",
    name: "Abel Mulugeta",
    email: "abel.mulugeta@gmail.com",
    phoneNumber: "+251913776655",
    role: "client",
    profileImage: "https://images.unsplash.com/photo-1506277886164-e25aa3f4ef7f?w=500&auto=format&fit=crop&q=80",
    location: "Sarbet, Addis Ababa",
    favoriteWorkers: [],
    postedJobs: ["job_kitchen_cabinet_1"],
    appliedJobs: [],
    profileComplete: true,
    jobsPosted: 1,
    paymentsComplete: 1
  },
  {
    uid: "user_selam_bekele",
    id: "user_selam_bekele",
    name: "Selam Bekele",
    email: "selam.b@gmail.com",
    phoneNumber: "+251914887766",
    role: "client",
    profileImage: "https://images.unsplash.com/photo-1567532939604-b6b5b0db2604?w=500&auto=format&fit=crop&q=80",
    location: "Megenagna, Addis Ababa",
    favoriteWorkers: [],
    postedJobs: ["job_house_paint_1"],
    appliedJobs: [],
    profileComplete: true,
    jobsPosted: 1,
    paymentsComplete: 1
  }
];

// Jobs posted in Addis Ababa
const habeshaJobs = [
  {
    id: "job_water_pump_1",
    title: "Urgent Water Tank Pump Repair",
    description: "Our rooftop water pump stopped pumping water to the second floor. Need an experienced plumber in Sarbet to inspect and replace the motor capacitor or repair the line.",
    category: "Plumber",
    profession: "Plumber",
    location: "Sarbet, Addis Ababa",
    budget: 1800.0,
    price: 1800.0,
    status: "open",
    clientId: "user_abel_mulugeta",
    clientName: "Abel Mulugeta",
    clientImage: "https://images.unsplash.com/photo-1506277886164-e25aa3f4ef7f?w=500&auto=format&fit=crop&q=80",
    clientPhone: "+251913776655",
    latitude: 8.9890,
    longitude: 38.7420,
    applications: [],
    urgency: "High",
    createdAt: new Date().toISOString()
  },
  {
    id: "job_house_paint_1",
    title: "3-Room Apartment Interior Painting",
    description: "Looking for a professional painter for a 3-bedroom flat near Megenagna round-about. Needs primer and two coats of washable white paint.",
    category: "Painter",
    profession: "Painter",
    location: "Megenagna, Addis Ababa",
    budget: 4500.0,
    price: 4500.0,
    status: "open",
    clientId: "user_selam_bekele",
    clientName: "Selam Bekele",
    clientImage: "https://images.unsplash.com/photo-1567532939604-b6b5b0db2604?w=500&auto=format&fit=crop&q=80",
    clientPhone: "+251914887766",
    latitude: 9.0195,
    longitude: 38.8010,
    applications: [],
    urgency: "Medium",
    createdAt: new Date().toISOString()
  },
  {
    id: "job_kitchen_cabinet_1",
    title: "Custom Kitchen Cabinet Installation",
    description: "Looking for a skilled carpenter to design and install L-shaped kitchen cabinets in CMC apartment. Modern wood finish with soft-close hinges.",
    category: "Carpenter",
    profession: "Carpenter",
    location: "CMC, Addis Ababa",
    budget: 12000.0,
    price: 12000.0,
    status: "open",
    clientId: "user_alazar_molla",
    clientName: "Alazar Molla",
    clientImage: "https://images.unsplash.com/photo-1531384441138-2736e62e0919?w=500&auto=format&fit=crop&q=80",
    clientPhone: "+251911554433",
    latitude: 9.0250,
    longitude: 38.8250,
    applications: [],
    urgency: "Medium",
    createdAt: new Date().toISOString()
  },
  {
    id: "job_solar_1",
    title: "5kW Solar Inverter & Battery System Installation",
    description: "Need a certified solar technician in Kazanchis to install a hybrid 5kW inverter, 4 lithium batteries, and roof mounting brackets for power outage backup.",
    category: "Solar & Electrical Engineer",
    profession: "Solar & Electrical Engineer",
    location: "Kazanchis, Addis Ababa",
    budget: 8500.0,
    price: 8500.0,
    status: "open",
    clientId: "user_hiwot_mengistu",
    clientName: "Hiwot Mengistu",
    clientImage: "https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=500&auto=format&fit=crop&q=80",
    clientPhone: "+251912665544",
    latitude: 9.0180,
    longitude: 38.7660,
    applications: [],
    urgency: "High",
    createdAt: new Date().toISOString()
  },
  {
    id: "job_cctv_1",
    title: "8-Camera HD CCTV System Installation",
    description: "Installing 8 outdoor IP cameras around commercial compound near Bole Atlas. Includes DVR setup, mobile app connection, and hidden cabling.",
    category: "Technician",
    profession: "Technician",
    location: "Bole Atlas, Addis Ababa",
    budget: 6500.0,
    price: 6500.0,
    status: "open",
    clientId: "user_alazar_molla",
    clientName: "Alazar Molla",
    clientImage: "https://images.unsplash.com/photo-1531384441138-2736e62e0919?w=500&auto=format&fit=crop&q=80",
    clientPhone: "+251911554433",
    latitude: 8.9980,
    longitude: 38.7790,
    applications: [],
    urgency: "Medium",
    createdAt: new Date().toISOString()
  }
];

async function seedDatabase() {
  console.log("==========================================");
  console.log("🇪🇹 SEEDING HABESHA PROFILES & DATA 🇪🇹");
  console.log("==========================================");

  // Quick cleanup pass
  console.log("🧹 Quick cleanup pass...");
  await clearCollection('professionals');
  await clearCollection('users');
  await clearCollection('jobs');

  // Seed Professionals
  console.log(`\n👨‍🔧 Seeding ${habeshaWorkers.length} Habesha Professionals...`);
  for (const worker of habeshaWorkers) {
    const doc = createFirestoreDoc(worker);
    await makeRequest(`${BASE_URL}/professionals?documentId=${worker.id}`, 'POST', doc);
    console.log(`  ✓ Added Professional: ${worker.name} (${worker.profession})`);
  }

  // Seed Users/Clients
  console.log(`\n👤 Seeding ${habeshaUsers.length} Habesha Clients...`);
  for (const user of habeshaUsers) {
    const doc = createFirestoreDoc(user);
    await makeRequest(`${BASE_URL}/users?documentId=${user.id}`, 'POST', doc);
    console.log(`  ✓ Added Client User: ${user.name}`);
  }

  // Seed Jobs
  console.log(`\n📋 Seeding ${habeshaJobs.length} Jobs in Addis Ababa...`);
  for (const job of habeshaJobs) {
    const doc = createFirestoreDoc(job);
    await makeRequest(`${BASE_URL}/jobs?documentId=${job.id}`, 'POST', doc);
    console.log(`  ✓ Added Job: ${job.title} (${job.location})`);
  }

  console.log("\n==========================================");
  console.log("🎉 HABESHA DATA SEEDING COMPLETE! 🎉");
  console.log("==========================================");
}

seedDatabase().catch(err => {
  console.error("Fatal error during seeding:", err);
});
