import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class LoanCalculator extends StatefulWidget {
  const LoanCalculator({super.key});

  @override
  State<LoanCalculator> createState() => _LoanCalculatorState();
}

class _LoanCalculatorState extends State<LoanCalculator>
    with SingleTickerProviderStateMixin {
  // Currency formatter
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  // Controllers for the text fields
  final TextEditingController _loanAmountController = TextEditingController();
  final TextEditingController _interestRateController =
      TextEditingController(text: '5.0');
  final TextEditingController _loanTermController =
      TextEditingController(text: '30');
  final TextEditingController _propertyTaxController = TextEditingController();
  final TextEditingController _homeInsuranceController =
      TextEditingController();
  final TextEditingController _pmiController = TextEditingController();

  // Toggle for advanced options
  bool _showAdvancedOptions = false;

  // Values for calculations
  double _loanAmount = 0.0;
  double _interestRate = 5.0;
  int _loanTermYears = 30;
  double _propertyTax = 0.0;
  double _homeInsurance = 0.0;
  double _pmi = 0.0;

  // Results
  double _monthlyPayment = 0.0;
  double _totalPayment = 0.0;
  double _totalInterest = 0.0;
  double _monthlyPropertyTax = 0.0;
  double _monthlyHomeInsurance = 0.0;
  double _monthlyPmi = 0.0;
  double _totalMonthlyPayment = 0.0;

  // For chart animation
  late AnimationController _animationController;
  late Animation<double> _animation;

  // For chart interaction
  int _touchedIndex = -1;
  int _hoverBarIndex = -1;
  Offset _hoverPosition = Offset.zero;

  // Chart display options
  bool _showPieChart = true;
  List<MonthlyPaymentData> _monthlyData = [];

  @override
  void initState() {
    super.initState();

    // Initialize animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    // Calculate initial values
    _calculateLoan();

    _animationController.forward();
  }

  @override
  void dispose() {
    _loanAmountController.dispose();
    _interestRateController.dispose();
    _loanTermController.dispose();
    _propertyTaxController.dispose();
    _homeInsuranceController.dispose();
    _pmiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _calculateLoan() {
    setState(() {
      // Parse inputs with safe defaults
      _loanAmount =
          double.tryParse(_loanAmountController.text.replaceAll(',', '')) ??
              0.0;
      _interestRate = double.tryParse(_interestRateController.text) ?? 5.0;
      _loanTermYears = int.tryParse(_loanTermController.text) ?? 30;
      _propertyTax =
          double.tryParse(_propertyTaxController.text.replaceAll(',', '')) ??
              0.0;
      _homeInsurance =
          double.tryParse(_homeInsuranceController.text.replaceAll(',', '')) ??
              0.0;
      _pmi = double.tryParse(_pmiController.text.replaceAll(',', '')) ?? 0.0;

      if (_loanAmount <= 0 || _interestRate <= 0 || _loanTermYears <= 0) {
        _monthlyPayment = 0.0;
        _totalPayment = 0.0;
        _totalInterest = 0.0;
        _monthlyPropertyTax = 0.0;
        _monthlyHomeInsurance = 0.0;
        _monthlyPmi = 0.0;
        _totalMonthlyPayment = 0.0;
        _monthlyData = [];
        return;
      }

      // Convert annual interest rate to monthly
      double monthlyRate = _interestRate / 100 / 12;
      int totalMonths = _loanTermYears * 12;

      // Calculate monthly payment using the formula:
      // P = L[c(1 + c)^n]/[(1 + c)^n - 1]
      // where P = payment, L = loan amount, c = monthly interest rate, n = number of payments
      double x = math.pow(1 + monthlyRate, totalMonths).toDouble();
      _monthlyPayment = _loanAmount * monthlyRate * x / (x - 1);

      // Calculate total payment and interest
      _totalPayment = _monthlyPayment * totalMonths;
      _totalInterest = _totalPayment - _loanAmount;

      // Calculate monthly property tax, insurance, and PMI
      _monthlyPropertyTax = _propertyTax / 12;
      _monthlyHomeInsurance = _homeInsurance / 12;
      _monthlyPmi = _pmi / 12;

      // Calculate total monthly payment (PITI - Principal, Interest, Taxes, Insurance)
      _totalMonthlyPayment = _monthlyPayment +
          _monthlyPropertyTax +
          _monthlyHomeInsurance +
          _monthlyPmi;

      // Generate monthly data for the bar chart
      _generateMonthlyData(totalMonths, monthlyRate);

      // Restart animation when values change
      _animationController.reset();
      _animationController.forward();
    });
  }

  void _generateMonthlyData(int totalMonths, double monthlyRate) {
    _monthlyData = [];

    // We'll limit the data points to avoid excessive computation
    // and make the chart more readable
    int interval =
        totalMonths > 120 ? 12 : 6; // Show yearly or half-yearly data points

    double remainingBalance = _loanAmount;

    for (int month = 1; month <= totalMonths; month++) {
      // Interest for this month
      double interestPayment = remainingBalance * monthlyRate;

      // Principal for this month
      double principalPayment = _monthlyPayment - interestPayment;

      // Update remaining balance
      remainingBalance -= principalPayment;

      // Store data at intervals
      if (month % interval == 0 || month == 1 || month == totalMonths) {
        _monthlyData.add(MonthlyPaymentData(
          month: month,
          principal: principalPayment,
          interest: interestPayment,
          balance: remainingBalance,
          totalPrincipalPaid: _loanAmount - remainingBalance,
          totalInterestPaid:
              (month * _monthlyPayment) - (_loanAmount - remainingBalance),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Calculator'),
        elevation: 0,
      ),
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
                    Text(
                      'Loan Details',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _loanAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Loan Amount (\$)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                        _ThousandsSeparatorInputFormatter(),
                      ],
                      onChanged: (_) => _calculateLoan(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _interestRateController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Interest Rate (%)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.percent),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]')),
                            ],
                            onChanged: (_) => _calculateLoan(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _loanTermController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Term (Years)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => _calculateLoan(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Interest rate slider
                    Row(
                      children: [
                        const Text('Interest Rate:'),
                        Expanded(
                          child: Slider(
                            value: _interestRate,
                            min: 0.1,
                            max: 15.0,
                            divisions: 149,
                            label: '${_interestRate.toStringAsFixed(1)}%',
                            onChanged: (value) {
                              setState(() {
                                _interestRate = value;
                                _interestRateController.text =
                                    value.toStringAsFixed(1);
                                _calculateLoan();
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    // Advanced Options Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: TextButton.icon(
                            icon: Icon(_showAdvancedOptions
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down),
                            label: Text(
                              _showAdvancedOptions
                                  ? 'Hide Advanced Options'
                                  : 'Show Advanced (Taxes & Insurance)',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                            onPressed: () {
                              setState(() {
                                _showAdvancedOptions = !_showAdvancedOptions;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    // Advanced Options Fields (Property Tax, Insurance, PMI)
                    if (_showAdvancedOptions) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Annual Expenses',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _propertyTaxController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Annual Property Tax (\$)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.home),
                          helperText: 'Annual amount',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                          _ThousandsSeparatorInputFormatter(),
                        ],
                        onChanged: (_) => _calculateLoan(),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _homeInsuranceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Annual Home Insurance (\$)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.security),
                          helperText: 'Annual amount',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                          _ThousandsSeparatorInputFormatter(),
                        ],
                        onChanged: (_) => _calculateLoan(),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pmiController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monthly PMI (\$)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.shield),
                          helperText: 'Private Mortgage Insurance (monthly)',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                          _ThousandsSeparatorInputFormatter(),
                        ],
                        onChanged: (_) => _calculateLoan(),
                      ),
                    ],
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
                    Text(
                      'Payment Summary',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ResultRow(
                      label: 'Principal & Interest:',
                      amount: _monthlyPayment,
                      color: colorScheme.primary,
                      currencyFormat: _currencyFormat,
                      isBold: false,
                    ),
                    if (_monthlyPropertyTax > 0) ...[
                      const SizedBox(height: 8),
                      ResultRow(
                        label: 'Property Tax:',
                        amount: _monthlyPropertyTax,
                        color: Colors.orange,
                        currencyFormat: _currencyFormat,
                      ),
                    ],
                    if (_monthlyHomeInsurance > 0) ...[
                      const SizedBox(height: 8),
                      ResultRow(
                        label: 'Home Insurance:',
                        amount: _monthlyHomeInsurance,
                        color: Colors.blue,
                        currencyFormat: _currencyFormat,
                      ),
                    ],
                    if (_monthlyPmi > 0) ...[
                      const SizedBox(height: 8),
                      ResultRow(
                        label: 'PMI:',
                        amount: _monthlyPmi,
                        color: Colors.purple,
                        currencyFormat: _currencyFormat,
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Divider(),
                    ResultRow(
                      label: 'Total Monthly Payment:',
                      amount: _totalMonthlyPayment,
                      color: colorScheme.primary,
                      currencyFormat: _currencyFormat,
                      isBold: true,
                    ),
                    const SizedBox(height: 12),
                    const Divider(thickness: 2),
                    const SizedBox(height: 8),
                    ResultRow(
                      label: 'Loan Amount:',
                      amount: _loanAmount,
                      color: Colors.grey.shade700,
                      currencyFormat: _currencyFormat,
                    ),
                    const SizedBox(height: 8),
                    ResultRow(
                      label: 'Total Interest:',
                      amount: _totalInterest,
                      color: colorScheme.error,
                      currencyFormat: _currencyFormat,
                    ),
                    if (_propertyTax > 0 || _homeInsurance > 0 || _pmi > 0) ...[
                      const SizedBox(height: 8),
                      ResultRow(
                        label: 'Total Additional Costs:',
                        amount: (_propertyTax + _homeInsurance + (_pmi * 12)) *
                            _loanTermYears,
                        color: Colors.orange.shade700,
                        currencyFormat: _currencyFormat,
                      ),
                    ],
                    const SizedBox(height: 8),
                    ResultRow(
                      label: 'Total Cost:',
                      amount: _totalPayment +
                          (_propertyTax + _homeInsurance + (_pmi * 12)) *
                              _loanTermYears,
                      color: Colors.black,
                      currencyFormat: _currencyFormat,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Chart toggle buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Pie Chart'),
                  selected: _showPieChart,
                  onSelected: (selected) {
                    setState(() {
                      _showPieChart = true;
                    });
                  },
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('Bar Chart'),
                  selected: !_showPieChart,
                  onSelected: (selected) {
                    setState(() {
                      _showPieChart = false;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Visualization section
            if (_loanAmount > 0) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _showPieChart
                            ? 'Payment Breakdown'
                            : 'Amortization Schedule',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),

                      // Pie chart for total payment breakdown
                      if (_showPieChart)
                        _buildPieChart(colorScheme)
                      // Bar chart for payment over time
                      else
                        _buildBarChart(colorScheme),

                      // Remove spacing
                      if (!_showPieChart) const SizedBox(height: 16),

                      // Legend for bar chart only - using wrap for better layout
                      if (!_showPieChart)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _buildLegendItem(
                              'Principal',
                              colorScheme.primary,
                              '',
                            ),
                            _buildLegendItem(
                              'Interest',
                              colorScheme.error,
                              '',
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Enter loan details to see visualizations',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(ColorScheme colorScheme) {
    // Only show tax, insurance and PMI if they are greater than 0
    bool hasAdditionalCosts =
        _monthlyPropertyTax > 0 || _monthlyHomeInsurance > 0 || _monthlyPmi > 0;

    // Determine which segments to show
    List<PieChartSectionData> sections = [];

    // Principal segment
    sections.add(
      PieChartSectionData(
        color: colorScheme.primary,
        value: _loanAmount,
        title: '', // Removed text for cleaner look
        radius: 100 * _animation.value,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: _touchedIndex == 0
            ? _Badge(
                'Principal',
                _currencyFormat.format(_loanAmount),
                colorScheme.primary,
              )
            : null,
        badgePositionPercentageOffset: 0.8,
      ),
    );

    // Interest segment
    sections.add(
      PieChartSectionData(
        color: colorScheme.error,
        value: _totalInterest,
        title: '',
        radius: _touchedIndex == 1
            ? 110 * _animation.value
            : 100 * _animation.value,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: _touchedIndex == 1
            ? _Badge(
                'Interest',
                _currencyFormat.format(_totalInterest),
                colorScheme.error,
              )
            : null,
        badgePositionPercentageOffset: 0.8,
      ),
    );

    // Property Tax segment
    if (_propertyTax > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.orange,
          value: _propertyTax * _loanTermYears,
          title: '',
          radius: _touchedIndex == 2
              ? 110 * _animation.value
              : 100 * _animation.value,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: _touchedIndex == 2
              ? _Badge(
                  'Property Tax',
                  _currencyFormat.format(_propertyTax * _loanTermYears),
                  Colors.orange,
                )
              : null,
          badgePositionPercentageOffset: 0.8,
        ),
      );
    }

    // Home Insurance segment
    if (_homeInsurance > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.blue,
          value: _homeInsurance * _loanTermYears,
          title: '',
          radius: _touchedIndex == 3
              ? 110 * _animation.value
              : 100 * _animation.value,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: _touchedIndex == 3
              ? _Badge(
                  'Insurance',
                  _currencyFormat.format(_homeInsurance * _loanTermYears),
                  Colors.blue,
                )
              : null,
          badgePositionPercentageOffset: 0.8,
        ),
      );
    }

    // PMI segment
    if (_pmi > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.purple,
          value: _pmi * 12 * _loanTermYears,
          title: '',
          radius: _touchedIndex == 4
              ? 110 * _animation.value
              : 100 * _animation.value,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: _touchedIndex == 4
              ? _Badge(
                  'PMI',
                  _currencyFormat.format(_pmi * 12 * _loanTermYears),
                  Colors.purple,
                )
              : null,
          badgePositionPercentageOffset: 0.8,
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 280,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: sections,
                    ),
                  ),
                  if (_touchedIndex == -1)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tap segments for details',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),

        // Interactive Legend - Use Wrap widget to prevent overflow
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            _buildInteractiveLegendItem(
              'Principal',
              colorScheme.primary,
              _currencyFormat.format(_loanAmount),
              onTap: () =>
                  setState(() => _touchedIndex = _touchedIndex == 0 ? -1 : 0),
              isSelected: _touchedIndex == 0,
            ),
            _buildInteractiveLegendItem(
              'Interest',
              colorScheme.error,
              _currencyFormat.format(_totalInterest),
              onTap: () =>
                  setState(() => _touchedIndex = _touchedIndex == 1 ? -1 : 1),
              isSelected: _touchedIndex == 1,
            ),
            if (_propertyTax > 0)
              _buildInteractiveLegendItem(
                'Property Tax',
                Colors.orange,
                _currencyFormat.format(_propertyTax * _loanTermYears),
                onTap: () =>
                    setState(() => _touchedIndex = _touchedIndex == 2 ? -1 : 2),
                isSelected: _touchedIndex == 2,
              ),
            if (_homeInsurance > 0)
              _buildInteractiveLegendItem(
                'Insurance',
                Colors.blue,
                _currencyFormat.format(_homeInsurance * _loanTermYears),
                onTap: () =>
                    setState(() => _touchedIndex = _touchedIndex == 3 ? -1 : 3),
                isSelected: _touchedIndex == 3,
              ),
            if (_pmi > 0)
              _buildInteractiveLegendItem(
                'PMI',
                Colors.purple,
                _currencyFormat.format(_pmi * 12 * _loanTermYears),
                onTap: () =>
                    setState(() => _touchedIndex = _touchedIndex == 4 ? -1 : 4),
                isSelected: _touchedIndex == 4,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInteractiveLegendItem(
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: color, width: 2) : null,
          color: isSelected ? color.withOpacity(0.1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (amount.isNotEmpty)
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(ColorScheme colorScheme) {
    if (_monthlyData.isEmpty) {
      return const SizedBox(
        height: 350,
        child: Center(
          child: Text(
            'Insufficient data to display chart',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    // Get max payment value for scaling (only principal + interest)
    double maxPayment = _monthlyPayment;

    // Simplify the data to avoid overcrowding
    // Only show a reasonable number of data points based on the term length
    final List<MonthlyPaymentData> displayData = [];
    final int totalMonths = _loanTermYears * 12;

    // Determine sampling interval based on loan length
    int sampleInterval;
    if (totalMonths <= 60) {
      // 5 years or less: show quarterly
      sampleInterval = 3;
    } else if (totalMonths <= 180) {
      // 15 years or less: show semi-annually
      sampleInterval = 6;
    } else if (totalMonths <= 240) {
      // 20 years or less: show annually
      sampleInterval = 12;
    } else {
      // More than 20 years: show every 2-5 years
      sampleInterval = 24;
    }

    // Sample the data at the determined interval, always include first and last
    for (int i = 0; i < _monthlyData.length; i++) {
      final data = _monthlyData[i];
      if (i == 0 ||
          i == _monthlyData.length - 1 ||
          data.month % sampleInterval == 0) {
        displayData.add(data);
      }
    }

    // Create a list of tooltips
    List<Widget> tooltips = [];
    if (_hoverBarIndex >= 0 && _hoverBarIndex < displayData.length) {
      // Get data for the hovered bar
      final data = displayData[_hoverBarIndex];

      // Calculate the year from the month
      int year = (data.month / 12).ceil();

      tooltips.add(
        Positioned(
          left: 20, // Fixed position on the left side
          top: 20, // Fixed position at the top
          child: Card(
            elevation: 6,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Container(
              padding: const EdgeInsets.all(10),
              width: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Year $year (Month ${data.month})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Principal:'),
                      Text(
                        _currencyFormat.format(data.principal),
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Interest:'),
                      Text(
                        _currencyFormat.format(data.interest),
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining:'),
                      Text(
                        _currencyFormat.format(data.balance),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        MouseRegion(
          onHover: (event) {
            setState(() {
              _hoverPosition = event.localPosition;
            });
          },
          child: SizedBox(
            height: 350,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceBetween,
                    maxY: maxPayment * 1.2, // Add 20% padding at top
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return null; // Using custom tooltips instead
                        },
                      ),
                      touchCallback: (FlTouchEvent event, barTouchResponse) {
                        setState(() {
                          if (event is FlPanEndEvent ||
                              event is FlPointerExitEvent) {
                            _hoverBarIndex = -1;
                          } else if (barTouchResponse != null &&
                              barTouchResponse.spot != null &&
                              event is! FlTapUpEvent) {
                            _hoverBarIndex =
                                barTouchResponse.spot!.touchedBarGroupIndex;
                          }
                        });
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            // Display year markers
                            final int barIndex = value.toInt();
                            if (barIndex < 0 ||
                                barIndex >= displayData.length) {
                              return const Text('');
                            }

                            final month = displayData[barIndex].month;
                            final year = (month / 12).ceil();

                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Y$year',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _hoverBarIndex == barIndex
                                      ? colorScheme.primary
                                      : Colors.grey[600],
                                  fontWeight: _hoverBarIndex == barIndex
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) {
                              return const Text('');
                            }

                            String label;
                            if (value >= 1000) {
                              label = '\$${(value / 1000).toStringAsFixed(0)}k';
                            } else {
                              label = '\$${value.toInt()}';
                            }

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            );
                          },
                          reservedSize: 42,
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                        left: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval:
                          maxPayment / 4, // 4 horizontal grid lines
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                        dashArray: [5, 5], // Dashed lines
                      ),
                    ),
                    barGroups: List.generate(
                      displayData.length,
                      (index) {
                        final data = displayData[index];

                        // Calculate animation progress for this specific bar
                        double animationProgress = _animation.value;

                        // Calculate width based on hover state
                        double width = _hoverBarIndex == index ? 22 : 18;

                        // Calculate scale effect for animation
                        double scale = _hoverBarIndex == index
                            ? 1.0 + (0.1 * animationProgress)
                            : 1.0;

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: (data.principal + data.interest) *
                                  animationProgress *
                                  scale,
                              width: width,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                              rodStackItems: [
                                // Principal
                                BarChartRodStackItem(
                                  0,
                                  data.principal * animationProgress * scale,
                                  colorScheme.primary,
                                ),
                                // Interest
                                BarChartRodStackItem(
                                  data.principal * animationProgress * scale,
                                  (data.principal + data.interest) *
                                      animationProgress *
                                      scale,
                                  colorScheme.error,
                                ),
                              ],
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxPayment,
                                color: Colors.grey.shade100,
                              ),
                            ),
                          ],
                          // Show a dot indicator on hover
                          showingTooltipIndicators:
                              _hoverBarIndex == index ? [0] : [],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        ...tooltips,
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, String amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade700,
              ),
            ),
            if (amount.isNotEmpty)
              Text(
                amount,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
      ],
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

class MonthlyPaymentData {
  final int month;
  final double principal;
  final double interest;
  final double balance;
  final double totalPrincipalPaid;
  final double totalInterestPaid;

  MonthlyPaymentData({
    required this.month,
    required this.principal,
    required this.interest,
    required this.balance,
    required this.totalPrincipalPaid,
    required this.totalInterestPaid,
  });
}

// Custom input formatter for thousands separators
// (reused from tip calculator)
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
        selection: TextSelection.collapsed(
          offset: formattedValue.length,
        ),
      );
    }

    return newValue;
  }
}

// Badge widget for pie chart
class _Badge extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;

  const _Badge(this.title, this.amount, this.color);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
