-- ============================================================================
-- Recurso: DDL Sistema ecommerce
-- Descripción: Este script SQL crea el esquema 'ecommerce' y las tablas necesarias
--              para gestionar clientes, ítems, categorías y órdenes de compra.
--              También establece las relaciones de clave foránea y crea índices
--              para mejorar el rendimiento en consultas específicas.
-- ============================================================================


-- (A) Generar una funcion de borrado si existen las tablas y el schema, con este proceso 
--     se garantiza empezar limpio.
DROP TABLE IF EXISTS ecommerce.customer CASCADE;
DROP TABLE IF EXISTS ecommerce.item CASCADE;
DROP TABLE IF EXISTS ecommerce.category CASCADE;
DROP TABLE IF EXISTS ecommerce.orders CASCADE;

DROP SCHEMA IF EXISTS ecommerce CASCADE;

-- (B) Creacion del schema y de las tablas pertenecientes
CREATE SCHEMA ecommerce;

-- (B.1) Almacena usuarios(clientes)
CREATE TABLE ecommerce.customer (
  customer_id SERIAL PRIMARY KEY,
  name varchar(255) NOT NULL,
  last_name varchar(255) NOT NULL,
  email varchar(255) NOT NULL,
  phone varchar(100) NOT NULL,
  address varchar(255) NOT NULL,
  gender varchar(10),
  birth_date timestamp NOT NULL,
  created_at timestamp DEFAULT (now())
);

-- (B.2) Almacena productos(items)
CREATE TABLE ecommerce.item (
  item_id SERIAL PRIMARY KEY,
  customer_id integer NOT NULL,
  category_id varchar(255) NOT NULL,
  price numeric(15,4) NOT NULL,
  status varchar(255) NOT NULL,
  published_date timestamp NOT NULL,
  created_at timestamp DEFAULT (now())
);

-- (B.3) Almacena la descripcion de la categoria y su path
CREATE TABLE ecommerce.category (
  category_id varchar(255) PRIMARY KEY,
  category_name varchar(255) NOT NULL,
  parent_id varchar(255),
  path varchar(255) NOT NULL
);

-- (B.4) Almacena ordenes de compra(ventas)
CREATE TABLE ecommerce.orders (
  order_id SERIAL PRIMARY KEY,
  item_id integer NOT NULL,
  customer_id integer NOT NULL,
  total_items integer NOT NULL,
  order_date timestamp NOT NULL
);

-- (C) Se establecen las relaciones de clave foranea para asegurar la integridad referencial
ALTER TABLE ecommerce.item ADD FOREIGN KEY (customer_id) REFERENCES ecommerce.customer (customer_id);
ALTER TABLE ecommerce.item ADD FOREIGN KEY (category_id) REFERENCES ecommerce.category (category_id);
ALTER TABLE ecommerce.category ADD FOREIGN KEY (parent_id) REFERENCES ecommerce.category (category_id);
ALTER TABLE ecommerce.orders ADD FOREIGN KEY (item_id) REFERENCES ecommerce.item (item_id);
ALTER TABLE ecommerce.orders ADD FOREIGN KEY (customer_id) REFERENCES ecommerce.customer (customer_id);

-- (D) Creacion de indices para mejorar el rendimiento de consultas frecuentes
--     Nota: A partir de pruebas de rendimiento con la consulta "SECCION A RESOLVER: EJERCICIO 2" de respuestas_negocio.sql
--     fueron seleccionados los indices.

-- (D.1) Como el volumen de items puede ser muy grande, este indice optimiza las consultas basadas en item_id en la tabla orders
CREATE INDEX idx_orders_item_id ON ecommerce.orders (item_id);
-- (D.2) Como el volumen de items puede ser muy grande, este indice optimiza las consultas que buscan items teniendo como referencie el category_id
CREATE INDEX idx_item_category_id ON ecommerce.item (category_id);
