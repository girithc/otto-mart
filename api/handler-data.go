package api

// Define the Permission struct with Role and AuthRequired fields
type Permission struct {
	Role         string
	AuthRequired bool
}

// Redefine the authRequirements map to use Permission structs for values
var authRequirements = map[string]Permission{
	CustomerLoginVerify:                   {Role: "Customer", AuthRequired: false},
	CustomerGetAll:                        {Role: "Customer", AuthRequired: false},
	CustomerLoginAuto:                     {Role: "Customer", AuthRequired: false},
	PackerLogin:                           {Role: "Customer", AuthRequired: false},
	PackerGetAll:                          {Role: "Customer", AuthRequired: false},
	ShoppingCartGetAllActive:              {Role: "Customer", AuthRequired: false},
	ShoppingCartGetByCustomer:             {Role: "Customer", AuthRequired: false},
	CartItemDelete:                        {Role: "Customer", AuthRequired: false},
	StoreGetAll:                           {Role: "Customer", AuthRequired: false},
	StoreCreate:                           {Role: "Customer", AuthRequired: false},
	StoreUpdate:                           {Role: "Customer", AuthRequired: false},
	StoreDelete:                           {Role: "Customer", AuthRequired: false},
	HigherLevelCategoryGetAll:             {Role: "Customer", AuthRequired: false},
	HigherLevelCategoryCreate:             {Role: "Customer", AuthRequired: false},
	HigherLevelCategoryUpdate:             {Role: "Customer", AuthRequired: false},
	HigherLevelCategoryDelete:             {Role: "Customer", AuthRequired: false},
	CategoryGetAll:                        {Role: "Customer", AuthRequired: false},
	CategoryCreate:                        {Role: "Customer", AuthRequired: false},
	CategoryUpdate:                        {Role: "Customer", AuthRequired: false},
	CategoryDelete:                        {Role: "Customer", AuthRequired: false},
	CategoryList:                          {Role: "Customer", AuthRequired: false},
	CategoryHigherLevelMappingGetAll:      {Role: "Customer", AuthRequired: false},
	CategoryHigherLevelMappingCreate:      {Role: "Customer", AuthRequired: false},
	CategoryHigherLevelMappingUpdate:      {Role: "Customer", AuthRequired: false},
	CategoryHigherLevelMappingDelete:      {Role: "Customer", AuthRequired: false},
	LockedQuantityRemove:                  {Role: "Customer", AuthRequired: false},
	LockedQuantityUnlock:                  {Role: "Customer", AuthRequired: false},
	ItemUpdateBarcode:                     {Role: "Customer", AuthRequired: false},
	ItemUpdateAddStock:                    {Role: "Customer", AuthRequired: false},
	ItemUpdateAddStockByStore:             {Role: "Customer", AuthRequired: false},
	ItemByStoreAndBarcode:                 {Role: "Customer", AuthRequired: false},
	ItemGetAll:                            {Role: "Customer", AuthRequired: false},
	ItemCreate:                            {Role: "Customer", AuthRequired: false},
	ItemUpdate:                            {Role: "Customer", AuthRequired: false},
	ItemDelete:                            {Role: "Customer", AuthRequired: false},
	ItemAddStockAll:                       {Role: "Customer", AuthRequired: false},
	SearchItems:                           {Role: "Customer", AuthRequired: false},
	ItemAddQuick:                          {Role: "Customer", AuthRequired: false},
	PackerPackOrder:                       {Role: "Customer", AuthRequired: false},
	PackerFetchItem:                       {Role: "Customer", AuthRequired: false},
	PackerGetPackedItems:                  {Role: "Customer", AuthRequired: false},
	PackerPackItem:                        {Role: "Customer", AuthRequired: false},
	PackerCancelOrder:                     {Role: "Customer", AuthRequired: false},
	PackerAllocateSpace:                   {Role: "Customer", AuthRequired: false},
	CheckoutLockItems:                     {Role: "Customer", AuthRequired: false},
	CheckoutPayment:                       {Role: "Customer", AuthRequired: false},
	CheckoutCancel:                        {Role: "Customer", AuthRequired: false},
	DeliveryPartnerLogin:                  {Role: "Customer", AuthRequired: false},
	DeliveryPartnerGet:                    {Role: "Customer", AuthRequired: false},
	DeliveryPartnerUpdate:                 {Role: "Customer", AuthRequired: false},
	DeliveryPartnerCheckAssignedOrder:     {Role: "Customer", AuthRequired: false},
	DeliveryPartnerAcceptOrder:            {Role: "Customer", AuthRequired: false},
	DeliveryPartnerPickupOrder:            {Role: "Customer", AuthRequired: false},
	DeliveryPartnerDispatchOrder:          {Role: "Customer", AuthRequired: false},
	DeliveryPartnerCompleteOrder:          {Role: "Customer", AuthRequired: false},
	SalesOrderGetAll:                      {Role: "Customer", AuthRequired: false},
	SalesOrderGetByDeliveryPartner:        {Role: "Customer", AuthRequired: false},
	SalesOrderGetByCustomer:               {Role: "Customer", AuthRequired: false},
	SalesOrderGetByCartIdCustomerId:       {Role: "Customer", AuthRequired: false},
	SalesOrderDetailsByCustomerAndOrderId: {Role: "Customer", AuthRequired: false},
	StoreReceivedSalesOrder:               {Role: "Customer", AuthRequired: false},
	StoreGetSalesOrderItemsBySalesOrderId: {Role: "Customer", AuthRequired: false},
	AddressGetByCustomerId:                {Role: "Customer", AuthRequired: false},
	AddressGetDefaultByCustomerId:         {Role: "Customer", AuthRequired: false},
	AddressMakeDefault:                    {Role: "Customer", AuthRequired: false},
	AddressCreate:                         {Role: "Customer", AuthRequired: false},
	AddressUpdate:                         {Role: "Customer", AuthRequired: false},
	AddressDelete:                         {Role: "Customer", AuthRequired: false},
	AddressDeliverTo:                      {Role: "Customer", AuthRequired: false},
	BrandGetAll:                           {Role: "Customer", AuthRequired: false},
	BrandGet:                              {Role: "Customer", AuthRequired: false},
	BrandCreate:                           {Role: "Customer", AuthRequired: false},
	BrandUpdate:                           {Role: "Customer", AuthRequired: false},
	BrandDelete:                           {Role: "Customer", AuthRequired: false},
	PhonePeCheckStatus:                    {Role: "Customer", AuthRequired: false},
	PhonePeCallback:                       {Role: "Customer", AuthRequired: false},
	PhonePePaymentInit:                    {Role: "Customer", AuthRequired: false},
	PhonePePaymentVerify:                  {Role: "Customer", AuthRequired: false},
	OtpSend:                               {Role: "Customer", AuthRequired: false},
	OtpVerify:                             {Role: "Customer", AuthRequired: false},
	ShelfCreate:                           {Role: "Customer", AuthRequired: false},
	ShelfGetAll:                           {Role: "Customer", AuthRequired: false},
	LockStockCloudTask:                    {Role: "Customer", AuthRequired: false},
	// Additional handlers as needed...
}

const (
	CustomerLoginVerify                   = "customer-login-verify"
	CustomerGetAll                        = "customer-get-all"
	CustomerLoginAuto                     = "customer-login-auto"
	PackerLogin                           = "packer-login"
	PackerGetAll                          = "packer-get-all"
	ShoppingCartGetAllActive              = "shopping-cart-get-all-active"
	ShoppingCartGetByCustomer             = "shopping-cart-get-by-customer"
	CartItemDelete                        = "cart-item-delete"
	StoreGetAll                           = "store-get-all"
	StoreCreate                           = "store-create"
	StoreUpdate                           = "store-update"
	StoreDelete                           = "store-delete"
	HigherLevelCategoryGetAll             = "higher-level-category-get-all"
	HigherLevelCategoryCreate             = "higher-level-category-create"
	HigherLevelCategoryUpdate             = "higher-level-category-update"
	HigherLevelCategoryDelete             = "higher-level-category-delete"
	CategoryGetAll                        = "category-get-all"
	CategoryCreate                        = "category-create"
	CategoryUpdate                        = "category-update"
	CategoryDelete                        = "category-delete"
	CategoryList                          = "category-list"
	CategoryHigherLevelMappingGetAll      = "category-higher-level-mapping-get-all"
	CategoryHigherLevelMappingCreate      = "category-higher-level-mapping-create"
	CategoryHigherLevelMappingUpdate      = "category-higher-level-mapping-update"
	CategoryHigherLevelMappingDelete      = "category-higher-level-mapping-delete"
	LockedQuantityRemove                  = "locked-quantity-remove"
	LockedQuantityUnlock                  = "locked-quantity-unlock"
	ItemUpdateBarcode                     = "item-update-barcode"
	ItemUpdateAddStock                    = "item-update-add-stock"
	ItemUpdateAddStockByStore             = "item-update-add-stock-by-store"
	ItemByStoreAndBarcode                 = "item-by-store-and-barcode"
	ItemGetAll                            = "item-get-all"
	ItemCreate                            = "item-create"
	ItemUpdate                            = "item-update"
	ItemDelete                            = "item-delete"
	ItemAddStockAll                       = "item-add-stock-all"
	SearchItems                           = "search-items"
	ItemAddQuick                          = "item-add-quick"
	PackerPackOrder                       = "packer-pack-order"
	PackerFetchItem                       = "packer-fetch-item"
	PackerGetPackedItems                  = "packer-get-packed-items"
	PackerPackItem                        = "packer-pack-item"
	PackerCancelOrder                     = "packer-cancel-order"
	PackerAllocateSpace                   = "packer-allocate-space"
	CheckoutLockItems                     = "checkout-lock-items"
	CheckoutPayment                       = "checkout-payment"
	CheckoutCancel                        = "checkout-cancel"
	DeliveryPartnerLogin                  = "delivery-partner-login"
	DeliveryPartnerGet                    = "delivery-partner-get"
	DeliveryPartnerUpdate                 = "delivery-partner-update"
	DeliveryPartnerCheckAssignedOrder     = "delivery-partner-check-assigned-order"
	DeliveryPartnerAcceptOrder            = "delivery-partner-accept-order"
	DeliveryPartnerPickupOrder            = "delivery-partner-pickup-order"
	DeliveryPartnerDispatchOrder          = "delivery-partner-dispatch-order"
	DeliveryPartnerCompleteOrder          = "delivery-partner-complete-order"
	SalesOrderGetAll                      = "sales-order-get-all"
	SalesOrderGetByDeliveryPartner        = "sales-order-get-by-delivery-partner"
	SalesOrderGetByCustomer               = "sales-order-get-by-customer"
	SalesOrderGetByCartIdCustomerId       = "sales-order-get-by-cart-id-customer-id"
	SalesOrderDetailsByCustomerAndOrderId = "sales-order-details-by-customer-and-order-id"
	StoreReceivedSalesOrder               = "store-received-sales-order"
	StoreGetSalesOrderItemsBySalesOrderId = "store-get-sales-order-items-by-sales-order-id"
	AddressGetByCustomerId                = "address-get-by-customer-id"
	AddressGetDefaultByCustomerId         = "address-get-default-by-customer-id"
	AddressMakeDefault                    = "address-make-default"
	AddressCreate                         = "address-create"
	AddressUpdate                         = "address-update"
	AddressDelete                         = "address-delete"
	AddressDeliverTo                      = "address-deliver-to"
	BrandGetAll                           = "brand-get-all"
	BrandGet                              = "brand-get"
	BrandCreate                           = "brand-create"
	BrandUpdate                           = "brand-update"
	BrandDelete                           = "brand-delete"
	PhonePeCheckStatus                    = "phonepe-check-status"
	PhonePeCallback                       = "phonepe-callback"
	PhonePePaymentInit                    = "phonepe-payment-init"
	PhonePePaymentVerify                  = "phonepe-payment-verify"
	OtpSend                               = "send-otp"
	OtpVerify                             = "verify-otp"
	ShelfCreate                           = "shelf-create"
	ShelfGetAll                           = "shelf-get-all"
	LockStockCloudTask                    = "lock-stock-cloud-task"
)
