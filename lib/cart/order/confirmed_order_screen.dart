import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lottie/lottie.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/home/home_screen.dart';
import 'dart:convert';

import 'package:pronto/utils/network/service.dart';
import 'package:provider/provider.dart';

class OrderConfirmed extends StatefulWidget {
  const OrderConfirmed({super.key, required this.newOrder, this.orderId});

  final bool newOrder;
  final int? orderId; // Optional int parameter

  @override
  _OrderConfirmedState createState() => _OrderConfirmedState();
}

class _OrderConfirmedState extends State<OrderConfirmed> {
  String? _orderDetails;
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMsg;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Timer? _timer; // Declare a Timer variable

  String orderStatus = 'Preparing Order';
  String orderLottie =
      'https://lottie.host/ddddb99c-f46d-4ab1-a351-fe15819b4831/TrZJOISt7Y.json';
  double orderLottieTransform = 1.8;
  Map<String, OrderStatusInfo> orderStatusToInfo = {
    'received': OrderStatusInfo(
        lottieUrl:
            'https://lottie.host/ddddb99c-f46d-4ab1-a351-fe15819b4831/TrZJOISt7Y.json',
        transform: 1.4),
    'accepted': OrderStatusInfo(
        lottieUrl:
            'https://lottie.host/ddddb99c-f46d-4ab1-a351-fe15819b4831/TrZJOISt7Y.json',
        transform: 1.4),
    'packed': OrderStatusInfo(
        lottieUrl:
            'https://lottie.host/179d84ef-a18b-4b26-b03c-85d5e928fd14/HOR0cKFnFZ.json',
        transform: 1.0),
    'dispatched': OrderStatusInfo(
        lottieUrl:
            'https://assets1.lottiefiles.com/packages/lf20_jmejybvu.json',
        transform: 1.5),
    'arrived': OrderStatusInfo(
        lottieUrl:
            'https://lottie.host/af0a126c-e39f-42c0-897d-4885692650f3/IVv3ey2PJW.json',
        transform: 0.9),
    'completed': OrderStatusInfo(
        lottieUrl:
            'https://lottie.host/3974166c-0ce3-45be-847b-3a39ab3131ec/cKXCS62FCY.json',
        transform: 1.9),
  };

  int _numberOfItems = 0;
  String _customerAddress = '';
  String _paymentType = '';
  String _orderDate = '';

  void updateOrderStatus(String url) {
    setState(() {
      orderStatus = url;
      orderLottie = orderStatusToInfo[url]!.lottieUrl;
      orderLottieTransform = orderStatusToInfo[url]!.transform;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
    _setupPeriodicFetch(); // Set up periodic fetch of order info
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  void _setupPeriodicFetch() {
    _timer =
        Timer.periodic(Duration(minutes: 1), (Timer t) => fetchOrderInfo());
    // This sets up a timer that calls fetchOrderInfo every 2 minutes
  }

  Future<void> fetchOrderDetails() async {
    // Retrieve customerId and cartId from secure storage

    String? customerId = await _storage.read(key: 'customerId');
    String? cartId;
    final networkService = NetworkService();
    if (widget.newOrder) {
      cartId = await _storage.read(key: 'cartId');
      print("Cart ID: $cartId");
    } else {
      cartId = widget.orderId.toString();
      //print("PlacedCart ID: $cartId");
    }

    if (cartId == null || customerId == null) {
      throw Exception('Customer ID or Cart ID is missing');
    }

    final Map<String, dynamic> body = {
      'customer_id': int.parse(customerId),
      'cart_id': int.parse(cartId),
    };

    final response =
        await networkService.postWithAuth('/sales-order', additionalData: body);

    print("Confirmed Order Response: ${response.body}");

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = json.decode(response.body);
      String paymentType = responseData['payment_type'];

      if (responseData.isNotEmpty) {
        if (widget.newOrder) {
          String? oldCartId = await _storage.read(key: 'cartId');
          await _storage.write(key: 'placedCartId', value: oldCartId);

          final String newCartId = responseData["new_cart_id"].toString();
          await _storage.write(key: 'cartId', value: newCartId);
        }

        //await _storage.write(key: 'orderStatus', value: "Preparing Order");

        setState(() {
          _isLoading = false;
          _orderDetails = paymentType;

          //_deliveryPartnerName = responseData['delivery_partner']['name'];
          _numberOfItems =
              responseData['products'].length; // Assuming 'products' is a list
          _customerAddress = responseData['address']['street_address'];
          _paymentType = responseData['payment_type'];
          _orderDate = responseData['order_date'];
        });
      } else {
        setState(() {
          _isError = true;
          _errorMsg = 'No Order Found.';
        });
        throw Exception('Empty response data');
      }
    } else {
      setState(() {
        _isError = true;
        _errorMsg = 'Error loading order details.';
      });
      throw Exception('Failed to load order details');
    }
  }

  Future<void> fetchOrderInfo() async {
    final customerId = await _storage.read(key: 'customerId');
    final cartId = await _storage.read(key: 'placedCartId');
    print("PlacedCart ID: $cartId");
    final Map<String, dynamic> body = {
      'customer_id': int.parse(customerId!),
      'cart_id': int.parse(cartId!),
    };

    final networkService = NetworkService();
    final response = await networkService.postWithAuth('/customer-placed-order',
        additionalData: body);

    print("Response: ${response.statusCode} ${response.body}  ");
    // Deserialize the JSON response
    final jsonResponse = json.decode(response.body);
    final orderInfo = OrderInfo.fromJson(jsonResponse);
    // Use the parsed orderInfo object to update your UI
    // For example, you might want to set some state variables and call setState to refresh the UI
    setState(() {
      orderStatus = orderInfo.orderStatus;
      orderLottie = orderStatusToInfo[orderStatus]!.lottieUrl;
      orderLottieTransform = orderStatusToInfo[orderStatus]!.transform;
    });
  }

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();
    if (widget.newOrder) {
      cart.clearCart();
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Otto Mart ',
          style: TextStyle(color: Colors.deepPurpleAccent),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: Colors.black,
          ),
          onPressed: () {
            // Navigate to the HomeScreen, replacing the current route

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) => const MyHomePage(
                        title: 'Otto',
                      )),
            );
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: () {
              fetchOrderInfo();
            },
          ),
        ],
        centerTitle: true,
      ),
      body: _isLoading
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  Center(child: CircularProgressIndicator()),
                ])
          : _isError
              ? Center(child: Text(_errorMsg!))
              : SingleChildScrollView(
                  // Enables scrolling
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.height * 0.24,
                          width: MediaQuery.of(context).size.width * 0.95,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          padding: const EdgeInsets.only(bottom: 10.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            // Center the Lottie animation within the container
                            child: Transform.scale(
                              scale:
                                  orderLottieTransform, // Increase the size by 30%
                              child: Lottie.network(
                                orderLottie,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                              left: 10, right: 10, top: 0, bottom: 0),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(10), // Rounded corners
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 2,
                                offset: const Offset(
                                    0, 1), // Changes position of shadow
                              ),
                            ],
                            border: Border.all(color: Colors.white, width: 1.0),
                          ),
                          child: Center(
                            child: Text(
                              orderStatus,
                              style: const TextStyle(
                                  fontSize: 18, // Increased font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors
                                      .deepPurpleAccent // Bold font weight
                                  ),
                              // Ensure text is centered horizontally
                            ),
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.only(
                              left: 10, right: 10, top: 5, bottom: 5),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(10), // Rounded corners
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 2,
                                offset: const Offset(
                                    0, 1), // Changes position of shadow
                              ),
                            ],
                            border: Border.all(color: Colors.white, width: 1.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Number of Items: $_numberOfItems'),
                              Text('Address: $_customerAddress'),
                              Text('Payment Type: $_paymentType'),
                              Text('Order Date: $_orderDate'),
                            ],
                          ),
                        ),
                        //const ItemList(),
                        //const ItemTotal(),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class ItemList extends StatefulWidget {
  const ItemList({super.key});

  @override
  State<ItemList> createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  @override
  Widget build(BuildContext context) {
    var itemNameStyle = Theme.of(context).textTheme.titleMedium;
    var cart = context.watch<CartModel>();

    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2), // Changes position of shadow
          ),
        ],
        border: Border.all(color: Colors.white, width: 1.0),
      ),
      child: Column(
        children: [
          for (var item in cart.items)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                          // Add border
                          ),
                      child:
                          Center(child: Image.network(item.image, height: 75)),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Container(
                      decoration: const BoxDecoration(
                          //border: Border.all( color: Colors.black), // Add border
                          ),
                      child: Text(
                        item.productName,
                        style: itemNameStyle,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                        decoration: BoxDecoration(
                            color: Colors.deepPurpleAccent, // Add border
                            borderRadius: BorderRadius.circular(8.0)),
                        height: MediaQuery.of(context).size.height * 0.04,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(),
                              Text(
                                item.quantity.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        )),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: const BoxDecoration(
                          // Add border
                          ),
                      child: Center(
                        child: Text(
                            "\u{20B9}${item.soldPrice * item.quantity}", // Replace with your price calculation
                            style: itemNameStyle),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ItemTotal extends StatelessWidget {
  const ItemTotal({super.key});

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2), // Changes position of shadow
          ),
        ],
        border: Border.all(color: Colors.white, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
        child: Column(
          children: [
            _CustomListItem(
              icon: Icons.done_all_outlined,
              label: 'Item Total',
              amount: '${cart.totalPriceItems}',
              font: const TextStyle(fontSize: 16),
            ),
            cart.smallOrderFee > 0
                ? _CustomListItem(
                    icon: Icons.donut_small_rounded,
                    label: 'Small Order Fee',
                    amount: '${cart.smallOrderFee}',
                    font: const TextStyle(fontSize: 16),
                  )
                : Container(),
            _CustomListItem(
              icon: Icons.electric_bike_outlined,
              label: 'Delivery Fee',
              amount: '${cart.deliveryFee}',
              font: const TextStyle(fontSize: 16),
            ),
            _CustomListItem(
              icon: Icons.shopping_bag_outlined,
              label: 'Platform Fee',
              amount: '${cart.platformFee}',
              font: const TextStyle(fontSize: 16),
            ),
            _CustomListItem(
              icon: Icons.shopping_bag_outlined,
              label: 'Packaging Fee',
              amount: '${cart.packagingFee}',
              font: const TextStyle(fontSize: 16),
            ),
            cart.deliveryPartnerTip > 0
                ? _CustomListItem(
                    icon: Icons.volunteer_activism_outlined,
                    label: 'Delivery Partner Tip',
                    amount: '${cart.deliveryPartnerTip}',
                    font: const TextStyle(fontSize: 16),
                  )
                : Container(),
            const Divider(),
            _CustomListItem(
              icon: Icons.payments,
              label: 'Amount Paid',
              amount: '\u{20B9}${cart.totalPrice}',
              font: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomListItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final TextStyle? font;

  const _CustomListItem({
    required this.icon,
    required this.label,
    required this.amount,
    this.font,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 10.0, right: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: font,
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(right: 40, top: 0, bottom: 0),
            child: Text(
              amount,
              style: font,
            ),
          ),
        ],
      ),
    );
  }
}

class OrderStatusInfo {
  String lottieUrl;
  double transform;

  OrderStatusInfo({required this.lottieUrl, required this.transform});
}

class OrderInfo {
  final String orderStatus;
  final String orderDpStatus;
  final String paymentType;
  final bool paidStatus;
  final String orderDate;
  final int totalAmountPaid;
  final List<Item> items;
  final String address;

  OrderInfo({
    required this.orderStatus,
    required this.orderDpStatus,
    required this.paymentType,
    required this.paidStatus,
    required this.orderDate,
    required this.totalAmountPaid,
    required this.items,
    required this.address,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    return OrderInfo(
      orderStatus: json['order_status'],
      orderDpStatus: json['order_dp_status'],
      paymentType: json['payment_type'],
      paidStatus: json['paid_status'],
      orderDate: json['order_date'],
      totalAmountPaid: json['total_amount_paid'],
      items: List<Item>.from(json['items'].map((i) => Item.fromJson(i))),
      address: json['address'],
    );
  }
}

class Item {
  final String name;
  final String image;
  final int quantity;
  final String unitOfQuantity;
  final int size;

  Item({
    required this.name,
    required this.image,
    required this.quantity,
    required this.unitOfQuantity,
    required this.size,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      name: json['name'],
      image: json['image'],
      quantity: json['quantity'],
      unitOfQuantity: json['unit_of_quantity'],
      size: json['size'],
    );
  }
}
