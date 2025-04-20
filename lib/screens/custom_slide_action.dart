import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class CustomIconSlideAction extends StatelessWidget {
  const CustomIconSlideAction({
    Key? key,
    required this.onTap,
    required this.icon,
    this.color,
    this.label,
  }) : super(key: key);

  final VoidCallback onTap;
  final Widget icon;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: color,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            if (label != null)
              Text(
                label!,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}