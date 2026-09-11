// ============================================================
// Listing description generator (shared by local server + serverless).
// Builds copy from DB fields; no external API.
// ============================================================

const commaList = (arr) => {
  if (arr.length === 0) return '';
  if (arr.length === 1) return arr[0];
  return arr.slice(0, -1).join(', ') + ' and ' + arr[arr.length - 1];
};

// Real-estate convention: half baths shown as .5 (1 full + 1 half = 1.5)
function bathLabel(full, half) {
  if (half) return `${full + 0.5 * half}`;
  return `${full}`;
}

function featurePhrases(features) {
  const phrases = [];
  for (const f of features) {
    const t = f.feature_type.toLowerCase();
    if (t === 'main dwelling') continue;
    if (t.includes('garage')) {
      const cars = f.size_sqft >= 400 ? 'two-car' : 'one-car';
      const material = t.includes('masonry') || t.includes('brick') ? 'brick' : 'frame';
      phrases.push(`a detached ${cars} ${material} garage`);
    } else if (t.includes('porch')) {
      phrases.push(t.includes('enclos') ? 'an enclosed porch' : 'a covered front porch');
    } else if (t.includes('patio')) {
      phrases.push('a private patio');
    } else if (t.includes('basement')) {
      phrases.push('basement storage');
    }
  }
  return [...new Set(phrases)];
}

function generateDescription(p, tone = 'mls') {
  const beds = p.beds;
  const baths = bathLabel(p.full_baths, p.half_baths);
  const sqft = p.living_sqft ? p.living_sqft.toLocaleString('en-US') : null;
  const lot = p.lot_sqft ? p.lot_sqft.toLocaleString('en-US') : null;
  const year = p.core.year_built;
  const area = p.core.mls_area ? p.core.mls_area.replace(/^\d+\s*-\s*/, '') : 'Riverview Gardens';
  const feats = featurePhrases(p.features);
  const featText = feats.length ? ` The property includes ${commaList(feats)}.` : '';
  const rent = p.market_value_2025 ? Math.round((p.market_value_2025 * 0.009) / 25) * 25 : null;

  if (tone === 'investor') {
    const avm = p.realavm ? `$${p.realavm.toLocaleString('en-US')}` : 'market value';
    return `Investor opportunity in ${area}. This ${beds}-bed / ${baths}-bath single-family home` +
      `${sqft ? ` offers ${sqft} sq ft` : ''}${year ? `, built in ${year}` : ''}, on a ${lot ? `${lot} sq ft ` : ''}lot.` +
      `${featText} Current CoreLogic estimated value is ${avm}` +
      `${rent ? `, with an estimated market rent around $${rent.toLocaleString('en-US')}/mo` : ''}. ` +
      `Available individually or as part of an 8-property St. Louis portfolio — ideal for buy-and-hold cash flow or a turnkey rental package.`;
  }

  if (tone === 'retail') {
    return `Welcome home to this charming ${beds}-bedroom, ${baths}-bath home in ${area}!` +
      `${sqft ? ` With ${sqft} square feet of living space` : ''}${year ? `, this ${year}-built residence` : ' this home'} ` +
      `blends classic character with everyday comfort.${featText}` +
      `${lot ? ` Set on a generous ${lot} sq ft lot, there's` : ' There is'} plenty of room to relax and entertain. ` +
      `Conveniently located near shopping, schools, and major routes. Schedule your showing today!`;
  }

  return `${beds} bed, ${baths} bath single-family home in ${area}` +
    `${sqft ? `, ${sqft} sq ft` : ''}${year ? `, built ${year}` : ''}` +
    `${lot ? `, on a ${lot} sq ft lot` : ''}.${featText} ` +
    `Being sold individually or as part of an 8-home investment portfolio. ` +
    `Buyer to verify all information. Sold as-is.`;
}

module.exports = { generateDescription, bathLabel };
