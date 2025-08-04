import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'calculation_page_base.dart'; // CORRIGIDO: Importa a classe base CalculationPage
import 'package:calc_construtor/calculation_history_service.dart';

class LaborCalculationPage extends StatefulWidget {
  const LaborCalculationPage({super.key});

  @override
  State<LaborCalculationPage> createState() => _LaborCalculationPageState();
}

class _LaborCalculationPageState extends State<LaborCalculationPage> {
  final _formKey = GlobalKey<FormState>();

  // Lista de tipos de profissionais e seus controladores
  final Map<String, Map<String, TextEditingController>> _professionals = {
    'Pedreiros': {'quantity': TextEditingController(), 'rate': TextEditingController()},
    'Eletricistas': {'quantity': TextEditingController(), 'rate': TextEditingController()},
    'Encanadores': {'quantity': TextEditingController(), 'rate': TextEditingController()},
    'Engenheiro/Mestre de Obras': {'quantity': TextEditingController(), 'rate': TextEditingController()},
    'Pintores': {'quantity': TextEditingController(), 'rate': TextEditingController()},
    'Instaladores': {'quantity': TextEditingController(), 'rate': TextEditingController()},
  };

  Map<String, dynamic>? _result;
  bool _isLoading = false;

  final CalculationHistoryService _historyService = CalculationHistoryService();

  @override
  void initState() {
    super.initState();
    // Inicializa todos os controladores com '0.00'
    _professionals.forEach((key, controllers) {
      controllers['quantity']!.text = '0.00';
      controllers['rate']!.text = '0.00';
    });
  }

  @override
  void dispose() {
    _professionals.forEach((key, controllers) {
      controllers['quantity']!.dispose();
      controllers['rate']!.dispose();
    });
    super.dispose();
  }

  void _clearFields() {
    _formKey.currentState?.reset();
    _professionals.forEach((key, controllers) {
      controllers['quantity']!.text = '0.00';
      controllers['rate']!.text = '0.00';
    });
    setState(() {
      _result = null;
    });
    FocusScope.of(context).unfocus();
  }

  void _calculateLabor() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos corretamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    await Future.delayed(const Duration(seconds: 1));

    try {
      double totalLaborCost = 0.0;
      Map<String, Map<String, String>> detailedCosts = {};

      _professionals.forEach((professionalType, controllers) {
        final double quantity = double.parse(controllers['quantity']!.text.replaceAll(',', '.'));
        final double rate = double.parse(controllers['rate']!.text.replaceAll(',', '.'));
        final double cost = quantity * rate;
        totalLaborCost += cost;

        detailedCosts[professionalType] = {
          'quantity': quantity.toStringAsFixed(2),
          'rate': rate.toStringAsFixed(2),
          'cost': cost.toStringAsFixed(2),
        };
      });

      final Map<String, dynamic> currentCalculationResult = {
        "totalLaborCost": totalLaborCost.toStringAsFixed(2),
        "detailedCosts": detailedCosts, // Salva os custos detalhados
      };

      setState(() {
        _result = currentCalculationResult;
      });

      await _historyService.saveCalculation(currentCalculationResult, 'Mão de Obra Detalhada');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cálculo de mão de obra realizado e salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao calcular: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _result = {"error": "Ocorreu um erro no cálculo. Verifique os valores."};
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CalculationPage(
      title: 'Cálculo Detalhado de Mão de Obra',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Insira a quantidade de dias/horas e a taxa para cada tipo de profissional:',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ..._professionals.entries.map((entry) {
                final professionalType = entry.key;
                final controllers = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  elevation: 2.0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          professionalType,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        ),
                        const SizedBox(height: 12),
                        _buildTextFormField(
                          controller: controllers['quantity']!,
                          labelText: 'Quantidade (dias/horas)',
                          hintText: 'Ex: 10.5',
                          unitText: 'un.',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return null; // Não é obrigatório, 0 é o padrão
                            }
                            final double? parsedValue = double.tryParse(value.replaceAll(',', '.'));
                            if (parsedValue == null) {
                              return 'Valor inválido. Use números.';
                            }
                            if (parsedValue < 0) {
                              return 'A quantidade não pode ser negativa.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildTextFormField(
                          controller: controllers['rate']!,
                          labelText: 'Taxa Diária/Horária',
                          hintText: 'Ex: 150.00',
                          unitText: 'R\$',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return null; // Não é obrigatório, 0 é o padrão
                            }
                            final double? parsedValue = double.tryParse(value.replaceAll(',', '.'));
                            if (parsedValue == null) {
                              return 'Valor inválido. Use números.';
                            }
                            if (parsedValue < 0) {
                              return 'A taxa não pode ser negativa.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _calculateLabor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[500],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: Colors.blue.withOpacity(0.5),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Calcular Custo Total da Mão de Obra',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 24),
              if (_result != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 80),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _result!["error"] != null
                      ? Text(
                          _result!["error"],
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Resumo do Custo da Mão de Obra:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...( _result!['detailedCosts'] as Map<String, dynamic>).entries.map((entry) {
                              final professionalType = entry.key;
                              final details = entry.value as Map<String, dynamic>;
                              return _buildResultRow(
                                '$professionalType (Qtd: ${details['quantity']}, Tx: R\$ ${details['rate']}):',
                                'R\$ ${details['cost']}',
                              );
                            }).toList(),
                            const Divider(height: 20, thickness: 1),
                            _buildResultRow('Custo Total da Mão de Obra:', 'R\$ ${_result!["totalLaborCost"]}', isTotal: true),
                            const SizedBox(height: 10),
                            const Text(
                              '*Este cálculo é uma estimativa. Os custos reais podem variar.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _clearFields,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.clear_all, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    String? unitText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
        TextInputFormatter.withFunction((oldValue, newValue) {
          final text = newValue.text.replaceAll(',', '.');
          return newValue.copyWith(text: text, selection: newValue.selection);
        }),
      ],
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        suffixText: unitText,
        suffixStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        errorStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ),
      style: const TextStyle(fontSize: 16),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget _buildResultRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.black : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 18 : 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.green[700] : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
