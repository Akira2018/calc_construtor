import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para controlar o teclado numérico
import 'main.dart'; // Importa main.dart para usar CalculationPage
import 'package:calc_construtor/calculation_history_service.dart'; // NOVO: Importa o serviço de histórico
import 'calculation_page_base.dart';

class ConcreteCalculationPage extends StatefulWidget {
  const ConcreteCalculationPage({super.key});

  @override
  State<ConcreteCalculationPage> createState() => _ConcreteCalculationPageState();
}

class _ConcreteCalculationPageState extends State<ConcreteCalculationPage> {
  // Chave global para o formulário, usada para validação
  final _formKey = GlobalKey<FormState>();

  // Controladores para os campos de texto
  final TextEditingController _lengthController = TextEditingController(); // Comprimento
  final TextEditingController _widthController = TextEditingController(); // Largura/Base
  final TextEditingController _heightController = TextEditingController(); // Altura/Espessura
  final TextEditingController _concreteUnitPriceController = TextEditingController(); // Preço por m³ de concreto
  final TextEditingController _waterUnitPriceController = TextEditingController(); // Novo: Preço por litro de água

  Map<String, dynamic>? _result; // Resultado do cálculo
  bool _isLoading = false; // Estado para controlar o carregamento

  @override
  void dispose() {
    // Limpa os controladores quando o widget é descartado
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _concreteUnitPriceController.dispose();
    _waterUnitPriceController.dispose(); // Limpa o novo controlador
    super.dispose();
  }

  // Função para limpar todos os campos e resultados
  void _clearFields() {
    _formKey.currentState?.reset(); // Reseta o estado dos campos do formulário
    _lengthController.clear();
    _widthController.clear();
    _heightController.clear();
    _concreteUnitPriceController.clear();
    _waterUnitPriceController.clear(); // Limpa o novo controlador
    setState(() {
      _result = null; // Limpa os resultados exibidos
    });
    // Opcional: Remover o foco do teclado
    FocusScope.of(context).unfocus();
  }

  // Função para calcular o volume de concreto e o custo
  void _calculateConcrete() async { // Adicionado 'async' para simular um atraso
    // Valida todos os campos do formulário
    if (!_formKey.currentState!.validate()) {
      // Se a validação falhar, exibe uma SnackBar de erro
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos obrigatórios corretamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Interrompe a função se a validação falhar
    }

    setState(() {
      _isLoading = true; // Inicia o carregamento
      _result = null; // Limpa resultados anteriores enquanto carrega
    });

    // Simula um atraso para demonstrar o indicador de carregamento
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Tenta converter os valores para double (agora com replaceAll(',', '.'))
      final double length = double.parse(_lengthController.text.replaceAll(',', '.'));
      final double width = double.parse(_widthController.text.replaceAll(',', '.'));
      final double height = double.parse(_heightController.text.replaceAll(',', '.'));
      final double concretePrice = double.parse(_concreteUnitPriceController.text.replaceAll(',', '.'));
      final double waterPrice = double.parse(_waterUnitPriceController.text.replaceAll(',', '.')); // Novo: Preço da água

      // Validação dos preços (já tratada nos validators, mas um check extra para negativos)
      if (concretePrice < 0 || waterPrice < 0) { // Adicionada validação para preço negativo da água
        setState(() {
          _result = {"error": "Os preços unitários não podem ser negativos."};
        });
        return;
      }

      // Cálculo do volume de concreto (em m³)
      final double concreteVolume = length * width * height;

      // Estimativa de consumo de água para concreto (ex: 180-200 litros por m³ de concreto)
      // Usaremos 190 litros/m³ como uma média de referência.
      final double totalWaterLiters = concreteVolume * 190; // Litros

      // Cálculo do custo total do concreto
      final double totalConcreteCost = concreteVolume * concretePrice;
      final double totalWaterCost = totalWaterLiters * waterPrice; // Novo: Custo da água
      final double grandTotalCost = totalConcreteCost + totalWaterCost; // Novo: Soma o custo da água

      // *** AQUI É ONDE O MAPA _result É CONSTRUÍDO E O CÁLCULO É SALVO ***
      final Map<String, dynamic> currentCalculationResult = {
        "concreteVolume": concreteVolume.toStringAsFixed(2),
        "totalWaterLiters": totalWaterLiters.toStringAsFixed(2),
        "totalConcreteCost": totalConcreteCost.toStringAsFixed(2),
        "totalWaterCost": totalWaterCost.toStringAsFixed(2),
        "grandTotalCost": grandTotalCost.toStringAsFixed(2),
        // Opcional: Salvar também os valores de entrada para referência futura
        "length": length.toStringAsFixed(2),
        "width": width.toStringAsFixed(2),
        "height": height.toStringAsFixed(2),
        "concreteUnitPrice": concretePrice.toStringAsFixed(2),
        "waterUnitPrice": waterPrice.toStringAsFixed(2),
      };

      setState(() {
        _result = currentCalculationResult; // Atribui o resultado ao _result do estado
      });

      // Chame o serviço para salvar o cálculo
      final CalculationHistoryService historyService = CalculationHistoryService();
      await historyService.saveCalculation(currentCalculationResult, 'Concreto'); // 'Concreto' é o tipo de cálculo

      // Feedback visual de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cálculo realizado com sucesso e salvo no histórico!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Captura erros de parsing ou outros erros inesperados
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
        _isLoading = false; // Finaliza o carregamento, mesmo em caso de erro
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CalculationPage(
      title: 'Cálculo de Concreto e Custos',
      body: SingleChildScrollView( // Permite rolagem se o conteúdo for muito grande
        child: Form( // Envolve o conteúdo com um Form para validação
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Mensagem de instrução
              const Text(
                'Insira as dimensões do elemento de concreto (Laje, Pilar, Viga).',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Campo para Comprimento
              _buildTextFormField(
                controller: _lengthController,
                labelText: 'Comprimento',
                hintText: 'Ex: 5.0 para laje/viga/pilar',
                unitText: 'm', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o comprimento.';
                  }
                  if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                    return 'O comprimento deve ser maior que 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Campo para Largura/Base
              _buildTextFormField(
                controller: _widthController,
                labelText: 'Largura / Base',
                hintText: 'Ex: 3.0 para laje, 0.20 para viga/pilar',
                unitText: 'm', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a largura/base.';
                  }
                  if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                    return 'A largura/base deve ser maior que 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Campo para Altura/Espessura
              _buildTextFormField(
                controller: _heightController,
                labelText: 'Altura / Espessura',
                hintText: 'Ex: 0.10 para laje, 0.40 para viga/pilar',
                unitText: 'm', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a altura/espessura.';
                  }
                  if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                    return 'A altura/espessura deve ser maior que 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Seção de Preços Unitários
              const Text(
                'Preços Unitários (Opcional para Custo)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _concreteUnitPriceController,
                labelText: 'Preço por m³ de Concreto',
                hintText: 'Ex: 400.00',
                unitText: 'R\$', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    _concreteUnitPriceController.text = '0.0'; // Define 0 se vazio
                    return null;
                  }
                  if (double.tryParse(value.replaceAll(',', '.'))! < 0) {
                    return 'O preço não pode ser negativo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Novo campo para Preço por Litro de Água
              _buildTextFormField(
                controller: _waterUnitPriceController,
                labelText: 'Preço por Litro de Água',
                hintText: 'Ex: 0.01 (1 centavo)',
                unitText: 'R\$', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    _waterUnitPriceController.text = '0.0'; // Define 0 se vazio
                    return null;
                  }
                  if (double.tryParse(value.replaceAll(',', '.'))! < 0) {
                    return 'O preço não pode ser negativo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Botão de Cálculo
              ElevatedButton(
                onPressed: _isLoading ? null : _calculateConcrete, // Desabilita o botão durante o carregamento
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[500],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: Colors.blue.withOpacity(0.5),
                ),
                child: _isLoading // Exibe o indicador de carregamento ou o texto do botão
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Calcular Concreto e Custos',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 24),
              // Área de Resultados
              if (_result != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 80), // Adiciona margem inferior para o FAB
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
                              'Resultados do Cálculo:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildResultRow('Volume de Concreto Necessário:', '${_result!["concreteVolume"]} m³'),
                            _buildResultRow('Água Necessária:', '${_result!["totalWaterLiters"]} litros'), // Novo
                            const SizedBox(height: 20), // Espaço antes dos custos
                            const Text(
                              'Estimativa de Custos:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildResultRow('Custo Total do Concreto:', 'R\$ ${_result!["totalConcreteCost"]}'),
                            _buildResultRow('Custo da Água:', 'R\$ ${_result!["totalWaterCost"]}'), // Novo
                            const Divider(height: 20, thickness: 1, color: Colors.grey),
                            _buildResultRow('Custo Total Estimado:', 'R\$ ${_result!["grandTotalCost"]}', isTotal: true),
                            const SizedBox(height: 10),
                            const Text(
                              '*Este cálculo é uma estimativa. Consulte um profissional para projetos estruturais e traços de concreto.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                ),
            ],
          ),
        ),
      ),
      // Botão flutuante para limpar os campos
      floatingActionButton: FloatingActionButton(
        onPressed: _clearFields,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.clear_all, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // POSICIONAMENTO DO FAB
    );
  }

  // Helper para construir campos de texto com validação e melhorias de UX
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    String? unitText, // Novo: para exibir a unidade de medida
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number, // Teclado numérico
      inputFormatters: <TextInputFormatter>[
        // Permite números, vírgula ou ponto, e até 2 casas decimais
        FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
        // Substitui vírgulas por pontos automaticamente
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
        enabledBorder: OutlineInputBorder( // Borda quando o campo está habilitado
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder( // Borda quando o campo está focado
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue, width: 2.0),
        ),
        errorBorder: OutlineInputBorder( // Borda quando há erro
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder( // Borda quando há erro e o campo está focado
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        suffixText: unitText, // Exibe a unidade de medida
        suffixStyle: const TextStyle(color: Colors.grey, fontSize: 14), // Estilo da unidade
        errorStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), // Estilo da mensagem de erro
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
                color: isTotal ? Colors.black : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
