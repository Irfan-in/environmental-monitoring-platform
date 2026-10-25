import 'package:flutter/material.dart';
import 'package:environmental_monitoring_platform/theme/wx_style.dart';

class ComparisonBar extends StatelessWidget {
  final String label;
  final double indoorVal;
  final double outdoorVal;
  final String unit;
  final Color? indoorColor;
  final Color? outdoorColor;

  const ComparisonBar({
    super.key,
    required this.label,
    required this.indoorVal,
    required this.outdoorVal,
    required this.unit,
    this.indoorColor,
    this.outdoorColor,
  });

  @override
  Widget build(BuildContext context) {
    final wx = Wx.of(context);
    final inColor = indoorColor ?? wx.accent;
    final outColor = outdoorColor ?? wx.outdoorLine;

    final diff = indoorVal - outdoorVal;
    final diffSign = diff > 0 ? '+' : '';
    final diffColor = diff > 0 ? wx.outdoorLine : wx.accent;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: wx.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: wx.t(15, w: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Δ $diffSign${diff.toStringAsFixed(1)} $unit',
                  style: TextStyle(
                    color: diffColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: inColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Indoor',
                          style: wx.t(12, c: wx.textDim),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${indoorVal.toStringAsFixed(1)} $unit',
                      style: TextStyle(
                        color: inColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 36,
                width: 1,
                color: wx.textDim.withValues(alpha: 0.2),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: outColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Outdoor',
                            style: wx.t(12, c: wx.textDim),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${outdoorVal.toStringAsFixed(1)} $unit',
                        style: TextStyle(
                          color: outColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
