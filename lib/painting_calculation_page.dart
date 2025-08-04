import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para controlar o teclado numérico
import 'main.dart'; // Importa main.dart para usar CalculationPage
import 'package:calc_construtor/calculation_history_service.dart'; // IMPORTANTE: Adicione esta linha
import 'calculation_page_base.dart';

// Enum para os diferentes tipos de tinta com rendimentos padrão
enum PaintType {
  latexPVA(name: 'Tinta Látex PVA', defaultYield: 10.0), // Ex: 10 m²/L
  acrylic(name: 'Tinta Acrílica', defaultYield: 8.0), // Ex: 8 m²/L
  syntheticEnamel(name: 'Tinta Esmalte Sintético', defaultYield: 12.0), // Ex: 12 m²/L
  epoxy(name: 'Tinta Epóxi', defaultYield: 7.0), // Ex: 7 m²/L
  lime(name: 'Tinta a Cal', defaultYield: 4.0), // Ex: 4 m²/L
  floorTilesPaint(name: 'Tintas para Pisos e Azulejos', defaultYield: 6.0), // Ex: 6 m²/L
  woodPaint(name: 'Tintas para Madeira', defaultYield: 10.0), // Ex: 10 m²/L
  crepe(name: 'Crepe', defaultYield: 5.0), // Ex: 5 m²/L (assumindo um rendimento para crepe)
  varnish(name: 'Verniz', defaultYield: 15.0), // Ex: 15 m²/L
  oilPaint(name: 'Tinta a Óleo', defaultYield: 11.0); // Ex: 11 m²/L

  final String name;
  final double defaultYield; // Novo: rendimento padrão para cada tipo

  const PaintType({required this.name, required this.defaultYield});
}

class PaintingCalculationPage extends StatefulWidget {
  const PaintingCalculationPage({super.key});

  @override
  State<PaintingCalculationPage> createState() => _PaintingCalculationPageState();
}

class _PaintingCalculationPageState extends State<PaintingCalculationPage> {
  // Chave global para o formulário, usada para validação
  final _formKey = GlobalKey<FormState>();

  // Controladores para os campos de texto
  final TextEditingController _wallLengthController = TextEditingController(); // Comprimento da parede
  final TextEditingController _wallHeightController = TextEditingController(); // Altura da parede
  final TextEditingController _doorsWindowsAreaController = TextEditingController(); // Área de portas/janelas
  final TextEditingController _coatsOfPaintController = TextEditingController(); // Número de demãos
  final TextEditingController _paintYieldPerLiterController = TextEditingController(); // Rendimento da tinta por litro (m²/L)
  final TextEditingController _paintUnitPriceController = TextEditingController(); // Preço por litro de tinta

  // Variável para armazenar o tipo de tinta selecionado
  PaintType? _selectedPaintType;

  Map<String, dynamic>? _result; // Resultado do cálculo
  bool _isLoading = false; // Novo: Estado para controlar o carregamento

  // IMPORTANTE: Instância do serviço de histórico
  final CalculationHistoryService _historyService = CalculationHistoryService();

  @override
  void dispose() {
    // Limpa os controladores quando o widget é descartado
    _wallLengthController.dispose();
    _wallHeightController.dispose();
    _doorsWindowsAreaController.dispose();
    _coatsOfPaintController.dispose();
    _paintYieldPerLiterController.dispose();
    _paintUnitPriceController.dispose();
    super.dispose();
  }

  // Função para limpar todos os campos e resultados
  void _clearFields() {
    _formKey.currentState?.reset(); // Reseta o estado dos campos do formulário
    _wallLengthController.clear();
    _wallHeightController.clear();
    _doorsWindowsAreaController.clear();
    _coatsOfPaintController.clear();
    _paintYieldPerLiterController.clear();
    _paintUnitPriceController.clear();
    setState(() {
      _result = null; // Limpa os resultados exibidos
      _selectedPaintType = null; // Limpa o tipo de tinta selecionado
    });
    // Opcional: Remover o foco do teclado
    FocusScope.of(context).unfocus();
  }

  // Função para calcular a pintura e os custos
  void _calculatePainting() async { // Adicionado 'async' para simular um atraso
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

    // Valida se um tipo de tinta foi selecionado
    if (_selectedPaintType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um tipo de tinta.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null; // Limpa resultados anteriores enquanto carrega
    });

    // Simula um atraso para demonstrar o indicador de carregamento
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Tenta converter os valores para double (agora com replaceAll(',', '.'))
      final double wallLength = double.parse(_wallLengthController.text.replaceAll(',', '.'));
      final double wallHeight = double.parse(_wallHeightController.text.replaceAll(',', '.'));
      final double doorsWindowsArea = double.parse(_doorsWindowsAreaController.text.replaceAll(',', '.'));
      final int coatsOfPaint = int.parse(_coatsOfPaintController.text.replaceAll(',', '.')); // Convertendo para int
      final double paintYieldPerLiter = double.parse(_paintYieldPerLiterController.text.replaceAll(',', '.'));
      final double paintPrice = double.parse(_paintUnitPriceController.text.replaceAll(',', '.'));

      // Validação extra para garantir valores lógicos
      if (coatsOfPaint <= 0) {
        setState(() {
          _result = {"error": "O número de demãos deve ser maior que 0."};
        });
        return;
      }
      if (paintYieldPerLiter <= 0) {
        setState(() {
          _result = {"error": "O rendimento da tinta por litro deve ser maior que 0."};
        });
        return;
      }
      if (paintPrice < 0) {
        setState(() {
          _result = {"error": "O preço da tinta não pode ser negativo."};
        });
        return;
      }

      // Área total da parede sem descontos
      final double totalWallArea = wallLength * wallHeight;

      // Área a ser pintada (descontando portas e janelas)
      final double paintableArea = totalWallArea - doorsWindowsArea;

      if (paintableArea < 0) {
        setState(() {
          _result = {"error": "A área de portas/janelas não pode ser maior que a área total da parede."};
        });
        return;
      }

      // Consumo total de tinta em litros
      final double totalPaintLiters = (paintableArea / paintYieldPerLiter) * coatsOfPaint;

      // Custo total da tinta
      final double totalPaintCost = totalPaintLiters * paintPrice;

      // *** AQUI É ONDE O MAPA _result É CONSTRUÍDO E O CÁLCULO É SALVO ***
      final Map<String, dynamic> currentCalculationResult = {
        "paintType": _selectedPaintType!.name, // Salva o tipo de tinta selecionado
        "totalWallArea": totalWallArea.toStringAsFixed(2),
        "paintableArea": paintableArea.toStringAsFixed(2),
        "totalPaintLiters": totalPaintLiters.toStringAsFixed(2),
        "totalPaintCost": totalPaintCost.toStringAsFixed(2),
        // Opcional: Salvar também os valores de entrada para referência futura
        "wallLength": wallLength.toStringAsFixed(2),
        "wallHeight": wallHeight.toStringAsFixed(2),
        "doorsWindowsArea": doorsWindowsArea.toStringAsFixed(2),
        "coatsOfPaint": coatsOfPaint,
        "paintYieldPerLiter": paintYieldPerLiter.toStringAsFixed(2),
        "paintUnitPrice": paintPrice.toStringAsFixed(2),
      };

      setState(() {
        _result = currentCalculationResult; // Atribui o resultado ao _result do estado
      });

      // IMPORTANTE: Chame o serviço para salvar o cálculo
      await _historyService.saveCalculation(currentCalculationResult, 'Pintura');

      // Feedback visual de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cálculo realizado e salvo com sucesso!'),
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
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CalculationPage(
      title: 'Cálculo de Pintura e Custos',
      body: SingleChildScrollView( // Permite rolagem se o conteúdo for muito grande
        child: Form( // Envolve o conteúdo com um Form para validação
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Mensagem de instrução
              const Text(
                'Insira as dimensões da área a ser pintada, descontando portas e janelas.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Dropdown para seleção do tipo de tinta
              DropdownButtonFormField<PaintType>(
                value: _selectedPaintType,
                decoration: InputDecoration(
                  labelText: 'Tipo de Tinta',
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
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                hint: const Text('Selecione o tipo de tinta'),
                onChanged: (PaintType? newValue) {
                  setState(() {
                    _selectedPaintType = newValue;
                    if (newValue != null) {
                      _paintYieldPerLiterController.text = newValue.defaultYield.toStringAsFixed(2);
                    } else {
                      _paintYieldPerLiterController.clear();
                    }
                  });
                },
                items: PaintType.values.map((PaintType type) {
                  return DropdownMenuItem<PaintType>(
                    value: type,
                    child: Text(type.name),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null) {
                    return 'Por favor, selecione um tipo de tinta.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Comprimento da Parede
              _buildTextFormField(
                controller: _wallLengthController,
                labelText: 'Comprimento da Parede',
                hintText: 'Ex: 8.0',
                unitText: 'm', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o comprimento da parede.';
                  }
                  final double? parsedValue = double.tryParse(value.replaceAll(',', '.'));
                  if (parsedValue == null) {
                    return 'Valor inválido. Use números.';
                  }
                  if (parsedValue <= 0) {
                    return 'O comprimento deve ser maior que 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Altura da Parede
              _buildTextFormField(
                controller: _wallHeightController,
                labelText: 'Altura da Parede',
                hintText: 'Ex: 2.7',
                unitText: 'm', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a altura da parede.';
                  }
                  final double? parsedValue = double.tryParse(value.replaceAll(',', '.'));
                  if (parsedValue == null) {
                    return 'Valor inválido. Use números.';
                  }
                  if (parsedValue <= 0) {
                    return 'A altura deve ser maior que 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Área de Portas e Janelas
              _buildTextFormField(
                controller: _doorsWindowsAreaController,
                labelText: 'Área de Portas/Janelas',
                hintText: 'Ex: 2.0 (se houver)',
                unitText: 'm²', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    // Se o campo estiver vazio, considera 0 para o cálculo, mas não é um erro de validação
                    return null; // Não é obrigatório, 0 é o padrão se vazio
                  }
                  final double? parsedValue = double.tryParse(value.replaceAll(',', '.'));
                  if (parsedValue == null) {
                    return 'Valor inválido. Use números.';
                  }
                  if (parsedValue < 0) {
                    return 'A área não pode ser negativa.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Número de Demãos
              _buildTextFormField(
                controller: _coatsOfPaintController,
                labelText: 'Número de Demãos',
                hintText: 'Ex: 2 ou 3',
                unitText: 'demãos', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o número de demãos.';
                  }
                  final int? parsedValue = int.tryParse(value);
                  if (parsedValue == null) {
                    return 'Valor inválido. Use números inteiros.';
                  }
                  if (parsedValue <= 0) {
                    return 'O número de demãos deve ser um inteiro positivo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Rendimento da Tinta por Litro
              _buildTextFormField(
                controller: _paintYieldPerLiterController,
                labelText: 'Rendimento da Tinta por Litro',
                hintText: 'Ex: 5.0 (5m² por litro)',
                unitText: 'm²/L', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o rendimento da tinta.';
                  }
                  final double? parsedValue = double.tryParse(value.replaceAll(',', '.'));
                  if (parsedValue == null) {
                    return 'Valor inválido. Use números.';
                  }
                  if (parsedValue <= 0) {
                    return 'O rendimento deve ser maior que 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Seção de Preços Unitários
              const Text(
                'Preço Unitário da Tinta (Opcional para Custo)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _paintUnitPriceController,
                labelText: 'Preço por Litro de Tinta',
                hintText: 'Ex: 25.00',
                unitText: 'R\$', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null; // Não é obrigatório, 0 é o padrão se vazio
                  }
                  final double? parsedValue = double.tryParse(value.replaceAll(',', '.'));
                  if (parsedValue == null) {
                    return 'Valor inválido. Use números.';
                  }
                  if (parsedValue < 0) {
                    return 'O preço não pode ser negativo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Botão de Cálculo
              ElevatedButton(
                onPressed: _isLoading ? null : _calculatePainting, // Desabilita o botão durante o carregamento
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
                        'Calcular Pintura e Custos',
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
                            _buildResultRow('Tipo de Tinta:', '${_result!["paintType"]}'), // Exibe o tipo de tinta
                            _buildResultRow('Área Total da Parede:', '${_result!["totalWallArea"]} m²'),
                            _buildResultRow('Área a Ser Pintada:', '${_result!["paintableArea"]} m²'),
                            _buildResultRow('Total de Tinta Necessária:', '${_result!["totalPaintLiters"]} litros'),
                            _buildResultRow('Número de Demãos:', '${_result!["coatsOfPaint"]}'),
                            _buildResultRow('Rendimento por Litro:', '${_result!["paintYieldPerLiter"]} m²/L'),
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
                            _buildResultRow('Custo Total da Tinta:', 'R\$ ${_result!["totalPaintCost"]}', isTotal: true),
                            const SizedBox(height: 10),
                            const Text(
                              '*Este cálculo é uma estimativa. O rendimento da tinta pode variar.',
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
                color: isTotal ? Colors.green[700] : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
