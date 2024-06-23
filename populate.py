## IMPORTAR LIBRERIAS
import os
from dotenv import load_dotenv
import psycopg2
import psycopg2.extras
import functions 


## CONFIGURACION
load_dotenv() # cargar variables de entorno

## CONEXION A LA BASE DE DATOS
dbname = os.getenv("DBNAME") # obtener parametros de conexión
user = os.getenv("DBUSER")
password = os.getenv("PASSWORD")
host = os.getenv("HOST")
port = os.getenv("PORT")

try: # verificar valores de las variables de entorno
    print(f"DBNAME: {dbname}")
    print(f"DBUSER: {user}")
    print(f"HOST: {host}")
    print(f"PORT: {port}")
    
    conn = psycopg2.connect(dbname=dbname, user=user, password=password, host=host, port=port) # conectar a la base de datos
    print("Successful connection to the PostgreSQL database")
    cursor = conn.cursor()  # cursor para ejecutar consultas SQL

    cursor.execute("SELECT 1") # ejecutar consulta de prueba para verificar la conexion
    row = cursor.fetchone()
    print("Success: The test query was successful", row)    
except Exception as e:
    print(f"Error connecting to the database: {e}")
    exit(1)

## JOB PARA POBLAR LA BASE DE DATOS
num_customers = 50000 # definir el volumen de data dummie
num_items = 250000
num_orders = 100000

functions.populate_customers(num_customers, cursor) # llamar las funciones para poblar la base de datos
functions.populate_categories(cursor)
functions.populate_items(num_items, cursor)
functions.populate_orders(num_orders, cursor)

conn.commit() # enviar los cambios y cerrar la conexion
cursor.close()
conn.close()
