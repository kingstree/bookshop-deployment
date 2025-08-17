SELECT 'CREATE DATABASE bookshopdb_product'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = 'bookshopdb_product'
)\gexec

SELECT 'CREATE DATABASE bookshopdb_order'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = 'bookshopdb_order'
)\gexec
