# Details

Date : 2024-01-08 22:25:24

Directory /Users/girithc/work/pronto-go

Total : 75 files,  8928 codes, 643 comments, 1949 blanks, all 11520 lines

[Summary](results.md) / Details / [Diff Summary](diff.md) / [Diff Details](diff-details.md)

## Files
| filename | language | code | comment | blank | total |
| :--- | :--- | ---: | ---: | ---: | ---: |
| [.env](/.env) | Properties | 3 | 0 | 0 | 3 |
| [api/handle-address.go](/api/handle-address.go) | Go | 68 | 0 | 19 | 87 |
| [api/handle-brand.go](/api/handle-brand.go) | Go | 39 | 0 | 15 | 54 |
| [api/handle-cancel-checkout.go](/api/handle-cancel-checkout.go) | Go | 29 | 0 | 7 | 36 |
| [api/handle-cart-item.go](/api/handle-cart-item.go) | Go | 83 | 1 | 20 | 104 |
| [api/handle-category-higher-level-mapping.go](/api/handle-category-higher-level-mapping.go) | Go | 76 | 0 | 21 | 97 |
| [api/handle-category.go](/api/handle-category.go) | Go | 97 | 2 | 28 | 127 |
| [api/handle-checkout.go](/api/handle-checkout.go) | Go | 44 | 0 | 16 | 60 |
| [api/handle-cloud-task.go](/api/handle-cloud-task.go) | Go | 26 | 3 | 7 | 36 |
| [api/handle-customer.go](/api/handle-customer.go) | Go | 119 | 12 | 37 | 168 |
| [api/handle-delivery-partner.go](/api/handle-delivery-partner.go) | Go | 108 | 9 | 31 | 148 |
| [api/handle-higher-level-category.go](/api/handle-higher-level-category.go) | Go | 60 | 0 | 17 | 77 |
| [api/handle-item-store.go](/api/handle-item-store.go) | Go | 31 | 0 | 9 | 40 |
| [api/handle-item-update.go](/api/handle-item-update.go) | Go | 49 | 6 | 14 | 69 |
| [api/handle-item.go](/api/handle-item.go) | Go | 151 | 5 | 31 | 187 |
| [api/handle-packer.go](/api/handle-packer.go) | Go | 20 | 2 | 9 | 31 |
| [api/handle-payment-verify.go](/api/handle-payment-verify.go) | Go | 20 | 0 | 6 | 26 |
| [api/handle-phonepe.go](/api/handle-phonepe.go) | Go | 52 | 0 | 17 | 69 |
| [api/handle-sales-order.go](/api/handle-sales-order.go) | Go | 177 | 0 | 45 | 222 |
| [api/handle-search-items.go](/api/handle-search-items.go) | Go | 20 | 0 | 8 | 28 |
| [api/handle-shelf.go](/api/handle-shelf.go) | Go | 35 | 3 | 13 | 51 |
| [api/handle-shopping-cart.go](/api/handle-shopping-cart.go) | Go | 26 | 0 | 9 | 35 |
| [api/handle-store.go](/api/handle-store.go) | Go | 63 | 0 | 17 | 80 |
| [api/handler.go](/api/handler.go) | Go | 980 | 158 | 297 | 1,435 |
| [api/server.go](/api/server.go) | Go | 87 | 3 | 31 | 121 |
| [go.mod](/go.mod) | Go Module File | 42 | 0 | 4 | 46 |
| [go.sum](/go.sum) | Go Checksum File | 335 | 0 | 1 | 336 |
| [main.go](/main.go) | Go | 33 | 0 | 10 | 43 |
| [readme.md](/readme.md) | Markdown | 56 | 0 | 11 | 67 |
| [store/store-address.go](/store/store-address.go) | Go | 173 | 21 | 39 | 233 |
| [store/store-brand.go](/store/store-brand.go) | Go | 109 | 2 | 27 | 138 |
| [store/store-cancel-checkout.go](/store/store-cancel-checkout.go) | Go | 79 | 5 | 16 | 100 |
| [store/store-cart-item.go](/store/store-cart-item.go) | Go | 326 | 21 | 67 | 414 |
| [store/store-cart-lock.go](/store/store-cart-lock.go) | Go | 70 | 6 | 14 | 90 |
| [store/store-category-higher-level-mapping.go](/store/store-category-higher-level-mapping.go) | Go | 157 | 6 | 33 | 196 |
| [store/store-category.go](/store/store-category.go) | Go | 233 | 10 | 55 | 298 |
| [store/store-checkout.go](/store/store-checkout.go) | Go | 286 | 24 | 60 | 370 |
| [store/store-cloud-task.go](/store/store-cloud-task.go) | Go | 77 | 10 | 18 | 105 |
| [store/store-customer.go](/store/store-customer.go) | Go | 221 | 21 | 55 | 297 |
| [store/store-delivery-partner.go](/store/store-delivery-partner.go) | Go | 277 | 24 | 53 | 354 |
| [store/store-higher-level-category.go](/store/store-higher-level-category.go) | Go | 164 | 7 | 38 | 209 |
| [store/store-item-store.go](/store/store-item-store.go) | Go | 77 | 1 | 13 | 91 |
| [store/store-item.go](/store/store-item.go) | Go | 736 | 73 | 140 | 949 |
| [store/store-pack-item.go](/store/store-pack-item.go) | Go | 151 | 11 | 25 | 187 |
| [store/store-packer-shelf.go](/store/store-packer-shelf.go) | Go | 42 | 0 | 8 | 50 |
| [store/store-packer.go](/store/store-packer.go) | Go | 103 | 11 | 22 | 136 |
| [store/store-phonepe.go](/store/store-phonepe.go) | Go | 341 | 65 | 67 | 473 |
| [store/store-sales-order.go](/store/store-sales-order.go) | Go | 662 | 55 | 110 | 827 |
| [store/store-search-item.go](/store/store-search-item.go) | Go | 64 | 0 | 11 | 75 |
| [store/store-shelf.go](/store/store-shelf.go) | Go | 57 | 16 | 15 | 88 |
| [store/store-shopping-cart.go](/store/store-shopping-cart.go) | Go | 194 | 11 | 36 | 241 |
| [store/store-store.go](/store/store-store.go) | Go | 117 | 2 | 33 | 152 |
| [store/store-transaction.go](/store/store-transaction.go) | Go | 90 | 10 | 17 | 117 |
| [store/store.go](/store/store.go) | Go | 182 | 18 | 40 | 240 |
| [types/address.go](/types/address.go) | Go | 39 | 0 | 7 | 46 |
| [types/brand.go](/types/brand.go) | Go | 17 | 0 | 5 | 22 |
| [types/cart-item.go](/types/cart-item.go) | Go | 66 | 0 | 11 | 77 |
| [types/category-higher-level-mapping.go](/types/category-higher-level-mapping.go) | Go | 35 | 0 | 8 | 43 |
| [types/category.go](/types/category.go) | Go | 47 | 0 | 10 | 57 |
| [types/checkout.go](/types/checkout.go) | Go | 13 | 0 | 4 | 17 |
| [types/customer.go](/types/customer.go) | Go | 60 | 1 | 12 | 73 |
| [types/delivery-partner.go](/types/delivery-partner.go) | Go | 53 | 1 | 10 | 64 |
| [types/error.go](/types/error.go) | Go | 4 | 0 | 1 | 5 |
| [types/higher-level-category.go](/types/higher-level-category.go) | Go | 36 | 0 | 8 | 44 |
| [types/item-store.go](/types/item-store.go) | Go | 8 | 0 | 3 | 11 |
| [types/item-update.go](/types/item-update.go) | Go | 12 | 0 | 4 | 16 |
| [types/item.go](/types/item.go) | Go | 172 | 2 | 14 | 188 |
| [types/phonepe.go](/types/phonepe.go) | Go | 99 | 1 | 20 | 120 |
| [types/sales-order.go](/types/sales-order.go) | Go | 127 | 0 | 20 | 147 |
| [types/search-item.go](/types/search-item.go) | Go | 17 | 0 | 4 | 21 |
| [types/shelf.go](/types/shelf.go) | Go | 10 | 0 | 3 | 13 |
| [types/shopping-cart.go](/types/shopping-cart.go) | Go | 23 | 0 | 6 | 29 |
| [types/store.go](/types/store.go) | Go | 37 | 0 | 9 | 46 |
| [worker/http.go](/worker/http.go) | Go | 66 | 2 | 13 | 81 |
| [worker/worker-pool.go](/worker/worker-pool.go) | Go | 70 | 2 | 15 | 87 |

[Summary](results.md) / Details / [Diff Summary](diff.md) / [Diff Details](diff-details.md)