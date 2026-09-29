-- Three databases, three roles. Runs once on an empty data directory.
CREATE ROLE openmetadata LOGIN PASSWORD 'openmetadata';
CREATE DATABASE openmetadata OWNER openmetadata;
CREATE ROLE ranger LOGIN PASSWORD 'ranger';
CREATE DATABASE ranger OWNER ranger;
CREATE ROLE keycloak LOGIN PASSWORD 'keycloak';
CREATE DATABASE keycloak OWNER keycloak;
