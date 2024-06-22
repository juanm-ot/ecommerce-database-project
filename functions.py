## Importar librerias
import psycopg2
import psycopg2.extras
from faker import Faker

## Configuracion
fake = Faker() # Instancia de la clase Faker utilizada para generar datos ficticios
Faker.seed(0)  # Semilla para garantizar data reproducible para la instancia Faker

## Funciones
def populate_customers(num_records, cursor):
    """"
    Esta función genera una cantidad especificada de registros de clientes ficticios y los inserta en la tabla `ecommerce.customer`
    en la base de datos utilizando el cursor de base de datos proporcionado.

    Args:
        num_records (int): cantidad de registros de clientes ficticios a generar e insertar en la base de datos.
        cursor (psycopg2.extensions.cursor): objeto cursor de una conexión psycopg2, para ejecutar operaciones en base de datos.

    Returns:
        None
    """
    customers = []
    for _ in range(num_records):
        customers.append((
            fake.first_name(),
            fake.last_name(),
            fake.email(),
            fake.phone_number(),
            fake.address(),
            fake.random_element(elements=('Male', 'Female')),
            fake.date_of_birth(),
        ))
    
    query = """
            INSERT INTO ecommerce.customer (name, last_name, email, phone, address, gender, birth_date, created_at) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, now())
            """
    psycopg2.extras.execute_batch(cursor, query, customers)
    

def populate_categories(num_records, cursor):
    """
    Esta función genera una cantidad especificada de registros de categorías ficticias y los inserta en la tabla `ecommerce.category`
    en la base de datos utilizando el cursor de base de datos proporcionado.

    Args:
        num_records (int): cantidad de registros de categorías ficticias a generar e insertar en la base de datos.
        cursor (psycopg2.extensions.cursor): objeto cursor de una conexión psycopg2, para ejecutar operaciones en base de datos.

    Returns:
        None
    """
    categories = []
    for i in range(1, num_records + 1):
        category_id = f"CAT{i:03}"
        parent_id = f"CAT{fake.random_int(min=1, max=i-1):03}" if i > 1 else None
        categories.append((
            category_id,
            fake.word().capitalize(),
            parent_id,
            f"{category_id}/{parent_id}" if parent_id else category_id
        ))
    
    query = """
            INSERT INTO ecommerce.category (category_id, category_name, parent_id, path) 
            VALUES (%s, %s, %s, %s)
            """
    psycopg2.extras.execute_batch(cursor, query, categories)


def populate_items(num_records, cursor):
    """
    Esta función genera una cantidad especificada de registros de artículos ficticios y los inserta en la tabla `ecommerce.item`
    en la base de datos utilizando el cursor de base de datos proporcionado.

    Args:
        num_records (int): cantidad de registros de artículos ficticios a generar e insertar en la base de datos.
        cursor (psycopg2.extensions.cursor): objeto cursor de una conexión psycopg2, para ejecutar operaciones en base de datos.

    Returns:
        None
    """
    # Obtener los customer_id validos generados en la tabla customer 
    cursor.execute("SELECT customer_id FROM ecommerce.customer")
    valid_customer_ids = [row[0] for row in cursor.fetchall()]

    # Obtener los category_id validos generados en la tabla customer
    cursor.execute("SELECT category_id FROM ecommerce.category")
    valid_category_ids = [row[0] for row in cursor.fetchall()]

    items = []
    for i in range(1, num_records + 1):
        customer_id = fake.random_element(valid_customer_ids)
        category_id = fake.random_element(elements=valid_category_ids)
        prefix = fake.random_element(elements=('MCO', 'MLA'))
        
        items.append((
            customer_id,
            category_id,
            fake.random_number(digits=4, fix_len=True),
            fake.random_element(elements=('activo', 'inactivo')),
            fake.date_this_decade(),
        ))
    
    query = """
            INSERT INTO ecommerce.item (customer_id, category_id, price, status, published_date, created_at) 
            VALUES (%s, %s, %s, %s, %s, now())
            """
    psycopg2.extras.execute_batch(cursor, query, items)


def populate_orders(num_records, cursor):
    """
    Esta función genera una cantidad especificada de registros de órdenes ficticias y los inserta en la tabla `ecommerce.orders`
    en la base de datos utilizando el cursor de base de datos proporcionado.

    Args:
        num_records (int): cantidad de registros de órdenes ficticias a generar e insertar en la base de datos.
        cursor (psycopg2.extensions.cursor): objeto cursor de una conexión psycopg2, para ejecutar operaciones en base de datos.

    Returns:
        None
    """
    # Obtener los customer_id validos generados en la tabla customer
    cursor.execute("SELECT customer_id FROM ecommerce.customer")
    valid_customer_ids = [row[0] for row in cursor.fetchall()]

    cursor.execute("SELECT customer_id FROM ecommerce.item")
    valid_item_ids = [row[0] for row in cursor.fetchall()]

    orders = []
    for i in range(1, num_records + 1):
        orders.append((
            fake.random_element(valid_item_ids),
            fake.random_element(valid_customer_ids),
            fake.random_int(min=1, max=10),
            fake.date_this_year(),
        ))
    
    query = """
            INSERT INTO ecommerce.orders (item_id, customer_id, total_items, order_date) 
            VALUES (%s, %s, %s, %s)
            """
    psycopg2.extras.execute_batch(cursor, query, orders)
    