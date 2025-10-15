CREATE DATABASE IF NOT EXISTS tienda_online;
USE tienda_online;

CREATE TABLE categorias (
  id_categoria INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  descripcion TEXT
);


CREATE TABLE proveedores (
  id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL,
  email_contacto VARCHAR(150) UNIQUE,
  telefono_contacto VARCHAR(50)
);


CREATE TABLE productos (
  id_producto INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL UNIQUE,
  descripcion TEXT,
  precio DECIMAL(10,2) NOT NULL CHECK (precio > 0),
  costo DECIMAL(10,2) NOT NULL CHECK (costo >= 0),
  stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
  sku VARCHAR(100) NOT NULL UNIQUE,
  fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
  activo BOOLEAN DEFAULT TRUE,
  id_categoria INT,
  id_proveedor INT,
  FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria),
  FOREIGN KEY (id_proveedor) REFERENCES proveedores(id_proveedor)
);

CREATE TABLE clientes (
  id_cliente INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  apellido VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  contrasena VARCHAR(255) NOT NULL,
  direccion_envio TEXT,
  fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE metodos_pago (
  id_metodo INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE ventas (
  id_venta INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente INT NOT NULL,
  fecha_venta DATETIME DEFAULT CURRENT_TIMESTAMP,
  estado ENUM('Pendiente de Pago', 'Procesando', 'Enviado', 'Entregado', 'Cancelado') NOT NULL,
  total DECIMAL(10,2),
  id_metodo INT,
  FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
  FOREIGN KEY (id_metodo) REFERENCES metodos_pago(id_metodo)
);

CREATE TABLE detalle_ventas (
  id_detalle INT AUTO_INCREMENT PRIMARY KEY,
  id_venta INT NOT NULL,
  id_producto INT NOT NULL,
  cantidad INT NOT NULL CHECK (cantidad > 0),
  precio_unitario_congelado DECIMAL(10,2) NOT NULL CHECK (precio_unitario_congelado > 0),
  FOREIGN KEY (id_venta) REFERENCES ventas(id_venta),
  FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);



INSERT INTO categorias (nombre, descripcion) VALUES
('Electrónica', 'Dispositivos electrónicos y gadgets'),
('Ropa', 'Prendas de vestir para todas las edades'),
('Hogar', 'Artículos para el hogar y cocina'),
('Deportes', 'Equipamiento deportivo'),
('Libros', 'Libros físicos y electrónicos');

INSERT INTO proveedores (nombre, email_contacto, telefono_contacto) VALUES
('TechPro S.A.', 'contacto@techpro.com', '555-1234'),
('ModaEstilo Ltda.', 'ventas@modaestilo.com', '555-5678'),
('CasaBonita S.A.', 'hogar@casabonita.com', '555-8765'),
('SportWorld', 'info@sportworld.com', '555-4321'),
('Lectura Plus', 'editorial@lecturaplus.com', '555-6789');

INSERT INTO productos (nombre, descripcion, precio, costo, stock, sku, activo, id_categoria, id_proveedor) VALUES
('Smartphone X1', 'Smartphone de gama media con 128GB', 299.99, 200.00, 50, 'ELEC001', TRUE, 1, 1),
('Camiseta Básica', 'Camiseta de algodón unisex', 19.99, 7.50, 150, 'ROP001', TRUE, 2, 2),
('Licuadora Turbo', 'Licuadora de alta potencia 800W', 89.99, 55.00, 30, 'HOG001', TRUE, 3, 3),
('Balón de Fútbol', 'Balón profesional tamaño 5', 39.99, 20.00, 60, 'DEP001', TRUE, 4, 4),
('Libro "El Código"', 'Novela de misterio contemporánea', 24.90, 10.00, 80, 'LIB001', TRUE, 5, 5),
('Tablet Z10', 'Tablet 10 pulgadas con Android', 199.00, 140.00, 20, 'ELEC002', TRUE, 1, 1),
('Pantalón Jeans', 'Jeans azul clásico corte recto', 49.90, 20.00, 40, 'ROP002', TRUE, 2, 2);

INSERT INTO clientes (nombre, apellido, email, contrasena, direccion_envio) values
('Juan', 'Pérez', 'juan.perez@email.com', 'hash1', 'Av. Siempre Viva 123'),
('María', 'López', 'maria.lopez@email.com', 'hash2', 'Calle 45 #123'),
('Carlos', 'Gómez', 'carlos.gomez@email.com', 'hash3', 'Diagonal 56 #789'),
('Ana', 'Martínez', 'ana.martinez@email.com', 'hash4', 'Carrera 8 #456'),
('Laura', 'Torres', 'laura.torres@email.com', 'hash5', 'Calle Luna #12');

INSERT INTO metodos_pago (nombre) VALUES
('Tarjeta de Crédito'),
('Transferencia Bancaria'),
('PayPal'),
('Contra Entrega');

INSERT INTO ventas (id_cliente, estado, total, id_metodo) VALUES
(1, 'Entregado', 319.98, 1),
(2, 'Enviado', 59.97, 2),
(3, 'Procesando', 199.00, 3),
(1, 'Entregado', 89.99, 1),
(4, 'Cancelado', 0.00, 4);

INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, precio_unitario_congelado) values
(1, 1, 1, 299.99),
(1, 2, 1, 19.99),
(2, 2, 3, 19.99),
(3, 6, 1, 199.00),
(4, 3, 1, 89.99);
