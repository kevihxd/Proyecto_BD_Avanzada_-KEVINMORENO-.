-- fn_CalcularTotalVenta

CREATE FUNCTION fn_CalcularTotalVenta(p_id_venta INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
DECLARE total DECIMAL(10,2);
SELECT SUM(cantidad * precio_unitario_congelado)
INTO total
FROM detalle_ventas
WHERE id_venta = p_id_venta;
RETURN IFNULL(total, 0);
END;

-- fn_VerificarDisponibilidadStock

CREATE FUNCTION fn_VerificarDisponibilidadStock(p_id_producto INT, p_cantidad INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
DECLARE disponible INT;
SELECT stock INTO disponible FROM productos WHERE id_producto = p_id_producto;
RETURN disponible >= p_cantidad;
END;

-- fn_ObtenerPrecioProducto

CREATE FUNCTION fn_ObtenerPrecioProducto(p_id_producto INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
DECLARE precio DECIMAL(10,2);
SELECT precio INTO precio FROM productos WHERE id_producto = p_id_producto;
RETURN precio;
END;

-- fn_CalcularEdadCliente

CREATE FUNCTION fn_CalcularEdadCliente(fecha_nacimiento DATE)
RETURNS INT
DETERMINISTIC
BEGIN
RETURN TIMESTAMPDIFF(YEAR, fecha_nacimiento, CURDATE());
END;

-- fn_FormatearNombreCompleto

CREATE FUNCTION fn_FormatearNombreCompleto(p_id_cliente INT)
RETURNS VARCHAR(255)
DETERMINISTIC
READS SQL DATA
BEGIN
DECLARE nombre VARCHAR(100);
DECLARE apellido VARCHAR(100);
SELECT nombre, apellido INTO nombre, apellido
FROM clientes WHERE id_cliente = p_id_cliente;
RETURN CONCAT(UCASE(LEFT(nombre,1)), LCASE(SUBSTRING(nombre,2)), ' ', UCASE(LEFT(apellido,1)), LCASE(SUBSTRING(apellido,2)));
END;

-- fn_EsClienteNuevo

CREATE FUNCTION fn_EsClienteNuevo(p_id_cliente INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
DECLARE fecha_reg DATETIME;
SELECT fecha_registro INTO fecha_reg FROM clientes WHERE id_cliente = p_id_cliente;
RETURN DATEDIFF(CURDATE(), fecha_reg) <= 30;
END;

-- fn_CalcularCostoEnvio

CREATE FUNCTION fn_CalcularCostoEnvio(p_peso_total DECIMAL(10,2))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
RETURN 5.00 + (p_peso_total * 0.5); -- tarifa base + 0.5 por kg
END;

-- fn_AplicarDescuento

CREATE FUNCTION fn_AplicarDescuento(monto DECIMAL(10,2), porcentaje INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
RETURN monto - (monto * porcentaje / 100);
END;

-- fn_ObtenerUltimaFechaCompra

CREATE FUNCTION fn_ObtenerUltimaFechaCompra(p_id_cliente INT)
RETURNS DATETIME
DETERMINISTIC
READS SQL DATA
BEGIN
DECLARE fecha DATETIME;
SELECT MAX(fecha_venta) INTO fecha FROM ventas WHERE id_cliente = p_id_cliente;
RETURN fecha;
END;

-- fn_ValidarFormatoEmail

CREATE FUNCTION fn_ValidarFormatoEmail(p_email VARCHAR(255))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
  DECLARE tiene_arroba BOOLEAN;
  DECLARE tiene_punto BOOLEAN;

  -- Verificar si el correo contiene '@'
  SET tiene_arroba = INSTR(p_email, '@') > 0;

  -- Verificar si el correo contiene '.'
  SET tiene_punto = INSTR(p_email, '.') > 0;

  -- Si tiene ambos símbolos, se considera válido
  RETURN (tiene_arroba AND tiene_punto);
END;



-- fn_ObtenerNombreCategoria

CREATE FUNCTION fn_ObtenerNombreCategoria(p_id_producto INT)
RETURNS VARCHAR(100)
DETERMINISTIC
READS SQL DATA
BEGIN
DECLARE nombre_cat VARCHAR(100);
SELECT c.nombre INTO nombre_cat
FROM productos p
JOIN categorias c ON p.id_categoria = c.id_categoria
WHERE p.id_producto = p_id_producto;
RETURN nombre_cat;
END;

-- fn_ContarVentasCliente

CREATE FUNCTION fn_ContarVentasCliente(p_id_cliente INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
DECLARE total INT;
SELECT COUNT(*) INTO total FROM ventas WHERE id_cliente = p_id_cliente;
RETURN total;
END;

-- fn_CalcularDiasDesdeUltimaCompra

CREATE FUNCTION fn_CalcularDiasDesdeUltimaCompra(p_id_cliente INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
DECLARE fecha DATETIME;
SELECT MAX(fecha_venta) INTO fecha FROM ventas WHERE id_cliente = p_id_cliente;
RETURN DATEDIFF(CURDATE(), fecha);
END;

--  fn_DeterminarEstadoLealtad

CREATE FUNCTION fn_DeterminarEstadoLealtad(p_id_cliente INT)
RETURNS VARCHAR(20)
DETERMINISTIC
READS SQL DATA
BEGIN
DECLARE total DECIMAL(10,2);
SELECT SUM(total) INTO total FROM ventas WHERE id_cliente = p_id_cliente;
RETURN CASE
WHEN total >= 1000 THEN 'Oro'
WHEN total >= 500 THEN 'Plata'
ELSE 'Bronce'
END;
END;

-- fn_GenerarSKU

CREATE FUNCTION fn_GenerarSKU(p_nombre_producto VARCHAR(100), p_id_categoria INT)
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
RETURN CONCAT(UCASE(LEFT(p_nombre_producto,3)), '-', p_id_categoria, '-', FLOOR(RAND() * 10000));
END;

fn_CalcularIVA

CREATE FUNCTION fn_CalcularIVA(p_total DECIMAL(10,2), p_porcentaje_iva INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
RETURN p_total * p_porcentaje_iva / 100;
END;

fn_ObtenerStockTotalPorCategoria

CREATE FUNCTION fn_ObtenerStockTotalPorCategoria(p_id_categoria INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
DECLARE total INT;
SELECT SUM(stock) INTO total FROM productos WHERE id_categoria = p_id_categoria;
RETURN IFNULL(total, 0);
END;

fn_EstimarFechaEntrega

CREATE FUNCTION fn_EstimarFechaEntrega(p_region VARCHAR(50))
RETURNS DATE
DETERMINISTIC
BEGIN
RETURN CASE
WHEN p_region = 'Capital' THEN DATE_ADD(CURDATE(), INTERVAL 2 DAY)
WHEN p_region = 'Interior' THEN DATE_ADD(CURDATE(), INTERVAL 5 DAY)
ELSE DATE_ADD(CURDATE(), INTERVAL 7 DAY)
END;
END;

-- fn_ConvertirMoneda

CREATE FUNCTION fn_ConvertirMoneda(monto DECIMAL(10,2), tasa DECIMAL(10,4))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
RETURN monto * tasa;
END;

-- fn_ValidarComplejidadContraseña

DELIMITER //

CREATE FUNCTION fn_ValidarComplejidadContraseña(p_password VARCHAR(255))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
  DECLARE tiene_mayuscula BOOLEAN DEFAULT FALSE;
  DECLARE tiene_minuscula BOOLEAN DEFAULT FALSE;
  DECLARE tiene_numero BOOLEAN DEFAULT FALSE;
  DECLARE tiene_longitud BOOLEAN DEFAULT FALSE;

  -- Verificar longitud
  IF LENGTH(p_password) >= 8 THEN
    SET tiene_longitud = TRUE;
  END IF;

  -- Verificar si contiene al menos una mayúscula
  IF p_password != LOWER(p_password) THEN
    SET tiene_mayuscula = TRUE;
  END IF;

  -- Verificar si contiene al menos una minúscula
  IF p_password != UPPER(p_password) THEN
    SET tiene_minuscula = TRUE;
  END IF;

  -- Verificar si contiene al menos un número
  IF p_password LIKE '%0%' OR p_password LIKE '%1%' OR p_password LIKE '%2%' OR
     p_password LIKE '%3%' OR p_password LIKE '%4%' OR p_password LIKE '%5%' OR
     p_password LIKE '%6%' OR p_password LIKE '%7%' OR p_password LIKE '%8%' OR
     p_password LIKE '%9%' THEN
    SET tiene_numero = TRUE;
  END IF;

  RETURN (tiene_longitud AND tiene_mayuscula AND tiene_minuscula AND tiene_numero);
END //

DELIMITER ;



