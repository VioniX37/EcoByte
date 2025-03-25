import 'package:flutter/material.dart';

class Rewards extends StatelessWidget {
  final int score;
  Rewards({super.key, required this.score});

  final List company = [
    'zomato',
    'swiggy',
    'amazon',
    'Flipkart',
  ];
  final List<Color> bgcolors = [
    Colors.red,
    Colors.orange,
    Colors.black,
    Colors.blue
  ];
  final List<Color> text = [
    Colors.white,
    Colors.white,
    Colors.white,
    Colors.yellow
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rewards',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              "🏆 Your points : $score",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 20,
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: RewardCard(
                      company: company[index],
                      bgcolor: bgcolors[index],
                      textColor: text[index],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RewardCard extends StatelessWidget {
  const RewardCard(
      {Key? key,
      required this.company,
      required this.bgcolor,
      required this.textColor})
      : super(key: key);

  final String company;
  final Color bgcolor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Zomato Logo (Red Square with Logo)
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: bgcolor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  company,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Discount Text and Code
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '10% discount',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'on selected items\non $company',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("100 points required to avail this coupon"),
                  SizedBox(
                    height: 12,
                  ),
                  // Code container with eye icon
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_off,
                          size: 20,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'xxxxxxx32',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
