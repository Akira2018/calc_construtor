import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para controlar o teclado numérico
import 'main.dart'; // Importa main.dart para usar CalculationPage
import 'package:calc_construtor/calculation_history_service.dart'; // NOVO: Importa o serviço de histórico
import 'calculation_page_base.dart';

class FlooringCalculationPage extends StatefulWidget {
  const FlooringCalculationPage({super.key});

  @override
  State<FlooringCalculationPage> createState() => _FlooringCalculationPageState();
}

class _FlooringCalculationPageState extends State<FlooringCalculationPage> {
  // Chave global para o formulário, usada para validação
  final _formKey = GlobalKey<FormState>();

  // Controladores para os campos de texto
  final TextEditingController _roomLengthController = TextEditingController(); // Comprimento do cômodo
  final TextEditingController _roomWidthController = TextEditingController(); // Largura do cômodo
  final TextEditingController _tileLengthController = TextEditingController(); // Comprimento do piso/azulejo
  final TextEditingController _tileWidthController = TextEditingController(); // Largura do piso/azulejo
  final TextEditingController _groutJointThicknessController = TextEditingController(); // Espessura do rejunte
  final TextEditingController _wastePercentageController = TextEditingController(); // Porcentagem de perda
  final TextEditingController _tileUnitPriceController = TextEditingController(); // Preço por unidade de piso/azulejo
  final TextEditingController _mortarUnitPriceController = TextEditingController(); // Preço por saco de argamassa colante
  final TextEditingController _groutUnitPriceController = TextEditingController(); // Preço por kg de rejunte

  Map<String, dynamic>? _result; // Resultado do cálculo
  bool _isLoading = false; // Novo: Estado para controlar o carregamento

  // NOVO: Instância do serviço de histórico
  final CalculationHistoryService _historyService = CalculationHistoryService();

  @override
  void dispose() {
    // Limpa os controladores quando o widget é descartado
    _roomLengthController.dispose();
    _roomWidthController.dispose();
    _tileLengthController.dispose();
    _tileWidthController.dispose();
    _groutJointThicknessController.dispose();
    _wastePercentageController.dispose();
    _tileUnitPriceController.dispose();
    _mortarUnitPriceController.dispose();
    _groutUnitPriceController.dispose();
    super.dispose();
  }

  // Função para limpar todos os campos e resultados
  void _clearFields() {
    _formKey.currentState?.reset(); // Reseta o estado dos campos do formulário
    _roomLengthController.clear();
    _roomWidthController.clear();
    _tileLengthController.clear();
    _tileWidthController.clear();
    _groutJointThicknessController.clear();
    _wastePercentageController.clear();
    _tileUnitPriceController.clear();
    _mortarUnitPriceController.clear();
    _groutUnitPriceController.clear();
    setState(() {
      _result = null; // Limpa os resultados exibidos
    });
    // Opcional: Remover o foco do teclado
    FocusScope.of(context).unfocus();
  }

  // Função para calcular o piso/revestimento e os custos
  void _calculateFlooring() async { // Adicionado 'async' para simular um atraso
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
      final double roomLength = double.parse(_roomLengthController.text.replaceAll(',', '.'));
      final double roomWidth = double.parse(_roomWidthController.text.replaceAll(',', '.'));
      final double tileLength = double.parse(_tileLengthController.text.replaceAll(',', '.')); // em cm
      final double tileWidth = double.parse(_tileWidthController.text.replaceAll(',', '.')); // em cm
      final double groutJointThickness = double.parse(_groutJointThicknessController.text.replaceAll(',', '.')); // em mm
      final double wastePercentage = double.parse(_wastePercentageController.text.replaceAll(',', '.')); // em %
      final double tilePrice = double.parse(_tileUnitPriceController.text.replaceAll(',', '.'));
      final double mortarPrice = double.parse(_mortarUnitPriceController.text.replaceAll(',', '.')); // por saco
      final double groutPrice = double.parse(_groutUnitPriceController.text.replaceAll(',', '.')); // por kg

      // Validação dos preços (já tratada nos validators, mas um check extra para negativos)
      if (tilePrice < 0 || mortarPrice < 0 || groutPrice < 0) {
        setState(() {
          _result = {"error": "Os preços unitários não podem ser negativos."};
        });
        return;
      }

      final double roomArea = roomLength * roomWidth; // Área do cômodo em m²

      // Área de um único piso/azulejo (convertendo cm para metros)
      final double tileArea = (tileLength / 100) * (tileWidth / 100); // em m²

      // Quantidade de pisos/azulejos sem considerar rejunte e perda
      final double rawTilesNeeded = roomArea / tileArea;

      // Adicionando a porcentagem de perda
      final double totalTilesNeededWithWaste = rawTilesNeeded * (1 + (wastePercentage / 100));
      final int totalTiles = totalTilesNeededWithWaste.ceil(); // Arredonda para cima

      // Estimativa de argamassa colante (ex: 5 kg/m² para espessura de 5mm, um saco de 20kg rende ~4m²)
      final double mortarNeededKg = roomArea * 5; // kg
      final int totalMortarBags = (mortarNeededKg / 20).ceil(); // Sacos de 20kg

      // Estimativa de rejunte (ex: 0.3 kg/m² para rejunte de 3mm com peças 60x60)
      // Este valor varia muito com o tamanho da peça e espessura do rejunte.
      // Vamos usar uma estimativa baseada na área e espessura do rejunte (em mm)
      // Um valor de referência comum é 0.2 a 0.5 kg/m²
      final double groutNeededKg = roomArea * (groutJointThickness / 10); // Simplificado: 0.X kg/m² baseado na espessura em mm
      final double totalGroutKg = groutNeededKg; // kg

      // Cálculo dos custos
      final double totalTileCost = totalTiles * tilePrice;
      final double totalMortarCost = totalMortarBags * mortarPrice;
      final double totalGroutCost = totalGroutKg * groutPrice;
      final double grandTotalCost = totalTileCost + totalMortarCost + totalGroutCost;

      // *** AQUI É ONDE O MAPA _result É CONSTRUÍDO E O CÁLCULO É SALVO ***
      final Map<String, dynamic> currentCalculationResult = {
        "roomArea": roomArea.toStringAsFixed(2),
        "totalTiles": totalTiles,
        "totalMortarBags": totalMortarBags,
        "totalGroutKg": totalGroutKg.toStringAsFixed(2),
        "totalTileCost": totalTileCost.toStringAsFixed(2),
        "totalMortarCost": totalMortarCost.toStringAsFixed(2),
        "totalGroutCost": totalGroutCost.toStringAsFixed(2),
        "grandTotalCost": grandTotalCost.toStringAsFixed(2),
        // Opcional: Salvar também os valores de entrada para referência futura
        "roomLength": roomLength.toStringAsFixed(2),
        "roomWidth": roomWidth.toStringAsFixed(2),
        "tileLength": tileLength.toStringAsFixed(2),
        "tileWidth": tileWidth.toStringAsFixed(2),
        "groutJointThickness": groutJointThickness.toStringAsFixed(2),
        "wastePercentage": wastePercentage.toStringAsFixed(2),
        "tileUnitPrice": tilePrice.toStringAsFixed(2),
        "mortarUnitPrice": mortarPrice.toStringAsFixed(2),
        "groutUnitPrice": groutPrice.toStringAsFixed(2),
      };

      setState(() {
        _result = currentCalculationResult; // Atribui o resultado ao _result do estado
      });

      // Chame o serviço para salvar o cálculo
      await _historyService.saveCalculation(currentCalculationResult, 'Piso/Revestimento');

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
      title: 'Cálculo de Piso/Revestimento e Custos',
      body: SingleChildScrollView( // Permite rolagem se o conteúdo for muito grande
        child: Form( // Envolve o conteúdo com um Form para validação
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Mensagem de instrução
              const Text(
                'Insira as dimensões do cômodo, do piso/azulejo e a porcentagem de perda.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Comprimento do Cômodo
              _buildTextFormField(
                controller: _roomLengthController,
                labelText: 'Comprimento do Cômodo',
                hintText: 'Ex: 4.0',
                unitText: 'm', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o comprimento do cômodo.';
                  }
                  if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                    return 'O comprimento deve ser maior que 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Largura do Cômodo
              _buildTextFormField(
                controller: _roomWidthController,
                labelText: 'Largura do Cômodo',
                hintText: 'Ex: 3.5',
                unitText: 'm', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a largura do cômodo.';
                  }
                  if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                    return 'A largura deve ser maior que 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Comprimento do Piso/Azulejo
              _buildTextFormField(
                controller: _tileLengthController,
                labelText: 'Comprimento do Piso/Azulejo',
                hintText: 'Ex: 60 (para peça 60x60)',
                unitText: 'cm', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o comprimento do piso/azulejo.';
                  }
                  if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                    return 'O comprimento deve ser maior que 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Largura do Piso/Azulejo
              _buildTextFormField(
                controller: _tileWidthController,
                labelText: 'Largura do Piso/Azulejo',
                hintText: 'Ex: 60 (para peça 60x60)',
                unitText: 'cm', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a largura do piso/azulejo.';
                  }
                  if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                    return 'A largura deve ser maior que 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Espessura do Rejunte
              _buildTextFormField(
                controller: _groutJointThicknessController,
                labelText: 'Espessura do Rejunte',
                hintText: 'Ex: 3.0 (para rejunte padrão)',
                unitText: 'mm', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a espessura do rejunte.';
                  }
                  if (double.tryParse(value.replaceAll(',', '.'))! < 0) {
                    return 'A espessura não pode ser negativa.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Porcentagem de Perda
              _buildTextFormField(
                controller: _wastePercentageController,
                labelText: 'Porcentagem de Perda',
                hintText: 'Ex: 10 (para 10% de perda)',
                unitText: '%', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a porcentagem de perda.';
                  }
                  final double? parsedValue = double.tryParse(value.replaceAll(',', '.'));
                  if (parsedValue == null || parsedValue < 0) {
                    return 'A porcentagem não pode ser negativa.';
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
                controller: _tileUnitPriceController,
                labelText: 'Preço por Unidade de Piso/Azulejo',
                hintText: 'Ex: 25.00',
                unitText: 'R\$', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    _tileUnitPriceController.text = '0.0'; // Define 0 se vazio
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
                controller: _mortarUnitPriceController,
                labelText: 'Preço por Saco de Argamassa Colante',
                hintText: 'Ex: 20.00 (saco de 20kg)',
                unitText: 'R\$', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    _mortarUnitPriceController.text = '0.0'; // Define 0 se vazio
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
                controller: _groutUnitPriceController,
                labelText: 'Preço por Kg de Rejunte',
                hintText: 'Ex: 5.00',
                unitText: 'R\$', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    _groutUnitPriceController.text = '0.0'; // Define 0 se vazio
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
                onPressed: _isLoading ? null : _calculateFlooring, // Desabilita o botão durante o carregamento
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
                        'Calcular Piso/Revestimento e Custos',
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
                            _buildResultRow('Área do Cômodo:', '${_result!["roomArea"]} m²'),
                            _buildResultRow('Total de Pisos/Azulejos:', '${_result!["totalTiles"]} unidades'),
                            _buildResultRow('Sacos de Argamassa Colante (20kg):', '${_result!["totalMortarBags"]} unidades'),
                            _buildResultRow('Rejunte:', '${_result!["totalGroutKg"]} kg'),
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
                            _buildResultRow('Custo dos Pisos/Azulejos:', 'R\$ ${_result!["totalTileCost"]}'),
                            _buildResultRow('Custo da Argamassa Colante:', 'R\$ ${_result!["totalMortarCost"]}'),
                            _buildResultRow('Custo do Rejunte:', 'R\$ ${_result!["totalGroutCost"]}'),
                            const Divider(height: 20, thickness: 1, color: Colors.grey),
                            _buildResultRow('Custo Total Estimado:', 'R\$ ${_result!["grandTotalCost"]}', isTotal: true),
                            const SizedBox(height: 10),
                            const Text(
                              '*Este cálculo é uma estimativa. Considere perdas por corte e variações nos consumos de argamassa/rejunte.',
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
