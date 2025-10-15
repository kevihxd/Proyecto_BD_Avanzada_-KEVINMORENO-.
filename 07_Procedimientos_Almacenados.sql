USE tienda_online;


DELIMITER //

-- 1. sp_RealizarNuevaVenta
DROP PROCEDURE IF EXISTS sp_RealizarNuevaVenta;
CREATE PROCEDURE sp_RealizarNuevaVenta(
    IN p_id_cliente INT,
    IN p_total DECIMAL(10,2)
)
BEGIN
    DECLARE v_id_venta INT;

    START TRANSACTION;
    INSERT INTO ventas (id_cliente, fecha, total, estado)
    VALUES (p_id_cliente, NOW(), p_total, 'Pendiente');

    SET v_id_venta = LAST_INSERT_ID();

    INSERT INTO logs_ventas (id_venta, accion, fecha)
    VALUES (v_id_venta, 'Venta registrada', NOW());

    COMMIT;
END;

DELIMITER ;


-- 2. sp_AgregarNuevoProducto
DELIMITER //
DROP PROCEDURE IF EXISTS sp_AgregarNuevoProducto;
CREATE PROCEDURE sp_AgregarNuevoProducto(
    IN p_nombre VARCHAR(100),
    IN p_precio DECIMAL(10,2),
    IN p_stock INT,
    IN p_id_categoria INT
)
BEGIN
    INSERT INTO productos (nombre, precio, stock, id_categoria, fecha_creacion)
    VALUES (p_nombre, p_precio, p_stock, p_id_categoria, NOW());
END;
DELIMITER ;

-- 3. sp_ActualizarDireccionCliente

DELIMITER //
DROP PROCEDURE IF EXISTS sp_ActualizarDireccionCliente;
CREATE PROCEDURE sp_ActualizarDireccionCliente(
    IN p_id_cliente INT,
    IN p_nueva_direccion VARCHAR(255)
)
BEGIN
    UPDATE clientes SET direccion_envio = p_nueva_direccion WHERE id_cliente = p_id_cliente;
    UPDATE ventas SET direccion_envio = p_nueva_direccion WHERE id_cliente = p_id_cliente;
END;
DELIMITER ;

-- 4. sp_ProcesarDevolucion
DELIMITER //
DROP PROCEDURE IF EXISTS sp_ProcesarDevolucion;
CREATE PROCEDURE sp_ProcesarDevolucion(
    IN p_id_venta INT,
    IN p_id_producto INT,
    IN p_cantidad INT
)
BEGIN
    START TRANSACTION;
    UPDATE productos SET stock = stock + p_cantidad WHERE id_producto = p_id_producto;
    INSERT INTO devoluciones (id_venta, id_producto, cantidad, fecha)
    VALUES (p_id_venta, p_id_producto, p_cantidad, NOW());
    COMMIT;
END;
DELIMITER ;

-- 5. sp_ObtenerHistorialComprasCliente

DELIMITER //
DROP PROCEDURE IF EXISTS sp_ObtenerHistorialComprasCliente;
CREATE PROCEDURE sp_ObtenerHistorialComprasCliente(IN p_id_cliente INT)
BEGIN
    SELECT v.id_venta, v.fecha, v.total, v.estado
    FROM ventas v
    WHERE v.id_cliente = p_id_cliente
    ORDER BY v.fecha DESC;
END;

DELIMITER ;

-- 6. sp_AjustarNivelStock
DELIMITER //

DROP PROCEDURE IF EXISTS sp_AjustarNivelStock;
CREATE PROCEDURE sp_AjustarNivelStock(
    IN p_id_producto INT,
    IN p_nuevo_stock INT,
    IN p_motivo VARCHAR(255)
)
BEGIN
    UPDATE productos SET stock = p_nuevo_stock WHERE id_producto = p_id_producto;
    INSERT INTO logs_inventario (id_producto, motivo, fecha) VALUES (p_id_producto, p_motivo, NOW());
END;

DELIMITER ;

-- 7. sp_EliminarClienteDeFormaSegura

DELIMITER //
DROP PROCEDURE IF EXISTS sp_EliminarClienteDeFormaSegura;
CREATE PROCEDURE sp_EliminarClienteDeFormaSegura(IN p_id_cliente INT)
BEGIN
    UPDATE clientes
    SET nombre = 'Anonimo', apellido = '', email = CONCAT('anonimo', p_id_cliente, '@mail.com')
    WHERE id_cliente = p_id_cliente;
END;
DELIMITER ;

-- 8. sp_AplicarDescuentoPorCategoria
DELIMITER //
DROP PROCEDURE IF EXISTS sp_AplicarDescuentoPorCategoria;
CREATE PROCEDURE sp_AplicarDescuentoPorCategoria(
    IN p_id_categoria INT,
    IN p_porcentaje DECIMAL(5,2)
)
BEGIN
    UPDATE productos
    SET precio = precio - (precio * (p_porcentaje / 100))
    WHERE id_categoria = p_id_categoria;
END;
DELIMITER ;

-- 9. sp_GenerarReporteMensualVentas

DELIMITER //

DROP PROCEDURE IF EXISTS sp_GenerarReporteMensualVentas;
CREATE PROCEDURE sp_GenerarReporteMensualVentas(
    IN p_anio INT,
    IN p_mes INT
)
BEGIN
    SELECT 
        COUNT(*) AS cantidad_ventas,
        SUM(total) AS monto_total
    FROM ventas
    WHERE YEAR(fecha) = p_anio AND MONTH(fecha) = p_mes;
END;
DELIMITER ;

-- 10. sp_CambiarEstadoPedido
DELIMITER //
DROP PROCEDURE IF EXISTS sp_CambiarEstadoPedido;
CREATE PROCEDURE sp_CambiarEstadoPedido(
    IN p_id_venta INT,
    IN p_nuevo_estado VARCHAR(50)
)
BEGIN
    UPDATE ventas SET estado = p_nuevo_estado WHERE id_venta = p_id_venta;
    INSERT INTO logs_pedidos (id_venta, nuevo_estado, fecha)
    VALUES (p_id_venta, p_nuevo_estado, NOW());
END;
DELIMITER ;

-- 11. sp_RegistrarNuevoCliente
DELIMITER //
DROP PROCEDURE IF EXISTS sp_RegistrarNuevoCliente;
CREATE PROCEDURE sp_RegistrarNuevoCliente(
    IN p_nombre VARCHAR(100),
    IN p_apellido VARCHAR(100),
    IN p_email VARCHAR(150),
    IN p_direccion VARCHAR(255)
)
BEGIN
    IF EXISTS (SELECT 1 FROM clientes WHERE email = p_email) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El correo ya existe';
    ELSE
        INSERT INTO clientes (nombre, apellido, email, direccion_envio, fecha_registro)
        VALUES (p_nombre, p_apellido, p_email, p_direccion, NOW());
    END IF;
END;
DELIMITER ;

-- 12. sp_ObtenerDetallesProductoCompleto
DELIMITER //
DROP PROCEDURE IF EXISTS sp_ObtenerDetallesProductoCompleto;
CREATE PROCEDURE sp_ObtenerDetallesProductoCompleto(IN p_id_producto INT)
BEGIN
    SELECT p.*, c.nombre AS categoria, pr.nombre AS proveedor
    FROM productos p
    JOIN categorias c ON p.id_categoria = c.id_categoria
    JOIN proveedores pr ON p.id_proveedor = pr.id_proveedor
    WHERE p.id_producto = p_id_producto;
END;
DELIMITER ;

-- 13. sp_FusionarCuentasCliente
DELIMITER //
DROP PROCEDURE IF EXISTS sp_FusionarCuentasCliente;
CREATE PROCEDURE sp_FusionarCuentasCliente(
    IN p_id_cliente_origen INT,
    IN p_id_cliente_destino INT
)
BEGIN
    UPDATE ventas SET id_cliente = p_id_cliente_destino WHERE id_cliente = p_id_cliente_origen;
    DELETE FROM clientes WHERE id_cliente = p_id_cliente_origen;
END;
DELIMITER ;

-- 14. sp_AsignarProductoAProveedor
DELIMITER //
DROP PROCEDURE IF EXISTS sp_AsignarProductoAProveedor;
CREATE PROCEDURE sp_AsignarProductoAProveedor(
    IN p_id_producto INT,
    IN p_id_proveedor INT
)
BEGIN
    UPDATE productos SET id_proveedor = p_id_proveedor WHERE id_producto = p_id_producto;
END;
DELIMITER ;

-- 15. sp_BuscarProductos
DELIMITER //
DROP PROCEDURE IF EXISTS sp_BuscarProductos;
CREATE PROCEDURE sp_BuscarProductos(
    IN p_nombre VARCHAR(100),
    IN p_categoria INT,
    IN p_precio_min DECIMAL(10,2),
    IN p_precio_max DECIMAL(10,2)
)
BEGIN
    SELECT *
    FROM productos
    WHERE (p_nombre IS NULL OR nombre LIKE CONCAT('%', p_nombre, '%'))
      AND (p_categoria IS NULL OR id_categoria = p_categoria)
      AND (p_precio_min IS NULL OR precio >= p_precio_min)
      AND (p_precio_max IS NULL OR precio <= p_precio_max);
END;
DELIMITER ;

-- 16. sp_ObtenerDashboardAdmin
DELIMITER //
DROP PROCEDURE IF EXISTS sp_ObtenerDashboardAdmin;
CREATE PROCEDURE sp_ObtenerDashboardAdmin()
BEGIN
    SELECT 
        (SELECT COUNT(*) FROM clientes WHERE DATE(fecha_registro) = CURDATE()) AS nuevos_clientes,
        (SELECT SUM(total) FROM ventas WHERE DATE(fecha) = CURDATE()) AS ventas_hoy,
        (SELECT COUNT(*) FROM productos WHERE stock < 10) AS productos_bajo_stock,
        (SELECT COUNT(*) FROM ventas WHERE estado = 'Pendiente') AS pedidos_pendientes;
END;
DELIMITER ;

-- 17. sp_ProcesarPago

DELIMITER //

DROP PROCEDURE IF EXISTS sp_ProcesarPago;
CREATE PROCEDURE sp_ProcesarPago(IN p_id_venta INT)
BEGIN
    UPDATE ventas SET estado = 'Pagado', fecha_pago = NOW() WHERE id_venta = p_id_venta;
    INSERT INTO pagos (id_venta, fecha, estado) VALUES (p_id_venta, NOW(), 'Exitoso');
END;
DELIMITER ;

-- 18. sp_AñadirReseñaProducto
DELIMITER //
DROP PROCEDURE IF EXISTS sp_AñadirReseñaProducto;
CREATE PROCEDURE sp_AñadirReseñaProducto(
    IN p_id_cliente INT,
    IN p_id_producto INT,
    IN p_calificacion INT,
    IN p_comentario TEXT
)
BEGIN
    INSERT INTO reseñas (id_cliente, id_producto, calificacion, comentario, fecha)
    VALUES (p_id_cliente, p_id_producto, p_calificacion, p_comentario, NOW());
END;

DELIMITER ;


-- 19. sp_ObtenerProductosRelacionados

DELIMITER //
DROP PROCEDURE IF EXISTS sp_ObtenerProductosRelacionados;
CREATE PROCEDURE sp_ObtenerProductosRelacionados(IN p_id_producto INT)
BEGIN
    SELECT DISTINCT dv2.id_producto AS producto_relacionado
    FROM detalle_ventas dv1
    JOIN detalle_ventas dv2 ON dv1.id_venta = dv2.id_venta
    WHERE dv1.id_producto = p_id_producto
      AND dv2.id_producto <> p_id_producto
    LIMIT 10;
END;
DELIMITER ;

-- 20. sp_MoverProductosEntreCategorias

DELIMITER //
DROP PROCEDURE IF EXISTS sp_MoverProductosEntreCategorias;
CREATE PROCEDURE sp_MoverProductosEntreCategorias(
    IN p_id_categoria_origen INT,
    IN p_id_categoria_destino INT
)
BEGIN
    UPDATE productos
    SET id_categoria = p_id_categoria_destino
    WHERE id_categoria = p_id_categoria_origen;
END;
DELIMITER ;
