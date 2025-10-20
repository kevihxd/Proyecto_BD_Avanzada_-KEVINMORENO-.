-- ============================================================
--                 solucion examen 
-- ============================================================

USE tienda_online;

-- 1. Crear la tabla de registro de devoluciones

CREATE TABLE IF NOT EXISTS Devoluciones (
    id_devolucion INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad_devuelta INT NOT NULL,
    fecha_devolucion DATETIME DEFAULT CURRENT_TIMESTAMP,
    comentario VARCHAR(255)
);

-- Crear procedimiento almacenado para procesar devoluciones 

DELIMITER //

CREATE PROCEDURE sp_ProcesarDevolucion(
    IN p_id_venta INT,
    IN p_id_producto INT,
    IN p_cantidad_devuelta INT
)
BEGIN
    DECLARE cantidad_comprada INT;
    DECLARE cantidad_actual_devuelta INT;
    DECLARE nueva_cantidad_devuelta INT;
    DECLARE estado_actual VARCHAR(50);

    -- Iniciar la transacción
   
    START TRANSACTION;

    -- Obtener la cantidad comprada del producto en la venta
   
    SELECT cantidad, IFNULL((SELECT SUM(cantidad_devuelta) 
                             FROM Devoluciones 
                             WHERE id_venta = p_id_venta AND id_producto = p_id_producto), 0)
    INTO cantidad_comprada, cantidad_actual_devuelta
    FROM DetalleVentas
    WHERE id_venta = p_id_venta AND id_producto = p_id_producto
    FOR UPDATE;

    -- Validar que la cantidad a devolver no supere la comprada
   
    IF p_cantidad_devuelta <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cantidad a devolver debe ser mayor que 0.';
    ELSEIF (cantidad_actual_devuelta + p_cantidad_devuelta) > cantidad_comprada THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cantidad a devolver supera la cantidad comprada.';
    END IF;

    --  Actualizar el stock del producto
   
    UPDATE Productos
    SET stock = stock + p_cantidad_devuelta
    WHERE id_producto = p_id_producto;

    -- Insertar registro en la tabla Devoluciones
   
    INSERT INTO Devoluciones (id_venta, id_producto, cantidad_devuelta)
    VALUES (p_id_venta, p_id_producto, p_cantidad_devuelta);

    -- Actualizar el estado de la venta según la cantidad devuelta
   
    SET nueva_cantidad_devuelta = cantidad_actual_devuelta + p_cantidad_devuelta;

    IF nueva_cantidad_devuelta = cantidad_comprada THEN
        SET estado_actual = 'Devuelto Totalmente';
    ELSE
        SET estado_actual = 'Devolución Parcial';
    END IF;

    UPDATE Ventas
    SET estado = estado_actual
    WHERE id_venta = p_id_venta;

    -- transaccion realizada 
    COMMIT;
END 

DELIMITER ;
   
