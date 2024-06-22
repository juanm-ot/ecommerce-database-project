## Importar librerias 
import os
from dotenv import load_dotenv
import psycopg2
import psycopg2.extras
import functions 

## Cargar las variables de entorno
load_dotenv()

## Obtener los parámetros de conexión a la base de datos desde las variables de entorno
dbname = os.getenv("DBNAME")
user = os.getenv("DBUSER")
password = os.getenv("PASSWORD")
host = os.getenv("HOST")
port = os.getenv("PORT")

try:
    # Verificar valores de las variables de entorno
    print(f"DBNAME: {dbname}")
    print(f"DBUSER: {user}")
    print(f"HOST: {host}")
    print(f"PORT: {port}")

    # Conectar a la base de datos PostgreSQL
    conn = psycopg2.connect(dbname=dbname, user=user, password=password, host=host, port=port)
    print("******Successful connection******")
    
    # Crear un cursor para ejecutar consultas SQL
    cursor = conn.cursor()

    # Ejecutar una prueba simple de consulta para verificar la conexión
    cursor.execute("SELECT 1")
    row = cursor.fetchone()
    print("Successful test query:", row)
    
except Exception as e:
    print(f"Error connecting to the database: {e}")
    exit(1)


# Definir el numero de datos a generar
num_customers = 1000
num_categories = 100
num_items = 5000
num_orders = 12000

# Llamar a las funciones para poblar las tablas creadas
functions.populate_customers(num_customers, cursor)
functions.populate_categories(num_categories, cursor)
functions.populate_items(num_items, cursor)
functions.populate_orders(num_orders, cursor)

# Enviar los cambios y cerrar la conexion
conn.commit()
cursor.close()
conn.close()
