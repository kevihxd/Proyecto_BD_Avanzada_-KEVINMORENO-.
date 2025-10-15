USE tienda_online;

SHOW GRANTS FOR CURRENT_USER;


CREATE TABLE IF NOT EXISTS auditoria_precios (
  id_log INT AUTO_INCREMENT PRIMARY KEY,
  id_producto INT,
  precio_anterior DECIMAL(10,2),
  precio_nuevo DECIMAL(10,2),
  fecha_cambio DATETIME,
  FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);


CREATE TABLE IF NOT EXISTS auditoria_clientes (
  id_log INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente INT,
  accion VARCHAR(255),
  fecha DATETIME,
  FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);


CREATE TABLE IF NOT EXISTS auditoria_pedidos (
  id_log INT AUTO_INCREMENT PRIMARY KEY,
  id_venta INT,
  estado_anterior VARCHAR(50),
  estado_nuevo VARCHAR(50),
  fecha DATETIME,
  FOREIGN KEY (id_venta) REFERENCES ventas(id_venta)
);


CREATE TABLE IF NOT EXISTS alertas (
  id_alerta INT AUTO_INCREMENT PRIMARY KEY,
  id_producto INT,
  mensaje VARCHAR(255),
  fecha DATETIME,
  FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);


CREATE TABLE IF NOT EXISTS ventas_archivo (
  id_venta INT PRIMARY KEY,
  id_cliente INT,
  fecha_venta DATETIME,
  total DECIMAL(10,2),
  estado VARCHAR(50),
  usuario VARCHAR(100)
);




CREATE TABLE IF NOT EXISTS referidos (
  id_referido INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente INT,
  id_referente INT,
  fecha DATETIME DEFAULT NOW(),
  FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
  FOREIGN KEY (id_referente) REFERENCES clientes(id_cliente)
);


CREATE TABLE IF NOT EXISTS permisos (
  id_usuario INT PRIMARY KEY,
  permiso VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS auditoria_permisos (
  id_log INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario INT,
  permiso_anterior VARCHAR(100),
  permiso_nuevo VARCHAR(100),
  fecha DATETIME,
  FOREIGN KEY (id_usuario) REFERENCES permisos(id_usuario)
);


INSERT INTO categorias (nombre)
SELECT 'General'
WHERE NOT EXISTS (
  SELECT 1 FROM categorias WHERE nombre = 'General'
);



-- ===========================================
--            TRIGERS 
-- ===========================================


-- 1. Guarda un log cuando cambia el precio de un producto
DELIMITER //
CREATE TRIGGER trg_audit_precio_producto_after_update
AFTER UPDATE ON productos
FOR EACH ROW
BEGIN
  IF NEW.precio <> OLD.precio THEN
    INSERT INTO auditoria_precios (id_producto, precio_anterior, precio_nuevo, fecha_cambio)
    VALUES (OLD.id_producto, OLD.precio, NEW.precio, NOW());
  END IF;
END //
DELIMITER ;



-- 2. Verifica que haya stock antes de registrar una venta
DELIMITER //
CREATE TRIGGER trg_check_stock_before_insert_venta
BEFORE INSERT ON detalle_venta
FOR EACH ROW
BEGIN
  DECLARE stock_actual INT;
  SELECT stock INTO stock_actual FROM productos WHERE id_producto = NEW.id_producto;
  IF stock_actual < NEW.cantidad THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente para realizar la venta';
  END IF;
END //
DELIMITER ;

-- 3. Reduce el stock después de registrar una venta
DELIMITER //
CREATE TRIGGER trg_update_stock_after_insert_venta
AFTER INSERT ON detalle_venta
FOR EACH ROW
BEGIN
  UPDATE productos
  SET stock = stock - NEW.cantidad
  WHERE id_producto = NEW.id_producto;
END //
DELIMITER ;

-- 4. Impide eliminar una categoría si tiene productos asociados
DELIMITER //
CREATE TRIGGER trg_prevent_delete_categoria_with_products
BEFORE DELETE ON categorias
FOR EACH ROW
BEGIN
  IF (SELECT COUNT(*) FROM productos WHERE id_categoria = OLD.id_categoria) > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar una categoría con productos asociados';
  END IF;
END //
DELIMITER ;


-- 5. Registra en auditoría la creación de un nuevo cliente

DELIMITER //
CREATE TRIGGER trg_log_new_customer_after_insert
AFTER INSERT ON clientes
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_clientes (id_cliente, accion, fecha)
  VALUES (NEW.id_cliente, 'Nuevo cliente creado', NOW());
END //
DELIMITER ;

-- 6. Actualiza el total gastado por el cliente después de cada venta
DELIMITER //
CREATE TRIGGER trg_update_total_gastado_cliente
AFTER INSERT ON ventas
FOR EACH ROW
BEGIN
  UPDATE clientes
  SET total_gastado = total_gastado + NEW.total_venta
  WHERE id_cliente = NEW.id_cliente;
END //
DELIMITER ;


-- 7. Actualiza la fecha de última modificación de un producto
DELIMITER //
CREATE TRIGGER trg_set_fecha_modificacion_producto
BEFORE UPDATE ON productos
FOR EACH ROW
BEGIN
  SET NEW.fecha_modificacion = NOW();
END //
DELIMITER ;

-- 8. Evita que el stock de un producto sea negativo
DELIMITER //
CREATE TRIGGER trg_prevent_negative_stock
BEFORE UPDATE ON productos
FOR EACH ROW
BEGIN
  IF NEW.stock < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El stock no puede ser negativo';
  END IF;
END //
DELIMITER ;

-- 9. Capitaliza el nombre y apellido de un cliente al insertarlo
DELIMITER //
CREATE TRIGGER trg_capitalize_nombre_cliente
BEFORE INSERT ON clientes
FOR EACH ROW
BEGIN
  SET NEW.nombre = CONCAT(UCASE(LEFT(NEW.nombre,1)), LCASE(SUBSTRING(NEW.nombre,2)));
  SET NEW.apellido = CONCAT(UCASE(LEFT(NEW.apellido,1)), LCASE(SUBSTRING(NEW.apellido,2)));
END //
DELIMITER ;

-- 10. Recalcula el total de la venta cuando se cambia un detalle
DELIMITER //
CREATE TRIGGER trg_recalculate_total_venta_on_detalle_change
AFTER UPDATE ON detalle_venta
FOR EACH ROW
BEGIN
  UPDATE ventas
  SET total_venta = (SELECT SUM(cantidad * precio_unitario) FROM detalle_venta WHERE id_venta = NEW.id_venta)
  WHERE id_venta = NEW.id_venta;
END //
DELIMITER ;


-- 11. Actualiza la fecha de la última compra de un cliente
DELIMITER //
CREATE TRIGGER trg_set_fecha_ultima_compra
AFTER INSERT ON ventas
FOR EACH ROW
BEGIN
  UPDATE clientes
  SET ultima_compra = NOW()
  WHERE id_cliente = NEW.id_cliente;
END //
DELIMITER ;


-- 12. Registra cambios en los permisos de usuario
DELIMITER //
CREATE TRIGGER trg_auditoria_permisos_after_update
AFTER UPDATE ON permisos
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_permisos (id_usuario, permiso_anterior, permiso_nuevo, fecha_cambio)
  VALUES (OLD.id_usuario, OLD.permiso, NEW.permiso, NOW());
END //
DELIMITER ;

-- 13. Evita eliminar al usuario administrador principal
DELIMITER //
CREATE TRIGGER trg_prevent_delete_usuario_admin
BEFORE DELETE ON usuarios
FOR EACH ROW
BEGIN
  IF OLD.rol = 'admin' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar el usuario administrador principal';
  END IF;
END //
DELIMITER ;

-- 14. Calcula automáticamente el total en detalle_venta


DELIMITER //
CREATE TRIGGER trg_update_precio_total_detalle
BEFORE INSERT ON detalle_venta
FOR EACH ROW
BEGIN
  SET NEW.total = NEW.cantidad * NEW.precio_unitario;
END //
DELIMITER ;

-- 15. Guarda registro cuando se elimina un producto
DELIMITER //
CREATE TRIGGER trg_audit_delete_producto
AFTER DELETE ON productos
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_productos (id_producto, accion, fecha)
  VALUES (OLD.id_producto, 'Producto eliminado', NOW());
END //
DELIMITER ;

-- 16. Verifica que la fecha de vencimiento sea posterior a la actual
DELIMITER //
CREATE TRIGGER trg_check_fecha_vencimiento_before_insert
BEFORE INSERT ON productos
FOR EACH ROW
BEGIN
  IF NEW.fecha_vencimiento <= CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de vencimiento debe ser posterior a la actual';
  END IF;
END //
DELIMITER ;


-- 17. Guarda registro cuando se crea un nuevo proveedor
DELIMITER //
CREATE TRIGGER trg_log_new_proveedor
AFTER INSERT ON proveedores
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_proveedores (id_proveedor, accion, fecha)
  VALUES (NEW.id_proveedor, 'Nuevo proveedor registrado', NOW());
END //
DELIMITER ;


-- 18. Actualiza la fecha de modificación al editar datos de un empleado

DELIMITER //
CREATE TRIGGER trg_update_fecha_actualizacion_empleado
BEFORE UPDATE ON empleados
FOR EACH ROW
BEGIN
  SET NEW.fecha_actualizacion = NOW();
END //
DELIMITER ;

-- 19. Impide eliminar una venta si ya tiene detalles asociados
DELIMITER //
CREATE TRIGGER trg_control_eliminacion_venta
BEFORE DELETE ON ventas
FOR EACH ROW
BEGIN
  IF (SELECT COUNT(*) FROM detalle_venta WHERE id_venta = OLD.id_venta) > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar una venta con detalles registrados';
  END IF;
END //
DELIMITER ;

-- 20. Registra un evento cuando se crea una nueva referencia (referido)
DELIMITER //
CREATE TRIGGER trg_audit_referrals_after_insert
AFTER INSERT ON referidos
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_referidos (id_cliente, id_referente, fecha_registro)
  VALUES (NEW.id_cliente, NEW.id_referente, NOW());
END //
DELIMITER ;
