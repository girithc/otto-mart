import 'package:flutter/material.dart';
import 'package:pronto/utils/network/service.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key, required this.cartId, required this.orderId});

  final String cartId;
  final String orderId;

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  @override
  void initState() {
    super.initState();
    getOrder();
  }

  Future<void> getOrder() async {
    Map<String, dynamic> body = {
      "cart_id": int.parse(widget.cartId),
      "order_id": int.parse(widget.orderId)
    };

    final networkService = NetworkService();

    final response =
        await networkService.postWithAuth('/sales-order', additionalData: body);
    if (response.statusCode == 200) {
      print(response.body);
    } else {
      print(response.body);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
