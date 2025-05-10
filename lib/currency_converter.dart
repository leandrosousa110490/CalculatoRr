import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class CurrencyData {
  final String code;
  final String name;
  final String symbol;
  final double rate;

  CurrencyData({
    required this.code,
    required this.name,
    required this.symbol,
    required this.rate,
  });

  factory CurrencyData.fromJson(Map<String, dynamic> json, String code) {
    return CurrencyData(
      code: code,
      name: json['name'] ?? code,
      symbol: json['symbol'] ?? code,
      rate: json['value']?.toDouble() ?? 1.0,
    );
  }
}

class CurrencyService {
  // Using the Exchange Rate API
  static const String apiKey =
      'YOUR_API_KEY'; // Replace with your actual API key
  static const String baseUrl =
      'https://api.exchangerate-api.com/v4/latest/USD';

  // For demo purposes, we're using a free tier without an API key
  // You might want to replace this with a more reliable API in production

  static Future<Map<String, CurrencyData>> fetchCurrencyRates() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        final result = <String, CurrencyData>{};

        // Common currency symbols
        final symbols = {
          'USD': '\$',
          'EUR': '€',
          'GBP': '£',
          'JPY': '¥',
          'AUD': 'A\$',
          'CAD': 'CA\$',
          'CHF': 'Fr',
          'CNY': '¥',
          'INR': '₹',
          'MXN': 'Mex\$',
          'BRL': 'R\$',
          'RUB': '₽',
          'KRW': '₩',
          'TRY': '₺',
          'ZAR': 'R',
          'SEK': 'kr',
          'NOK': 'kr',
          'DKK': 'kr',
          'NZD': 'NZ\$',
          'PLN': 'zł',
          'THB': '฿',
          'IDR': 'Rp',
          'HUF': 'Ft',
          'CZK': 'Kč',
          'ILS': '₪',
          'CLP': 'CLP\$',
          'PHP': '₱',
          'AED': 'د.إ',
          'COP': 'COL\$',
          'SAR': '﷼',
          'MYR': 'RM',
          'RON': 'lei',
        };

        // Common currency names
        final names = {
          'USD': 'US Dollar',
          'EUR': 'Euro',
          'GBP': 'British Pound',
          'JPY': 'Japanese Yen',
          'AUD': 'Australian Dollar',
          'CAD': 'Canadian Dollar',
          'CHF': 'Swiss Franc',
          'CNY': 'Chinese Yuan',
          'INR': 'Indian Rupee',
          'MXN': 'Mexican Peso',
          'BRL': 'Brazilian Real',
          'RUB': 'Russian Ruble',
          'KRW': 'South Korean Won',
          'TRY': 'Turkish Lira',
          'ZAR': 'South African Rand',
          'SEK': 'Swedish Krona',
          'NOK': 'Norwegian Krone',
          'DKK': 'Danish Krone',
          'NZD': 'New Zealand Dollar',
          'PLN': 'Polish Złoty',
          'THB': 'Thai Baht',
          'IDR': 'Indonesian Rupiah',
          'HUF': 'Hungarian Forint',
          'CZK': 'Czech Koruna',
          'ILS': 'Israeli New Shekel',
          'CLP': 'Chilean Peso',
          'PHP': 'Philippine Peso',
          'AED': 'United Arab Emirates Dirham',
          'COP': 'Colombian Peso',
          'SAR': 'Saudi Riyal',
          'MYR': 'Malaysian Ringgit',
          'RON': 'Romanian Leu',
        };

        rates.forEach((key, value) {
          result[key] = CurrencyData(
            code: key,
            name: names[key] ?? key,
            symbol: symbols[key] ?? key,
            rate: (value is num) ? value.toDouble() : 1.0,
          );
        });

        return result;
      } else {
        throw Exception('Failed to load currency data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch currency data: $e');

      // If API fails, return fallback data
      // This is just for demo - you should handle errors properly in production
      // return _getFallbackData();
    }
  }

  // Fallback data in case the API doesn't work
  static Map<String, CurrencyData> _getFallbackData() {
    final mockRates = {
      'USD': 1.0,
      'EUR': 0.92,
      'GBP': 0.78,
      'JPY': 149.82,
      'AUD': 1.52,
      'CAD': 1.35,
      'CHF': 0.90,
      'CNY': 7.24,
      'INR': 83.12,
      'MXN': 16.76,
    };

    final result = <String, CurrencyData>{};
    mockRates.forEach((key, value) {
      result[key] = CurrencyData(
        code: key,
        name: key,
        symbol: key,
        rate: value,
      );
    });

    return result;
  }
}

class CurrencyConverter extends StatefulWidget {
  const CurrencyConverter({super.key});

  @override
  State<CurrencyConverter> createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<CurrencyConverter> {
  final TextEditingController _amountController =
      TextEditingController(text: '1');

  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';
  double _amount = 1.0;

  Map<String, CurrencyData> _currencies = {};
  bool _isLoading = true;
  String _errorMessage = '';
  DateTime _lastUpdated = DateTime.now();

  // For beautiful formatting of the result
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();

    // Force portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _fetchCurrencyData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrencyData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final currencies = await CurrencyService.fetchCurrencyRates();
      setState(() {
        _currencies = currencies;
        _lastUpdated = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load currency data: $e';
        _isLoading = false;
      });
    }
  }

  double _convertCurrency() {
    if (_currencies.isEmpty) return 0.0;

    final fromRate = _currencies[_fromCurrency]?.rate ?? 1.0;
    final toRate = _currencies[_toCurrency]?.rate ?? 1.0;

    // Convert to USD first (base currency), then to target currency
    return _amount * (toRate / fromRate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Converter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCurrencyData,
            tooltip: 'Refresh Rates',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Data',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchCurrencyData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Last updated timestamp
                      Text(
                        'Last Updated: ${DateFormat('MMM d, yyyy HH:mm').format(_lastUpdated)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Amount input card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Amount',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Enter Amount',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: Icon(
                                    Icons.attach_money,
                                    color: colorScheme.primary,
                                  ),
                                  prefixText:
                                      _currencies[_fromCurrency]?.symbol ?? '',
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _amount = double.tryParse(value) ?? 0.0;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Currency selection card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Currencies',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),

                              // From currency dropdown
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'From',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.currency_exchange),
                                ),
                                value: _fromCurrency,
                                items: _currencies.keys.map((String currency) {
                                  return DropdownMenuItem<String>(
                                    value: currency,
                                    child: Container(
                                      constraints:
                                          const BoxConstraints(maxWidth: 250),
                                      child: Text(
                                        '${currency} - ${_currencies[currency]?.name}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _fromCurrency = newValue;
                                    });
                                  }
                                },
                                isExpanded: true,
                              ),

                              const SizedBox(height: 8),

                              // Swap currencies button
                              Center(
                                child: IconButton(
                                  icon: const Icon(Icons.swap_vert),
                                  onPressed: () {
                                    setState(() {
                                      final temp = _fromCurrency;
                                      _fromCurrency = _toCurrency;
                                      _toCurrency = temp;
                                    });
                                  },
                                  tooltip: 'Swap Currencies',
                                ),
                              ),

                              const SizedBox(height: 8),

                              // To currency dropdown
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'To',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.currency_exchange),
                                ),
                                value: _toCurrency,
                                items: _currencies.keys.map((String currency) {
                                  return DropdownMenuItem<String>(
                                    value: currency,
                                    child: Container(
                                      constraints:
                                          const BoxConstraints(maxWidth: 250),
                                      child: Text(
                                        '${currency} - ${_currencies[currency]?.name}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _toCurrency = newValue;
                                    });
                                  }
                                },
                                isExpanded: true,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Result card
                      Card(
                        elevation: 4,
                        color: colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                'Result',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${_currencies[_fromCurrency]?.symbol ?? _fromCurrency} ',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      _currencyFormat.format(_amount),
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        color: colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Icon(Icons.arrow_downward),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${_currencies[_toCurrency]?.symbol ?? _toCurrency} ',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      _currencyFormat
                                          .format(_convertCurrency()),
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                        color: colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Exchange Rate',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer
                                      .withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '1 $_fromCurrency = ${_currencyFormat.format(_currencies[_toCurrency]!.rate / _currencies[_fromCurrency]!.rate)} $_toCurrency',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Quick conversions section
                      if (_amount > 0) ...[
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quick Conversions',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                const Divider(),
                                const SizedBox(height: 8),
                                ..._getQuickConversions(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  List<Widget> _getQuickConversions() {
    final widgets = <Widget>[];
    final fromRate = _currencies[_fromCurrency]?.rate ?? 1.0;

    // Only show 5 popular currencies
    final popularCurrencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD'];

    for (final code in popularCurrencies) {
      // Skip the from currency
      if (code == _fromCurrency) continue;

      final currency = _currencies[code];
      if (currency != null) {
        final toRate = currency.rate;
        final convertedAmount = _amount * (toRate / fromRate);

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '${currency.code} - ${currency.name}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${currency.symbol} ',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(convertedAmount),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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

    return widgets;
  }
}
