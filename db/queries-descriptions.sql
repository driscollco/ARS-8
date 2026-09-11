-- ============================================================
-- Listing Description Queries
-- ============================================================

-- Query all descriptions for a property
SELECT 
    p.address,
    p.beds,
    p.full_baths,
    p.living_sqft,
    d.mls_description,
    d.retail_description,
    d.investor_description
FROM properties p
JOIN descriptions d ON p.property_id = d.property_id
WHERE p.address = '10037 Dorothy Ave';

-- Query MLS descriptions for all properties
SELECT 
    p.address,
    d.mls_description
FROM properties p
JOIN descriptions d ON p.property_id = d.property_id
ORDER BY p.address;

-- Query retail descriptions for all properties
SELECT 
    p.address,
    d.retail_description
FROM properties p
JOIN descriptions d ON p.property_id = d.property_id
ORDER BY p.address;

-- Query investor descriptions for all properties
SELECT 
    p.address,
    d.investor_description
FROM properties p
JOIN descriptions d ON p.property_id = d.property_id
ORDER BY p.address;

-- Get descriptions with property details (comprehensive view)
SELECT 
    p.property_id,
    p.address,
    p.beds,
    p.full_baths,
    p.living_sqft,
    p.year_built,
    d.mls_description,
    d.retail_description,
    d.investor_description
FROM properties p
JOIN descriptions d ON p.property_id = d.property_id
ORDER BY p.address;

-- Query a single description by tone for a specific property
SELECT d.mls_description FROM descriptions d 
WHERE d.property_id = (SELECT property_id FROM properties WHERE address = '839 Font Ln');

SELECT d.retail_description FROM descriptions d 
WHERE d.property_id = (SELECT property_id FROM properties WHERE address = '839 Font Ln');

SELECT d.investor_description FROM descriptions d 
WHERE d.property_id = (SELECT property_id FROM properties WHERE address = '839 Font Ln');
