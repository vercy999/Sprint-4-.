#Nivell 1
#Descàrrega els arxius CSV, estudia'ls i dissenya una base de dades amb un esquema d'estrella que contingui,
#almenys 4 taules de les quals puguis realitzar les següents consultes:

CREATE DATABASE IF NOT EXISTS salesb;
USE salesb;

#he cambiado el formato fecha a varchar porque estan en diferentes formatos, el user id a varchar y el id a varchar y ya no me da error 
CREATE TABLE credit_cards (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50),
    iban VARCHAR(100),
    pan VARCHAR(100),
    pin VARCHAR(100),
    cvv VARCHAR(100),
	track1 TEXT,
    track2 TEXT,
    expiring_date VARCHAR(50)
);

 set global local_infile = "on" ;

#cambios : cambié el slash de direccion y ahora ya me permite acceder a los archivos , si el slash está para el otro lado (izquierdo) no te deja acceder a los archivos )
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/credit_cards.csv'
 INTO TABLE credit_cards 
 FIELDS TERMINATED BY ',' 
 ENCLOSED BY '"' 
 LINES TERMINATED BY '\n'
 IGNORE 1 LINES; 
  
 SELECT * FROM credit_cards;
 

 USE salesb;
 CREATE TABLE transactions(
    id VARCHAR(100) PRIMARY KEY,
    card_id VARCHAR(100),
	business_id VARCHAR(100),
    timestamp TIMESTAMP,
	amount DECIMAL(10, 2),
    declined  BOOLEAN,
	product_ids TEXT,
    user_id TEXT,
    lat FLOAT,
    longitude FLOAT
);
 
  set global local_infile = "on" ;
  
  
  SET SESSION SQL_MODE='ALLOW_INVALID_DATES';

  
 LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions.csv'
 INTO TABLE transactions 
 FIELDS TERMINATED BY ';' 
 ENCLOSED BY '"' 
 LINES TERMINATED BY  '\n'
  IGNORE 1 LINES;
 

  #me da error en el timestamp y lo he camniado a varchar 

USE salesb;
    
 CREATE TABLE companies(
   company_id VARCHAR(100) PRIMARY KEY,
    company_name VARCHAR(100),
	email VARCHAR(100),
   phone VARCHAR(100),
   country VARCHAR(100),
   website VARCHAR(100)

);
 
  set global local_infile = "on" ;
  
  
  SET SESSION SQL_MODE='ALLOW_INVALID_DATES';

  
 LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/companies.csv'
 INTO TABLE companies
 FIELDS TERMINATED BY ',' 
 ENCLOSED BY '"' 
 LINES TERMINATED BY '\n'
 IGNORE 1 LINES ;

USE salesb;
 
 CREATE TABLE users(
	id INT PRIMARY KEY, 
	name VARCHAR(100),
	surname VARCHAR(100),
	phone VARCHAR(100),
	email VARCHAR(100),
	birth_date VARCHAR(50) , 
	country VARCHAR(100),
	city VARCHAR(100),
	postal_code VARCHAR(100),
	address VARCHAR(100)
);
 


  set global local_infile = "on" ;
  
  
  #SET SESSION SQL_MODE='ALLOW_INVALID_DATES';

  
 LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_usa.csv'
 INTO TABLE users
 FIELDS TERMINATED BY ',' 
 ENCLOSED BY '"' 
 LINES TERMINATED BY '\r\n'
 IGNORE 1 LINES ;
 
  LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_ca.csv'
 INTO TABLE users
 FIELDS TERMINATED BY ',' 
 ENCLOSED BY '"' 
 LINES TERMINATED BY '\r\n'
 IGNORE 1 LINES ;
 
  LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_uk.csv'
 INTO TABLE users
 FIELDS TERMINATED BY ',' 
 ENCLOSED BY '"' 
 LINES TERMINATED BY '\r\n'
 IGNORE 1 LINES ;
 

  select user_id from transactions ;
  select id from users ;
  #revison para saber si en transactions el userd_id q es texto , concuerda con el id de users q es int
  

  #añado las foreig keys 

ALTER TABLE transactions ADD CONSTRAINT fk_card_id FOREIGN KEY (card_id) REFERENCES credit_cards(id);
ALTER TABLE transactions ADD CONSTRAINT fk_business_id FOREIGN KEY (business_id) REFERENCES companies(company_id);
ALTER TABLE transactions MODIFY COLUMN user_id INT;
ALTER TABLE transactions ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES users(id);
CREATE INDEX idx_declined ON transactions(declined);


  #revison para saber si en transactions el userd_id q es texto , concuerda con el id de users q es int
  
  select transactions.user_id , users.id as user_id_from_users
  from users
  join transactions  on users.id = transactions.user_id ;  
  




#- Exercici 1
#Realitza una subconsulta que mostri tots els usuaris amb més de 30 transaccions utilitzant almenys 2 taules.

SELECT * FROM (
    SELECT 
        u.id,
        u.name,
        u.surname,
        COUNT(t.id) AS total_transactions
    FROM
        USERS u
    INNER JOIN
        TRANSACTIONS t ON u.id = t.user_id
    GROUP BY
        u.id
) AS user_transactions
WHERE
    user_transactions.total_transactions > 30;



 #- Exercici 2
#Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd, utilitza almenys 2 taules.
SELECT cc.iban, AVG(t.amount) AS average_amount
FROM credit_cards cc
JOIN transactions t ON cc.id = t.card_id
JOIN companies c ON t.business_id = c.company_id
WHERE c.company_name = 'Donec Ltd'
GROUP BY cc.iban;


#Nivell 2
#Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat en si les últimes tres transaccions van ser declinades i genera la següent consulta:
#Exercici 1
#Quantes targetes estan actives?


-- Crear la tabla credit_card_status
CREATE TABLE credit_card_status (
    card_id VARCHAR(100) PRIMARY KEY,
    last_three_transactions_declined BOOLEAN
);

-- Inserto datos en la tabla credit_card_status
INSERT INTO credit_card_status (card_id, last_three_transactions_declined)
SELECT 
    card_id,
    COUNT(CASE WHEN declined = 1 THEN 1 END) >= 3 AS last_three_transactions_declined
FROM 
    transactions
GROUP BY 
    card_id;

#aqui el resultado indica que no hay una trajeta rechazada mas de tres veces 
SELECT COUNT(*) 
FROM (
    SELECT COUNT(*) AS count_by_card_id
    FROM Credit_Card_Status
    WHERE last_three_transactions_declined = TRUE
    GROUP BY card_id
    HAVING COUNT(*) >= 3
) AS counts;

#cuantas tarjetas estan activas ? estan todas activas 
SELECT COUNT(*) AS total_active_cards 
FROM Credit_Card_Status 
WHERE  last_three_transactions_declined = FALSE;
#hasta aqui esta bien 

#Nivell 3
#Crea una taula amb la qual puguem unir les dades del nou arxiu products.csv amb la base de dades creada,
# tenint en compte que des de transaction tens product_ids. Genera la següent consulta:
#Exercici 1
#Necessitem conèixer el nombre de vegades que s'ha venut cada producte.

use salesb;
CREATE TABLE products (
    id varchar (100)  PRIMARY KEY,
    product_name VARCHAR(100),
    price DECIMAL(10, 2),
    colour VARCHAR(50),
    weight DECIMAL(10, 2),
    warehouse_id VARCHAR (100)
);



  set global local_infile = "on" ;
#UPDATE products
#SET price = CAST(price AS DECIMAL(10, 2));


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@id, @product_name, @price ,@colour,@weight,@warehouse_id )  -- Definir variables para las columnas
SET
    id = @id,
    product_name = @product_name,
    price = REPLACE(@price, '$', ''),
    colour =  @colour,
    weight = @weight,
    warehouse_id = @warehouse_id
    ;  -- Eliminar el símbolo "$" de la columna price

ALTER TABLE transactions ADD CONSTRAINT fk_product_ids FOREIGN KEY (product_ids) REFERENCES product(id);

SELECT transactions.product_ids AS id_prom_product, products.id AS id_product, transactions.id
FROM sales.products
JOIN transactions ON products.id = transactions.product_ids;


 #aqui hago un error porque no me cuenta todos los productos vendidos si no que señala todos los que hay por transaccion 1 a uno 
 #primera prueba
SELECT 
    p.id,
    p.product_name,t.id,
    COUNT(*) AS times_sold
FROM 
    Transactions t
JOIN 
    Products p ON FIND_IN_SET(p.id, t.product_ids) > 0
GROUP BY 
    p.id, p.product_name,t.id;
    
    #segunda prueba 
   SELECT 
    p.id,t.id,
    COUNT(*) AS times_sold
FROM 
    Transactions t
JOIN 
    Products p ON FIND_IN_SET(p.id, t.product_ids) > 0
GROUP BY 
    p.id, t.id; 
    
    
    #tercera  prueba 
       
    SELECT 
    t.product_ids,p.id,t.id,
    COUNT(*) AS times_sold
FROM 
    transactions t
JOIN 
    products p ON p.id = t.product_ids
GROUP BY 
    p.id,t.id, t.product_ids; 

#cuarta prueba 
     SELECT 
        t.product_ids,p.product_name,
    COUNT(*) AS times_sold
FROM 
    transactions t
JOIN 
    products p ON p.id = t.product_ids
GROUP BY 
    p.product_name,  t.product_ids; 
    
  