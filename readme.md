# gcloud deploy



# Docker build

docker build -t gcr.io/hip-well-400702/myapp:version1 .

# Docker push

docker push gcr.io/hip-well-400702/myapp:version1

# Local build and deploy

export RUN_ENV=LOCAL
go run main.go

# delete db

DROP TABLE IF EXISTS
category,
category_image,
brand,
cart_item,
cart_lock,
category_higher_level_mapping,
item,
item_category,
item_store,
address,
item_image,
store,
higher_level_category,
higher_level_category_image,
customer,
delivery_partner,
delivery_order,
shopping_cart,
sales_order,
transaction,
order_timeline,
packer,
packer_item,
shelf,
packer_shelf
CASCADE;

DROP TABLE IF EXISTS
category,
category_image,
cart_item,
category_higher_level_mapping,
item,
item_category,
item_store,
item_image,
higher_level_category,
higher_level_category_image,
shopping_cart,
customer,
CASCADE;
