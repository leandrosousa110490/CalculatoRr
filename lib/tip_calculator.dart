import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';

class TipCalculator extends StatefulWidget {
  const TipCalculator({super.key});

  @override
  State<TipCalculator> createState() => _TipCalculatorState();
}

class _TipCalculatorState extends State<TipCalculator>
    with SingleTickerProviderStateMixin {
  // Currency formatter
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  // Controllers for the text fields
  final TextEditingController _billAmountController = TextEditingController();
  final TextEditingController _tipPercentController = TextEditingController(
    text: '15',
  );
  final TextEditingController _numberOfPeopleController = TextEditingController(
    text: '1',
  );

  // Values for calculations
  double _billAmount = 0.0;
  double _tipPercent = 15.0;
  int _numberOfPeople = 1;

  // Results
  double _tipAmount = 0.0;
  double _totalAmount = 0.0;
  double _perPersonAmount = 0.0;
  double _perPersonBillAmount = 0.0;
  double _perPersonTipAmount = 0.0;

  // For pie chart interaction
  int _touchedIndex = -1;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Force portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize animation first
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    // Calculate tip only after animation setup is complete
    _calculateTip();

    // Start animation after everything is initialized
    _animationController.forward();
  }

  @override
  void dispose() {
    _billAmountController.dispose();
    _tipPercentController.dispose();
    _numberOfPeopleController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _calculateTip() {
    setState(() {
      _billAmount =
          double.tryParse(_billAmountController.text.replaceAll(',', '')) ??
              0.0;
      _tipPercent = double.tryParse(_tipPercentController.text) ?? 15.0;
      _numberOfPeople = int.tryParse(_numberOfPeopleController.text) ?? 1;

      _tipAmount = (_billAmount * _tipPercent) / 100;
      _totalAmount = _billAmount + _tipAmount;
      _perPersonAmount = _totalAmount / _numberOfPeople;
      _perPersonBillAmount = _billAmount / _numberOfPeople;
      _perPersonTipAmount = _tipAmount / _numberOfPeople;

      // Only reset animation if it's already been initialized
      if (_animationController.isAnimating) {
        _animationController.reset();
        _animationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tip Calculator'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input fields section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bill Details', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _billAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Bill Amount (\$)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                        _ThousandsSeparatorInputFormatter(),
                      ],
                      onChanged: (_) => _calculateTip(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tipPercentController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Tip %',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.percent),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            onChanged: (_) => _calculateTip(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _numberOfPeopleController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Number of People',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.people),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => _calculateTip(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Tip percentage slider
                    Row(
                      children: [
                        const Text('Tip %:'),
                        Expanded(
                          child: Slider(
                            value: _tipPercent,
                            min: 0,
                            max: 30,
                            divisions: 30,
                            label: '${_tipPercent.round()}%',
                            onChanged: (value) {
                              setState(() {
                                _tipPercent = value;
                                _tipPercentController.text =
                                    value.round().toString();
                                _calculateTip();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Results section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Results', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    ResultRow(
                      label: 'Bill Amount:',
                      amount: _billAmount,
                      color: Colors.grey,
                      currencyFormat: _currencyFormat,
                    ),
                    const SizedBox(height: 8),
                    ResultRow(
                      label: 'Tip Amount (${_tipPercent.round()}%):',
                      amount: _tipAmount,
                      color: colorScheme.primary,
                      currencyFormat: _currencyFormat,
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    ResultRow(
                      label: 'Total Amount:',
                      amount: _totalAmount,
                      color: Colors.black,
                      isBold: true,
                      currencyFormat: _currencyFormat,
                    ),
                    if (_numberOfPeople > 1) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      Text(
                        'Per Person Breakdown:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ResultRow(
                        label: 'Bill Per Person:',
                        amount: _perPersonBillAmount,
                        color: Colors.grey,
                        currencyFormat: _currencyFormat,
                      ),
                      const SizedBox(height: 8),
                      ResultRow(
                        label: 'Tip Per Person:',
                        amount: _perPersonTipAmount,
                        color: colorScheme.primary,
                        currencyFormat: _currencyFormat,
                      ),
                      const SizedBox(height: 8),
                      ResultRow(
                        label: 'Total Per Person:',
                        amount: _perPersonAmount,
                        color: colorScheme.secondary,
                        isBold: true,
                        currencyFormat: _currencyFormat,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Interactive pie chart breakdown
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Visual Breakdown', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    if (_billAmount > 0) ...[
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 250,
                            child: AnimatedBuilder(
                              animation: _animation,
                              builder: (context, child) {
                                return PieChart(
                                  PieChartData(
                                    pieTouchData: PieTouchData(
                                      touchCallback: (
                                        FlTouchEvent event,
                                        pieTouchResponse,
                                      ) {
                                        setState(() {
                                          if (!event
                                                  .isInterestedForInteractions ||
                                              pieTouchResponse == null ||
                                              pieTouchResponse.touchedSection ==
                                                  null) {
                                            _touchedIndex = -1;
                                            return;
                                          }
                                          _touchedIndex = pieTouchResponse
                                              .touchedSection!
                                              .touchedSectionIndex;
                                        });
                                      },
                                    ),
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                    sections: [
                                      PieChartSectionData(
                                        color: Colors.grey.shade400,
                                        value: _billAmount,
                                        title: 'Bill',
                                        radius: _touchedIndex == 0
                                            ? 110
                                            : 100 * _animation.value,
                                        titleStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        badgeWidget: _touchedIndex == 0
                                            ? _Badge(
                                                _currencyFormat.format(
                                                  _billAmount,
                                                ),
                                                Colors.grey.shade400,
                                              )
                                            : null,
                                        badgePositionPercentageOffset: 1.2,
                                      ),
                                      PieChartSectionData(
                                        color: colorScheme.primary,
                                        value: _tipAmount,
                                        title: '${_tipPercent.round()}%',
                                        radius: _touchedIndex == 1
                                            ? 110
                                            : 100 * _animation.value,
                                        titleStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        badgeWidget: _touchedIndex == 1
                                            ? _Badge(
                                                _currencyFormat.format(
                                                  _tipAmount,
                                                ),
                                                colorScheme.primary,
                                              )
                                            : null,
                                        badgePositionPercentageOffset: 1.2,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          // Center of chart is kept empty for cleaner look
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Interactive legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem(
                            'Bill',
                            Colors.grey.shade400,
                            _currencyFormat.format(_billAmount),
                            onTap: () => setState(
                              () => _touchedIndex = _touchedIndex == 0 ? -1 : 0,
                            ),
                            isSelected: _touchedIndex == 0,
                          ),
                          const SizedBox(width: 24),
                          _buildLegendItem(
                            'Tip',
                            colorScheme.primary,
                            _currencyFormat.format(_tipAmount),
                            onTap: () => setState(
                              () => _touchedIndex = _touchedIndex == 1 ? -1 : 1,
                            ),
                            isSelected: _touchedIndex == 1,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Tap chart or legend to see details',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ] else ...[
                      const Center(
                        child: Text(
                          'Enter bill amount to see the breakdown',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    String label,
    Color color,
    String amount, {
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: color, width: 2) : null,
          color: isSelected ? color.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  amount,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Badge widget for pie chart
class _Badge extends StatelessWidget {
  final String amount;
  final Color color;

  const _Badge(this.amount, this.color);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        amount,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ResultRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isBold;
  final NumberFormat currencyFormat;

  const ResultRow({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
    required this.currencyFormat,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        Text(
          currencyFormat.format(amount),
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Custom input formatter to add thousands separators
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final NumberFormat _numberFormat = NumberFormat('#,##0.##', 'en_US');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Only format if the text has changed and contains digits
    if (newValue.text != oldValue.text &&
        RegExp(r'^\d*\.?\d*$').hasMatch(newValue.text.replaceAll(',', ''))) {
      // Remove all commas
      final String newText = newValue.text.replaceAll(',', '');

      // Split on decimal point
      final parts = newText.split('.');

      // Format the whole number part
      String formattedValue = '';
      if (parts[0].isNotEmpty) {
        formattedValue = _numberFormat.format(int.parse(parts[0]));
      } else {
        formattedValue = '0';
      }

      // Add back the decimal part if it exists
      if (parts.length > 1) {
        formattedValue = '$formattedValue.${parts[1]}';
      }

      // If the original ends with a decimal point, make sure we keep it
      if (newText.endsWith('.')) {
        formattedValue = '$formattedValue';
      }

      return TextEditingValue(
        text: formattedValue,
        selection: TextSelection.collapsed(offset: formattedValue.length),
      );
    }

    return newValue;
  }
}
