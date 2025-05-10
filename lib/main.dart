import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'tip_calculator.dart';
import 'loan_calculator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const CalculatorApp());
}

// Class to handle fraction operations
class Fraction {
  final int numerator;
  final int denominator;

  Fraction(this.numerator, this.denominator);

  Fraction.fromString(String numStr, String denStr)
      : numerator = int.parse(numStr),
        denominator = int.parse(denStr);

  // Factory to create a fraction from whole number
  factory Fraction.fromInt(int value) {
    return Fraction(value, 1);
  }

  // Factory to create a fraction from decimal
  factory Fraction.fromDouble(double value) {
    // Special case for infinity or NaN
    if (value.isInfinite || value.isNaN) {
      return Fraction(0, 1); // Default to 0 for invalid values
    }

    // Handle negative numbers
    bool isNegative = value < 0;
    value = value.abs();

    // For whole numbers
    if (value == value.truncate()) {
      return Fraction(isNegative ? -value.toInt() : value.toInt(), 1);
    }

    // Use a more accurate method for decimal-to-fraction conversion
    // First, try some common fractions
    const epsilon = 1e-10;

    // Check for common fractions with denominators up to 100
    for (int den = 2; den <= 100; den++) {
      for (int num = 1; num < den; num++) {
        double frac = num / den;
        if ((frac - value).abs() < epsilon) {
          return Fraction(isNegative ? -num : num, den);
        }
      }
    }

    // For more complex fractions, use continued fraction algorithm
    int maxIterations = 20; // Limit iterations for very complex fractions
    int a = value.floor();
    double rem = value - a;

    if (rem < epsilon) {
      return Fraction(isNegative ? -a : a, 1);
    }

    int n0 = 0, n1 = 1, d0 = 1, d1 = 0;
    double b = value;

    for (int i = 0; i < maxIterations && rem > epsilon; i++) {
      a = b.floor();
      b = 1 / (b - a);

      int n2 = a * n1 + n0;
      int d2 = a * d1 + d0;

      // Check if we're getting too large numbers
      if (n2 > 1000000 || d2 > 1000000) {
        break;
      }

      n0 = n1;
      n1 = n2;
      d0 = d1;
      d1 = d2;

      rem = (value - n1 / d1).abs();
      if (rem < epsilon) {
        return Fraction(isNegative ? -n1 : n1, d1);
      }
    }

    // If all else fails, use a simpler approximation with smaller denominator
    int precision = 1000; // Limit to avoid huge numbers
    int num = (value * precision).round();
    int gcd = _gcd(num, precision);
    return Fraction(
        isNegative ? -(num ~/ gcd) : (num ~/ gcd), precision ~/ gcd);
  }

  // Greatest common divisor for simplification
  static int _gcd(int a, int b) {
    while (b != 0) {
      var t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  // Simplify fraction
  Fraction simplified() {
    if (denominator == 0) return this; // Can't simplify division by zero

    int gcd = _gcd(numerator.abs(), denominator.abs());
    int sign = denominator < 0 ? -1 : 1;
    return Fraction(numerator * sign ~/ gcd, denominator.abs() ~/ gcd);
  }

  // Basic operations
  Fraction add(Fraction other) {
    return Fraction(
            numerator * other.denominator + other.numerator * denominator,
            denominator * other.denominator)
        .simplified();
  }

  Fraction subtract(Fraction other) {
    return Fraction(
            numerator * other.denominator - other.numerator * denominator,
            denominator * other.denominator)
        .simplified();
  }

  Fraction multiply(Fraction other) {
    return Fraction(
            numerator * other.numerator, denominator * other.denominator)
        .simplified();
  }

  Fraction divide(Fraction other) {
    return Fraction(
            numerator * other.denominator, denominator * other.numerator)
        .simplified();
  }

  @override
  String toString() {
    if (denominator == 1) {
      return numerator.toString();
    }
    return '$numerator/$denominator';
  }

  // Convert to decimal for some operations
  double toDouble() {
    return numerator / denominator;
  }
}

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _setThemeMode(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Professional Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      themeMode: _themeMode,
      home: ProfessionalCalculator(
        toggleTheme: _setThemeMode,
        currentThemeMode: _themeMode,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ProfessionalCalculator extends StatefulWidget {
  final Function(ThemeMode) toggleTheme;
  final ThemeMode currentThemeMode;

  const ProfessionalCalculator({
    super.key,
    required this.toggleTheme,
    required this.currentThemeMode,
  });

  @override
  State<ProfessionalCalculator> createState() => _ProfessionalCalculatorState();
}

class _ProfessionalCalculatorState extends State<ProfessionalCalculator> {
  // Input management
  String _input = '';

  // Result management
  String _displayResult = '0';
  bool _isError = false;
  bool _hasCalculated = false;

  // UI state
  final List<String> _history = [];
  bool _showHistory = false;
  bool _isScientificMode = false;

  // Fraction result for display
  bool _resultIsFraction = false;
  Fraction? _fractionResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Result widget based on state
    Widget resultWidget;
    if (_resultIsFraction && _fractionResult != null && _hasCalculated) {
      resultWidget = _buildFractionResult(_fractionResult!);
    } else {
      resultWidget = Text(
        _displayResult,
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: _isError ? colorScheme.error : colorScheme.onSurface,
        ),
        textAlign: TextAlign.right,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isScientificMode ? 'Scientific Calculator' : 'Standard Calculator',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TipCalculator()),
              );
            },
            tooltip: 'Tip Calculator',
          ),
          IconButton(
            icon: const Icon(Icons.attach_money),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoanCalculator()),
              );
            },
            tooltip: 'Loan Calculator',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _toggleHistory,
            tooltip: 'History',
          ),
          IconButton(
            icon: Icon(_isScientificMode ? Icons.calculate : Icons.science),
            onPressed: _toggleCalculatorMode,
            tooltip: _isScientificMode
                ? 'Switch to Standard'
                : 'Switch to Scientific',
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleTheme,
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
          ),
        ],
        elevation: 0,
        backgroundColor: colorScheme.surface,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Display Area
          Container(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            color: colorScheme.surface,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Expression display
                Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _input,
                    style: TextStyle(
                      fontSize: 20,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Result display
                Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: resultWidget,
                ),
              ],
            ),
          ),

          // History Panel (conditionally shown)
          if (_showHistory)
            Expanded(
              flex: 2,
              child: Container(
                color: colorScheme.surfaceVariant,
                child: _history.isEmpty
                    ? Center(
                        child: Text(
                          'No history yet',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        itemCount: _history.length,
                        separatorBuilder: (context, index) => Divider(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.2),
                        ),
                        itemBuilder: (context, index) {
                          final item = _history[_history.length - 1 - index];
                          final parts = item.split('=');

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              parts[0].trim(),
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            subtitle: Text(
                              '= ${parts[1].trim()}',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            onTap: () {
                              setState(() {
                                _displayResult = parts[1].trim();
                                _input = '';
                                _hasCalculated = true;

                                // Check if this is a fraction result
                                if (_displayResult.contains('/')) {
                                  try {
                                    final fracParts = _displayResult.split('/');
                                    final num = int.parse(fracParts[0]);
                                    final den = int.parse(fracParts[1]);
                                    _fractionResult = Fraction(num, den);
                                    _resultIsFraction = true;
                                  } catch (e) {
                                    _resultIsFraction = false;
                                  }
                                } else {
                                  _resultIsFraction = false;
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
            ),

          // Calculator Buttons
          Expanded(
            flex: _showHistory ? 3 : 5,
            child: Container(
              color: colorScheme.surface,
              child: Column(
                children: [
                  // Function buttons (top row)
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton(
                          'C',
                          isFunction: true,
                          onPressed: _clearAll,
                        ),
                        _buildButton(
                          '⌫',
                          isFunction: true,
                          onPressed: _deleteLastCharacter,
                        ),
                        _buildButton(
                          '%',
                          isFunction: true,
                          onPressed: () => _appendToInput('%'),
                        ),
                        _buildButton(
                          '÷',
                          isOperator: true,
                          onPressed: () => _appendToInput('÷'),
                        ),
                      ],
                    ),
                  ),
                  // Scientific functions
                  if (_isScientificMode)
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton(
                            'sin',
                            isFunction: true,
                            onPressed: () => _appendToInput('sin('),
                          ),
                          _buildButton(
                            'cos',
                            isFunction: true,
                            onPressed: () => _appendToInput('cos('),
                          ),
                          _buildButton(
                            'tan',
                            isFunction: true,
                            onPressed: () => _appendToInput('tan('),
                          ),
                          _buildButton(
                            'π',
                            isFunction: true,
                            onPressed: () => _appendToInput('${math.pi}'),
                          ),
                        ],
                      ),
                    ),
                  if (_isScientificMode)
                    Expanded(
                      child: Row(
                        children: [
                          _buildButton(
                            '(',
                            isFunction: true,
                            onPressed: () => _appendToInput('('),
                          ),
                          _buildButton(
                            ')',
                            isFunction: true,
                            onPressed: () => _appendToInput(')'),
                          ),
                          _buildButton(
                            '√',
                            isFunction: true,
                            onPressed: () => _appendToInput('sqrt('),
                          ),
                          _buildButton(
                            '^',
                            isFunction: true,
                            onPressed: () => _appendToInput('^'),
                          ),
                        ],
                      ),
                    ),
                  // Number rows
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton('7', onPressed: () => _appendToInput('7')),
                        _buildButton('8', onPressed: () => _appendToInput('8')),
                        _buildButton('9', onPressed: () => _appendToInput('9')),
                        _buildButton(
                          '×',
                          isOperator: true,
                          onPressed: () => _appendToInput('×'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton('4', onPressed: () => _appendToInput('4')),
                        _buildButton('5', onPressed: () => _appendToInput('5')),
                        _buildButton('6', onPressed: () => _appendToInput('6')),
                        _buildButton(
                          '-',
                          isOperator: true,
                          onPressed: () => _appendToInput('-'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton('1', onPressed: () => _appendToInput('1')),
                        _buildButton('2', onPressed: () => _appendToInput('2')),
                        _buildButton('3', onPressed: () => _appendToInput('3')),
                        _buildButton(
                          '+',
                          isOperator: true,
                          onPressed: () => _appendToInput('+'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton(
                          '/',
                          isFunction: true,
                          onPressed: () => _appendToInput('/'),
                        ),
                        _buildButton(
                          '0',
                          onPressed: () => _appendToInput('0'),
                        ),
                        _buildButton(
                          '.',
                          onPressed: () => _appendToInput('.'),
                        ),
                        _buildButton(
                          '=',
                          isOperator: true,
                          onPressed: _calculateResult,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleTheme() {
    if (Theme.of(context).brightness == Brightness.dark) {
      widget.toggleTheme(ThemeMode.light);
    } else {
      widget.toggleTheme(ThemeMode.dark);
    }
  }

  Widget _buildFractionResult(Fraction fraction) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // If denominator is 1, just display the numerator as a whole number
    if (fraction.denominator == 1) {
      return Text(
        fraction.numerator.toString(),
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      );
    }

    final numStr = fraction.numerator.toString();
    final denStr = fraction.denominator.toString();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              numStr,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Container(
              height: 3,
              width: numStr.length > denStr.length
                  ? null
                  : (denStr.length * 20).toDouble(),
              color: colorScheme.onSurface,
            ),
            Text(
              denStr,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButton(
    String text, {
    bool isOperator = false,
    bool isFunction = false,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine button style based on type
    Color backgroundColor;
    Color textColor;

    if (isOperator) {
      backgroundColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
    } else if (isFunction) {
      backgroundColor = colorScheme.secondaryContainer;
      textColor = colorScheme.onSecondaryContainer;
    } else {
      backgroundColor = theme.brightness == Brightness.dark
          ? colorScheme.surface.withOpacity(0.7)
          : colorScheme.surface.withOpacity(0.9);
      textColor = colorScheme.onSurface;
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: isOperator ? FontWeight.bold : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Simplified input handling - treat everything as raw text until calculation
  void _appendToInput(String value) {
    setState(() {
      // If we've just calculated a result and start a new input
      if (_hasCalculated) {
        // If the new input is an operator, use the previous result
        if (value == '+' ||
            value == '-' ||
            value == '×' ||
            value == '÷' ||
            value == '/') {
          _input = _displayResult + value;
        } else {
          _input = value;
        }
        _hasCalculated = false;
      } else {
        // Just append to the current input
        _input += value;
      }

      // Clear error state if any
      _isError = false;
    });
  }

  void _clearAll() {
    setState(() {
      _input = '';
      _displayResult = '0';
      _isError = false;
      _hasCalculated = false;
      _resultIsFraction = false;
      _fractionResult = null;
    });
  }

  void _deleteLastCharacter() {
    setState(() {
      if (_input.isNotEmpty) {
        // Check if we need to remove function names completely
        final functionNames = ['sin(', 'cos(', 'tan(', 'sqrt('];
        bool removedFunction = false;

        for (final func in functionNames) {
          if (_input.endsWith(func)) {
            _input = _input.substring(0, _input.length - func.length);
            removedFunction = true;
            break;
          }
        }

        if (!removedFunction) {
          _input = _input.substring(0, _input.length - 1);
        }
      }
    });
  }

  void _calculateResult() {
    if (_input.isEmpty) return;

    try {
      // Process the expression to handle fractions
      String expr = _processFractionExpression();

      // Handle percentage calculations
      expr = expr.replaceAll('%', '/100');

      // Parse and evaluate expression
      Parser p = Parser();
      Expression exp = p.parse(expr);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      // Try to convert result to a fraction
      Fraction resultFraction = Fraction.fromDouble(eval);

      // Format the displayed expression (for history)
      String displayExpr = _input;

      setState(() {
        _fractionResult = resultFraction;
        _resultIsFraction = true;
        _displayResult = resultFraction.toString();
        _history.add('$displayExpr = $_displayResult');
        _hasCalculated = true;
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _displayResult = 'Error';
        _isError = true;
        _resultIsFraction = false;
        _hasCalculated = true;
      });
    }
  }

  String _processFractionExpression() {
    // Replace display operators with calculation operators
    String expr = _input.replaceAll('×', '*').replaceAll('÷', '/');

    // We need to properly handle fraction operations
    // First, try to find pattern: fraction operator fraction
    RegExp fracOpFracRegex = RegExp(r'(\d+)/(\d+)([+\-*/])(\d+)/(\d+)');

    // Iterate until no more direct fraction operations are found
    bool madeReplacement = true;
    while (madeReplacement) {
      madeReplacement = false;

      // Find first fraction operation
      var match = fracOpFracRegex.firstMatch(expr);
      if (match != null) {
        String fullMatch = match.group(0)!;
        int num1 = int.parse(match.group(1)!);
        int den1 = int.parse(match.group(2)!);
        String op = match.group(3)!;
        int num2 = int.parse(match.group(4)!);
        int den2 = int.parse(match.group(5)!);

        // Create fraction objects
        Fraction frac1 = Fraction(num1, den1);
        Fraction frac2 = Fraction(num2, den2);

        // Perform the operation
        Fraction result;
        switch (op) {
          case '+':
            result = frac1.add(frac2);
            break;
          case '-':
            result = frac1.subtract(frac2);
            break;
          case '*':
            result = frac1.multiply(frac2);
            break;
          case '/':
            result = frac1.divide(frac2);
            break;
          default:
            result = frac1; // Default case, should not happen
        }

        // Replace the expression with the result
        expr = expr.replaceFirst(fullMatch, result.toString());
        madeReplacement = true;
      }
    }

    // Now convert any remaining fractions to decimal for standard evaluation
    RegExp singleFractionRegex = RegExp(r'(\d+)/(\d+)');
    Iterable<RegExpMatch> matches = singleFractionRegex.allMatches(expr);

    for (var match in matches) {
      String fullMatch = match.group(0)!;
      int numerator = int.parse(match.group(1)!);
      int denominator = int.parse(match.group(2)!);

      try {
        double decimal = numerator / denominator;
        expr = expr.replaceFirst(fullMatch, decimal.toString());
      } catch (e) {
        // Handle division by zero
      }
    }

    return expr;
  }

  void _toggleHistory() {
    setState(() {
      _showHistory = !_showHistory;
    });
  }

  void _toggleCalculatorMode() {
    setState(() {
      _isScientificMode = !_isScientificMode;
    });
  }
}
