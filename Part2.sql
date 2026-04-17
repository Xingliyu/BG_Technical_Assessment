CREATE TABLE paper (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pmid       TEXT        NOT NULL UNIQUE,
    pmc        TEXT,
    doi        TEXT,
    title      TEXT,
    created_at TIMESTAMP   DEFAULT NOW()
);

CREATE TABLE gene (
    id             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hgnc_id        TEXT    NOT NULL UNIQUE, 
    hgnc_gene_name TEXT    NOT NULL,
    gene_symbol    TEXT    NOT NULL,
    hg38_coords    TEXT,               
    hg19_coords    TEXT,
    created_at     TIMESTAMP DEFAULT NOW()
);

CREATE TABLE gene_alias (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    gene_id    INTEGER NOT NULL REFERENCES gene(id) ON DELETE CASCADE,
    alias      TEXT    NOT NULL,
    alias_type TEXT    CHECK (alias_type IN ('prev_symbol', 'alias_symbol')),
    UNIQUE (gene_id, alias)
);

CREATE TABLE disease (
    id           INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    disease_name TEXT    NOT NULL,
    omim_id      TEXT,
    created_at   TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_disease_name_gin
    ON disease USING gin(to_tsvector('english', disease_name));

CREATE TABLE gene_disease (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    gene_id    INTEGER NOT NULL REFERENCES gene(id)    ON DELETE CASCADE,
    disease_id INTEGER NOT NULL REFERENCES disease(id) ON DELETE CASCADE,
    paper_id   INTEGER          REFERENCES paper(id),
    evidence   TEXT,            
    UNIQUE (gene_id, disease_id)
);


CREATE INDEX idx_gene_symbol  ON gene(gene_symbol);
CREATE INDEX idx_gene_hgnc_id ON gene(hgnc_id);
CREATE INDEX idx_alias_gene   ON gene_alias(gene_id);
CREATE INDEX idx_gd_gene      ON gene_disease(gene_id);
CREATE INDEX idx_gd_disease   ON gene_disease(disease_id);


INSERT INTO paper (pmid, pmc, doi, title) VALUES (
    '38790019',
    'PMC11127317',
    '10.1186/s13023-024-03213-x',
    'Diagnostic yield of exome and genome sequencing after non-diagnostic multi-gene panels in patients with single-system diseases'
);

INSERT INTO gene (hgnc_id, hgnc_gene_name, gene_symbol, hg38_coords, hg19_coords) VALUES
    ('HGNC:19903', 'Ras related GTP binding D',               'RRAGD',  'chr6:122745884-122766785 (+)',  'chr6:122747748-122768649 (+)'),
    ('HGNC:2204',  'collagen type IV alpha 3 chain',           'COL4A3', 'chr2:227985926-228170802 (-)',  'chr2:228155027-228341100 (-)'),
    ('HGNC:13394', 'nephrosis 2 idiopathic steroid resistant', 'NPHS2',  'chr1:179520246-179546562 (+)',  'chr1:179481263-179510055 (+)'),
    ('HGNC:11621', 'HNF1 homeobox A',                          'HNF1A',  'chr12:120977000-121003863 (-)', 'chr12:121416548-121443440 (-)'),
    ('HGNC:618',   'apolipoprotein L1',                         'APOL1',  'chr22:36253070-36267531 (+)',   'chr22:36649138-36663717 (+)');

INSERT INTO gene_alias (gene_id, alias, alias_type) VALUES
    (1, 'RagD',      'alias_symbol'),
    (1, 'LACZ2',     'alias_symbol'),
    (2, 'CA43',      'alias_symbol'),
    (2, 'TUMSTATIN', 'alias_symbol'),
    (3, 'SRN1',      'prev_symbol'),
    (3, 'PDCP',      'alias_symbol'),
    (4, 'TCF1',      'prev_symbol'),
    (4, 'MODY3',     'alias_symbol'),
    (4, 'LFB1',      'alias_symbol'),
    (5, 'APOL',      'prev_symbol'),
    (5, 'FSGS4',     'alias_symbol'),
    (5, 'NPHS8',     'alias_symbol');

-- Diseases as named in the paper
INSERT INTO disease (disease_name, omim_id) VALUES
    ('Hypomagnesemia, tubulopathy, and dilated cardiomyopathy', NULL),
    ('Alport syndrome, autosomal recessive',                    '203780'),
    ('Alport syndrome, autosomal dominant',                     '104200'),
    ('Autosomal recessive nephrotic syndrome type 2',           '600995'),
    ('Partial phenotype (specific disease not named in paper)', NULL),
    ('Kidney disease risk in individuals of African ancestry',  NULL);

INSERT INTO gene_disease (gene_id, disease_id, paper_id, evidence) VALUES
    (1, 1, 1, 'Case 3: gene newly associated with hypomagnesemia, tubulopathy, and dilated cardiomyopathy; electrolyte-losing tubulopathy due to mTOR signaling activation'),
    (2, 2, 1, 'Case 1: gene associated with recessive form of Alport syndrome (MIM 203780)'),
    (2, 3, 1, 'Case 1: gene associated with dominant form of Alport syndrome (MIM 104200)'),
    (3, 4, 1, 'Case 2: variant associated with autosomal recessive nephrotic syndrome type 2 (MIM 600995)'),
    (4, 5, 1, 'Case 4 / Table 3: likely pathogenic variant that might explain patient partial phenotype; no specific disease named'),
    (5, 6, 1, 'Results: G1/G2 polymorphic risk alleles evaluated due to association with kidney disease in African ancestry patients');


-- Query 1: HGNC ID and disease connection
SELECT
    g.hgnc_id,
    d.disease_name
FROM gene         g
JOIN gene_disease gd ON gd.gene_id   = g.id
JOIN disease      d  ON d.id         = gd.disease_id
ORDER BY g.hgnc_id, d.disease_name;


-- Query 2: HGNC Gene Name and all gene name aliases
SELECT
    g.hgnc_gene_name,
    STRING_AGG(ga.alias, '; ' ORDER BY ga.alias) AS gene_aliases
FROM gene            g
LEFT JOIN gene_alias ga ON ga.gene_id = g.id
GROUP BY g.id, g.hgnc_gene_name
ORDER BY g.hgnc_gene_name;

