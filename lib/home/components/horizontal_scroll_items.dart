import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class HorizontalScrollItems extends StatelessWidget {
  const HorizontalScrollItems({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        CarouselSlider(
          items: [
            GestureDetector(
              onTap: () {},
              child: Card(
                elevation: 5,
                shadowColor: Colors.transparent,
                color: Colors.white,
                child: SizedBox(
                  width: 300,
                  height: 500,
                  child: Stack(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              'Product-1',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              // Add your button logic here
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  12.0, // Adjust the value for squareness
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal:
                                    16.0, // Adjust the horizontal padding
                                vertical: 8.0, // Adjust the vertical padding
                              ),
                            ),
                            child: const Text('Add'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Card(
                elevation: 5,
                shadowColor: Colors.transparent,
                color: Colors.white,
                child: SizedBox(
                  width: 300,
                  height: 500,
                  child: Stack(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              'Product-2',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              // Add your button logic here
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  12.0,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal:
                                    16.0, // Adjust the horizontal padding
                                vertical: 8.0, // Adjust the vertical padding
                              ),
                            ),
                            child: const Text('Add'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Card(
                elevation: 5,
                shadowColor: Colors.transparent,
                color: Colors.white,
                child: SizedBox(
                  width: 300,
                  height: 500,
                  child: Stack(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              'Product-3',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              // Add your button logic here
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  12.0, // Adjust the value for squareness
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal:
                                    16.0, // Adjust the horizontal padding
                                vertical: 8.0, // Adjust the vertical padding
                              ),
                            ),
                            child: const Text('Add'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Add more cards with different texts here...
          ],

          //Slider Container properties
          options: CarouselOptions(
            height: 150.0,
            enlargeCenterPage: false,
            autoPlay: false,
            aspectRatio: 4 / 9,
            autoPlayCurve: Curves.fastOutSlowIn,
            enableInfiniteScroll: true,
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            viewportFraction: 0.33,
          ),
        ),
      ],
    );
  }
}
