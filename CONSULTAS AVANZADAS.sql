USE tienda_online;

-- ============================
-- CONSULTAS AVANZADAS :D
-- ============================


-- 1. Top 10 Productos Más Vendidos (por ingreso total)
SELECT
  p.nombre AS producto,
  SUM(dv.cantidad) AS unidades_vendidas,
  SUM(dv.cantidad * dv.precio_unitario_congelado) AS ingresos_totales
FROM detalle_ventas dv
JOIN productos p ON dv.id_producto = p.id_producto
GROUP BY p.nombre
ORDER BY ingresos_totales DESC
LIMIT 10;


-- 2. Top 5 Clientes que Más Han Gastado
SELECT
  c.nombre,
  c.apellido,
  c.email,
  SUM(v.total) AS total_gastado
FROM clientes c
JOIN ventas v ON c.id_cliente = v.id_cliente
WHERE v.estado != 'Cancelado'
GROUP BY c.id_cliente
ORDER BY total_gastado DESC
LIMIT 5;


-- 3. Análisis de Ventas Mensuales
SELECT
  YEAR(fecha_venta) AS año,
  MONTH(fecha_venta) AS mes,
  COUNT(*) AS cantidad_ventas,
  SUM(total) AS monto_total
FROM ventas
WHERE estado != 'Cancelado'
GROUP BY año, mes
ORDER BY año, mes;


-- 4. Crecimiento de Clientes por Trimestre
SELECT
  YEAR(fecha_registro) AS año,
  QUARTER(fecha_registro) AS trimestre,
  COUNT(*) AS nuevos_clientes
FROM clientes
GROUP BY año, trimestre
ORDER BY año, trimestre;


-- 5. Tasa de Compra Repetida
SELECT
  ROUND(
    (
      (SELECT COUNT(*) 
       FROM (
         SELECT id_cliente
         FROM ventas
         GROUP BY id_cliente
         HAVING COUNT(id_venta) > 1
       ) AS clientes_recurrentes)
      /
      (SELECT COUNT(*) FROM clientes)
    * 100
  ), 2
  ) AS porcentaje_clientes_recurrentes;


-- 6. Productos Comprados Juntos Frecuentemente
SELECT
  a.id_producto AS producto_a,
  b.id_producto AS producto_b,
  COUNT(*) AS veces_comprados_juntos
FROM detalle_ventas a
JOIN detalle_ventas b ON a.id_venta = b.id_venta AND a.id_producto < b.id_producto
GROUP BY a.id_producto, b.id_producto
ORDER BY veces_comprados_juntos DESC
LIMIT 10;


-- 7. Rotación de Inventario por Categoría
SELECT
  c.nombre AS categoria,
  SUM(dv.cantidad) AS unidades_vendidas,
  SUM(p.stock) AS stock_actual,
  ROUND(SUM(dv.cantidad) / NULLIF(SUM(p.stock), 0), 2) AS rotacion_stock
FROM detalle_ventas dv
JOIN productos p ON dv.id_producto = p.id_producto
JOIN categorias c ON p.id_categoria = c.id_categoria
GROUP BY c.id_categoria;


-- 8. Productos que Necesitan Reabastecimiento (stock bajo un umbral)
SELECT
  nombre,
  stock
FROM productos
WHERE stock < 10
ORDER BY stock ASC;


-- 9. Carrito Abandonado (clientes sin compras)
SELECT
  c.nombre,
  c.apellido,
  c.email
FROM clientes c
LEFT JOIN ventas v ON c.id_cliente = v.id_cliente
WHERE v.id_venta IS NULL;


-- 10. Rendimiento de Proveedores
SELECT
  pr.nombre AS proveedor,
  SUM(dv.cantidad * dv.precio_unitario_congelado) AS ingresos
FROM detalle_ventas dv
JOIN productos p ON dv.id_producto = p.id_producto
JOIN proveedores pr ON p.id_proveedor = pr.id_proveedor
GROUP BY pr.id_proveedor
ORDER BY ingresos DESC;


-- 11. Análisis Geográfico de Ventas (por dirección del cliente)
SELECT
  c.direccion_envio,
  COUNT(*) AS ventas,
  SUM(v.total) AS monto_total
FROM ventas v
JOIN clientes c ON v.id_cliente = c.id_cliente
GROUP BY c.direccion_envio
ORDER BY monto_total DESC;


-- 12. Ventas por Hora del Día
SELECT
  HOUR(fecha_venta) AS hora,
  COUNT(*) AS cantidad_ventas,
  SUM(total) AS monto
FROM ventas
GROUP BY hora
ORDER BY hora;


-- 13. Impacto de Promociones (simulado con producto específico)
SELECT
  fecha_venta,
  total
FROM ventas
WHERE id_venta IN (
  SELECT id_venta
  FROM detalle_ventas
  WHERE id_producto = 1 -- producto promocionado
)
ORDER BY fecha_venta;


-- 14. Análisis de Cohort (retención de clientes mes a mes)
SELECT
  YEAR(v1.fecha_venta) AS año_registro,
  MONTH(v1.fecha_venta) AS mes_registro,
  YEAR(v2.fecha_venta) AS año_actividad,
  MONTH(v2.fecha_venta) AS mes_actividad,
  COUNT(DISTINCT v2.id_cliente) AS clientes_activos
FROM ventas v1
JOIN ventas v2 ON v1.id_cliente = v2.id_cliente
WHERE v1.id_venta = (
  SELECT MIN(id_venta)
  FROM ventas
  WHERE id_cliente = v1.id_cliente
)
GROUP BY año_registro, mes_registro, año_actividad, mes_actividad
ORDER BY año_registro, mes_registro, año_actividad, mes_actividad;


-- 15. Margen de Beneficio por Producto
SELECT
  p.nombre,
  SUM(dv.cantidad * (dv.precio_unitario_congelado - p.costo)) AS beneficio_total
FROM detalle_ventas dv
JOIN productos p ON dv.id_producto = p.id_producto
GROUP BY p.id_producto
ORDER BY beneficio_total DESC;


-- 16. Tiempo Promedio Entre Compras (por cliente)
SELECT 
  id_cliente,
  ROUND(DATEDIFF(MAX(fecha_venta), MIN(fecha_venta)), 2) AS dias_promedio
FROM ventas
WHERE estado != 'Cancelado'
GROUP BY id_cliente;


-- 17. Segmentación de Clientes (RFM)
SELECT
  c.id_cliente,
  MAX(v.fecha_venta) AS ultima_compra,
  COUNT(v.id_venta) AS cantidad_compras,
  SUM(v.total) AS total_gastado
FROM clientes c
JOIN ventas v ON c.id_cliente = v.id_cliente
WHERE v.estado != 'Cancelado'
GROUP BY c.id_cliente;


-- 18. Predicción de Demanda Simple (proyección por promedio)
SELECT
  c.nombre AS categoria,
  SUM(dv.cantidad) AS total_vendido,
  ROUND(SUM(dv.cantidad) / COUNT(DISTINCT MONTH(v.fecha_venta)), 2) AS promedio_mensual,
  ROUND(SUM(dv.cantidad) / COUNT(DISTINCT MONTH(v.fecha_venta)), 2) AS proyeccion_siguiente_mes
FROM detalle_ventas dv
JOIN productos p ON dv.id_producto = p.id_producto
JOIN categorias c ON p.id_categoria = c.id_categoria
JOIN ventas v ON dv.id_venta = v.id_venta
WHERE v.estado != 'Cancelado'
GROUP BY c.id_categoria;
