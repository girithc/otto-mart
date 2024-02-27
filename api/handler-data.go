package api

// Define the Permission struct with Role and AuthRequired fields
type Permission struct {
	Role         string
	AuthRequired bool
}

// Redefine the authRequirements map to use Permission structs for values
var authRequirements = map[string]Permission{
	CustomerLoginVerify:                   {Role: "Customer", AuthRequired: true},
	CustomerGetAll:                        {Role: "Customer", AuthRequired: true},
	CustomerLoginAuto:                     {Role: "Customer", AuthRequired: true},
	ManagerLogin:                          {Role: "Manager", AuthRequired: true},
	ManagerItems:                          {Role: "Manager", AuthRequired: false},
	PackerLogin:                           {Role: "Customer", AuthRequired: true},
	PackerGetAll:                          {Role: "Customer", AuthRequired: true},
	ShoppingCartGetAllActive:              {Role: "Customer", AuthRequired: true},
	ShoppingCartGetByCustomer:             {Role: "Customer", AuthRequired: true},
	CartItemDelete:                        {Role: "Customer", AuthRequired: true},
	StoreGetAll:                           {Role: "Customer", AuthRequired: true},
	StoreCreate:                           {Role: "Customer", AuthRequired: true},
	StoreUpdate:                           {Role: "Customer", AuthRequired: true},
	StoreDelete:                           {Role: "Customer", AuthRequired: true},
	HigherLevelCategoryGetAll:             {Role: "Customer", AuthRequired: true},
	HigherLevelCategoryCreate:             {Role: "Customer", AuthRequired: true},
	HigherLevelCategoryUpdate:             {Role: "Customer", AuthRequired: true},
	HigherLevelCategoryDelete:             {Role: "Customer", AuthRequired: true},
	CategoryGetAll:                        {Role: "Customer", AuthRequired: true},
	CategoryCreate:                        {Role: "Customer", AuthRequired: true},
	CategoryUpdate:                        {Role: "Customer", AuthRequired: true},
	CategoryDelete:                        {Role: "Customer", AuthRequired: true},
	CategoryList:                          {Role: "Customer", AuthRequired: true},
	CategoryHigherLevelMappingGetAll:      {Role: "Customer", AuthRequired: true},
	CategoryHigherLevelMappingCreate:      {Role: "Customer", AuthRequired: true},
	CategoryHigherLevelMappingUpdate:      {Role: "Customer", AuthRequired: true},
	CategoryHigherLevelMappingDelete:      {Role: "Customer", AuthRequired: true},
	LockedQuantityRemove:                  {Role: "Customer", AuthRequired: true},
	LockedQuantityUnlock:                  {Role: "Customer", AuthRequired: true},
	ItemUpdateBarcode:                     {Role: "Customer", AuthRequired: true},
	ItemUpdateAddStock:                    {Role: "Customer", AuthRequired: true},
	ItemUpdateAddStockByStore:             {Role: "Customer", AuthRequired: true},
	ItemByStoreAndBarcode:                 {Role: "Customer", AuthRequired: true},
	ItemGetAll:                            {Role: "Customer", AuthRequired: true},
	ItemCreate:                            {Role: "Customer", AuthRequired: true},
	ItemUpdate:                            {Role: "Customer", AuthRequired: true},
	ItemDelete:                            {Role: "Customer", AuthRequired: true},
	ItemAddStockAll:                       {Role: "Customer", AuthRequired: true},
	ManagerItemEdit:                       {Role: "Manager", AuthRequired: true},
	SearchItems:                           {Role: "Customer", AuthRequired: true},
	ItemAddQuick:                          {Role: "Customer", AuthRequired: true},
	PackerPackOrder:                       {Role: "Customer", AuthRequired: true},
	PackerFetchItem:                       {Role: "Customer", AuthRequired: true},
	PackerGetPackedItems:                  {Role: "Customer", AuthRequired: true},
	PackerPackItem:                        {Role: "Customer", AuthRequired: true},
	PackerCancelOrder:                     {Role: "Customer", AuthRequired: true},
	PackerAllocateSpace:                   {Role: "Customer", AuthRequired: true},
	CheckoutLockItems:                     {Role: "Customer", AuthRequired: true},
	CheckoutPayment:                       {Role: "Customer", AuthRequired: true},
	CheckoutCancel:                        {Role: "Customer", AuthRequired: true},
	DeliveryPartnerLogin:                  {Role: "Customer", AuthRequired: true},
	DeliveryPartnerGet:                    {Role: "Customer", AuthRequired: true},
	DeliveryPartnerUpdate:                 {Role: "Customer", AuthRequired: true},
	DeliveryPartnerCheckAssignedOrder:     {Role: "Customer", AuthRequired: true},
	DeliveryPartnerAcceptOrder:            {Role: "Customer", AuthRequired: true},
	DeliveryPartnerPickupOrder:            {Role: "Customer", AuthRequired: true},
	DeliveryPartnerDispatchOrder:          {Role: "Customer", AuthRequired: true},
	DeliveryPartnerArrive:                 {Role: "Customer", AuthRequired: true},
	DeliveryPartnerCompleteOrder:          {Role: "Customer", AuthRequired: true},
	SalesOrderGetAll:                      {Role: "Customer", AuthRequired: true},
	SalesOrderGetByDeliveryPartner:        {Role: "Customer", AuthRequired: true},
	SalesOrderGetByCustomer:               {Role: "Customer", AuthRequired: true},
	SalesOrderGetByCartIdCustomerId:       {Role: "Customer", AuthRequired: true},
	SalesOrderDetailsByCustomerAndOrderId: {Role: "Customer", AuthRequired: true},
	StoreReceivedSalesOrder:               {Role: "Customer", AuthRequired: true},
	StoreGetSalesOrderItemsBySalesOrderId: {Role: "Customer", AuthRequired: true},
	AddressGetByCustomerId:                {Role: "Customer", AuthRequired: true},
	AddressGetDefaultByCustomerId:         {Role: "Customer", AuthRequired: true},
	AddressMakeDefault:                    {Role: "Customer", AuthRequired: true},
	AddressCreate:                         {Role: "Customer", AuthRequired: true},
	AddressUpdate:                         {Role: "Customer", AuthRequired: true},
	AddressDelete:                         {Role: "Customer", AuthRequired: true},
	AddressDeliverTo:                      {Role: "Customer", AuthRequired: true},
	BrandGetAll:                           {Role: "Customer", AuthRequired: true},
	BrandGet:                              {Role: "Customer", AuthRequired: true},
	BrandCreate:                           {Role: "Customer", AuthRequired: true},
	BrandUpdate:                           {Role: "Customer", AuthRequired: true},
	BrandDelete:                           {Role: "Customer", AuthRequired: true},
	PhonePeCheckStatus:                    {Role: "Customer", AuthRequired: true},
	PhonePeCallback:                       {Role: "Customer", AuthRequired: false},
	PhonePePaymentInit:                    {Role: "Customer", AuthRequired: true},
	PhonePePaymentVerify:                  {Role: "Customer", AuthRequired: true},
	OtpSend:                               {Role: "Customer", AuthRequired: false},
	OtpVerify:                             {Role: "Customer", AuthRequired: false},
	OtpSendPacker:                         {Role: "Customer", AuthRequired: false},
	OtpVerifyPacker:                       {Role: "Customer", AuthRequired: false},
	OtpSendDeliveryPartner:                {Role: "Customer", AuthRequired: false},
	OtpVerifyDeliveryPartner:              {Role: "Customer", AuthRequired: false},
	OtpSendManager:                        {Role: "Customer", AuthRequired: false},
	OtpVerifyManager:                      {Role: "Customer", AuthRequired: false},
	ShelfCreate:                           {Role: "Customer", AuthRequired: true},
	ShelfGetAll:                           {Role: "Customer", AuthRequired: true},
	LockStockCloudTask:                    {Role: "Customer", AuthRequired: false},
	VendorGetAll:                          {Role: "Customer", AuthRequired: false},
	VendorAdd:                             {Role: "Customer", AuthRequired: false},
	VendorEdit:                            {Role: "Customer", AuthRequired: false},
	NeedToUpdate:                          {Role: "Customer", AuthRequired: false},
	ManagerGetItems:                       {Role: "Customer", AuthRequired: true},
	ManagerSearchItem:                     {Role: "Customer", AuthRequired: true},
	ManagerItemFinanceGet:                 {Role: "Customer", AuthRequired: true},
	ManagerItemFinanceEdit:                {Role: "Customer", AuthRequired: true},
	ManagerGetTax:                         {Role: "Customer", AuthRequired: true},
	ManagerItemStoreCombo:                 {Role: "Manager", AuthRequired: true},
	ManagerAddNewItem:                     {Role: "Manager", AuthRequired: true},
}

const (
	CustomerLoginVerify = "customer-login-verify"
	CustomerGetAll      = "customer-get-all"
	CustomerLoginAuto   = "customer-login-auto"

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
	ManagerItemEdit                       = "manager-item-edit"
	SearchItems                           = "search-items"
	ItemAddQuick                          = "item-add-quick"
	PackerLogin                           = "packer-login"
	PackerGetAll                          = "packer-get-all"
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
	DeliveryPartnerDispatchOrder          = "packer-dispatch-order"
	DeliveryPartnerArrive                 = "delivery-partner-arrive"
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
	OtpSendPacker                         = "send-otp-packer"
	OtpVerifyPacker                       = "verify-otp-packer"
	OtpSendDeliveryPartner                = "send-otp-delivery-partner"
	OtpVerifyDeliveryPartner              = "verify-otp-delivery-partner"
	OtpSendManager                        = "send-otp-manager"
	OtpVerifyManager                      = "verify-otp-manager"
	ManagerLogin                          = "manager-login"
	ManagerItems                          = "manager-items"
	ShelfCreate                           = "shelf-create"
	ShelfGetAll                           = "shelf-get-all"
	LockStockCloudTask                    = "lock-stock-cloud-task"
	VendorGetAll                          = "vendor-get-all"
	VendorAdd                             = "vendor-add"
	VendorEdit                            = "vendor-edit"
	NeedToUpdate                          = "need-to-update"
	ManagerGetItems                       = "manager-get-items"
	ManagerSearchItem                     = "manager-search-item"
	ManagerItemFinanceGet                 = "manager-item-finance-get"
	ManagerItemFinanceEdit                = "manager-item-finance-edit"
	ManagerGetTax                         = "manager-get-tax"
	ManagerItemStoreCombo                 = "manager-item-store-combo"
	ManagerAddNewItem                     = "manager-add-new-item"
)
