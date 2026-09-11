#!/usr/bin/env node

/**
 * Generate listing descriptions for each property
 * Run with: node generate-descriptions.js
 */

const path = require('path');

const dbPath = path.join(__dirname, 'db', 'ars.db');

const properties = [
  {
    address: '10037 Dorothy Ave',
    beds: 2,
    baths: 1,
    sqft: 720,
    yearBuilt: 1940,
    neighborhood: 'Riverview Gardens',
  },
  {
    address: '10062 Dorothy Ave',
    beds: 2,
    baths: 1,
    sqft: 720,
    yearBuilt: 1942,
    neighborhood: 'Riverview Gardens',
  },
  {
    address: '10326 Ashbrook Dr',
    beds: 2,
    baths: 1,
    sqft: 792,
    yearBuilt: 1953,
    neighborhood: 'Riverview Gardens',
  },
  {
    address: '1229 Kilgore Dr',
    beds: 2,
    baths: 1,
    sqft: 792,
    yearBuilt: 1952,
    neighborhood: 'Riverview Gardens',
  },
  {
    address: '651 Gleason Dr',
    beds: 2,
    baths: 1,
    sqft: 851,
    yearBuilt: 1956,
    neighborhood: 'Riverview Gardens',
  },
  {
    address: '839 Font Ln',
    beds: 3,
    baths: 1,
    sqft: 1276,
    yearBuilt: 1965,
    neighborhood: 'Riverview Gardens',
  },
  {
    address: '9266 Waldorf Dr',
    beds: 2,
    baths: 2,
    sqft: 957,
    yearBuilt: 1950,
    neighborhood: 'Riverview Gardens',
  },
  {
    address: '9464 Adler Ave',
    beds: 3,
    baths: 1,
    sqft: 1046,
    yearBuilt: 1954,
    neighborhood: 'Riverview Gardens',
  },
];

/**
 * Generate descriptions in different tones
 */
function generateDescriptions(prop) {
  const age = new Date().getFullYear() - prop.yearBuilt;

  // MLS tone - professional, neutral, highlighting selling points
  const mls = `Charming ${prop.beds} bedroom, ${prop.baths} bathroom home in ${prop.neighborhood}. Built in ${prop.yearBuilt}, this ${prop.sqft}-square-foot residence offers solid bones and great potential. Nestled in a quiet, established neighborhood, this property is ready for new ownership. Perfect for owner-occupants or investors seeking value and opportunity.`;

  // Retail/Consumer tone - warm, inviting, emotional appeal
  const retail = `Welcome home! This delightful ${prop.beds}-bed, ${prop.baths}-bath ${prop.neighborhood} gem offers ${prop.sqft} sq ft of comfortable living space. Built in ${prop.yearBuilt}, this classic home features the character and charm of mid-century residential architecture. Situated in a peaceful, tight-knit community, this is your canvas to create lasting memories. Ideal for buyers looking to establish roots in an affordable, friendly neighborhood.`;

  // Investor tone - focus on metrics, ROI, fundamentals
  const investor = `${prop.beds}BR/${prop.baths}BA SFR in ${prop.neighborhood}. ${prop.sqft} sf. Built ${prop.yearBuilt}. Stable rental market area with established tenant demand. Well-positioned for rental income or renovation/resale play. Strong fundamentals: solid construction, manageable footprint, proven resilience in local market. Excellent value-add opportunity for disciplined investors. Held or repositioned.`;

  return { mls, retail, investor };
}

/**
 * Save descriptions to JSON file
 */
function saveDescriptions() {
  const descriptions = {};

  properties.forEach((prop) => {
    const desc = generateDescriptions(prop);
    descriptions[prop.address] = desc;
  });

  const fs = require('fs');
  fs.writeFileSync(
    path.join(__dirname, 'listing-descriptions.json'),
    JSON.stringify(descriptions, null, 2)
  );

  console.log('✓ Listing descriptions saved to listing-descriptions.json');
  console.log('\nGenerated descriptions for:');
  Object.keys(descriptions).forEach((addr) => {
    console.log(`  • ${addr}`);
  });

  // Also print to console for quick reference
  console.log('\n' + '='.repeat(70));
  Object.entries(descriptions).forEach(([addr, descs]) => {
    console.log(`\n${addr}`);
    console.log('-'.repeat(70));
    console.log(`MLS:\n  ${descs.mls}\n`);
    console.log(`RETAIL:\n  ${descs.retail}\n`);
    console.log(`INVESTOR:\n  ${descs.investor}\n`);
  });
}

saveDescriptions();
