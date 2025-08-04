import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para controlar o teclado numérico
import 'main.dart'; // Importa main.dart para usar CalculationPage
import 'calculation_history_service.dart'; // NOVO: Importa o serviço de histórico
import 'calculation_page_base.dart';

// --- Classe para representar um tipo de tijolo/bloco ---
class BrickType {
  final String name;
  final double length; // em cm
  final double height; // em cm

  const BrickType(this.name, this.length, this.height);
}
// --- Fim da classe BrickType ---

class MasonryCalculationPage extends StatefulWidget {
  const MasonryCalculationPage({super.key});

  @override
  State<MasonryCalculationPage> createState() => _MasonryCalculationPageState();
}

class _MasonryCalculationPageState extends State<MasonryCalculationPage> {
  // Chave global para o formulário, usada para validação
  final _formKey = GlobalKey<FormState>();

  // Controladores para os campos de texto
  final TextEditingController _wallLengthController = TextEditingController();
  final TextEditingController _wallHeightController = TextEditingController();
  final TextEditingController _brickSizeLengthController = TextEditingController();
  final TextEditingController _brickSizeHeightController = TextEditingController();
  final TextEditingController _mortarJointThicknessController = TextEditingController();
  final TextEditingController _brickUnitPriceController = TextEditingController();
  final TextEditingController _cementUnitPriceController = TextEditingController(); // Preço por saco de cimento
  final TextEditingController _limeUnitPriceController = TextEditingController(); // Preço por saco de cal
  final TextEditingController _sandUnitPriceController = TextEditingController(); // Preço por m³ de areia

  Map<String, dynamic>? _result; // Resultado do cálculo
  bool _isLoading = false; // Estado para controlar o carregamento

  // --- Novos para opções de tijolo pré-definidas ---
  // Lista de tipos de tijolos/blocos pré-definidos
  static const List<BrickType> _predefinedBrickTypes = [
    BrickType('Personalizado', 0.0, 0.0), // Opção para entrada manual
    BrickType('Tijolo Comum (Baiano)', 19.0, 9.0),
    BrickType('Tijolo de 6 Furos', 19.0, 14.0),
    BrickType('Bloco de Concreto 19x19x39', 39.0, 19.0),
    BrickType('Bloco de Concreto 14x19x39', 39.0, 19.0),
    BrickType('Bloco de Concreto 9x19x39', 39.0, 19.0),
  ];

  BrickType? _selectedBrickType; // O tipo de tijolo selecionado atualmente

  bool _isCustomBrickSelected = true; // Controla a visibilidade dos campos de entrada manual

  // NOVO: Instância do serviço de histórico
  final CalculationHistoryService _historyService = CalculationHistoryService();

  @override
  void initState() {
    super.initState();
    // Define "Personalizado" como a opção inicial e garante que os campos estejam visíveis
    _selectedBrickType = _predefinedBrickTypes.first; // "Personalizado"
    _isCustomBrickSelected = true;
  }

  @override
  void dispose() {
    // Limpa os controladores quando o widget é descartado
    _wallLengthController.dispose();
    _wallHeightController.dispose();
    _brickSizeLengthController.dispose();
    _brickSizeHeightController.dispose();
    _mortarJointThicknessController.dispose();
    _brickUnitPriceController.dispose();
    _cementUnitPriceController.dispose();
    _limeUnitPriceController.dispose();
    _sandUnitPriceController.dispose();
    super.dispose();
  }

  // Função para limpar todos os campos e resultados
  void _clearFields() {
    _formKey.currentState?.reset(); // Reseta o estado dos campos do formulário
    _wallLengthController.clear();
    _wallHeightController.clear();
    _brickSizeLengthController.clear();
    _brickSizeHeightController.clear();
    _mortarJointThicknessController.clear();
    _brickUnitPriceController.clear();
    _cementUnitPriceController.clear();
    _limeUnitPriceController.clear();
    _sandUnitPriceController.clear();
    setState(() {
      _result = null; // Limpa os resultados exibidos
      _selectedBrickType = _predefinedBrickTypes.first; // Volta para "Personalizado"
      _isCustomBrickSelected = true; // Reativa campos manuais
    });
    // Opcional: Remover o foco do teclado
    FocusScope.of(context).unfocus();
  }

  // Função para calcular a alvenaria e os custos
  void _calculateMasonry() async {
    // Valida todos os campos do formulário
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos obrigatórios corretamente.'),
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
      final double length = double.parse(_wallLengthController.text.replaceAll(',', '.'));
      final double height = double.parse(_wallHeightController.text.replaceAll(',', '.'));
      final double brickL = double.parse(_brickSizeLengthController.text.replaceAll(',', '.'));
      final double brickH = double.parse(_brickSizeHeightController.text.replaceAll(',', '.'));
      final double mortarT = double.parse(_mortarJointThicknessController.text.replaceAll(',', '.'));
      
      final double brickPrice = double.parse(_brickUnitPriceController.text.replaceAll(',', '.'));
      final double cementPrice = double.parse(_cementUnitPriceController.text.replaceAll(',', '.'));
      final double limePrice = double.parse(_limeUnitPriceController.text.replaceAll(',', '.'));
      final double sandPrice = double.parse(_sandUnitPriceController.text.replaceAll(',', '.'));

      if (brickL <= 0 || brickH <= 0 || mortarT < 0) {
        setState(() {
          _result = {"error": "As dimensões do tijolo/bloco e a espessura da argamassa devem ser válidas."};
        });
        return;
      }
      if (brickPrice < 0 || cementPrice < 0 || limePrice < 0 || sandPrice < 0) {
        setState(() {
          _result = {"error": "Os preços unitários não podem ser negativos."};
        });
        return;
      }

      final double wallArea = length * height;

      final double brickWithJointLength = (brickL + mortarT) / 100;
      final double brickWithJointHeight = (brickH + mortarT) / 100;

      final double bricksPerM2 = 1 / (brickWithJointLength * brickWithJointHeight);

      final int totalBricks = (bricksPerM2 * wallArea).ceil();

      final double mortarJointThicknessM = mortarT / 100;
      final double volumeMortarPerM2 = (1 - (brickL/100 * brickH/100 * bricksPerM2)) * mortarJointThicknessM;
      final double totalMortarVolume = wallArea * volumeMortarPerM2;

      final double totalCementBags = totalMortarVolume * 6;
      final double totalLimeBags = totalMortarVolume * 2;
      final double totalSandM3 = totalMortarVolume * 1.0;

      final double totalBrickCost = totalBricks * brickPrice;
      final double totalCementCost = totalCementBags * cementPrice;
      final double totalLimeCost = totalLimeBags * limePrice;
      final double totalSandCost = totalSandM3 * sandPrice;
      final double grandTotalCost = totalBrickCost + totalCementCost + totalLimeCost + totalSandCost;

      setState(() {
        _result = {
          "wallArea": wallArea.toStringAsFixed(2),
          "totalBricks": totalBricks,
          "mortarVolume": totalMortarVolume.toStringAsFixed(2),
          "bricksPerM2": bricksPerM2.toStringAsFixed(2),
          "totalCementBags": totalCementBags.ceil(),
          "totalLimeBags": totalLimeBags.ceil(),
          "totalSandM3": totalSandM3.toStringAsFixed(2),
          "totalBrickCost": totalBrickCost.toStringAsFixed(2),
          "totalCementCost": totalCementCost.toStringAsFixed(2),
          "totalLimeCost": totalLimeCost.toStringAsFixed(2),
          "totalSandCost": totalSandCost.toStringAsFixed(2),
          "grandTotalCost": grandTotalCost.toStringAsFixed(2),
        };
      });

      // NOVO: Salva o cálculo no histórico
      await _historyService.saveCalculation(_result!, 'Alvenaria');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cálculo realizado e salvo com sucesso!'), // Mensagem atualizada
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
      title: 'Cálculo de Alvenaria e Custos',
      body: SingleChildScrollView( // Garante que a tela possa rolar
        child: Form( // Envolve o conteúdo com um Form para validação
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Estica os campos horizontalmente
            children: <Widget>[
              // Mensagem de instrução
              const Text(
                'Insira as dimensões da parede, do tijolo/bloco e a espessura da junta de argamassa.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24), // Espaçamento após a mensagem de instrução
              // Campos de entrada para as dimensões da parede
              _buildTextFormField(
                controller: _wallLengthController,
                labelText: 'Comprimento da Parede',
                hintText: 'Ex: 5.0',
                unitText: 'm', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o comprimento da parede.';
                  }
                  if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                    return 'O comprimento deve ser maior que 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _wallHeightController,
                labelText: 'Altura da Parede',
                hintText: 'Ex: 2.8',
                unitText: 'm', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a altura da parede.';
                  }
                  if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                    return 'A altura deve ser maior que 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // --- Dropdown para seleção de tipo de tijolo/bloco ---
              DropdownButtonFormField<BrickType>(
                value: _selectedBrickType,
                decoration: InputDecoration(
                  labelText: 'Tipo de Tijolo/Bloco',
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
                onChanged: (BrickType? newValue) {
                  setState(() {
                    _selectedBrickType = newValue;
                    _isCustomBrickSelected = (newValue?.name == 'Personalizado');
                    if (!_isCustomBrickSelected) {
                      // Se não for personalizado, preenche os controladores
                      _brickSizeLengthController.text = newValue!.length.toString();
                      _brickSizeHeightController.text = newValue.height.toString();
                    } else {
                      // Se for personalizado, limpa os campos para nova entrada
                      _brickSizeLengthController.clear();
                      _brickSizeHeightController.clear();
                    }
                  });
                },
                items: _predefinedBrickTypes.map((BrickType type) {
                  return DropdownMenuItem<BrickType>(
                    value: type,
                    child: Text(type.name),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null) {
                    return 'Por favor, selecione um tipo de tijolo/bloco.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // --- Campos de entrada manual (visibilidade controlada) ---
              if (_isCustomBrickSelected) ...[
                _buildTextFormField(
                  controller: _brickSizeLengthController,
                  labelText: 'Comprimento do Tijolo/Bloco',
                  hintText: 'Ex: 19 (tijolo comum)',
                  unitText: 'cm', // Unidade de medida
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o comprimento do tijolo/bloco.';
                    }
                    if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                      return 'O comprimento do tijolo/bloco deve ser maior que 0.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _brickSizeHeightController,
                  labelText: 'Altura do Tijolo/Bloco',
                  hintText: 'Ex: 9 (tijolo comum)',
                  unitText: 'cm', // Unidade de medida
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira a altura do tijolo/bloco.';
                    }
                    if (double.tryParse(value.replaceAll(',', '.'))! <= 0) {
                      return 'A altura do tijolo/bloco deve ser maior que 0.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              // --- Fim dos campos de entrada manual ---

              _buildTextFormField(
                controller: _mortarJointThicknessController,
                labelText: 'Espessura da Junta de Argamassa',
                hintText: 'Ex: 1.5',
                unitText: 'cm', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a espessura da junta.';
                  }
                  if (double.tryParse(value.replaceAll(',', '.'))! < 0) {
                    return 'A espessura não pode ser negativa.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Seção de Preços Unitários
              const Text(
                'Preços Unitários dos Materiais (Opcional para Custo)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _brickUnitPriceController,
                labelText: 'Preço por Tijolo/Bloco',
                hintText: 'Ex: 0.80',
                unitText: 'R\$', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    _brickUnitPriceController.text = '0.0'; // Define 0 se vazio
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
                controller: _cementUnitPriceController,
                labelText: 'Preço por Saco de Cimento (50kg)',
                hintText: 'Ex: 35.00',
                unitText: 'R\$', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    _cementUnitPriceController.text = '0.0';
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
                controller: _limeUnitPriceController,
                labelText: 'Preço por Saco de Cal (20kg)',
                hintText: 'Ex: 15.00',
                unitText: 'R\$', // Unidade de medida
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    _limeUnitPriceController.text = '0.0';
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
                    _sandUnitPriceController.text = '0.0';
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
                onPressed: _isLoading ? null : _calculateMasonry, // Desabilita o botão durante o carregamento
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
                        'Calcular Alvenaria e Custos',
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
                            _buildResultRow('Área da Parede:', '${_result!["wallArea"]} m²'),
                            _buildResultRow('Tijolos/Blocos por m²:', '${_result!["bricksPerM2"]} unidades'),
                            _buildResultRow('Total de Tijolos/Blocos Necessários:', '${_result!["totalBricks"]} unidades'),
                            _buildResultRow('Volume de Massa Estimado:', '${_result!["mortarVolume"]} m³'),
                            _buildResultRow('Sacos de Cimento (50kg):', '${_result!["totalCementBags"]} unidades'),
                            _buildResultRow('Sacos de Cal (20kg):', '${_result!["totalLimeBags"]} unidades'),
                            _buildResultRow('Areia:', '${_result!["totalSandM3"]} m³'),
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
                            _buildResultRow('Custo dos Tijolos/Blocos:', 'R\$ ${_result!["totalBrickCost"]}'),
                            _buildResultRow('Custo do Cimento:', 'R\$ ${_result!["totalCementCost"]}'),
                            _buildResultRow('Custo da Cal:', 'R\$ ${_result!["totalLimeCost"]}'),
                            _buildResultRow('Custo da Areia:', 'R\$ ${_result!["totalSandCost"]}'),
                            const Divider(height: 20, thickness: 1, color: Colors.grey),
                            _buildResultRow('Custo Total Estimado:', 'R\$ ${_result!["grandTotalCost"]}', isTotal: true),
                            const SizedBox(height: 10),
                            const Text(
                              '*Este cálculo é uma estimativa baseada em traços comuns. Consulte um profissional para validação e ajuste de proporções.',
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

