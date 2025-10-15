USE tienda_online;

-- ======================================================
-- 🚀 CREACIÓN DE ROLES
-- ======================================================

CREATE ROLE Administrador_Sistema;
CREATE ROLE Gerente_Marketing;
CREATE ROLE Analista_Datos;
CREATE ROLE Empleado_Inventario;
CREATE ROLE Atencion_Cliente;
CREATE ROLE Auditor_Financiero;
CREATE ROLE Visitante;


-- ======================================================
-- ASIGNACIÓN DE PRIVILEGIOS A CADA ROL
-- ======================================================

-- Administrador del sistema: todos los privilegios
GRANT ALL PRIVILEGES ON tienda_online.* TO Administrador_Sistema;

-- Gerente de marketing: solo lectura sobre ventas y clientes
GRANT SELECT ON tienda_online.ventas TO Gerente_Marketing;
GRANT SELECT ON tienda_online.clientes TO Gerente_Marketing;

-- Analista de datos: solo lectura, excepto tablas de auditoría
REVOKE ALL PRIVILEGES ON tienda_online.* FROM Analista_Datos;
GRANT SELECT ON tienda_online.ventas TO Analista_Datos;
GRANT SELECT ON tienda_online.clientes TO Analista_Datos;
GRANT SELECT ON tienda_online.productos TO Analista_Datos;
GRANT SELECT ON tienda_online.categorias TO Analista_Datos;
GRANT SELECT ON tienda_online.detalle_ventas TO Analista_Datos;

--  Empleado de inventario: modificar solo el stock de productos
GRANT SELECT, UPDATE (stock) ON tienda_online.productos TO Empleado_Inventario;

--  Atención al cliente: ver clientes y ventas, sin modificar precios
GRANT SELECT ON tienda_online.clientes TO Atencion_Cliente;
GRANT SELECT ON tienda_online.ventas TO Atencion_Cliente;

-- Auditor financiero: lectura sobre ventas y productos
GRANT SELECT ON tienda_online.ventas TO Auditor_Financiero;
GRANT SELECT ON tienda_online.productos TO Auditor_Financiero;

-- Visitante: acceso mínimo (solo productos)
GRANT SELECT ON tienda_online.productos TO Visitante;


-- ======================================================
-- CREACIÓN DE USUARIOS
-- ======================================================

CREATE USER 'admin_user'@'localhost' IDENTIFIED BY 'Admin#2024';
CREATE USER 'marketing_user'@'localhost' IDENTIFIED BY 'Marketing#2024';
CREATE USER 'inventory_user'@'localhost' IDENTIFIED BY 'Inventory#2024';
CREATE USER 'support_user'@'localhost' IDENTIFIED BY 'Support#2024';
CREATE USER 'analista_user'@'localhost' IDENTIFIED BY 'Analyst#2024';
CREATE USER 'auditor_user'@'localhost' IDENTIFIED BY 'Auditor#2024';
CREATE USER 'visitante_user'@'localhost' IDENTIFIED BY 'Visit#2024';


-- ======================================================
-- ASIGNACIÓN DE ROLES A USUARIOS por jerarquia
-- ======================================================

GRANT Administrador_Sistema TO 'admin_user'@'localhost';
GRANT Gerente_Marketing TO 'marketing_user'@'localhost';
GRANT Empleado_Inventario TO 'inventory_user'@'localhost';
GRANT Atencion_Cliente TO 'support_user'@'localhost';
GRANT Analista_Datos TO 'analista_user'@'localhost';
GRANT Auditor_Financiero TO 'auditor_user'@'localhost';
GRANT Visitante TO 'visitante_user'@'localhost';


-- ======================================================
-- sEGURIDAD ADICIONAL
-- ======================================================

-- Bloquear acceso remoto del usuario root
DROP USER IF EXISTS 'root'@'%';


-- ======================================================
-- LIMITACIONES DE USO
-- ======================================================

-- Limitar el número de consultas y conexiones por hora del analista
ALTER USER 'analista_user'@'localhost'
WITH 
    MAX_QUERIES_PER_HOUR 1000,
    MAX_CONNECTIONS_PER_HOUR 100;


-- ======================================================
-- VISTAS Y RESTRICCIONES POR USUARIO / SUCURSAL
-- ======================================================

-- (Opcional) Vista filtrada por sucursal, si existe la columna id_sucursal
CREATE OR REPLACE VIEW tienda_online.v_ventas_sucursal AS
SELECT * 
FROM tienda_online.ventas
WHERE id_sucursal = CURRENT_USER();

GRANT SELECT ON tienda_online.v_ventas_sucursal TO Analista_Datos;

-- Vista alternativa si no existe id_sucursal (por usuario)
CREATE OR REPLACE VIEW tienda_online.v_ventas_limitadas AS
SELECT id_venta, fecha, total
FROM tienda_online.ventas
WHERE usuario = CURRENT_USER();

GRANT SELECT ON tienda_online.v_ventas_limitadas TO Analista_Datos;








