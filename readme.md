# Diseño de base de datos para ecommerce 

## Contexto de negocio

En este modelo de comercio electrónico, las siguientes entidades dirigen la estructura operativa:

1. **customer:**  representa a todos los usuarios, ya sean buyers o sellers, diferenciados por atributos. Estos atributos facilitan interacciones personalizadas con los usuarios y la gestión de ordenes.

2. **items:** conforman una entidad central dentro del modelo de negocio, abarcando todos los productos que alguna vez se han publicado. El __volumen significativo subraya__ el extenso catálogo de la plataforma, con ítems activos indicados por su estado o fecha de desactivación.

3. **categorias:** proporcionan una estructura organizativa, definiendo la clasificación de cada ítem a través de un path. Cada ítem está asociado con una categoría específica, __mejorando las funcionalidades de navegación y búsqueda__.

4. **ordenes:** reflejan las actividades transaccionales, capturando cada compra realizada. En este modelo, **cada venta se registra como una orden**, prescindiendo de un flujo de carrito de compras, lo que simplifica el proceso de compra y asegura registros transaccionales claros. En conjunto, estas entidades sustentan la plataforma de comercio electrónico, apoyando la eficiente interacción con usuarios, una amplia oferta de productos, una estructurada categorización y operaciones transaccionales transparentes.


## DER
Para diseñar la base de datos, el punto de partida fue el entendimiento del negocio. Con esto, fue posible identificar las entidades y definir los atributos para cada una. Se tuvo rigor en ***parametrizar los atributos*** desde el diseño para asegurar la calidad de los datos acogiendo una metodologia *process driven*. 

Para guiar la parametrización de atributos fue necesario seleccionar el motor de bases de datos. Fue seleccionado `PostgreSQL`, por las siguientes razones:

* **Motor open source y flexible:** Al ser de código abierto, lo respalda una comunidad que aporta innovación y conocimiento, así como la posibilidad de acceder a una amplia gama de recursos disponibles, como documentación detallada, tutoriales y foros de discusión. 
* **Escalabilidad:** Es rápido, tiene mecanismos para replicación de datos y para garantizar la alta disponibilidad. Además, tiene varias opciones de índices para ajustar los requisitos de rendimiento mientras la base de datos escala.
* **Flexibilidad:** Permite llamar a procedimientos almacenados escritos en lenguajes diferentes a SQL. También tiene muchos tipos de datos nativos que permiten modelar y almacenar los datos de manera precisa.
* La adopción que tiene en el mercado y en las grandes industrias es otro factor que incentiva a explorar y elegir este motor de bases de datos. 

Finalmente, se definieron las relaciones entre las entidades y, con la ayuda de la herramienta [dbdiagram](https://dbdiagram.io/), se construyó el DER. Esta herramienta usa DBML (Database Markup Language) para diseñar las estructuras de datos y tiene la ventaja de generar el diagrama, exportarlo en diferentes formatos y además generar el DDL para diferentes motores de bases de datos. Se referencia la [documentación de dbdiagram](https://dbml.dbdiagram.io/docs/), y en el archivo `ecommerce.dbml` se encuentra el código desarrollado que generó el DER.

![Diagrama del proyecto](https://raw.githubusercontent.com/juanm-ot/ecommerce-database-project/main/resources/project_master/ecommerce_project.png)

## DDL
Fue seleccionado **pgAdmin** como herramienta de administración y desarrollo de bases de datos PostgreSQL. Se creó una nueva base de datos que fue nombrada `transactional_core`, la cual contiene el esquema **public** por defecto, y se creó el esquema **ecommerce** para darle estructura, orden y control de acceso a las entidades a modelar.

El código exportado desde dbdiagram que generó el DDL se llevó a una herramienta de consulta de pgAdmin para crear la base de datos. Este proceso fue iterativo porque durante el diseño algunas características se omitieron, como el tipo de dato serial para los id, el tipo de dato para las variables que almacenan moneda, entre otras; hasta lograr el código que creó con éxito el esquema y las tablas. Este script se encuentra documentado en el archivo `create_tables.sql`

### Crear un usuario de conexion a la base de datos
Para garantizar la seguridad y por terminos de escalabilidad, se propone la creación un usuario de conexión dedicado a la base de datos para restringir el acceso a los datos solo a usuarios autorizados. Para el alcance de este proyecto, este usuario conecta los procesos de llenado de tablas con data dummie. El código se encuentra en el archivo `user_cnx.sql`

## Poblar la base de datos con fake data
Este proyecto propone crear datos ficticios a través de un pipeline que los ingiere en las tablas creadas. Estos datos son necesarios para desarrollar las consultas solicitadas por el ejercicio. El pipeline automatiza de forma rápida la ingestión para proveer los datos al proyecto.

Se utiliza la librería Faker de Python para generar los datos. Se referencia aquí: [documentación de Faker](https://faker.readthedocs.io/en/master/). El pipeline usa el adaptador psycopg - PostgreSQL database adapter for Python para crear la conexión y enviar las consultas a la base de datos. Se referencia aquí: [documentación del adaptador de base de datos](https://www.psycopg.org/docs/).

1. En el archivo `functions.sql` se crean las funciones para poblar las tablas del proyecto:
  * **populate_customers:** Se usan las funciones de la libreria Fake para generar los datos de acuerdo al tipo. Las funciones usadas son: first_name() para name, last_name() para name, email() para email, phone_number() para phone, address() para address, random_element() para genero asignando las opciones Femenino y Masculino y finalmente date_of_birth() para birth_date.
  ![customers](https://github.com/juanm-ot/ecommerce-database-project/blob/main/resources/project_master/customer_table.png?raw=true)
  * **populate_categories:** Se propociona una lista de categorias padre con sus respectivas categorias hijas. Por ejemplo: **Tecnologia** como categoria padre y *Celulares, Consolas y Videojuegos,Computadoras y Laptops, Accesorios Electrónicos* como categorias hijas. 
  ![category](https://github.com/juanm-ot/ecommerce-database-project/blob/main/resources/project_master/category_table.png?raw=true)
  * **populate_items:** Para crear la data de items, los campos category_id y customer_id se hacen coincidir con los datos generados en las funciones anteriores para que hagan sentidos las relaciones entre entidades; estos campos se ingestan en la nueva tabla con la funcion fake.random_element(). Se usan las funciones random_number() para el price, random_element para status asignando las opciones activo e inactivo y finalmente date_this_decade() para published_date
  ![item](https://github.com/juanm-ot/ecommerce-database-project/blob/main/resources/project_master/item_table.png?raw=true)
  * **populate_orders:** Para crear la data de orders, los campos item_id y customer_id se hacen coincidir con los datos generados en las funciones anteriores para que hagan sentidos las relaciones entre entidades; estos campos se ingestan en la nueva tabla con la funcion fake.random_element(). Se usan las funciones random_int() para total_items y finalmente date_time_between_dates() para genera el order_date estableciendo el rango de años entre 2020 y 2023.
  ![orders](https://github.com/juanm-ot/ecommerce-database-project/blob/main/resources/project_master/orders_table.png?raw=true)

2. En el archivo `populate.sql` se encarga de cargar las variables de entorno para configurar la conexion, crear la conexion a la base de datos, orquestar las funciones para ingestar la data y cerrar la conexion una vez el proceso finalice. Los parametros para el volumen de datos dummies generados para cada entidad: 

 - num_customers = 50000
 - num_items = 250000
 - num_orders = 100000

 La definición de estos volumenes busca contrastar en proporcion el gran volumen de datos asociado a la entidad items, tal como lo describe el contexto de negocio.

## Consultas a la base de datos
La data dummie generada permitio darle sentido a las querys solicitadas por el ejercicio. En una estancia inicial se adaptaron las condiciones de los ejercicio a los datos disponibles, pero sobre el entregable final se ajustaron a las condiciones solicitadas. 

Se desarrollaron tres ejercicios, almacenados en el archivo `respuestas_negocio.sql`:

1. CTE para calcular el número de ordenes por mes para cada vendedor, filtrando los que tienen > 1500 ordenes. Se filtra la subconsulta anterior segun la fecha de la orden y la fecha de cumpleaños del vendedor.
![ejercicio_1](https://github.com/juanm-ot/ecommerce-database-project/blob/main/resources/project_master/ejercicio_1.png?raw=true)
Nota: Con la data generada aleatoriamente no fue posible lograr que se cumplieran todas las condiciones para evidenciarlas en el query, entonces para efectos de este ejercicio se ignoro la cantidad de ordenes o ventas > 1500. En el codigo, si cumple con el requerimiento

2. CTE para caracterizar en terminos de volumen (total_items, total_ordenes, total_sales-$) las ventas mensuales por customer(seller) y categoria. CTE para ordenar los customers por total_sales-$ en cada mes usando una window function. Se filtra la subconsulta anterior para los customers que estan en el top 5 segun total_sales en el año 2020. 
![ejercicio_2](https://github.com/juanm-ot/ecommerce-database-project/blob/main/resources/project_master/ejercicio_2.png?raw=true)

### Análisis de costos de procesamiento
En este query, se explora el costo asociado al procesamiento utilizando la función descrita a continuación, junto con las funcionalidades disponibles en pgAdmin para este propósito, como se muestra en el análisis gráfico adjunto en la imagen.

```
 EXPLAIN ANALYZE (+query)
```
![explain_analyze_graph](https://github.com/juanm-ot/ecommerce-database-project/blob/main/resources/project_master/graph_explain.png?raw=true)

Para iniciar, se calculó el costo con la consulta propuesta, obteniendo un **cost = 10207.20**. Posteriormente, se agregaron índices a partir de las funciones críticas en la consulta, guiados por el volumen de datos y los procesos de la misma. A continuación, se muestran los índices que se probaron:

```
CREATE INDEX idx_orders_item_id ON ecommerce.orders (item_id);
CREATE INDEX idx_item_category_id ON ecommerce.item (category_id);
--CREATE INDEX idx_orders_order_date ON ecommerce.orders (order_date);
--CREATE INDEX idx_customer_id ON ecommerce.customer (customer_id);
--CREATE INDEX idx_category_name ON ecommerce.category (category_name);
```

Después de varias iteraciones, se determinó que debido al ***potencial volumen de ítems***, era crucial optimizar las consultas basadas en item_id en la tabla orders, así como las consultas que buscan ítems usando category_id como referencia (índices no comentados en el código anterior). Esta optimización resultó en un **cost = 7242.66**, lo cual demostró la efectividad de los índices y subrayó la importancia de considerarlos en el diseño del sistema gracias a una optimización del 29,06% asociada a la reducción del costo de procesamiento.

![query_plan](https://github.com/juanm-ot/ecommerce-database-project/blob/main/resources/project_master/query_plan.png?raw=true)

3. Creación de la tabla ecommerce.historical_item_daily_snapshot, desarrollo del procedimiento(SP) almacenado populate_item_daily_snapshot y verificación de su funcionamiento. Este ejercicio esta ampliamente documentado la seccion **Ejercicio 3** del archivo `respuestas_negocio.sql`


## Estructura repositorio

```linux

.
├── readme.md                          # descripción del repositorio
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
└── requirements.txt                   

```

## Adecuación del ambiente de trabajo

```
Prerrequisitos:

- PostgreSQL
- Python >= 3.7 
- Git/git bash 
```

1. Abrir una terminal de git bash
2. Otorgar permisos para la ejecución del archivo .sh con el comando `chmod +x run.sh`
![Step 2](https://github.com/juanm-ot/ecommerce-database-project/blob/main/resources/set_up_environment/2.png?raw=true)
3. Modificar el archivo **run.sh** e incluir en la linea 4 la ruta a la instalación de PostgreSQL en el sistema. Para el caso de este ambiente es: `"C:\Program Files\PostgreSQL\16\bin\psql.exe"`
4. Editar el archivo **.env** con los datos necesarios para conectar el bash como administrador al servidor local de base de datos. Esto permitirá la creación de la base de datos y su esquema. Además modificar el puerto y el host si es necesario.
5. Correr el archivo .sh con el comando `./run.sh`
![Step 5](https://github.com/juanm-ot/ecommerce-database-project/blob/main/resources/set_up_environment/5.png?raw=true)
