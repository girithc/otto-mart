# Details

Date : 2023-10-17 13:10:38

Directory /Users/girithc/work/pronto-go

Total : 55 files,  4530 codes, 218 comments, 1007 blanks, all 5755 lines

[Summary](results.md) / Details / [Diff Summary](diff.md) / [Diff Details](diff-details.md)

## Files
| filename | language | code | comment | blank | total |
| :--- | :--- | ---: | ---: | ---: | ---: |
| [.env](/.env) | Properties | 3 | 0 | 0 | 3 |
| [api/handle-address.go](/api/handle-address.go) | Go | 31 | 0 | 9 | 40 |
| [api/handle-brand.go](/api/handle-brand.go) | Go | 32 | 0 | 11 | 43 |
| [api/handle-cancel-checkout.go](/api/handle-cancel-checkout.go) | Go | 28 | 0 | 9 | 37 |
| [api/handle-cart-item.go](/api/handle-cart-item.go) | Go | 79 | 1 | 19 | 99 |
| [api/handle-category-higher-level-mapping.go](/api/handle-category-higher-level-mapping.go) | Go | 76 | 0 | 21 | 97 |
| [api/handle-category.go](/api/handle-category.go) | Go | 90 | 2 | 22 | 114 |
| [api/handle-checkout.go](/api/handle-checkout.go) | Go | 27 | 1 | 8 | 36 |
| [api/handle-customer.go](/api/handle-customer.go) | Go | 79 | 9 | 26 | 114 |
| [api/handle-delivery-partner.go](/api/handle-delivery-partner.go) | Go | 78 | 8 | 22 | 108 |
| [api/handle-higher-level-category.go](/api/handle-higher-level-category.go) | Go | 60 | 0 | 17 | 77 |
| [api/handle-item.go](/api/handle-item.go) | Go | 112 | 3 | 22 | 137 |
| [api/handle-sales-order.go](/api/handle-sales-order.go) | Go | 9 | 0 | 5 | 14 |
| [api/handle-search-items.go](/api/handle-search-items.go) | Go | 20 | 0 | 8 | 28 |
| [api/handle-shopping-cart.go](/api/handle-shopping-cart.go) | Go | 26 | 0 | 9 | 35 |
| [api/handle-store.go](/api/handle-store.go) | Go | 63 | 0 | 17 | 80 |
| [api/handler.go](/api/handler.go) | Go | 357 | 59 | 119 | 535 |
| [api/server.go](/api/server.go) | Go | 57 | 1 | 22 | 80 |
| [go.mod](/go.mod) | Go Module File | 35 | 0 | 3 | 38 |
| [go.sum](/go.sum) | Go Checksum File | 304 | 0 | 1 | 305 |
| [main.go](/main.go) | Go | 33 | 0 | 10 | 43 |
| [readme.md](/readme.md) | Markdown | 36 | 0 | 10 | 46 |
| [store/store-address.go](/store/store-address.go) | Go | 91 | 8 | 20 | 119 |
| [store/store-brand.go](/store/store-brand.go) | Go | 85 | 1 | 21 | 107 |
| [store/store-cancel-checkout.go](/store/store-cancel-checkout.go) | Go | 12 | 0 | 5 | 17 |
| [store/store-cart-item.go](/store/store-cart-item.go) | Go | 258 | 17 | 52 | 327 |
| [store/store-category-higher-level-mapping.go](/store/store-category-higher-level-mapping.go) | Go | 149 | 6 | 30 | 185 |
| [store/store-category.go](/store/store-category.go) | Go | 201 | 7 | 48 | 256 |
| [store/store-checkout.go](/store/store-checkout.go) | Go | 135 | 3 | 27 | 165 |
| [store/store-customer.go](/store/store-customer.go) | Go | 114 | 7 | 31 | 152 |
| [store/store-delivery-partner.go](/store/store-delivery-partner.go) | Go | 127 | 11 | 26 | 164 |
| [store/store-higher-level-category.go](/store/store-higher-level-category.go) | Go | 156 | 7 | 37 | 200 |
| [store/store-item.go](/store/store-item.go) | Go | 441 | 30 | 78 | 549 |
| [store/store-sales-order.go](/store/store-sales-order.go) | Go | 54 | 4 | 18 | 76 |
| [store/store-search-item.go](/store/store-search-item.go) | Go | 56 | 1 | 9 | 66 |
| [store/store-shopping-cart.go](/store/store-shopping-cart.go) | Go | 101 | 4 | 23 | 128 |
| [store/store-store.go](/store/store-store.go) | Go | 117 | 2 | 33 | 152 |
| [store/store.go](/store/store.go) | Go | 144 | 18 | 31 | 193 |
| [types/address.go](/types/address.go) | Go | 29 | 0 | 5 | 34 |
| [types/brand.go](/types/brand.go) | Go | 17 | 0 | 5 | 22 |
| [types/cart-item.go](/types/cart-item.go) | Go | 45 | 0 | 10 | 55 |
| [types/category-higher-level-mapping.go](/types/category-higher-level-mapping.go) | Go | 35 | 0 | 8 | 43 |
| [types/category.go](/types/category.go) | Go | 47 | 0 | 10 | 57 |
| [types/checkout.go](/types/checkout.go) | Go | 9 | 0 | 2 | 11 |
| [types/customer.go](/types/customer.go) | Go | 46 | 1 | 10 | 57 |
| [types/delivery-partner.go](/types/delivery-partner.go) | Go | 45 | 1 | 9 | 55 |
| [types/error.go](/types/error.go) | Go | 4 | 0 | 1 | 5 |
| [types/higher-level-category.go](/types/higher-level-category.go) | Go | 36 | 0 | 8 | 44 |
| [types/item.go](/types/item.go) | Go | 117 | 2 | 10 | 129 |
| [types/sales-order.go](/types/sales-order.go) | Go | 11 | 0 | 3 | 14 |
| [types/search-item.go](/types/search-item.go) | Go | 17 | 0 | 4 | 21 |
| [types/shopping-cart.go](/types/shopping-cart.go) | Go | 23 | 0 | 6 | 29 |
| [types/store.go](/types/store.go) | Go | 37 | 0 | 9 | 46 |
| [worker/http.go](/worker/http.go) | Go | 66 | 2 | 13 | 81 |
| [worker/worker-pool.go](/worker/worker-pool.go) | Go | 70 | 2 | 15 | 87 |

[Summary](results.md) / Details / [Diff Summary](diff.md) / [Diff Details](diff-details.md)