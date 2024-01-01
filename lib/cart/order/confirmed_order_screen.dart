import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:pronto/cart/cart.dart';
import 'package:pronto/home/home_screen.dart';
import 'dart:convert';

import 'package:pronto/utils/constants.dart';
import 'package:provider/provider.dart';

class OrderConfirmed extends StatefulWidget {
  OrderConfirmed({super.key, required this.newOrder});

  bool newOrder;

  @override
  _OrderConfirmedState createState() => _OrderConfirmedState();
}

class _OrderConfirmedState extends State<OrderConfirmed> {
  late String _orderDetails;
  bool _isLoading = true;
  bool _isError = false;
  late String _errorMsg;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String orderStatus = 'Preparing Order';
  String orderLottie =
      'https://lottie.host/ddddb99c-f46d-4ab1-a351-fe15819b4831/TrZJOISt7Y.json';
  double orderLottieTransform = 1.8;
  Map<String, OrderStatusInfo> orderStatusToInfo = {
    'Preparing Order': OrderStatusInfo(
        lottieUrl:
            'https://lottie.host/ddddb99c-f46d-4ab1-a351-fe15819b4831/TrZJOISt7Y.json',
        transform: 1.4),
    'Order Packed': OrderStatusInfo(
        lottieUrl:
            'https://lottie.host/179d84ef-a18b-4b26-b03c-85d5e928fd14/HOR0cKFnFZ.json',
        transform: 1.0),
    'Order Picked by Delivery Executive': OrderStatusInfo(
        lottieUrl:
            'https://assets1.lottiefiles.com/packages/lf20_jmejybvu.json',
        transform: 1.5),
    'Arrived': OrderStatusInfo(
        lottieUrl:
            'https://lottie.host/af0a126c-e39f-42c0-897d-4885692650f3/IVv3ey2PJW.json',
        transform: 0.9),
    'Order Completed': OrderStatusInfo(
        lottieUrl:
            'https://lottie.host/3974166c-0ce3-45be-847b-3a39ab3131ec/cKXCS62FCY.json',
        transform: 1.9),
  };

  String _deliveryPartnerName = '';
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
  }

  Future<void> fetchOrderDetails() async {
    // Retrieve customerId and cartId from secure storage
    String? customerId = await _storage.read(key: 'customerId');
    String? cartId;
    if (widget.newOrder) {
      cartId = await _storage.read(key: 'cartId');
      print("Cart ID: $cartId");
    } else {
      cartId = await _storage.read(key: 'placedCartId');
      print("PlacedCart ID: $cartId");
    }

    // Ensure both values are not null
    if (cartId == null || customerId == null) {
      throw Exception('Customer ID or Cart ID is missing');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/sales-order'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'customer_id': int.parse(customerId),
        'cart_id': int.parse(cartId),
        // Add other necessary fields if any
      }),
    );

    print("CustomerId: $customerId, CartId: $cartId");

    if (response.statusCode == 200) {
      // Decode the JSON response
      Map<String, dynamic> responseData = json.decode(response.body);

      // Extract and print the 'payment_type' field
      String paymentType = responseData['payment_type'];
      print("Payment Type: $paymentType");

      if (responseData.isNotEmpty) {
        // Extracting the 'paid' field from the first object in the list
        String? newCartId = await _storage.read(key: 'cartId');
        print("placeCartID: $newCartId");
        if (widget.newOrder) {
          await _storage.write(key: 'placedCartId', value: newCartId);

          newCartId = responseData["new_cart_id"].toString();
          await _storage.write(key: 'cartId', value: newCartId);
        }

        await _storage.write(key: 'orderStatus', value: "Preparing Order");

        setState(() {
          _isLoading = false;
          _orderDetails = paymentType;
          if (widget.newOrder) {
            print("Old Cart ID: $cartId");
            print("New Cart ID: $newCartId");
          }

          _deliveryPartnerName = responseData['delivery_partner']['name'];
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

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurpleAccent,
          title: const Text(
            'Otto Mart ',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              // Navigate to the HomeScreen, replacing the current route
              if (widget.newOrder) {
                cart.clearCart();
              }

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (context) => const MyHomePage(
                          title: 'Otto',
                        )),
              );
            },
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Center(child: CircularProgressIndicator()),
                  ])
            : _isError
                ? Center(child: Text(_errorMsg))
                : SingleChildScrollView(
                    // Enables scrolling
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height * 0.24,
                            width: MediaQuery.of(context).size.width * 0.95,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
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
                                left: 10, right: 10, top: 15, bottom: 5),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(15), // Rounded corners
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 4,
                                  offset: const Offset(
                                      0, 2), // Changes position of shadow
                                ),
                              ],
                              border:
                                  Border.all(color: Colors.white, width: 1.0),
                            ),
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                orderStatus,
                                style: const TextStyle(
                                    fontSize: 22, // Increased font size
                                    fontWeight: FontWeight.bold,
                                    color: Colors
                                        .deepPurpleAccent // Bold font weight
                                    ),
                                textAlign: TextAlign
                                    .center, // Ensure text is centered horizontally
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
                                  BorderRadius.circular(15), // Rounded corners
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 4,
                                  offset: const Offset(
                                      0, 2), // Changes position of shadow
                                ),
                              ],
                              border:
                                  Border.all(color: Colors.white, width: 1.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Delivery Partner: $_deliveryPartnerName'),
                                Text('Number of Items: $_numberOfItems'),
                                Text('Address: $_customerAddress'),
                                Text('Payment Type: $_paymentType'),
                                Text('Order Date: $_orderDate'),
                              ],
                            ),
                          ),
                          const ItemList(),
                          const ItemTotal(),
                        ],
                      ),
                    ),
                  )

        /*
              CustomScrollView(
                  slivers: <Widget>[
                    SliverAppBar(
                      leading: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          // Navigate to the HomeScreen, replacing the current route
                          if (widget.newOrder) {
                            cart.clearCart();
                          }

                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (context) => const MyHomePage(
                                      title: 'Otto',
                                    )),
                          );
                        },
                      ),
                      pinned: true,
                      bottom: PreferredSize(
                        preferredSize:
                            Size(0, MediaQuery.of(context).size.height * 0.2),
                        child: Container(),
                      ),
                      expandedHeight:
                          MediaQuery.of(context).size.height * (0.48),
                      centerTitle: true,
                      title: ShaderMask(
                        shaderCallback: (bounds) => const RadialGradient(
                                center: Alignment.topLeft,
                                radius: 1.0,
                                colors: [
                                  Colors.white,
                                  Color.fromARGB(255, 220, 239, 255)
                                ],
                                tileMode: TileMode.mirror)
                            .createShader(bounds),
                        child: const Text(
                          'Otto Mart',
                          style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      backgroundColor: Colors.white,
                      flexibleSpace: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              color: Colors.deepPurpleAccent,
                            ),
                          ),
                          Positioned(
                            top: MediaQuery.of(context).size.height * 0.12,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              color: Colors.transparent,
                              child: SingleChildScrollView(
                                // Enables scrolling
                                child: Column(
                                  children: [
                                    Container(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.24,
                                      width: MediaQuery.of(context).size.width *
                                          0.85,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 2),
                                      padding:
                                          const EdgeInsets.only(bottom: 10.0),
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
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.07,
                                      width: MediaQuery.of(context).size.width *
                                          0.85,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors
                                            .white, // Uniform color for all containers
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          orderStatus,
                                          style: const TextStyle(
                                            fontSize: 22, // Increased font size
                                            fontWeight: FontWeight
                                                .bold, // Bold font weight
                                          ),
                                          textAlign: TextAlign
                                              .center, // Ensure text is centered horizontally
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                            15), // Rounded corners
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.deepPurpleAccent
                                                .withOpacity(0.5),
                                            spreadRadius: 2,
                                            blurRadius: 4,
                                            offset: const Offset(0,
                                                2), // Changes position of shadow
                                          ),
                                        ],
                                        border: Border.all(
                                            color: Colors.white, width: 1.0),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'Delivery Partner: $_deliveryPartnerName'),
                                          Text(
                                              'Number of Items: $_numberOfItems'),
                                          Text('Address: $_customerAddress'),
                                          Text('Payment Type: $_paymentType'),
                                          Text('Order Date: $_orderDate'),
                                        ],
                                      ),
                                    ),

                                    /*
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.05,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.zero,
                                            margin: EdgeInsets.zero,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                updateOrderStatus(
                                                    'Preparing Order');
                                              },
                                              child: const Text('1'),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              updateOrderStatus('Order Packed');
                                            },
                                            child: const Text('2'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              updateOrderStatus(
                                                  'Order Picked by Delivery Executive');
                                            },
                                            child: const Text('3'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              updateOrderStatus('Arrived');
                                            },
                                            child: const Text('4'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              updateOrderStatus(
                                                  'Order Completed');
                                            },
                                            child: const Text('5'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    */
                                    // Add more containers or widgets if needed
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -1,
                            left: 0,
                            right: 0,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(50)),
                              child: Container(
                                height: 25,
                                decoration: const BoxDecoration(
                                    // Define the linear gradient
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverFixedExtentList(
                      itemExtent: 160.0, // Height of each item
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          // Define a list of custom widgets for each child
                          List<Widget> customChildren = [
                            Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                    15), // Rounded corners
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurpleAccent
                                        .withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 4,
                                    offset: const Offset(
                                        0, 2), // Changes position of shadow
                                  ),
                                ],
                                border:
                                    Border.all(color: Colors.white, width: 1.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Delivery Partner: $_deliveryPartnerName'),
                                  Text('Number of Items: $_numberOfItems'),
                                  Text('Address: $_customerAddress'),
                                  Text('Payment Type: $_paymentType'),
                                  Text('Order Date: $_orderDate'),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                    15), // Rounded corners
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurpleAccent
                                        .withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 4,
                                    offset: const Offset(
                                        0, 2), // Changes position of shadow
                                  ),
                                ],
                                border:
                                    Border.all(color: Colors.white, width: 1.0),
                              ),
                              child: const Center(
                                child: Text('Wishlist'),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                    15), // Rounded corners
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurpleAccent
                                        .withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 4,
                                    offset: const Offset(
                                        0, 2), // Changes position of shadow
                                  ),
                                ],
                                border:
                                    Border.all(color: Colors.white, width: 1.0),
                              ),
                              child: const Center(
                                child: Text('Wishlist'),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                    15), // Rounded corners
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurpleAccent
                                        .withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 4,
                                    offset: const Offset(
                                        0, 2), // Changes position of shadow
                                  ),
                                ],
                                border:
                                    Border.all(color: Colors.white, width: 1.0),
                              ),
                              child: const Center(
                                child: Text('Wishlist'),
                              ),
                            ),
                          ];

                          // Return the custom child based on the index
                          return customChildren[index];
                        },
                        childCount: 4, // Total number of children
                      ),
                    ),
                  ],
                ),
              */
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
              //padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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
                            style: itemNameStyle
                            /*
                                        const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        */
                            ),
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
