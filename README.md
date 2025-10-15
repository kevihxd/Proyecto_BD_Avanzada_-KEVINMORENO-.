# 🛒 Proyecto de Base de Datos para un E-commerce

---

## 📖 Descripción

Este proyecto tiene como objetivo diseñar e implementar una **base de datos completa para un sistema de comercio electrónico**.  
Permite gestionar clientes, productos, ventas, pagos, devoluciones y reportes de forma eficiente y segura.  
Incorpora **procedimientos almacenados, funciones, triggers, eventos y control de permisos**, asegurando integridad de la información y soporte para análisis de negocio.

---

## 👥 Integrantes

- Kevin Moreno  

## 📂 Archivos SQL y Descripción

| Archivo | Contenido | Comentario |
|---------|-----------|------------|
| `01_Esquema_y_Datos.sql` | `CREATE TABLE` + `INSERT INTO` | Estructura completa y datos de ejemplo. |
| `02_Consultas_Avanzadas.sql` | 20 consultas `SELECT` | Consultas de análisis y reporteo, con comentario explicativo. |
| `03_Funciones.sql` | 20 funciones `CREATE FUNCTION` | Funciones reutilizables para cálculos y validaciones. |
| `04_Seguridad.sql` | Roles, usuarios y permisos | `CREATE ROLE`, `CREATE USER`, `GRANT`. |
| `05_Triggers.sql` | Triggers de auditoría | Tabla `log_cambios_precio` + 20 triggers de control y registro. |
| `06_Eventos.sql` | Eventos programados | Tabla `reporte_ventas_semanales` + `CREATE EVENT` + activación `event_scheduler`. |
| `07_Procedimientos_Almacenados.sql` | 20 procedimientos `CREATE PROCEDURE` | Gestión de ventas, stock, clientes, pagos, reportes y operaciones críticas. |

---

## ⚙️ Instrucciones de Ejecución

Sigue este **orden** para construir y probar la base de datos correctamente:

1. **Ejecutar `01_Esquema_y_Datos.sql`**  
   - Crea la estructura de tablas y carga los datos iniciales.  

2. **Ejecutar `03_Funciones.sql`**  
   - Agrega funciones que serán usadas por procedimientos y consultas.  

3. **Ejecutar `07_Procedimientos_Almacenados.sql`**  
   - Implementa toda la lógica de negocio.  

4. **Ejecutar `05_Triggers.sql`**  
   - Registra cambios automáticos y mantiene auditoría.  

5. **Ejecutar `06_Eventos.sql`**  
   - Configura reportes automáticos.  

6. **Ejecutar `02_Consultas_Avanzadas.sql`**  
   - Prueba las consultas de análisis y reportes.  

7. **Ejecutar `04_Seguridad.sql`**  
   - Crea roles, usuarios y asigna permisos según necesidades.

> ⚠️ **Nota:** Ejecuta los archivos en este orden, ya que algunos objetos dependen de tablas, funciones y procedimientos creados en los scripts anteriores.

---
