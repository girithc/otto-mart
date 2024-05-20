import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lottie/lottie.dart' as lt;
import 'package:pronto/cart/cart.dart';
import 'package:pronto/home/home_screen.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:pronto/utils/network/service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class OrderConfirmed extends StatefulWidget {
  const OrderConfirmed({super.key, required this.newOrder, this.orderId});

  final bool newOrder;
  final int? orderId; // Optional int parameter

  @override
  _OrderConfirmedState createState() => _OrderConfirmedState();
}

class _OrderConfirmedState extends State<OrderConfirmed> {
  //String? _orderDetails;
  bool _isLoading = true;
  final bool _isError = false;

  String? _errorMsg;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Timer? _timer; // Declare a Timer variable
  OrderInfo? _orderInfo;
  String? OTP;
  String orderType = 'delivery';
  String? orderCartId;
  bool fetchOrder = false;

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

  String formatOrderDate(String orderDate) {
    DateTime parsedDate = DateTime.parse(orderDate);
    DateTime updatedDate =
        parsedDate.add(const Duration(hours: 5, minutes: 32));
    return DateFormat('h:mm a').format(updatedDate);
  }

  void updateOrderStatus(String url) {
    setState(() {
      orderStatus = url;
      orderLottie = orderStatusToInfo[url]!.lottieUrl;
      orderLottieTransform = orderStatusToInfo[url]!.transform;
    });
  }

  void _showQRCodeDialog(BuildContext context) async {
    final String? phone = await _storage.read(key: 'phone');

    final String phoneValue = phone ?? 'Unknown';

    String? cartId;

    if (widget.newOrder) {
      cartId = await _storage.read(key: 'cartId');
      print("Cart ID: $cartId");
    } else {
      cartId = widget.orderId.toString();
    }

    final String data = "$phoneValue-${int.parse(cartId!)}";

    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 4.0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          title: const Text("Order QR Code"),
          content: SizedBox(
            height: 300,
            width: 300,
            child: QrImageView(
              data: data,
              version: QrVersions.auto,
              size: 300.0,
              gapless: false,
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor:
                    const Color.fromRGBO(98, 0, 238, 1), // Button text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    // Introduce a 2-second delay before fetching order details and order info
    Future.delayed(Duration(seconds: widget.newOrder ? 1 : 0), () {
      //fetchOrderDetails(); // Call fetchOrderDetails after a 2-second delay
      fetchOrderInfo(); // Call fetchOrderInfo after a 2-second delay
    });

    // Set up periodic fetch of order info with a timer
    _setupPeriodicFetch();
  }

  void _setupPeriodicFetch() {
    // This sets up a timer that periodically calls fetchOrderInfo
    _timer = Timer.periodic(const Duration(seconds: 15), (Timer t) {
      //fetchOrderDetails();
      fetchOrderInfo(); // Modify this as needed, currently set to 45 seconds
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> fetchOrderInfo() async {
    final customerId = await _storage.read(key: 'customerId');
    String? cartId = await _storage.read(key: 'cartId');

    if (!widget.newOrder) {
      cartId = widget.orderId.toString();
      print("CartId: $cartId");
    }
    if (fetchOrder) {
      cartId = orderCartId;
    } else {
      orderCartId = cartId;
    }

    final Map<String, dynamic> body = {
      'customer_id': int.parse(customerId!),
      'cart_id': int.parse(cartId!),
    };

    final networkService = NetworkService();
    final response = await networkService.postWithAuth('/customer-placed-order',
        additionalData: body);

    print(
        "Response Fetch Order Info \n\n: ${response.statusCode} ${response.body}  ");
    // Deserialize the JSON response
    final jsonResponse = json.decode(response.body);
    _orderInfo = OrderInfo.fromJson(jsonResponse);

    setState(() {
      _isLoading = false;
      fetchOrder = true;
      orderStatus = _orderInfo!.orderStatus;
      orderLottie = orderStatusToInfo[orderStatus]!.lottieUrl;
      orderLottieTransform = orderStatusToInfo[orderStatus]!.transform;
    });

    if (widget.newOrder) {
      _storage.write(key: 'cartId', value: _orderInfo!.newCartId.toString());
    }
  }

  String formatDate(String orderDateString) {
    // Parse the date string into a DateTime object
    DateTime orderDate = DateTime.parse(orderDateString);

    // Add 5 hours and 30 minutes to the order date
    DateTime updatedOrderDate =
        orderDate.add(const Duration(hours: 5, minutes: 30));

    // Format the date with AM/PM, e.g., "dd MMM, yyyy hh:mm a"
    // Here, "hh" is used for hour format (01-12), "mm" for minute, and "a" for AM/PM
    return DateFormat('dd MMM, yyyy hh:mm a').format(updatedOrderDate);
  }

  String formatDeliveryDate(DateTime date) {
    final DateFormat formatter = DateFormat('d MMM');
    return formatter.format(date);
  }

  String formatSlotTime(DateTime startTime, DateTime endTime) {
    final DateFormat timeFormat = DateFormat('h:mm');
    return '${timeFormat.format(startTime)} - ${timeFormat.format(endTime)}';
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
              color: Colors.black,
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
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.height * 0.24,
                          width: MediaQuery.of(context).size.width * 0.95,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 0),
                          padding: const EdgeInsets.only(bottom: 5.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            // Center the Lottie animation within the container
                            child: Transform.scale(
                              scale:
                                  orderLottieTransform, // Increase the size by 30%
                              child: lt.Lottie.network(
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
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 0,
                                  offset: const Offset(
                                      0, 1), // Changes position of shadow
                                ),
                              ],
                              border:
                                  Border.all(color: Colors.white, width: 1.0),
                            ),
                            child: (orderStatus == "received" ||
                                    orderStatus == "accepted")
                                ? (orderStatus == "received"
                                    ? const Text(
                                        "Order accepted", // Right side text, assuming orderStatus is a variable holding the status
                                        textAlign: TextAlign
                                            .right, // Aligns text to the right
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurpleAccent,
                                        ),
                                      )
                                    : const Text(
                                        "Order getting packed", // Right side text, assuming orderStatus is a variable holding the status
                                        textAlign: TextAlign
                                            .right, // Aligns text to the right
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurpleAccent,
                                        ),
                                      ))
                                : Text(
                                    "Order $orderStatus", // Right side text, assuming orderStatus is a variable holding the status
                                    textAlign: TextAlign
                                        .right, // Aligns text to the right
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurpleAccent,
                                    ),
                                  )),

                        const SizedBox(height: 15),

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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.25,
                                    child: const Text("Order Date"),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    // Assuming _orderInfo!.orderDate is a string representing a date,
                                    // you'll first need to parse it into a DateTime object.
                                    // Then, add 5 hours and 30 minutes to it.
                                    // Finally, format it using the DateFormat class.
                                    formatDate(
                                        _orderInfo!.orderDate.toString()),
                                  )
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.25,
                                    child: const Text("Delivery Date"),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.lightGreenAccent,
                                          borderRadius: BorderRadius.circular(
                                              15), // Rounded corners
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.2),
                                              spreadRadius: 1,
                                              blurRadius: 1,
                                              offset: const Offset(0,
                                                  1), // Changes position of shadow
                                            ),
                                          ],
                                          border: Border.all(
                                              color: Colors.white, width: 2.0),
                                        ),
                                        child: Text(
                                          formatDeliveryDate(
                                                  _orderInfo!.deliveryDate)
                                              .toString(), // Added a space for visual separation
                                          style: const TextStyle(
                                            fontSize:
                                                14, // This adds the line through effect
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.lightGreenAccent,
                                          borderRadius: BorderRadius.circular(
                                              15), // Rounded corners
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.2),
                                              spreadRadius: 1,
                                              blurRadius: 1,
                                              offset: const Offset(0,
                                                  1), // Changes position of shadow
                                            ),
                                          ],
                                          border: Border.all(
                                              color: Colors.white, width: 2.0),
                                        ),
                                        child: Text(
                                            // Assuming _orderInfo!.orderDate is a string representing a date,
                                            // you'll first need to parse it into a DateTime object.
                                            // Then, add 5 hours and 30 minutes to it.
                                            // Finally, format it using the DateFormat class.
                                            formatSlotTime(
                                                _orderInfo!.slotStartTime,
                                                _orderInfo!.slotEndTime)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.25,
                                      child: const Text("Payment Type")),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurpleAccent,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Text(_orderInfo!.paymentType,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisSize: MainAxisSize
                                    .min, // To make the Row take minimum space
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.25,
                                    child: const Text(
                                      "subtotal",
                                      maxLines: 3,
                                      style: TextStyle(
                                          fontWeight: FontWeight.normal),
                                      overflow: TextOverflow
                                          .ellipsis, // To handle long item names
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurpleAccent,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Text(
                                        '\u{20B9} ${_orderInfo!.subtotal}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Provide some spacing after the title
                              Wrap(
                                spacing: 10, // Horizontal space between widgets
                                runSpacing:
                                    10, // Vertical space between widgets
                                children: _orderInfo!.items.map((item) {
                                  return Row(
                                    mainAxisSize: MainAxisSize
                                        .min, // To make the Row take minimum space
                                    children: [
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.55,
                                        child: Text(
                                          "${item.quantity.toString()} x  ${item.name} ${item.size}${item.unitOfQuantity}",
                                          maxLines: 3,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.normal),
                                          overflow: TextOverflow
                                              .ellipsis, // To handle long item names
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '\u{20B9} ${item.soldPrice}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                              _orderInfo!.platformFee > 0
                                  ? Row(
                                      mainAxisSize: MainAxisSize
                                          .min, // To make the Row take minimum space
                                      children: [
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.55,
                                          child: const Text(
                                            "platform fee",
                                            maxLines: 3,
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.normal),
                                            overflow: TextOverflow
                                                .ellipsis, // To handle long item names
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          '\u{20B9} ${_orderInfo!.platformFee}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                              _orderInfo!.deliveryFee > 0
                                  ? Row(
                                      mainAxisSize: MainAxisSize
                                          .min, // To make the Row take minimum space
                                      children: [
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.55,
                                          child: const Text(
                                            "delivery fee",
                                            maxLines: 3,
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.normal),
                                            overflow: TextOverflow
                                                .ellipsis, // To handle long item names
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          '\u{20B9} ${_orderInfo!.deliveryFee}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                              _orderInfo!.smallOrderFee > 0
                                  ? Row(
                                      mainAxisSize: MainAxisSize
                                          .min, // To make the Row take minimum space
                                      children: [
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.55,
                                          child: const Text(
                                            "small order fee",
                                            maxLines: 3,
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.normal),
                                            overflow: TextOverflow
                                                .ellipsis, // To handle long item names
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          '\u{20B9} ${_orderInfo!.smallOrderFee}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

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
  final DateTime orderDate;
  final int totalAmountPaid;
  final List<Item> items;
  final String address;
  // Added fields for fees and subtotal
  final int itemCost;
  final int deliveryFee;
  final int platformFee;
  final int smallOrderFee;
  final int rainFee;
  final int highTrafficSurcharge;
  final int packagingFee;
  final int peakTimeSurcharge;
  final int subtotal;
  final DateTime deliveryDate;
  final DateTime slotStartTime;
  final DateTime slotEndTime;
  final int newCartId;

  OrderInfo({
    required this.orderStatus,
    required this.orderDpStatus,
    required this.paymentType,
    required this.paidStatus,
    required this.orderDate,
    required this.totalAmountPaid,
    required this.items,
    required this.address,
    required this.itemCost,
    required this.deliveryFee,
    required this.platformFee,
    required this.smallOrderFee,
    required this.rainFee,
    required this.highTrafficSurcharge,
    required this.packagingFee,
    required this.peakTimeSurcharge,
    required this.subtotal,
    required this.deliveryDate,
    required this.slotStartTime,
    required this.slotEndTime,
    required this.newCartId,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    final dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS Z");
    final deliveryDateFormat = DateFormat("yyyy-MM-dd HH:mm:ss Z");

    return OrderInfo(
      orderStatus: json['order_status'],
      orderDpStatus: json['order_dp_status'],
      paymentType: json['payment_type'],
      paidStatus: json['paid_status'],
      orderDate: dateFormat.parse(json['order_date'].replaceFirst(' UTC', '')),
      totalAmountPaid: json['total_amount_paid'],
      items: List<Item>.from(json['items'].map((i) => Item.fromJson(i))),
      address: json['address'],
      itemCost: json['item_cost'],
      deliveryFee: json['delivery_fee'],
      platformFee: json['platform_fee'],
      smallOrderFee: json['small_order_fee'],
      rainFee: json['rain_fee'],
      highTrafficSurcharge: json['high_traffic_surcharge'],
      packagingFee: json['packaging_fee'],
      peakTimeSurcharge: json['peak_time_surcharge'],
      subtotal: json['subtotal'],
      deliveryDate: deliveryDateFormat
          .parse(json['delivery_date'].replaceFirst(' UTC', '')),
      slotStartTime: DateTime.parse(json['slot_start_time']),
      slotEndTime: DateTime.parse(json['slot_end_time']),
      newCartId: json['new_cart_id'],
    );
  }
}

class Item {
  final String name;
  final String image;
  final int quantity;
  final String unitOfQuantity;
  final int size;
  final int soldPrice; // Added field

  Item({
    required this.name,
    required this.image,
    required this.quantity,
    required this.unitOfQuantity,
    required this.size,
    required this.soldPrice, // Initialize the new field
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      name: json['name'],
      image: json['image'],
      quantity: json['quantity'],
      unitOfQuantity: json['unit_of_quantity'],
      size: json['size'],
      soldPrice: json['sold_price'], // Map the JSON field
    );
  }
}
