import 'package:flutter/material.dart';
import 'dart:math';

// Define Uom class (Unit of Measure)
class Uom {
  final String name;
  final String symbol;
  final double factor; // Factor to convert from base unit

  Uom(this.name, this.symbol, this.factor);
}

// Define Category class
class UnitCategory {
  final String name;
  final List<Uom> units;
  final String baseUnitSymbol; // Symbol of the base unit for this category

  UnitCategory(this.name, this.units, this.baseUnitSymbol);
}

class UnitConverter extends StatefulWidget {
  const UnitConverter({super.key});

  @override
  State<UnitConverter> createState() => _UnitConverterState();
}

class _UnitConverterState extends State<UnitConverter> {
  late List<UnitCategory> _categories;

  UnitCategory? _selectedCategory;
  Uom? _fromUnit;
  Uom? _toUnit;

  final TextEditingController _inputValueController = TextEditingController();
  String _resultValue = '0';

  @override
  void initState() {
    super.initState();
    _initializeCategories();
    if (_categories.isNotEmpty) {
      _selectedCategory = _categories.first;
      if (_selectedCategory!.units.isNotEmpty) {
        _fromUnit = _selectedCategory!.units.first;
        _toUnit = _selectedCategory!.units.length > 1
            ? _selectedCategory!.units[1]
            : _selectedCategory!.units.first;
      }
    }
    _inputValueController.addListener(_convertUnits);
  }

  void _initializeCategories() {
    _categories = [
      UnitCategory(
          'Length',
          [
            Uom('Meter', 'm', 1.0),
            Uom('Kilometer', 'km', 1000.0),
            Uom('Centimeter', 'cm', 0.01),
            Uom('Millimeter', 'mm', 0.001),
            Uom('Mile', 'mi', 1609.34),
            Uom('Yard', 'yd', 0.9144),
            Uom('Foot', 'ft', 0.3048),
            Uom('Inch', 'in', 0.0254),
          ],
          'm'),
      UnitCategory(
          'Weight/Mass',
          [
            Uom('Kilogram', 'kg', 1.0),
            Uom('Gram', 'g', 0.001),
            Uom('Milligram', 'mg', 0.000001),
            Uom('Pound', 'lb', 0.453592),
            Uom('Ounce', 'oz', 0.0283495),
            Uom('Tonne', 't', 1000.0),
          ],
          'kg'),
      UnitCategory(
          'Temperature',
          [
            Uom('Celsius', '°C', 0), // Factor not used directly for temp
            Uom('Fahrenheit', '°F', 0),
            Uom('Kelvin', 'K', 0),
          ],
          '°C'),
      UnitCategory(
          'Area',
          [
            Uom('Square Meter', 'm²', 1.0),
            Uom('Square Kilometer', 'km²', 1000000.0),
            Uom('Square Foot', 'ft²', 0.092903),
            Uom('Square Inch', 'in²', 0.00064516),
            Uom('Hectare', 'ha', 10000.0),
            Uom('Acre', 'acre', 4046.86),
          ],
          'm²'),
      UnitCategory(
          'Volume',
          [
            Uom('Cubic Meter', 'm³', 1.0),
            Uom('Liter', 'L', 0.001),
            Uom('Milliliter', 'mL', 0.000001),
            Uom('Cubic Foot', 'ft³', 0.0283168),
            Uom('Cubic Inch', 'in³', 0.0000163871),
            Uom('Gallon (US)', 'gal', 0.00378541),
          ],
          'm³'),
    ];
  }

  void _convertUnits() {
    final String inputText = _inputValueController.text;
    if (inputText.isEmpty) {
      setState(() {
        _resultValue = '0';
      });
      return;
    }

    final double? inputValue = double.tryParse(inputText);
    if (inputValue == null ||
        _fromUnit == null ||
        _toUnit == null ||
        _selectedCategory == null) {
      setState(() {
        _resultValue = 'Error';
      });
      return;
    }

    double result;

    if (_selectedCategory!.name == 'Temperature') {
      // Temperature conversions
      if (_fromUnit!.symbol == '°C') {
        if (_toUnit!.symbol == '°F') {
          result = (inputValue * 9 / 5) + 32;
        } else if (_toUnit!.symbol == 'K') {
          result = inputValue + 273.15;
        } else {
          result = inputValue; // C to C
        }
      } else if (_fromUnit!.symbol == '°F') {
        if (_toUnit!.symbol == '°C') {
          result = (inputValue - 32) * 5 / 9;
        } else if (_toUnit!.symbol == 'K') {
          result = ((inputValue - 32) * 5 / 9) + 273.15;
        } else {
          result = inputValue; // F to F
        }
      } else if (_fromUnit!.symbol == 'K') {
        if (_toUnit!.symbol == '°C') {
          result = inputValue - 273.15;
        } else if (_toUnit!.symbol == '°F') {
          result = ((inputValue - 273.15) * 9 / 5) + 32;
        } else {
          result = inputValue; // K to K
        }
      } else {
        result = inputValue; // Should not happen
      }
    } else {
      // Factor-based conversions (Length, Weight, Area, Volume)
      double valueInBaseUnit = inputValue * _fromUnit!.factor;
      // For categories where base unit is not 1 (e.g. grams where kg is base)
      // we need to adjust if the _fromUnit IS the category base unit.
      // However, our factors are defined relative TO the base unit for that category.
      // Example: cm to m: value_cm * 0.01 = value_m
      //          m to cm: value_m / 0.01 = value_cm

      // Convert from input unit to category's base unit
      double baseValue;
      // The factor in Uom is 'how many base units make one of this unit'.
      // So, to convert from _fromUnit to baseUnit, we multiply.
      // If _fromUnit is 'km' (factor 1000) and baseUnit is 'm', 2 km * 1000 = 2000m.
      baseValue = inputValue * _fromUnit!.factor;

      // Convert from base unit to _toUnit
      // To convert from baseUnit to _toUnit, we divide by _toUnit's factor.
      // If _toUnit is 'cm' (factor 0.01) and baseUnit is 'm', 2000m / 0.01 = 200000cm.
      result = baseValue / _toUnit!.factor;
    }

    setState(() {
      // Format to a reasonable number of decimal places
      _resultValue = result.toStringAsFixed(5);
      // Remove trailing zeros and decimal point if it's a whole number
      _resultValue = _resultValue.replaceAll(RegExp(r'0+$'), '');
      if (_resultValue.endsWith('.')) {
        _resultValue = _resultValue.substring(0, _resultValue.length - 1);
      }
    });
  }

  @override
  void dispose() {
    _inputValueController.removeListener(_convertUnits);
    _inputValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unit Converter'),
        backgroundColor: theme.colorScheme.surfaceVariant,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Dropdown
            DropdownButtonFormField<UnitCategory>(
              decoration: InputDecoration(
                labelText: 'Category',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              value: _selectedCategory,
              items: _categories.map((UnitCategory category) {
                return DropdownMenuItem<UnitCategory>(
                  value: category,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (UnitCategory? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                  _fromUnit = _selectedCategory?.units.first;
                  _toUnit = (_selectedCategory?.units.length ?? 0) > 1
                      ? _selectedCategory?.units[1]
                      : _selectedCategory?.units.first;
                  _inputValueController.clear();
                  _resultValue = '0';
                });
              },
            ),
            const SizedBox(height: 20),

            if (_selectedCategory != null) ...[
              // Input Value TextField
              TextField(
                controller: _inputValueController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Enter value to convert',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  suffixText: _fromUnit?.symbol ?? '',
                ),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  // From Unit Dropdown
                  Expanded(
                    child: DropdownButtonFormField<Uom>(
                      decoration: InputDecoration(
                        labelText: 'From',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      value: _fromUnit,
                      items: _selectedCategory!.units.map((Uom unit) {
                        return DropdownMenuItem<Uom>(
                          value: unit,
                          child: Text(unit.name),
                        );
                      }).toList(),
                      onChanged: (Uom? newValue) {
                        setState(() {
                          _fromUnit = newValue;
                          _convertUnits(); // Re-calculate on unit change
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 8.0), // Align with dropdowns
                    child: Icon(Icons.swap_horiz,
                        size: 28, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),

                  // To Unit Dropdown
                  Expanded(
                    child: DropdownButtonFormField<Uom>(
                      decoration: InputDecoration(
                        labelText: 'To',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      value: _toUnit,
                      items: _selectedCategory!.units.map((Uom unit) {
                        return DropdownMenuItem<Uom>(
                          value: unit,
                          child: Text(unit.name),
                        );
                      }).toList(),
                      onChanged: (Uom? newValue) {
                        setState(() {
                          _toUnit = newValue;
                          _convertUnits(); // Re-calculate on unit change
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Result Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.5))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Result:',
                      style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _resultValue,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    Text(
                      _toUnit?.name ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
