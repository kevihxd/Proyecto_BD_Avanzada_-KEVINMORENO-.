use tienda_online

-- 1. Genera un reporte de ventas semanal
CREATE EVENT evt_generate_weekly_sales_report
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
DO
  INSERT INTO reportes_ventas_semanales (fecha_generacion, total_ventas)
  SELECT NOW(), SUM(total) FROM ventas
  WHERE fecha >= DATE_SUB(NOW(), INTERVAL 7 DAY);

-- 2. Borra tablas temporales diariamente
CREATE EVENT evt_cleanup_temp_tables_daily
ON SCHEDULE EVERY 1 DAY
DO
  DROP TEMPORARY TABLE IF EXISTS tmp_ventas, tmp_clientes, tmp_reporte;

-- 3. Archiva logs de más de 6 meses
CREATE EVENT evt_archive_old_logs_monthly
ON SCHEDULE EVERY 1 MONTH
DO
  INSERT INTO logs_historicos SELECT * FROM logs WHERE fecha < DATE_SUB(NOW(), INTERVAL 6 MONTH);
  DELETE FROM logs WHERE fecha < DATE_SUB(NOW(), INTERVAL 6 MONTH);

-- 4. Desactiva promociones expiradas cada hora
CREATE EVENT evt_deactivate_expired_promotions_hourly
ON SCHEDULE EVERY 1 HOUR
DO
  UPDATE promociones SET activa = 0 WHERE fecha_fin < NOW() AND activa = 1;

-- 5. Recalcula niveles de lealtad de clientes cada noche
CREATE EVENT evt_recalculate_customer_loyalty_tiers_nightly
ON SCHEDULE EVERY 1 DAY STARTS TIMESTAMP(CURRENT_DATE, '23:59:00')
DO
  CALL recalcular_niveles_lealtad();

-- 6. Genera lista de productos por reabastecer diariamente
CREATE EVENT evt_generate_reorder_list_daily
ON SCHEDULE EVERY 1 DAY
DO
  INSERT INTO lista_reabastecimiento (id_producto, cantidad_sugerida, fecha)
  SELECT id_producto, stock_minimo - stock_actual, NOW()
  FROM productos
  WHERE stock_actual < stock_minimo;

-- 7. Reconstruye índices semanalmente
CREATE EVENT evt_rebuild_indexes_weekly
ON SCHEDULE EVERY 1 WEEK
DO
  OPTIMIZE TABLE productos, ventas, clientes;

-- 8. Suspende cuentas inactivas por más de un año cada trimestre
CREATE EVENT evt_suspend_inactive_accounts_quarterly
ON SCHEDULE EVERY 3 MONTH
DO
  UPDATE clientes SET estado = 'inactivo'
  WHERE ultima_compra < DATE_SUB(NOW(), INTERVAL 1 YEAR);

-- 9. Agrega los datos de ventas del día en una tabla resumen
CREATE EVENT evt_aggregate_daily_sales_data
ON SCHEDULE EVERY 1 DAY
DO
  INSERT INTO resumen_ventas_diarias (fecha, total_dia)
  SELECT CURDATE(), SUM(total) FROM ventas WHERE DATE(fecha) = CURDATE();

-- 10. Busca inconsistencias en los datos (ventas sin detalles)
CREATE EVENT evt_check_data_consistency_nightly
ON SCHEDULE EVERY 1 DAY
DO
  INSERT INTO inconsistencias (tipo, id_afectado, fecha)
  SELECT 'Venta sin detalles', v.id_venta, NOW()
  FROM ventas v
  LEFT JOIN detalle_venta d ON v.id_venta = d.id_venta
  WHERE d.id_venta IS NULL;

-- 11. Genera lista de cumpleaños diarios
CREATE EVENT evt_send_birthday_greetings_daily
ON SCHEDULE EVERY 1 DAY
DO
  INSERT INTO cumpleaños_hoy (id_cliente, fecha)
  SELECT id_cliente, NOW() FROM clientes
  WHERE DATE_FORMAT(fecha_nacimiento, '%m-%d') = DATE_FORMAT(CURDATE(), '%m-%d');

-- 12. Actualiza ranking de productos cada hora
CREATE EVENT evt_update_product_rankings_hourly
ON SCHEDULE EVERY 1 HOUR
DO
  REPLACE INTO ranking_productos (id_producto, ventas_totales)
  SELECT id_producto, SUM(cantidad) FROM detalle_venta GROUP BY id_producto;

-- 13. Realiza respaldo lógico diario de tablas críticas
CREATE EVENT evt_backup_critical_tables_daily
ON SCHEDULE EVERY 1 DAY
DO
  CALL backup_tablas_criticas();

-- 14. Limpia carritos abandonados hace más de 72 horas
CREATE EVENT evt_clear_abandoned_carts_daily
ON SCHEDULE EVERY 1 DAY
DO
  DELETE FROM carritos WHERE TIMESTAMPDIFF(HOUR, fecha_creacion, NOW()) > 72;

-- 15. Calcula KPIs mensuales
CREATE EVENT evt_calculate_monthly_kpis
ON SCHEDULE EVERY 1 MONTH
DO
  CALL calcular_kpis_mensuales();

-- 16. Refresca vistas materializadas cada noche
CREATE EVENT evt_refresh_materialized_views_nightly
ON SCHEDULE EVERY 1 DAY
DO
  CALL refrescar_vistas_materializadas();

-- 17. Registra tamaño de la base de datos semanalmente
CREATE EVENT evt_log_database_size_weekly
ON SCHEDULE EVERY 1 WEEK
DO
  INSERT INTO log_tamano_bd (fecha, tamano_mb)
  SELECT NOW(), SUM(data_length + index_length) / 1024 / 1024
  FROM information_schema.tables
  WHERE table_schema = DATABASE();

-- 18. Detecta posibles fraudes (pedidos fallidos repetidos)
CREATE EVENT evt_detect_fraudulent_activity_hourly
ON SCHEDULE EVERY 1 HOUR
DO
  INSERT INTO alertas_fraude (id_cliente, fecha)
  SELECT id_cliente, NOW()
  FROM pedidos
  WHERE estado = 'fallido'
  GROUP BY id_cliente
  HAVING COUNT(*) >= 3;

-- 19. Genera reporte mensual de desempeño de proveedores
CREATE EVENT evt_generate_supplier_performance_report_monthly
ON SCHEDULE EVERY 1 MONTH
DO
  INSERT INTO reporte_proveedores (id_proveedor, fecha, total_compras)
  SELECT id_proveedor, NOW(), SUM(total)
  FROM compras
  WHERE fecha >= DATE_SUB(NOW(), INTERVAL 1 MONTH)
  GROUP BY id_proveedor;

-- 20. Elimina registros "borrados lógicamente" hace más de 30 días
CREATE EVENT evt_purge_soft_deleted_records_weekly
ON SCHEDULE EVERY 1 WEEK
DO
  DELETE FROM clientes WHERE eliminado = 1 AND fecha_eliminacion < DATE_SUB(NOW(), INTERVAL 30 DAY);

