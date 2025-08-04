import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para controlar o teclado numérico
import 'main.dart'; // Importa main.dart para usar CalculationPage
import 'package:calc_construtor/calculation_history_service.dart'; // Importa o serviço de histórico
import 'calculation_page_base.dart';

class GeneralConstructionCalculationPage extends StatefulWidget {
  const GeneralConstructionCalculationPage({super.key});

  @override
  State<GeneralConstructionCalculationPage> createState() => _GeneralConstructionCalculationPageState();
}

class _GeneralConstructionCalculationPageState extends State<GeneralConstructionCalculationPage> {
  final _formKey = GlobalKey<FormState>(); // Chave global para o formulário

  // Estrutura de dados para as etapas e itens da construção
  final Map<String, List<String>> _constructionStages = {
    '1. Projetos e Licenças': [
      'Projeto arquitetônico',
      'Projeto estrutural',
      'Projeto elétrico',
      'Projeto hidráulico',
      'Taxas de aprovação e licenciamento',
      'Estudos de solo e topografia',
    ],
    '2. Infraestrutura Inicial': [
      'Terraplanagem e escavação',
      'Ligação provisória de água e energia',
      'Barracão de obra e segurança',
    ],
    '3. Fundação e Estrutura': [
      'Cimento',
      'Areia',
      'Brita',
      'Cal',
      'Vergalhões',
      'Formas',
      'Escoras',
      'Mão de obra especializada (Fundação/Estrutura)',
    ],
    '4. Alvenaria': [
      'Blocos ou tijolos',
      'Argamassa e reboco (Alvenaria)',
      'Tubos de PVC e conduítes (Alvenaria)',
    ],
    '5. Instalações Elétricas e Hidráulicas': [
      'Fios',
      'Tomadas',
      'Interruptores',
      'Tubulações (Hidráulica)',
      'Conexões (Hidráulica)',
      'Caixa d’água',
      'Bombas',
      'Registros',
      'Torneiras',
    ],
    '6. Cobertura': [
      'Telhas',
      'Vigas',
      'Caibros',
      'Mantas térmicas e impermeabilizantes',
      'Rufos e calhas',
    ],
    '7. Acabamentos': [
      'Pisos',
      'Revestimentos',
      'Azulejos',
      'Tintas (Acabamentos)',
      'Massa corrida',
      'Gesso',
      'Louças sanitárias',
      'Portas',
      'Janelas',
    ],
    '8. Mão de Obra': [
      'Pedreiros',
      'Eletricistas',
      'Encanadores',
      'Engenheiro ou mestre de obras',
      'Pintores',
      'Instaladores',
    ],
    '9. Custos Adicionais': [
      'Transporte de materiais',
      'Equipamentos e ferramentas',
    ],
  };

  // Controladores para os campos de custo de cada item
  final Map<String, TextEditingController> _costControllers = {};
  final TextEditingController _safetyMarginController = TextEditingController(text: '10'); // Padrão de 10%

  Map<String, dynamic>? _result; // Resultado do cálculo
  bool _isLoading = false; // Estado para controlar o carregamento

  final CalculationHistoryService _historyService = CalculationHistoryService();

  @override
  void initState() {
    super.initState();
    // Inicializa os controladores para cada item de custo
    _constructionStages.forEach((stage, items) {
      for (var item in items) {
        _costControllers[item] = TextEditingController(text: '0.00'); // Valor inicial 0.00
      }
    });
  }

  @override
  void dispose() {
    // Descarta todos os controladores
    _costControllers.forEach((key, controller) => controller.dispose());
    _safetyMarginController.dispose();
    super.dispose();
  }

  // Função para limpar todos os campos e resultados
  void _clearFields() {
    _formKey.currentState?.reset();
    _costControllers.forEach((key, controller) => controller.text = '0.00'); // Reseta para 0.00
    _safetyMarginController.text = '10'; // Reseta a margem para 10%
    setState(() {
      _result = null;
    });
    FocusScope.of(context).unfocus();
  }

  // Função para calcular o custo total da construção
  void _calculateGeneralConstruction() async {
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
      double subtotalCost = 0.0;
      Map<String, double> itemCosts = {};

      _constructionStages.forEach((stage, items) {
        for (var item in items) {
          final controller = _costControllers[item];
          final double itemValue = double.parse(controller!.text.replaceAll(',', '.'));
          itemCosts[item] = itemValue;
          subtotalCost += itemValue;
        }
      });

      final double safetyMarginPercentage = double.parse(_safetyMarginController.text.replaceAll(',', '.'));
      if (safetyMarginPercentage < 0) {
        setState(() {
          _result = {"error": "A margem de segurança não pode ser negativa."};
        });
        return;
      }

      final double safetyMarginAmount = subtotalCost * (safetyMarginPercentage / 100);
      final double grandTotalCost = subtotalCost + safetyMarginAmount;

      final Map<String, dynamic> currentCalculationResult = {
        "subtotalCost": subtotalCost.toStringAsFixed(2),
        "safetyMarginPercentage": safetyMarginPercentage.toStringAsFixed(2),
        "safetyMarginAmount": safetyMarginAmount.toStringAsFixed(2),
        "grandTotalCost": grandTotalCost.toStringAsFixed(2),
        "itemCosts": itemCosts.map((key, value) => MapEntry(key, value.toStringAsFixed(2))), // Salva os custos individuais
      };

      setState(() {
        _result = currentCalculationResult;
      });

      await _historyService.saveCalculation(currentCalculationResult, 'Construção Geral');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cálculo geral realizado e salvo com sucesso!'),
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
      title: 'Cálculo Geral de Construção',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Insira os custos estimados para cada item da construção:',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ..._constructionStages.entries.map((entry) {
                final stageName = entry.key;
                final items = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        stageName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                    ),
                    ...items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildTextFormField(
                          controller: _costControllers[item]!,
                          labelText: item,
                          hintText: 'Custo estimado',
                          unitText: 'R\$',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira um valor.';
                            }
                            final double? parsedValue = double.tryParse(value.replaceAll(',', '.'));
                            if (parsedValue == null || parsedValue < 0) {
                              return 'O custo não pode ser negativo.';
                            }
                            return null;
                          },
                        ),
                      );
                    }).toList(),
                    const Divider(height: 32, thickness: 1), // Divisor entre as etapas
                  ],
                );
              }).toList(),
              // Campo para a margem de segurança
              _buildTextFormField(
                controller: _safetyMarginController,
                labelText: 'Margem de Segurança',
                hintText: 'Ex: 10 (10% para imprevistos)',
                unitText: '%',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a margem de segurança.';
                  }
                  final double? parsedValue = double.tryParse(value.replaceAll(',', '.'));
                  if (parsedValue == null || parsedValue < 0) {
                    return 'A margem não pode ser negativa.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Botão de Cálculo
              ElevatedButton(
                onPressed: _isLoading ? null : _calculateGeneralConstruction,
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
                        'Calcular Custo Total da Construção',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 24),
              // Área de Resultados
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
                              'Resumo do Custo Total:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildResultRow('Custo Subtotal (Itens):', 'R\$ ${_result!["subtotalCost"]}'),
                            _buildResultRow('Margem de Segurança (${_result!["safetyMarginPercentage"]}%):', 'R\$ ${_result!["safetyMarginAmount"]}'),
                            const Divider(height: 20, thickness: 1),
                            _buildResultRow('Custo Total Estimado:', 'R\$ ${_result!["grandTotalCost"]}', isTotal: true),
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

  // Helper para construir campos de texto com validação e melhorias de UX
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

  // Helper para exibir linhas de resultado
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
