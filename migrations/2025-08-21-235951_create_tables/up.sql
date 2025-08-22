CREATE TABLE IF NOT EXISTS manufacturers_info
(
    id                   SERIAL PRIMARY KEY,
    manufacturer_address TEXT NOT NULL,
    manufacturer_name    TEXT NOT NULL,
    timestamp            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tnx_hash             TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS contracts_created
(
    id               SERIAL PRIMARY KEY,
    contract_address VARCHAR NOT NULL,
    owner            VARCHAR NOT NULL,
    timestamp        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);