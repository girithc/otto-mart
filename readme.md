# GO API REPO SAMPLE

https://github.com/anthdm/gobank/blob/master/storage.go

# GO POSTGRES LIB/PQ SAMPLE

https://www.calhoun.io/querying-for-a-single-record-using-gos-database-sql-package/

# Google Cloud Storage

https://cloud.google.com/blog/products/storage-data-transfer/uploading-images-directly-to-cloud-storage-by-using-signed-url

## GCP Command

gcloud init
gcloud auth application-default login

# Schema - Postgresql

-- Create the Store table (same as before)
CREATE TABLE Store (
id SERIAL PRIMARY KEY,
name VARCHAR(100) NOT NULL,
address VARCHAR(200) NOT NULL,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
created_by INT
);

-- Create the Higher_Level_Category table
CREATE TABLE Higher_Level_Category (
id SERIAL PRIMARY KEY,
name VARCHAR(100) NOT NULL,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
created_by INT
);

-- Create the Category table
CREATE TABLE Category (
id SERIAL PRIMARY KEY,
name VARCHAR(100) NOT NULL,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
created_by INT
);

-- Create the Category_Higher_Level_Mapping table to represent the many-to-many relationship
CREATE TABLE Category_Higher_Level_Mapping (
id SERIAL PRIMARY KEY,
higher_level_category_id INT REFERENCES Higher_Level_Category(higher_level_category_id) ON DELETE CASCADE,
category_id INT REFERENCES Category(category_id) ON DELETE CASCADE,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
created_by INT
);

-- Create the Item table with stock_quantity field and reference to the Category
CREATE TABLE Item (
id SERIAL PRIMARY KEY,
name VARCHAR(100) NOT NULL,
price DECIMAL(10, 2) NOT NULL,
store_id INT REFERENCES Store(store_id) ON DELETE CASCADE,
category_id INT REFERENCES Category(category_id) ON DELETE CASCADE,
stock_quantity INT NOT NULL,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
created_by INT
);

-- Create the Customer table (same as before)
CREATE TABLE Customer (
id SERIAL PRIMARY KEY,
name VARCHAR(100) NOT NULL,
email VARCHAR(100),
phone_number VARCHAR(10),
address VARCHAR(200)
);

-- Create the Shopping_Cart table (same as before)
CREATE TABLE Shopping_Cart (
id SERIAL PRIMARY KEY,
customer_id INT REFERENCES Customer(customer_id) ON DELETE CASCADE
);

-- Create the Cart_Item table (same as before)
CREATE TABLE Cart_Item (
id SERIAL PRIMARY KEY,
cart_id INT REFERENCES Shopping_Cart(cart_id) ON DELETE CASCADE,
item_id INT REFERENCES Item(item_id) ON DELETE CASCADE,
quantity INT NOT NULL
);
