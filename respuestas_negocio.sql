-- ----------------------------------------------------------------------------
-- *SECCION A RESOLVER: EJERCICIO 1
-- ----------------------------------------------------------------------------

-- (A) Subconsulta para calcular el número de ordenes por mes para cada vendedor, filtra los que tienen > 1500 ordenes
WITH orders_per_month_by_seller AS (
    SELECT
        i.customer_id AS seller_id,
        u.name,
        u.last_name,
        u.birth_date::DATE,
        DATE_TRUNC('month', o.order_date)::DATE AS month_order_date,
        COUNT(o.*) AS total_orders
    FROM ecommerce.orders AS o
    INNER JOIN ecommerce.item AS i
        ON o.item_id = i.item_id
    INNER JOIN ecommerce.customer AS u
        ON i.customer_id = u.customer_id	
    GROUP BY
            i.customer_id,
            u.name,
            u.last_name,
            u.birth_date::DATE,
            DATE_TRUNC('month', o.order_date)::DATE
    HAVING COUNT(o.*) > 1500

)

-- (B) Filtra la consulta anterior segun la fecha de la orden y la fecha de cumpleaños del vendedor
SELECT * 
FROM orders_per_month_by_seller
WHERE 
    EXTRACT(month FROM birth_date) = EXTRACT(month FROM CURRENT_DATE)
    AND EXTRACT(day FROM birth_date) = EXTRACT(day FROM CURRENT_DATE)
	AND month_order_date = '2020-01-01'::DATE





-- ----------------------------------------------------------------------------
-- *SECCION A RESOLVER: EJERCICIO 2
-- ----------------------------------------------------------------------------

-- (A) Subconsulta para caracterizar en terminos de volumen las ventas mensuales por customer(seller) y categoria
WITH monthly_sales_by_customer_per_category AS (
	SELECT
		o.customer_id,
		DATE_TRUNC('month', o.order_date)::DATE AS order_month,
		SUM(o.total_items) AS total_items,
		SUM(i.price * o.total_items) AS total_sales,
        COUNT(o.*) AS total_orders
	FROM ecommerce.orders AS o
	INNER JOIN ecommerce.item AS i
		ON o.item_id = i.item_id
	INNER JOIN ecommerce.category AS cat
		ON i.category_id = cat.category_id
	WHERE cat.category_name = 'Celulares'
	GROUP BY 
		o.customer_id,
		DATE_TRUNC('month', o.order_date)::DATE
),

-- (B) Subconsulta para ordenar los customer(seller) por total_sales($) en cada mes
ranking_sellers_by_month AS (
	SELECT
        msc.customer_id,
		c.name,
		c.last_name,
		msc.total_orders,
		msc.total_items,
		msc.total_sales,
		EXTRACT(MONTH FROM msc.order_month) AS order_month,
	    EXTRACT(YEAR FROM msc.order_month) AS order_year,
		ROW_NUMBER() OVER (PARTITION BY msc.order_month ORDER BY msc.total_sales DESC) AS user_rank
	FROM monthly_sales_by_customer_per_category AS msc
	INNER JOIN ecommerce.customer AS c
		ON msc.customer_id = c.customer_id
)
-- (C) Filtra los usuarios que estan en el top 5 segun total_sales en el año 2020
SELECT * FROM ranking_sellers_by_month 
WHERE user_rank <= 5 AND order_year = 2020





-- ----------------------------------------------------------------------------
-- *SECCION A RESOLVER: EJERCICIO 3
-- ----------------------------------------------------------------------------

-- ============================================================================
-- Tabla: ecommerce.historical_item_daily_snapshot
-- Descripción: Esta tabla almacena un registro histórico diario de los items.
--              Cada registro captura el precio y el estado de un item en una fecha específica.
-- Columnas:
--   - item_id: Identificador, permite asociar cada registro con un producto específico
--   - price: Precio del item en la fecha del registro 
--   - status: Estado del item en la fecha del registro
--   - report_date: Fecha y hora en que se registró el snapshot diario
--
-- Notas:
--   - Se agrega la linea DROP TABLE para eliminar la tabla si ya existe. Esto para 
--     evitar duplicados en el schema
-- ============================================================================
DROP TABLE IF EXISTS ecommerce.historical_item_daily_snapshot CASCADE;

CREATE TABLE ecommerce.historical_item_daily_snapshot (
    item_id VARCHAR(20),
    price NUMERIC(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    report_date TIMESTAMP NOT NULL
);

-- ============================================================================
-- Procedimiento Almacenado(SP): populate_item_daily_snapshot
-- Descripción: Este procedimiento actualiza la tabla historical_item_daily_snapshot
--              eliminando los registros existentes para la fecha de ejecucion,luego extrae la data
--              desde la tabla items e inserta los estados más recientes de cada ítem. 
--              Es reprocesable ya que si es necesario se eliminan los registros para el dia
--              y se corre el procedimiento para llenar la tabla, evitando la duplicacion de los datos.     
-- ============================================================================
CREATE OR REPLACE PROCEDURE populate_item_daily_snapshot()
LANGUAGE plpgsql
AS $$
BEGIN
	
    DELETE FROM ecommerce.historical_item_daily_snapshot
    WHERE report_date::DATE = CURRENT_DATE;

    -- (A) Se insertan los datos en la tabla historical_item_daily_snapshot desde la tabla item
    INSERT INTO ecommerce.historical_item_daily_snapshot (item_id, price, status, report_date)
    SELECT item_id, price, status, CURRENT_TIMESTAMP
    FROM (
    -- (B) Seleccionar el último estado de cada ítem basado en la PK definida
        SELECT
            item_id, 
            price, 
            status
        FROM ecommerce.item
        ORDER BY item_id, published_date DESC
    ) AS latest_items;
END $$;

-- (0) Adecuar el item de prueba
UPDATE ecommerce.item SET status = 'activo'  WHERE item_id = 3;

-- (A) Llamar una primera vez al procedimiento almacenado(SP) para que haga una primera carga
CALL populate_item_daily_snapshot();

-- (A.1) Consulta para validar que se cargo data en la tabla de historico
SELECT * FROM ecommerce.historical_item_daily_snapshot;
-- (A.2) Consulta para validar que un item 'X' tenga un unico estado asociado
SELECT * FROM ecommerce.historical_item_daily_snapshot where item_id = '3';


-- ============================================================================
-- Proceso: Verificación del Funcionamiento de populate_item_daily_snapshot
-- Descripción: Este proceso tiene como objetivo verificar el correcto funcionamiento
--              del procedimiento almacenado (SP) populate_item_daily_snapshot. Se realiza
--              la verificación de dos aspectos principales:
--              1. Que el SP esté manteniendo un histórico por días de los ítems, asegurando
--                 que los cambios en los estados de los ítems se reflejen adecuadamente.
--              2. Si se reprocesa el SP para la fecha actual, se deben actualizar 
--                 los registros del historico registrados para la fecha actual (reprocesamiento)
--
--              Para realizar esta verificación, se ejecutan los siguientes pasos:
--              - Se realiza un cambio en el estado de un ítem
--              - Se ajusta la fecha en la tabla para simular que el cambio ocurrió el dia anterior
--              - Se vuelve a llamar al SP para procesar los cambios como si fueran del día actual,
--                y se verifica que los cambios se reflejen en la tabla historical_item_daily_snapshot.
--              - Se ajusta la fecha de los datos existentes en el histórico para simular
--                que fueron procesados ayer, observando cómo el SP crea nuevos registros al no encontrar
--                datos para la fecha actual, demostrando así que mantiene el estado histórico de manera
--                adecuada.
--              - Finalmente para comprobar el reprocesamiento, se actualiza un dato en la tabla item y 
--                se invoca nuevamente el SP verificando que el dato se sobrescribio en el registro teniendo
--                en consideracion el timeframe igual.
-- ============================================================================

-- (A) Proceso para actualizar un estado en la tabla item
UPDATE ecommerce.item SET status = 'inactivo'  WHERE item_id = 3;

-- (A.1) Consulta para validar el cambio de estado tras la actualizacion
SELECT * FROM ecommerce.item where item_id =3;


-- (B) Para ver el cambio hay que procesar nuevamente el procedimiento, entonces actualizamos  
--     las fechas de hoy como si hubiesen pasaron ayer.
UPDATE ecommerce.historical_item_daily_snapshot
SET report_date = CURRENT_DATE - INTERVAL '1 day';


-- (C) Llamar al procedimiento para cargar la data con la fecha actual
CALL populate_item_daily_snapshot();

-- (C.1) Consulta para validar que se tiene varios registros para el mismo item_id
--       con los cambios asociados ingestados desde la tabla item.
SELECT * FROM ecommerce.historical_item_daily_snapshot WHERE item_id = '3';


-- (D) Se actualiza un dato asociado al item_id de prueba. Se invoca al SP para que actualice la data
UPDATE ecommerce.item SET price = 23000 WHERE item_id = 3;
UPDATE ecommerce.item SET status = 'activo'  WHERE item_id = 3;
CALL populate_item_daily_snapshot();
-- (C.1) Consulta para validar que se tienen los mismos registros para el item_id
--       con los cambios asociados al reprocesamiento del procedmiento con las actualizaciones de la tabla item.
SELECT * FROM ecommerce.historical_item_daily_snapshot WHERE item_id = '3';

