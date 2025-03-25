import 'package:flutter/material.dart';

class sdgCard extends StatelessWidget {
  final String url;
  const sdgCard({
    super.key,
    required this.url
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.asset(url,fit: BoxFit.cover,)),
    );
  }
}