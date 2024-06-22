# Diseño de base de datos para ecommerce 

En este modelo de comercio electrónico, las siguientes entidades dirigen la estructura operativa:

1. **customer:**  representa a todos los usuarios, ya sean buyers o sellers, diferenciados por atributos. Estos atributos facilitan interacciones personalizadas con los usuarios y la gestión de ordenes.

2. **items:** conforman una entidad central dentro del modelo de negocio, abarcando todos los productos que alguna vez se han publicado. El __volumen significativo subraya__ el extenso catálogo de la plataforma, con ítems activos indicados por su estado o fecha de desactivación.

3. **categorias:** proporcionan una estructura organizativa, definiendo la clasificación de cada ítem a través de un path. Cada ítem está asociado con una categoría específica, __mejorando las funcionalidades de navegación y búsqueda__.

4. **ordenes:** reflejan las actividades transaccionales, capturando cada compra realizada. En este modelo, **cada venta se registra como una orden**, prescindiendo de un flujo de carrito de compras, lo que simplifica el proceso de compra y asegura registros transaccionales claros. En conjunto, estas entidades sustentan la plataforma de comercio electrónico, apoyando la eficiente interacción con usuarios, una amplia oferta de productos, una estructurada categorización y operaciones transaccionales transparentes.


## DER
Para diseñar la base de datos, el punto de partida fue el entendimiento del negocio. Con esto, fue posible identificar las entidades y definir los atributos para cada una. Se tuvo rigor en *parametrizar los atributos* desde el diseño para asegurar la calidad de los datos acogiendo una metodologia process driven. 

Para guiar la parametrizacion de atributos fue necesario seleccionar el motor de bases de datos. Fue seleccionado `PostgreSQL`, por las siguientes razones:

* **Motor open source y flexible:** Como no tiene intereses comerciales, tiene la fuerza de una comunidad que aporta innovacion y conocimiento, asi como acceder a amplia gama de recursos disponibles, como documentación detallada, tutoriales y foros de discusión. 
* **Escalabilidad:** Es rapida,tiene mecanismos para replicacion de datos y para la alta disponibilidad. Ademas tiene muchas opciones de indices para justar los requisitos de rendimiendo mientras que la base de datos escala
* **Flexibilidad:** Permite llamar a procedimientos almacenados escritos en lenguajes diferentes a SQL, tambien tiene muchos tipos de datos nativos que permiten modelar y almacenar la data de manera precisa
* La adopcion que tiene en el mercado y en las grandes industrias es otro factor que incentiva a explorar y elegir este motor de bases de datos. 

Finalmente, se definieron las relaciones entre las entidades y con la ayuda de la herramienta https://dbdiagram.io/ se construyo el DER. Esta herramienta usa DBML (database markup language) para diseñar las estructuras de datos y tiene la bondad de generar el diagram a, exportarlo en diferentes formatos y ademas generar el DDL para diferentes motores de bases de datos. Se referencia aca: https://dbml.dbdiagram.io/docs/, la documentación de la herramienta y en el archivo `ecommerce.dbml` se encuentra el codigo desarrollado que generó el DER

[![ecommerce-project.png](https://i.postimg.cc/Px9G0gKf/ecommerce-project.png)](https://postimg.cc/xJvFzFWB)


## DDL
Fue seleccionado **pgAdmin** como herramienta de administración y desarrollo de bases de datos PostgreSQL. Se creo una nueva base de datos que fue nombrada `transactional_core` que contiene el schema publico por defecto, y  se creo el schema  `ecommerce` para darle estructura, orden y control de acceso a las entidades a modelar. 

El codigo exportado desde dbdiagram que genero el DDL, se llevo a un query tool de pgadmin para crear la base de datos. Este proceso fue iterativo porque durante al diseño algunas carateristicas se escaparon como el tipo de dato serial para los id, el tipo de dato para las variables que almacenan moneda, entre otras; hasta lograr el codigo que creo con exito el esquema y las tablas. Este script se encuentra documentado en el archivo `create_tables.sql`

### Crear un usuario de conexion a la base de datos
Para garantizar la seguridad y por terminos de escalabilidad, se propone la creación un usuario de conexión dedicado a la base de datos para restringir el acceso a los datos solo a usuarios autorizados. Para el alcance de este proyecto, este usuario conecta los procesos de llenados de tablas con data dummie. El codigo se encuentra en el archivo `user_cnx.sql`

## Poblar la base de datos con fake data
Este proyecto propone crear data dummie a traves de un pipeline que la ingeste a las tablas creadas, esta data es necesaria para desarrollar las consultas solicitadas por el ejercicio. El pipeline automatiza de forma rapida la ingestion para proveer los datos al proyecto. 

Se utiliza la libreria faker de python para generar la data. Se referencia aca: https://faker.readthedocs.io/en/master/ la documentación del servicio. El pipeline usa el adaptador psycopg - PostgreSQL database adapter for Python para crear la conexion y enviar los querys a la base de datos. Se referencia aca: https://www.psycopg.org/docs/ la documentación del database adapter. 

En el archivo `functions.sql` se crean las funciones populate_customers, populate_categories, populate_items y populate_orders para poblar las tablas del proyecto. Por otra parte el archivo `populate.sql` se encarga de cargar las variables de entorno para configurar la conexion, crear la conexion a la base de datos, orquestar las funciones para ingestar la data y cerrar la conexion una vez el proceso finalice.

Los parametros para el volumen de datos dummies generados para cada entidad: 

- num_customers = 1000
- num_categories = 100
- num_items = 5000
- num_orders = 12000

La definición de estos volumenes busca contrastar en proporcion el gran volumen de datos asociado a la entidad items, tal como lo describe el contexto de negocio.

La siguiente es un screenshot de la consulta a la tabla ecommerce.customer para evidenciar la data dummie generada:
[![fake-data-from-customers.png](https://i.postimg.cc/VvkftK8Q/fake-data-from-customers.png)](https://postimg.cc/Pp0nszJ2)

## Consultas a la base de datos
La data dummie generada permitio darle sentido a las querys solicitadas por el ejercicio. En una estancia inicial se adaptaron las condiciones de los ejercicio a los datos disponibles, pero sobre el entregable final se ajustaron a las condiciones solicitadas. 

Se desarrollaron tres ejercicios, almacenados en el archivo `respuestas_negocio.sql`:

1. CTE para calcular el número de ordenes por mes para cada vendedor, filtrando los que tienen > 1500 ordenes. Se filtra la subconsulta anterior segun la fecha de la orden y la fecha de cumpleaños del vendedor

2. CTE para caracterizar en terminos de volumen(total_items, total_ordenes, total_sales($)) las ventas mensuales por customer(seller) y categoria. CTE para ordenar los customer(seller) por total_sales($) en cada mes usando una window function. Se filtra la subconsulta anterior para los customers que estan en el top 5 segun total_sales en el año 2020. 

En este query compleja, se propone la exploración del costo asociado al procesamiento usando la funcion descrita a continuación junto con las funcionalidades en pgadmin para lograr este proposito, como el analyze graphical adjunto en el screenshot

```
 EXPLAIN ANALYZE (+query)
```
[![explain-graphical-ejercicio-2.png](https://i.postimg.cc/pd9CkvPq/explain-graphical-ejercicio-2.png)](https://postimg.cc/d7YGtzky)

Para iniciar se calculo el costo con la query propuesta, logrando un cost= 403,36. Posteriormente se fueron agregando index a partir de las funciones criticas en el query guiados por el volumen de datos y los procesos de la consulta. Los siguientes fueron los index que se probaron:

```
CREATE INDEX idx_orders_item_id ON ecommerce.orders (item_id);
CREATE INDEX idx_item_category_id ON ecommerce.item (category_id);
--CREATE INDEX idx_orders_order_date ON ecommerce.orders (order_date);
--CREATE INDEX idx_customer_id ON ecommerce.customer (customer_id);
--CREATE INDEX idx_category_name ON ecommerce.category (category_name);
```

Despues de las iteraciones, se logro identificar que como el volumen de items puede ser muy grande, se debe optimizar las consultas basadas en item_id en la tabla orders y optimizar tambien las consultas que buscan items teniendo como referencie el category_id. (Se refiere a los index que no estan comentados en el codigo anterior). Con esto se logro un cost = 138,11 comprobando asi la efectividad de los indices y la importancia de considerarlos en el diseño

[![queryplan-evaluation.png](https://i.postimg.cc/Qxwv3fV4/queryplan-evaluation.png)](https://postimg.cc/0bGVGdYD)

3. Creación de la tabla ecommerce.historical_item_daily_snapshot, desarrollo del procedimiento almacenado populate_item_daily_snapshot y verificación de su funcionamiento. Este ejercicio esta ampliamente documentado en su script


## Estructura repositorio

```linux

.
├── readme.md                          # descripcion del repositorio
├── .env                               # contiene las variables de entorno
├── create_tables.sql                  # script DDL 
├── ecommerce.dbml                     # script DBML para generar el DER 
├── respuestas_negocio.sql             # analisis exploratorio parte b
├── user_cnx.sql                       # contiene la confg del usuario de conexion
├── functions.py                       # funciones para poblar las tablas con fake data
├── populate.py                        # orquesta la conexion a la bd y la ingesta de datos
│
├── resources                          # carpeta para almacenar recursos de apoyo
│   └── algún-archivo
│
└── requirements.txt                   # output feture engineering

```

## Requerimientos
Si este proyecto se va a correr en el local,  se sugiere crear un ambiente virtual e instalar las dependencias necesarias desde el archivo requirements.txt

