import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para controlar o teclado numérico
import 'main.dart'; // Importa main.dart para usar CalculationPage
import 'package:calc_construtor/calculation_history_service.dart'; // NOVO: Importa o serviço de histórico
import 'calculation_page_base.dart';

class PlasterCalculationPage extends StatefulWidget {
  const PlasterCalculationPage({super.key});

  @override
  State<PlasterCalculationPage> createState() => _PlasterCalculationPageState();
}

class _PlasterCalculationPageState extends State<PlasterCalculationPage> {
  // Chave global para o formulário, usada para validação
  final _formKey = GlobalKey<FormState>();

  // Controladores para os campos de texto
  final TextEditingController _lengthController = TextEditingController(); // Comprimento da área
  final TextEditingController _heightController = TextEditingController(); // Altura da área
  final TextEditingController _thicknessController = TextEditingController(); // Espessura do reboco/chapisco
  final TextEditingController _cementUnitPriceController = TextEditingController(); // Preço do saco de cimento
  final TextEditingController _sandUnitPriceController = TextEditingController(); // Preço do m³ de areia
  final TextEditingController _waterUnitPriceController = TextEditingController(); // Preço do litro de água

  Map<String, dynamic>? _result; // Resultado do cálculo
  bool _isLoading = false; // Estado para controlar o carregamento

  // NOVO: Instância do serviço de histórico
  final CalculationHistoryService _historyService = CalculationHistoryService();

  @override
  void dispose() {
    // Limpa os controladores quando o widget é descartado
    _lengthController.dispose();
    _heightController.dispose();
    _thicknessController.dispose();
    _cementUnitPriceController.dispose();
    _sandUnitPriceController.dispose();
    _waterUnitPriceController.dispose(); // Limpa o novo controlador
    super.dispose();
  }

  // Função para limpar todos os campos e resultados
  void _clearFields() {
    _formKey.currentState?.reset(); // Reseta o estado dos campos do formulário
    _lengthController.clear();
    _heightController.clear();
    _thicknessController.clear();
    _cementUnitPriceController.clear();
    _sandUnitPriceController.clear();
    _waterUnitPriceController.clear(); // Limpa o novo controlador
    setState(() {
      _result = null; // Limpa os resultados exibidos
    });
    // Opcional: Remover o foco do teclado
    FocusScope.of(context).unfocus();
  }

  // Função para calcular o reboco/chapisco e os custos
  void _calculatePlaster() async { // Adicionado 'async' para simular um atraso
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
      final double height = double.parse(_heightController.text.replaceAll(',', '.'));
      final double thickness = double.parse(_thicknessController.text.replaceAll(',', '.')); // em cm
      final double cementPrice = double.parse(_cementUnitPriceController.text.replaceAll(',', '.'));
      final double sandPrice = double.parse(_sandUnitPriceController.text.replaceAll(',', '.'));
      final double waterPrice = double.parse(_waterUnitPriceController.text.replaceAll(',', '.')); // Novo: Preço da água

      // Validação dos preços (já tratada nos validators, mas um check extra para negativos)
      if (cementPrice < 0 || sandPrice < 0 || waterPrice < 0) {
        setState(() {
          _result = {"error": "Os preços unitários não podem ser negativos."};
        });
        return;
      }

      final double area = length * height; // Área em m²
      final double volume = area * (thickness / 100); // Volume em m³ (convertendo cm para metros)

      // Proporções de traço comuns (exemplo para reboco 1:2:8 cimento:cal:areia)
      // Para simplificar, vamos usar um consumo médio por m³ de argamassa pronta:
      // Cimento: 6 sacos de 50kg por m³ de argamassa (300 kg)
      // Areia: 1.0 m³ de areia por m³ de argamassa
      // Água: 200 litros por m³ de argamassa (NOVO: Adicionado consumo de água)

      // Quantidade de materiais necessários para o volume calculado
      final double totalCementBags = volume * 6; // Sacos de 50kg
      final double totalSandM3 = volume * 1.0; // m³
      final double totalWaterLiters = volume * 200; // Litros (NOVO: Cálculo de água)

      // Cálculo dos custos
      final double totalCementCost = totalCementBags * cementPrice;
      final double totalSandCost = totalSandM3 * sandPrice;
      final double totalWaterCost = totalWaterLiters * waterPrice; // NOVO: Custo da água
      final double grandTotalCost = totalCementCost + totalSandCost + totalWaterCost; // NOVO: Soma o custo da água

      // *** AQUI É ONDE O MAPA _result É CONSTRUÍDO E O CÁLCULO É SALVO ***
      final Map<String, dynamic> currentCalculationResult = {
        "area": area.toStringAsFixed(2),
        "volume": volume.toStringAsFixed(2),
        "totalCementBags": totalCementBags.ceil(), // Arredonda para cima
        "totalSandM3": totalSandM3.toStringAsFixed(2),
        "totalWaterLiters": totalWaterLiters.toStringAsFixed(2), // NOVO: Água necessária
        "totalCementCost": totalCementCost.toStringAsFixed(2),
        "totalSandCost": totalSandCost.toStringAsFixed(2),
        "totalWaterCost": totalWaterCost.toStringAsFixed(2), // NOVO: Custo da água
        "grandTotalCost": grandTotalCost.toStringAsFixed(2),
        // Opcional: Salvar também os valores de entrada para referência futura
        "length": length.toStringAsFixed(2),
        "height": height.toStringAsFixed(2),
        "thickness": thickness.toStringAsFixed(2),
        "cementUnitPrice": cementPrice.toStringAsFixed(2),
        "sandUnitPrice": sandPrice.toStringAsFixed(2),
        "waterUnitPrice": waterPrice.toStringAsFixed(2),
      };

      setState(() {
        _result = currentCalculationResult; // Atribui o resultado ao _result do estado
      });

      // Chame o serviço para salvar o cálculo
      await _historyService.saveCalculation(currentCalculationResult, 'Reboco/Chapisco');

      // Feedback visual de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cálculo realizado e salvo com sucesso!'), // Mensagem atualizada
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
      title: 'Cálculo de Reboco/Chapisco e Custos',
      body: SingleChildScrollView( // Permite rolagem se o conteúdo for muito grande
        child: Form( // Envolve o conteúdo com um Form para validação
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Mensagem de instrução
              const Text(
                'Insira as dimensões da área a ser rebocada/chapiscada e a espessura desejada.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Campo para Comprimento da Área
              _buildTextFormField(
                controller: _lengthController,
                labelText: 'Comprimento da Área',
                hintText: 'Ex: 10.0',
                unitText: 'm', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o comprimento da área.';
                  }
                  if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                    return 'O comprimento deve ser maior que 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Campo para Altura da Área
              _buildTextFormField(
                controller: _heightController,
                labelText: 'Altura da Área',
                hintText: 'Ex: 3.0',
                unitText: 'm', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a altura da área.';
                  }
                  if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                    return 'A altura deve ser maior que 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Campo para Espessura do Reboco/Chapisco
              _buildTextFormField(
                controller: _thicknessController,
                labelText: 'Espessura do Reboco/Chapisco',
                hintText: 'Ex: 2.5 para reboco, 0.5 para chapisco',
                unitText: 'cm', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a espessura.';
                  }
                  if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                    return 'A espessura deve ser maior que 0.';
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
                controller: _cementUnitPriceController,
                labelText: 'Preço por Saco de Cimento',
                hintText: 'Ex: 35.00',
                unitText: 'R\$', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    _cementUnitPriceController.text = '0.0'; // Define 0 se vazio
                    return null;
                  }
                  if (double.tryParse(value.replaceAll(',', '.'))! < 0) {
                    return 'O preço não pode ser negativo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _sandUnitPriceController,
                labelText: 'Preço por m³ de Areia',
                hintText: 'Ex: 80.00',
                unitText: 'R\$', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    _sandUnitPriceController.text = '0.0'; // Define 0 se vazio
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
                onPressed: _isLoading ? null : _calculatePlaster, // Desabilita o botão durante o carregamento
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
                        'Calcular Reboco/Chapisco e Custos',
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
                            _buildResultRow('Área Total:', '${_result!["area"]} m²'),
                            _buildResultRow('Volume de Argamassa:', '${_result!["volume"]} m³'),
                            _buildResultRow('Sacos de Cimento (50kg):', '${_result!["totalCementBags"]} unidades'),
                            _buildResultRow('Areia:', '${_result!["totalSandM3"]} m³'),
                            _buildResultRow('Água:', '${_result!["totalWaterLiters"]} litros'), // NOVO
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
                            _buildResultRow('Custo do Cimento:', 'R\$ ${_result!["totalCementCost"]}'),
                            _buildResultRow('Custo da Areia:', 'R\$ ${_result!["totalSandCost"]}'),
                            _buildResultRow('Custo da Água:', 'R\$ ${_result!["totalWaterCost"]}'), // NOVO
                            const Divider(height: 20, thickness: 1, color: Colors.grey),
                            _buildResultRow('Custo Total Estimado:', 'R\$ ${_result!["grandTotalCost"]}', isTotal: true),
                            const SizedBox(height: 10),
                            const Text(
                              '*Este cálculo é uma estimativa baseada em proporções médias. Consulte um profissional para validação e ajuste de traços.',
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
