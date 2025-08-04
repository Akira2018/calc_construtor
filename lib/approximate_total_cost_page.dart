import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'calculation_page_base.dart'; // Importa a classe base CalculationPage
import 'package:calc_construtor/calculation_history_service.dart';

// Enum para os diferentes padrões de construção com custos médios por m²
enum ConstructionStandard {
  economico(name: 'Econômico', costPerM2: 1800.0), // Ex: R$ 1800/m²
  medio(name: 'Médio', costPerM2: 2800.0), // Ex: R$ 2800/m²
  altoPadrao(name: 'Alto Padrão', costPerM2: 4500.0); // Ex: R$ 4500/m²

  final String name;
  final double costPerM2;

  const ConstructionStandard({required this.name, required this.costPerM2});
}

class ApproximateTotalCostPage extends StatefulWidget {
  const ApproximateTotalCostPage({super.key});

  @override
  State<ApproximateTotalCostPage> createState() => _ApproximateTotalCostPageState();
}

class _ApproximateTotalCostPageState extends State<ApproximateTotalCostPage> {
  final _formKey = GlobalKey<FormState>();

  // Lista de controladores para os campos de nome e área dos cômodos
  final List<Map<String, TextEditingController>> _roomControllers = [];
  ConstructionStandard? _selectedStandard; // Padrão de construção selecionado
  final TextEditingController _safetyMarginController = TextEditingController(text: '10'); // Margem de segurança padrão
  final TextEditingController _editableCostPerM2Controller = TextEditingController(); // Controlador para o custo por m² editável

  Map<String, dynamic>? _result;
  bool _isLoading = false;

  final CalculationHistoryService _historyService = CalculationHistoryService();

  @override
  void initState() {
    super.initState();
    _addRoomField(); // Começa com um campo de cômodo
  }

  @override
  void dispose() {
    // Descarta todos os controladores de cômodos
    for (var controllers in _roomControllers) {
      controllers['name']!.dispose();
      controllers['area']!.dispose();
    }
    _safetyMarginController.dispose();
    _editableCostPerM2Controller.dispose(); // Descarta o controlador do custo por m²
    super.dispose();
  }

  // Adiciona um novo campo de cômodo
  void _addRoomField() {
    setState(() {
      _roomControllers.add({
        'name': TextEditingController(),
        'area': TextEditingController(text: '0.00'),
      });
    });
  }

  // Remove um campo de cômodo
  void _removeRoomField(int index) {
    setState(() {
      _roomControllers[index]['name']!.dispose();
      _roomControllers[index]['area']!.dispose();
      _roomControllers.removeAt(index);
    });
  }

  // Limpa todos os campos e resultados
  void _clearFields() {
    _formKey.currentState?.reset();
    for (var controllers in _roomControllers) {
      controllers['name']!.clear();
      controllers['area']!.text = '0.00';
    }
    _safetyMarginController.text = '10';
    _editableCostPerM2Controller.clear(); // Limpa o campo de custo por m²
    setState(() {
      _result = null;
      _selectedStandard = null;
      _roomControllers.clear(); // Limpa todos os campos de cômodos
      _addRoomField(); // Adiciona um campo vazio novamente
    });
    FocusScope.of(context).unfocus();
  }

  // Função para calcular o custo aproximado total da obra
  void _calculateApproximateCost() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos corretamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedStandard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um padrão de construção.'),
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
      double totalArea = 0.0;
      List<Map<String, String>> roomDetails = [];

      for (var controllers in _roomControllers) {
        final String roomName = controllers['name']!.text.trim().isEmpty
            ? 'Cômodo ${(_roomControllers.indexOf(controllers) + 1)}'
            : controllers['name']!.text.trim();
        final double roomArea = double.parse(controllers['area']!.text.replaceAll(',', '.'));

        if (roomArea < 0) {
          throw Exception('A área do cômodo não pode ser negativa.');
        }

        totalArea += roomArea;
        roomDetails.add({'name': roomName, 'area': roomArea.toStringAsFixed(2)});
      }

      if (totalArea <= 0) {
        setState(() {
          _result = {"error": "A área total dos cômodos deve ser maior que 0."};
        });
        return;
      }

      // Usa o valor do campo editável para o custo por m²
      final double costPerM2 = double.parse(_editableCostPerM2Controller.text.replaceAll(',', '.'));
      if (costPerM2 <= 0) {
        setState(() {
          _result = {"error": "O custo por m² deve ser maior que 0."};
        });
        return;
      }

      final double baseCost = totalArea * costPerM2;

      final double safetyMarginPercentage = double.parse(_safetyMarginController.text.replaceAll(',', '.'));
      if (safetyMarginPercentage < 0) {
        setState(() {
          _result = {"error": "A margem de segurança não pode ser negativa."};
        });
        return;
      }

      final double safetyMarginAmount = baseCost * (safetyMarginPercentage / 100);
      final double grandTotalCost = baseCost + safetyMarginAmount;

      final Map<String, dynamic> currentCalculationResult = {
        "totalArea": totalArea.toStringAsFixed(2),
        "selectedStandard": _selectedStandard!.name,
        "costPerM2": costPerM2.toStringAsFixed(2), // Salva o valor potencialmente alterado
        "baseCost": baseCost.toStringAsFixed(2),
        "safetyMarginPercentage": safetyMarginPercentage.toStringAsFixed(2),
        "safetyMarginAmount": safetyMarginAmount.toStringAsFixed(2),
        "grandTotalCost": grandTotalCost.toStringAsFixed(2),
        "roomDetails": roomDetails, // Salva os detalhes de cada cômodo
      };

      setState(() {
        _result = currentCalculationResult;
      });

      await _historyService.saveCalculation(currentCalculationResult, 'Custo Total da Obra');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cálculo aproximado realizado e salvo com sucesso!'),
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

  // Função para exibir as informações de custo de mercado em um AlertDialog
  void _showMarketCostInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Custo Médio da Construção por M² (2025)'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Com base em dados do SINAPI (IBGE) e outras fontes, o custo médio do m² no Brasil tem variado em 2025:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  '• Média Nacional (Abril/Maio 2025): Aproximadamente R\$ 1.810,25 a R\$ 1.818,64 por m².',
                ),
                Text(
                  '  - Componentes: Materiais (cerca de R\$ 1.040/m²) e Mão de obra (cerca de R\$ 770/m²).',
                ),
                SizedBox(height: 10),
                Text(
                  '• Variação Regional (Abril/Maio 2025):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('  - Sul: R\$ 1.919,27 a R\$ 1.940,27 por m² (geralmente a mais cara).'),
                Text('  - Norte: R\$ 1.866,70 a R\$ 1.884,03 por m²'),
                Text('  - Sudeste: R\$ 1.847,11 a R\$ 1.865,98 por m² (São Paulo em torno de R\$ 1.821,57 a R\$ 1.914,58 por m²)'),
                Text('  - Centro-Oeste: R\$ 1.805,18 a R\$ 1.817,07 por m²'),
                Text('  - Nordeste: R\$ 1.674,30 a R\$ 1.694,67 por m² (geralmente a mais barata).'),
                SizedBox(height: 10),
                Text(
                  '• Custo Unitário Básico (CUB/m²) - Março/Abril 2025 (com desoneração):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('  - CUB Brasil (Janeiro 2025): R\$ 2.210,41 por m² (Este índice é mais abrangente e inclui outros custos além de materiais e mão de obra direta).'),
                Text('  - CUB SP (Março 2025): R\$ 1.961,78 a R\$ 2.048,48 por m² (dependendo do padrão e desoneração).'),
                SizedBox(height: 15),
                Text(
                  'Considerações Importantes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Padrão de Construção: Os valores acima são médias. O custo varia muito conforme o padrão (econômico, médio, alto luxo) e os acabamentos escolhidos. Por exemplo, um sobrado de médio padrão pode ter um custo de R\$ 2.599,89/m².'),
                Text('• Localização Específica: Dentro de cada região, cidades maiores ou com maior demanda tendem a ter custos mais elevados.'),
                Text('• Imprevistos: Lembre-se sempre de incluir uma margem de segurança (geralmente 10% a 20%) para imprevistos no seu orçamento.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CalculationPage(
      title: 'Custo Total Aproximado da Obra',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Esta é uma estimativa de alto nível. Os custos reais podem variar significativamente.',
                style: TextStyle(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ConstructionStandard>(
                value: _selectedStandard,
                decoration: InputDecoration(
                  labelText: 'Padrão de Construção',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                hint: const Text('Selecione o padrão da obra'),
                onChanged: (ConstructionStandard? newValue) {
                  setState(() {
                    _selectedStandard = newValue;
                    if (newValue != null) {
                      _editableCostPerM2Controller.text = newValue.costPerM2.toStringAsFixed(2);
                    } else {
                      _editableCostPerM2Controller.clear();
                    }
                  });
                },
                items: ConstructionStandard.values.map((ConstructionStandard standard) {
                  return DropdownMenuItem<ConstructionStandard>(
                    value: standard,
                    child: Text(standard.name), // Exibe apenas o nome no dropdown
                  );
                }).toList(),
                validator: (value) {
                  if (value == null) {
                    return 'Por favor, selecione um padrão de construção.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Campo de texto editável para o custo por m²
              _buildTextFormField(
                controller: _editableCostPerM2Controller,
                labelText: 'Custo por m² (Estimado)',
                hintText: 'Ex: 2500.00',
                unitText: 'R\$',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final text = newValue.text.replaceAll(',', '.');
                    return newValue.copyWith(text: text, selection: newValue.selection);
                  }),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o custo por m².';
                  }
                  final double? parsedValue = double.tryParse(value.replaceAll(',', '.'));
                  if (parsedValue == null) {
                    return 'Valor inválido. Use números.';
                  }
                  if (parsedValue <= 0) {
                    return 'O custo por m² deve ser maior que 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // NOVO: Botão para exibir informações de custo de mercado
              ElevatedButton.icon(
                onPressed: () => _showMarketCostInfo(context),
                icon: const Icon(Icons.info_outline, color: Colors.white),
                label: const Text(
                  'Ver Custos de Mercado (Referência)',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Área dos Cômodos:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true, // Importante para ListView dentro de SingleChildScrollView
                physics: const NeverScrollableScrollPhysics(), // Desabilita a rolagem interna
                itemCount: _roomControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildTextFormField(
                            controller: _roomControllers[index]['name']!,
                            labelText: 'Nome do Cômodo (Opcional)',
                            hintText: 'Ex: Sala, Quarto 1',
                            keyboardType: TextInputType.text,
                            inputFormatters: [],
                            validator: (value) {
                              // Nome do cômodo é opcional
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildTextFormField(
                            controller: _roomControllers[index]['area']!,
                            labelText: 'Área',
                            hintText: 'Ex: 15.5',
                            unitText: 'm²',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
                              TextInputFormatter.withFunction((oldValue, newValue) {
                                final text = newValue.text.replaceAll(',', '.');
                                return newValue.copyWith(text: text, selection: newValue.selection);
                              }),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Insira a área.';
                              }
                              final double? parsedValue = double.tryParse(value.replaceAll(',', '.'));
                              if (parsedValue == null) {
                                return 'Valor inválido.';
                              }
                              if (parsedValue <= 0) {
                                return 'A área deve ser > 0.';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (_roomControllers.length > 1) // Permite remover se houver mais de um campo
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeRoomField(index),
                          ),
                      ],
                    ),
                  );
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _addRoomField,
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  label: const Text('Adicionar Cômodo', style: TextStyle(color: Colors.blue)),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextFormField(
                controller: _safetyMarginController,
                labelText: 'Margem de Segurança',
                hintText: 'Ex: 10 (10% para imprevistos)',
                unitText: '%',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final text = newValue.text.replaceAll(',', '.');
                    return newValue.copyWith(text: text, selection: newValue.selection);
                  }),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Insira a margem de segurança.';
                  }
                  final double? parsedValue = double.tryParse(value.replaceAll(',', '.'));
                  if (parsedValue == null) {
                    return 'Valor inválido.';
                  }
                  if (parsedValue < 0) {
                    return 'A margem não pode ser negativa.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _calculateApproximateCost,
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
                        'Calcular Custo Total Aproximado',
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
                              'Resumo do Custo Total Aproximado:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildResultRow('Padrão de Construção:', '${_result!["selectedStandard"]}'),
                            _buildResultRow('Custo por m² (Estimado):', 'R\$ ${_result!["costPerM2"]}'),
                            const SizedBox(height: 10),
                            const Text(
                              'Detalhes dos Cômodos:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 5),
                            for (var room in (_result!["roomDetails"] as List))
                              _buildResultRow('${room['name']}:', '${room['area']} m²'),
                            const Divider(height: 16, thickness: 1),
                            _buildResultRow('Área Total dos Cômodos:', '${_result!["totalArea"]} m²'),
                            _buildResultRow('Custo Base (Área Total x Custo/m²):', 'R\$ ${_result!["baseCost"]}'),
                            _buildResultRow('Margem de Segurança (${_result!["safetyMarginPercentage"]}%):', 'R\$ ${_result!["safetyMarginAmount"]}'),
                            const Divider(height: 20, thickness: 1),
                            _buildResultRow('Custo Total Aproximado:', 'R\$ ${_result!["grandTotalCost"]}', isTotal: true),
                            const SizedBox(height: 10),
                            const Text(
                              '*Esta é uma estimativa simplificada. Consulte profissionais para orçamentos detalhados.',
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

  // Helper para construir campos de texto com validação e melhorias de UX
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    String? unitText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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

