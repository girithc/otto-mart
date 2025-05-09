# Diff Details

Date : 2024-01-08 22:25:24

Directory /Users/girithc/work/pronto-go

Total : 57 files,  4398 codes, 425 comments, 942 blanks, all 5765 lines

[Summary](results.md) / [Details](details.md) / [Diff Summary](diff.md) / Diff Details

## Files
| filename | language | code | comment | blank | total |
| :--- | :--- | ---: | ---: | ---: | ---: |
| [api/handle-address.go](/api/handle-address.go) | Go | 37 | 0 | 10 | 47 |
| [api/handle-brand.go](/api/handle-brand.go) | Go | 7 | 0 | 4 | 11 |
| [api/handle-cancel-checkout.go](/api/handle-cancel-checkout.go) | Go | 1 | 0 | -2 | -1 |
| [api/handle-cart-item.go](/api/handle-cart-item.go) | Go | 4 | 0 | 1 | 5 |
| [api/handle-category.go](/api/handle-category.go) | Go | 7 | 0 | 6 | 13 |
| [api/handle-checkout.go](/api/handle-checkout.go) | Go | 17 | -1 | 8 | 24 |
| [api/handle-cloud-task.go](/api/handle-cloud-task.go) | Go | 26 | 3 | 7 | 36 |
| [api/handle-customer.go](/api/handle-customer.go) | Go | 40 | 3 | 11 | 54 |
| [api/handle-delivery-partner.go](/api/handle-delivery-partner.go) | Go | 30 | 1 | 9 | 40 |
| [api/handle-item-store.go](/api/handle-item-store.go) | Go | 31 | 0 | 9 | 40 |
| [api/handle-item-update.go](/api/handle-item-update.go) | Go | 49 | 6 | 14 | 69 |
| [api/handle-item.go](/api/handle-item.go) | Go | 39 | 2 | 9 | 50 |
| [api/handle-packer.go](/api/handle-packer.go) | Go | 20 | 2 | 9 | 31 |
| [api/handle-payment-verify.go](/api/handle-payment-verify.go) | Go | 20 | 0 | 6 | 26 |
| [api/handle-phonepe.go](/api/handle-phonepe.go) | Go | 52 | 0 | 17 | 69 |
| [api/handle-sales-order.go](/api/handle-sales-order.go) | Go | 168 | 0 | 40 | 208 |
| [api/handle-shelf.go](/api/handle-shelf.go) | Go | 35 | 3 | 13 | 51 |
| [api/handler.go](/api/handler.go) | Go | 623 | 99 | 178 | 900 |
| [api/server.go](/api/server.go) | Go | 30 | 2 | 9 | 41 |
| [go.mod](/go.mod) | Go Module File | 7 | 0 | 1 | 8 |
| [go.sum](/go.sum) | Go Checksum File | 31 | 0 | 0 | 31 |
| [readme.md](/readme.md) | Markdown | 20 | 0 | 1 | 21 |
| [store/store-address.go](/store/store-address.go) | Go | 82 | 13 | 19 | 114 |
| [store/store-brand.go](/store/store-brand.go) | Go | 24 | 1 | 6 | 31 |
| [store/store-cancel-checkout.go](/store/store-cancel-checkout.go) | Go | 67 | 5 | 11 | 83 |
| [store/store-cart-item.go](/store/store-cart-item.go) | Go | 68 | 4 | 15 | 87 |
| [store/store-cart-lock.go](/store/store-cart-lock.go) | Go | 70 | 6 | 14 | 90 |
| [store/store-category-higher-level-mapping.go](/store/store-category-higher-level-mapping.go) | Go | 8 | 0 | 3 | 11 |
| [store/store-category.go](/store/store-category.go) | Go | 32 | 3 | 7 | 42 |
| [store/store-checkout.go](/store/store-checkout.go) | Go | 151 | 21 | 33 | 205 |
| [store/store-cloud-task.go](/store/store-cloud-task.go) | Go | 77 | 10 | 18 | 105 |
| [store/store-customer.go](/store/store-customer.go) | Go | 107 | 14 | 24 | 145 |
| [store/store-delivery-partner.go](/store/store-delivery-partner.go) | Go | 150 | 13 | 27 | 190 |
| [store/store-higher-level-category.go](/store/store-higher-level-category.go) | Go | 8 | 0 | 1 | 9 |
| [store/store-item-store.go](/store/store-item-store.go) | Go | 77 | 1 | 13 | 91 |
| [store/store-item.go](/store/store-item.go) | Go | 295 | 43 | 62 | 400 |
| [store/store-pack-item.go](/store/store-pack-item.go) | Go | 151 | 11 | 25 | 187 |
| [store/store-packer-shelf.go](/store/store-packer-shelf.go) | Go | 42 | 0 | 8 | 50 |
| [store/store-packer.go](/store/store-packer.go) | Go | 103 | 11 | 22 | 136 |
| [store/store-phonepe.go](/store/store-phonepe.go) | Go | 341 | 65 | 67 | 473 |
| [store/store-sales-order.go](/store/store-sales-order.go) | Go | 608 | 51 | 92 | 751 |
| [store/store-search-item.go](/store/store-search-item.go) | Go | 8 | -1 | 2 | 9 |
| [store/store-shelf.go](/store/store-shelf.go) | Go | 57 | 16 | 15 | 88 |
| [store/store-shopping-cart.go](/store/store-shopping-cart.go) | Go | 93 | 7 | 13 | 113 |
| [store/store-transaction.go](/store/store-transaction.go) | Go | 90 | 10 | 17 | 117 |
| [store/store.go](/store/store.go) | Go | 38 | 0 | 9 | 47 |
| [types/address.go](/types/address.go) | Go | 10 | 0 | 2 | 12 |
| [types/cart-item.go](/types/cart-item.go) | Go | 21 | 0 | 1 | 22 |
| [types/checkout.go](/types/checkout.go) | Go | 4 | 0 | 2 | 6 |
| [types/customer.go](/types/customer.go) | Go | 14 | 0 | 2 | 16 |
| [types/delivery-partner.go](/types/delivery-partner.go) | Go | 8 | 0 | 1 | 9 |
| [types/item-store.go](/types/item-store.go) | Go | 8 | 0 | 3 | 11 |
| [types/item-update.go](/types/item-update.go) | Go | 12 | 0 | 4 | 16 |
| [types/item.go](/types/item.go) | Go | 55 | 0 | 4 | 59 |
| [types/phonepe.go](/types/phonepe.go) | Go | 99 | 1 | 20 | 120 |
| [types/sales-order.go](/types/sales-order.go) | Go | 116 | 0 | 17 | 133 |
| [types/shelf.go](/types/shelf.go) | Go | 10 | 0 | 3 | 13 |

[Summary](results.md) / [Details](details.md) / [Diff Summary](diff.md) / Diff Details