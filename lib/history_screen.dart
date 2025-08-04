import 'package:flutter/material.dart';
import 'package:calc_construtor/calculation_history_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _calculationsFuture;

  @override
  void initState() {
    super.initState();
    _loadCalculations();
  }

  void _loadCalculations() {
    _calculationsFuture = CalculationHistoryService().loadCalculations();
  }

  void _clearHistory() async {
    await CalculationHistoryService().clearHistory();
    setState(() {
      _loadCalculations();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Histórico limpo com sucesso!')),
    );
  }

  Future<void> _generateAndSavePdf() async {
    setState(() {
      // Opcional: Mostrar um indicador de carregamento
    });

    try {
      final calculations = await _calculationsFuture;
      if (calculations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não há histórico para gerar o PDF.')),
        );
        return;
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Text(
                  'Histórico de Cálculos de Materiais',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              for (var calculation in calculations) ...[
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  margin: pw.EdgeInsets.only(bottom: 10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Tipo: ${calculation['type'] ?? 'N/A'}',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Data: ${DateTime.tryParse(calculation['timestamp'] ?? '')?.toLocal().toString().substring(0, 16).replaceAll('T', ' ') ?? 'N/A'}',
                        style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                      ),
                      pw.Divider(),
                      if (calculation['type'] == 'Concreto')
                        _buildConcreteDetailsPdf(calculation)
                      else if (calculation['type'] == 'Alvenaria')
                        _buildMasonryDetailsPdf(calculation)
                      else if (calculation['type'] == 'Reboco/Chapisco')
                        _buildPlasterDetailsPdf(calculation)
                      else if (calculation['type'] == 'Piso/Revestimento')
                        _buildFlooringDetailsPdf(calculation)
                      else if (calculation['type'] == 'Pintura')
                        _buildPaintingDetailsPdf(calculation)
                      else if (calculation['type'] == 'Construção Geral')
                        _buildGeneralConstructionDetailsPdf(calculation)
                      else if (calculation['type'] == 'Mão de Obra Detalhada')
                        _buildLaborDetailsPdf(calculation)
                      else if (calculation['type'] == 'Custo Total da Obra')
                        _buildApproximateTotalCostDetailsPdf(calculation)
                      else
                        pw.Text('Detalhes adicionais não disponíveis para este tipo de cálculo.'),
                    ],
                  ),
                ),
              ],
            ];
          },
        ),
      );

      if (kIsWeb) {
        final bytes = await pdf.save();
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'historico_calculos.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF gerado e download iniciado.')),
        );
      } else {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/historico_calculos.pdf');
        await file.writeAsBytes(await pdf.save());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF gerado e salvo em: ${file.path}')),
        );
        await OpenFile.open(file.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar PDF: ${e.toString()}')),
      );
    } finally {
      setState(() {
        // Opcional: Esconder indicador de carregamento
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Cálculos'),
        backgroundColor: Colors.blue[600],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        actions: [
          const Text(
            'Exportar histórico PDF ==>>',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 28.0),
            onPressed: _generateAndSavePdf,
            tooltip: 'Gerar PDF do Histórico',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Limpar Histórico?'),
                    content: const Text('Tem certeza que deseja apagar todo o histórico de cálculos?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          _clearHistory();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Limpar'),
                      ),
                    ],
                  );
                },
              );
            },
            tooltip: 'Limpar Histórico',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _calculationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Erro ao carregar histórico: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Nenhum cálculo salvo ainda.'));
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final calculation = snapshot.data![index];
                        final timestamp = DateTime.tryParse(calculation['timestamp'] ?? '') ?? DateTime.now();
                        final formattedDate =
                            '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
                          elevation: 4.0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tipo: ${calculation['type'] ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Data: $formattedDate',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                                const Divider(height: 16, thickness: 1),

                                if (calculation['type'] == 'Concreto')
                                  _buildConcreteDetails(calculation)
                                else if (calculation['type'] == 'Alvenaria')
                                  _buildMasonryDetails(calculation)
                                else if (calculation['type'] == 'Reboco/Chapisco')
                                  _buildPlasterDetails(calculation)
                                else if (calculation['type'] == 'Piso/Revestimento')
                                  _buildFlooringDetails(calculation)
                                else if (calculation['type'] == 'Pintura')
                                  _buildPaintingDetails(calculation)
                                else if (calculation['type'] == 'Construção Geral')
                                  _buildGeneralConstructionDetails(calculation)
                                else if (calculation['type'] == 'Mão de Obra Detalhada')
                                  _buildLaborDetails(calculation)
                                else if (calculation['type'] == 'Custo Total da Obra')
                                  _buildApproximateTotalCostDetails(calculation)
                                else
                                  const Text('Detalhes adicionais não disponíveis para este tipo de cálculo.'),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.black : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.green[700] : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConcreteDetails(Map<String, dynamic> calculation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (calculation['concreteVolume'] != null)
          _buildResultRow('Volume de Concreto:', '${calculation['concreteVolume']} m³'),
        if (calculation['totalWaterLiters'] != null)
          _buildResultRow('Água Necessária:', '${calculation['totalWaterLiters']} litros'),
        if (calculation['totalConcreteCost'] != null)
          _buildResultRow('Custo do Concreto:', 'R\$ ${calculation['totalConcreteCost']}'),
        if (calculation['totalWaterCost'] != null)
          _buildResultRow('Custo da Água:', 'R\$ ${calculation['totalWaterCost']}'),
        const SizedBox(height: 10),
        if (calculation['grandTotalCost'] != null)
          _buildResultRow('Custo Total Estimado:', 'R\$ ${calculation['grandTotalCost']}', isTotal: true),
      ],
    );
  }

  Widget _buildMasonryDetails(Map<String, dynamic> calculation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (calculation['wallArea'] != null)
          _buildResultRow('Área da Parede:', '${calculation['wallArea']} m²'),
        if (calculation['bricksPerM2'] != null)
          _buildResultRow('Tijolos/Blocos por m²:', '${calculation['bricksPerM2']} un.'),
        if (calculation['totalBricks'] != null)
          _buildResultRow('Total de Tijolos/Blocos Necessários:', '${calculation['totalBricks']} un.'),
        if (calculation['mortarVolume'] != null)
          _buildResultRow('Volume de Massa Estimado:', '${calculation['mortarVolume']} m³'),
        if (calculation['totalCementBags'] != null)
          _buildResultRow('Sacos de Cimento (50kg):', '${calculation['totalCementBags']} un.'),
        if (calculation['totalLimeBags'] != null)
          _buildResultRow('Sacos de Cal (20kg):', '${calculation['totalLimeBags']} un.'),
        if (calculation['totalSandM3'] != null)
          _buildResultRow('Areia:', '${calculation['totalSandM3']} m³'),
        const SizedBox(height: 10),
        if (calculation['totalBrickCost'] != null)
          _buildResultRow('Custo dos Tijolos/Blocos:', 'R\$ ${calculation['totalBrickCost']}'),
        if (calculation['totalCementCost'] != null)
          _buildResultRow('Custo do Cimento:', 'R\$ ${calculation['totalCementCost']}'),
        if (calculation['totalLimeCost'] != null)
          _buildResultRow('Custo da Cal:', 'R\$ ${calculation['totalLimeCost']}'),
        if (calculation['totalSandCost'] != null)
          _buildResultRow('Custo da Areia:', 'R\$ ${calculation['totalSandCost']}'),
        const SizedBox(height: 10),
        if (calculation['grandTotalCost'] != null)
          _buildResultRow('Custo Total Estimado:', 'R\$ ${calculation['grandTotalCost']}', isTotal: true),
      ],
    );
  }

  Widget _buildPlasterDetails(Map<String, dynamic> calculation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (calculation['area'] != null)
          _buildResultRow('Área Total:', '${calculation['area']} m²'),
        if (calculation['volume'] != null)
          _buildResultRow('Volume de Argamassa:', '${calculation['volume']} m³'),
        if (calculation['totalCementBags'] != null)
          _buildResultRow('Sacos de Cimento (50kg):', '${calculation['totalCementBags']} un.'),
        if (calculation['totalSandM3'] != null)
          _buildResultRow('Areia:', '${calculation['totalSandM3']} m³'),
        if (calculation['totalWaterLiters'] != null)
          _buildResultRow('Água:', '${calculation['totalWaterLiters']} litros'),
        const SizedBox(height: 10),
        if (calculation['totalCementCost'] != null)
          _buildResultRow('Custo do Cimento:', 'R\$ ${calculation['totalCementCost']}'),
        if (calculation['totalSandCost'] != null)
          _buildResultRow('Custo da Areia:', 'R\$ ${calculation['totalSandCost']}'),
        if (calculation['totalWaterCost'] != null)
          _buildResultRow('Custo da Água:', 'R\$ ${calculation['totalWaterCost']}'),
        const SizedBox(height: 10),
        if (calculation['grandTotalCost'] != null)
          _buildResultRow('Custo Total Estimado:', 'R\$ ${calculation['grandTotalCost']}', isTotal: true),
      ],
    );
  }

  Widget _buildFlooringDetails(Map<String, dynamic> calculation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (calculation['roomArea'] != null)
          _buildResultRow('Área do Cômodo:', '${calculation['roomArea']} m²'),
        if (calculation['totalTiles'] != null)
          _buildResultRow('Total de Pisos/Azulejos:', '${calculation['totalTiles']} un.'),
        if (calculation['totalMortarBags'] != null)
          _buildResultRow('Sacos de Argamassa Colante (20kg):', '${calculation['totalMortarBags']} un.'),
        if (calculation['totalGroutKg'] != null)
          _buildResultRow('Rejunte:', '${calculation['totalGroutKg']} kg'),
        const SizedBox(height: 10),
        if (calculation['totalTileCost'] != null)
          _buildResultRow('Custo dos Pisos/Azulejos:', 'R\$ ${calculation['totalTileCost']}'),
        if (calculation['totalMortarCost'] != null)
          _buildResultRow('Custo da Argamassa Colante:', 'R\$ ${calculation['totalMortarCost']}'),
        if (calculation['totalGroutCost'] != null)
          _buildResultRow('Custo do Rejunte:', 'R\$ ${calculation['totalGroutCost']}'),
        const SizedBox(height: 10),
        if (calculation['grandTotalCost'] != null)
          _buildResultRow('Custo Total Estimado:', 'R\$ ${calculation['grandTotalCost']}', isTotal: true),
      ],
    );
  }

  Widget _buildPaintingDetails(Map<String, dynamic> calculation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (calculation['paintType'] != null)
          _buildResultRow('Tipo de Tinta:', '${calculation['paintType']}'),
        if (calculation['totalWallArea'] != null)
          _buildResultRow('Área Total da Parede:', '${calculation['totalWallArea']} m²'),
        if (calculation['paintableArea'] != null)
          _buildResultRow('Área a Ser Pintada:', '${calculation['paintableArea']} m²'),
        if (calculation['totalPaintLiters'] != null)
          _buildResultRow('Total de Tinta Necessária:', '${calculation['totalPaintLiters']} litros'),
        if (calculation['coatsOfPaint'] != null)
          _buildResultRow('Número de Demãos:', '${calculation['coatsOfPaint']}'),
        if (calculation['paintYieldPerLiter'] != null)
          _buildResultRow('Rendimento por Litro:', '${calculation['paintYieldPerLiter']} m²/L'),
        const SizedBox(height: 10),
        if (calculation['totalPaintCost'] != null)
          _buildResultRow('Custo Total da Tinta:', 'R\$ ${calculation['totalPaintCost']}', isTotal: true),
      ],
    );
  }

  Widget _buildGeneralConstructionDetails(Map<String, dynamic> calculation) {
    final itemCosts = calculation['itemCosts'] as Map<String, dynamic>?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (itemCosts != null) ...[
          const Text(
            'Custos por Item:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
          const SizedBox(height: 5),
          for (var entry in itemCosts.entries)
            _buildResultRow('${entry.key}:', 'R\$ ${entry.value}'),
          const Divider(height: 16, thickness: 1),
        ],
        if (calculation['subtotalCost'] != null)
          _buildResultRow('Custo Subtotal (Itens):', 'R\$ ${calculation['subtotalCost']}'),
        if (calculation['safetyMarginPercentage'] != null && calculation['safetyMarginAmount'] != null)
          _buildResultRow('Margem de Segurança (${calculation['safetyMarginPercentage']}%):', 'R\$ ${calculation['safetyMarginAmount']}'),
        const SizedBox(height: 10),
        if (calculation['grandTotalCost'] != null)
          _buildResultRow('Custo Total Estimado:', 'R\$ ${calculation['grandTotalCost']}', isTotal: true),
      ],
    );
  }

  Widget _buildLaborDetails(Map<String, dynamic> calculation) {
    final detailedCosts = calculation['detailedCosts'] as Map<String, dynamic>?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detailedCosts != null) ...[
          const Text(
            'Custos Detalhados por Profissional:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
          const SizedBox(height: 5),
          for (var entry in detailedCosts.entries)
            _buildResultRow(
              '${entry.key} (Qtd: ${entry.value['quantity']}, Tx: R\$ ${entry.value['rate']}):',
              'R\$ ${entry.value['cost']}',
            ),
          const Divider(height: 16, thickness: 1),
        ],
        if (calculation['totalLaborCost'] != null)
          _buildResultRow('Custo Total da Mão de Obra:', 'R\$ ${calculation['totalLaborCost']}', isTotal: true),
      ],
    );
  }

  Widget _buildApproximateTotalCostDetails(Map<String, dynamic> calculation) {
    final roomDetails = calculation['roomDetails'] as List<dynamic>?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (calculation['selectedStandard'] != null)
          _buildResultRow('Padrão de Construção:', '${calculation['selectedStandard']}'),
        if (calculation['costPerM2'] != null)
          _buildResultRow('Custo por m² (Estimado):', 'R\$ ${calculation['costPerM2']}'),
        const SizedBox(height: 10),
        if (roomDetails != null) ...[
          const Text(
            'Detalhes dos Cômodos:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 5),
          for (var room in roomDetails)
            _buildResultRow('${room['name']}:', '${room['area']} m²'),
          const Divider(height: 16, thickness: 1),
        ],
        if (calculation['totalArea'] != null)
          _buildResultRow('Área Total dos Cômodos:', '${calculation['totalArea']} m²'),
        if (calculation['baseCost'] != null)
          _buildResultRow('Custo Base (Área Total x Custo/m²):', 'R\$ ${calculation['baseCost']}'),
        if (calculation['safetyMarginPercentage'] != null && calculation['safetyMarginAmount'] != null)
          _buildResultRow('Margem de Segurança (${calculation['safetyMarginPercentage']}%):', 'R\$ ${calculation['safetyMarginAmount']}'),
        const SizedBox(height: 10),
        if (calculation['grandTotalCost'] != null)
          _buildResultRow('Custo Total Aproximado:', 'R\$ ${calculation['grandTotalCost']}', isTotal: true),
      ],
    );
  }

  // Helper para exibir linhas de resultado no PDF
  pw.Widget _buildResultRowPdf(String label, String value, {bool isTotal = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2.0),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 11 : 10,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isTotal ? PdfColors.black : PdfColors.grey700,
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: isTotal ? 11 : 10,
                fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: isTotal ? PdfColors.green700 : PdfColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Funções para construir detalhes específicos por tipo de cálculo no PDF
  pw.Widget _buildConcreteDetailsPdf(Map<String, dynamic> calculation) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (calculation['concreteVolume'] != null)
          _buildResultRowPdf('Volume de Concreto:', '${calculation['concreteVolume']} m³'),
        if (calculation['totalWaterLiters'] != null)
          _buildResultRowPdf('Água Necessária:', '${calculation['totalWaterLiters']} litros'),
        if (calculation['totalConcreteCost'] != null)
          _buildResultRowPdf('Custo do Concreto:', 'R\$ ${calculation['totalConcreteCost']}'),
        if (calculation['totalWaterCost'] != null)
          _buildResultRowPdf('Custo da Água:', 'R\$ ${calculation['totalWaterCost']}'),
        pw.SizedBox(height: 5),
        if (calculation['grandTotalCost'] != null)
          _buildResultRowPdf('Custo Total Estimado:', 'R\$ ${calculation['grandTotalCost']}', isTotal: true),
      ],
    );
  }

  pw.Widget _buildMasonryDetailsPdf(Map<String, dynamic> calculation) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (calculation['wallArea'] != null)
          _buildResultRowPdf('Área da Parede:', '${calculation['wallArea']} m²'),
        if (calculation['bricksPerM2'] != null)
          _buildResultRowPdf('Tijolos/Blocos por m²:', '${calculation['bricksPerM2']} un.'),
        if (calculation['totalBricks'] != null)
          _buildResultRowPdf('Total de Tijolos/Blocos Necessários:', '${calculation['totalBricks']} un.'),
        if (calculation['mortarVolume'] != null)
          _buildResultRowPdf('Volume de Massa Estimado:', '${calculation['mortarVolume']} m³'),
        if (calculation['totalCementBags'] != null)
          _buildResultRowPdf('Sacos de Cimento (50kg):', '${calculation['totalCementBags']} un.'),
        if (calculation['totalLimeBags'] != null)
          _buildResultRowPdf('Sacos de Cal (20kg):', '${calculation['totalLimeBags']} un.'),
        if (calculation['totalSandM3'] != null)
          _buildResultRowPdf('Areia:', '${calculation['totalSandM3']} m³'),
        pw.SizedBox(height: 5),
        if (calculation['totalBrickCost'] != null)
          _buildResultRowPdf('Custo dos Tijolos/Blocos:', 'R\$ ${calculation['totalBrickCost']}'),
        if (calculation['totalCementCost'] != null)
          _buildResultRowPdf('Custo do Cimento:', 'R\$ ${calculation['totalCementCost']}'),
        if (calculation['totalLimeCost'] != null)
          _buildResultRowPdf('Custo da Cal:', 'R\$ ${calculation['totalLimeCost']}'),
        if (calculation['totalSandCost'] != null)
          _buildResultRowPdf('Custo da Areia:', 'R\$ ${calculation['totalSandCost']}'),
        pw.SizedBox(height: 5),
        if (calculation['grandTotalCost'] != null)
          _buildResultRowPdf('Custo Total Estimado:', 'R\$ ${calculation['grandTotalCost']}', isTotal: true),
      ],
    );
  }

  pw.Widget _buildPlasterDetailsPdf(Map<String, dynamic> calculation) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (calculation['area'] != null)
          _buildResultRowPdf('Área Total:', '${calculation['area']} m²'),
        if (calculation['volume'] != null)
          _buildResultRowPdf('Volume de Argamassa:', '${calculation['volume']} m³'),
        if (calculation['totalCementBags'] != null)
          _buildResultRowPdf('Sacos de Cimento (50kg):', '${calculation['totalCementBags']} un.'),
        if (calculation['totalSandM3'] != null)
          _buildResultRowPdf('Areia:', '${calculation['totalSandM3']} m³'),
        if (calculation['totalWaterLiters'] != null)
          _buildResultRowPdf('Água:', '${calculation['totalWaterLiters']} litros'),
        pw.SizedBox(height: 5),
        if (calculation['totalCementCost'] != null)
          _buildResultRowPdf('Custo do Cimento:', 'R\$ ${calculation['totalCementCost']}'),
        if (calculation['totalSandCost'] != null)
          _buildResultRowPdf('Custo da Areia:', 'R\$ ${calculation['totalSandCost']}'),
        if (calculation['totalWaterCost'] != null)
          _buildResultRowPdf('Custo da Água:', 'R\$ ${calculation['totalWaterCost']}'),
        pw.SizedBox(height: 5),
        if (calculation['grandTotalCost'] != null)
          _buildResultRowPdf('Custo Total Estimado:', 'R\$ ${calculation['grandTotalCost']}', isTotal: true),
      ],
    );
  }

  pw.Widget _buildFlooringDetailsPdf(Map<String, dynamic> calculation) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (calculation['roomArea'] != null)
          _buildResultRowPdf('Área do Cômodo:', '${calculation['roomArea']} m²'),
        if (calculation['totalTiles'] != null)
          _buildResultRowPdf('Total de Pisos/Azulejos:', '${calculation['totalTiles']} un.'),
        if (calculation['totalMortarBags'] != null)
          _buildResultRowPdf('Sacos de Argamassa Colante (20kg):', '${calculation['totalMortarBags']} un.'),
        if (calculation['totalGroutKg'] != null)
          _buildResultRowPdf('Rejunte:', '${calculation['totalGroutKg']} kg'),
        pw.SizedBox(height: 5),
        if (calculation['totalTileCost'] != null)
          _buildResultRowPdf('Custo dos Pisos/Azulejos:', 'R\$ ${calculation['totalTileCost']}'),
        if (calculation['totalMortarCost'] != null)
          _buildResultRowPdf('Custo da Argamassa Colante:', 'R\$ ${calculation['totalMortarCost']}'),
        if (calculation['totalGroutCost'] != null)
          _buildResultRowPdf('Custo do Rejunte:', 'R\$ ${calculation['totalGroutCost']}'),
        pw.SizedBox(height: 5),
        if (calculation['grandTotalCost'] != null)
          _buildResultRowPdf('Custo Total Estimado:', 'R\$ ${calculation['grandTotalCost']}', isTotal: true),
      ],
    );
  }

  pw.Widget _buildPaintingDetailsPdf(Map<String, dynamic> calculation) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (calculation['paintType'] != null)
          _buildResultRowPdf('Tipo de Tinta:', '${calculation['paintType']}'),
        if (calculation['totalWallArea'] != null)
          _buildResultRowPdf('Área Total da Parede:', '${calculation['totalWallArea']} m²'),
        if (calculation['paintableArea'] != null)
          _buildResultRowPdf('Área a Ser Pintada:', '${calculation['paintableArea']} m²'),
        if (calculation['totalPaintLiters'] != null)
          _buildResultRowPdf('Total de Tinta Necessária:', '${calculation['totalPaintLiters']} litros'),
        if (calculation['coatsOfPaint'] != null)
          _buildResultRowPdf('Número de Demãos:', '${calculation['coatsOfPaint']}'),
        if (calculation['paintYieldPerLiter'] != null)
          _buildResultRowPdf('Rendimento por Litro:', '${calculation['paintYieldPerLiter']} m²/L'),
        pw.SizedBox(height: 5),
        if (calculation['totalPaintCost'] != null)
          _buildResultRowPdf('Custo Total da Tinta:', 'R\$ ${calculation['totalPaintCost']}', isTotal: true),
      ],
    );
  }

  pw.Widget _buildGeneralConstructionDetailsPdf(Map<String, dynamic> calculation) {
    final itemCosts = calculation['itemCosts'] as Map<String, dynamic>?;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (itemCosts != null) ...[
          pw.Text(
            'Custos por Item:',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey),
          ),
          pw.SizedBox(height: 5),
          for (var entry in itemCosts.entries)
            _buildResultRowPdf('${entry.key}:', 'R\$ ${entry.value}'),
          pw.Divider(height: 10, thickness: 0.5),
        ],
        if (calculation['subtotalCost'] != null)
          _buildResultRowPdf('Custo Subtotal (Itens):', 'R\$ ${calculation['subtotalCost']}'),
        if (calculation['safetyMarginPercentage'] != null && calculation['safetyMarginAmount'] != null)
          _buildResultRowPdf('Margem de Segurança (${calculation['safetyMarginPercentage']}%):', 'R\$ ${calculation['safetyMarginAmount']}'),
        pw.SizedBox(height: 5),
        if (calculation['grandTotalCost'] != null)
          _buildResultRowPdf('Custo Total Estimado:', 'R\$ ${calculation['grandTotalCost']}', isTotal: true),
      ],
    );
  }

  pw.Widget _buildLaborDetailsPdf(Map<String, dynamic> calculation) {
    final detailedCosts = calculation['detailedCosts'] as Map<String, dynamic>?;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (detailedCosts != null) ...[
          pw.Text(
            'Custos Detalhados por Profissional:',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey),
          ),
          pw.SizedBox(height: 5),
          for (var entry in detailedCosts.entries)
            _buildResultRowPdf(
              '${entry.key} (Qtd: ${entry.value['quantity']}, Tx: R\$ ${entry.value['rate']}):',
              'R\$ ${entry.value['cost']}',
            ),
          pw.Divider(height: 10, thickness: 0.5),
        ],
        if (calculation['totalLaborCost'] != null)
          _buildResultRowPdf('Custo Total da Mão de Obra:', 'R\$ ${calculation['totalLaborCost']}', isTotal: true),
      ],
    );
  }

  pw.Widget _buildApproximateTotalCostDetailsPdf(Map<String, dynamic> calculation) {
    final roomDetails = calculation['roomDetails'] as List<dynamic>?;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (calculation['selectedStandard'] != null)
          _buildResultRowPdf('Padrão de Construção:', '${calculation['selectedStandard']}'),
        if (calculation['costPerM2'] != null)
          _buildResultRowPdf('Custo por m² (Estimado):', 'R\$ ${calculation['costPerM2']}'),
        pw.SizedBox(height: 5),
        if (roomDetails != null) ...[
          pw.Text(
            'Detalhes dos Cômodos:',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black), // CORRIGIDO: Usando PdfColors.black
          ),
          pw.SizedBox(height: 2),
          for (var room in roomDetails)
            _buildResultRowPdf('${room['name']}:', '${room['area']} m²'),
          pw.Divider(height: 5, thickness: 0.2),
        ],
        if (calculation['totalArea'] != null)
          _buildResultRowPdf('Área Total dos Cômodos:', '${calculation['totalArea']} m²'),
        if (calculation['baseCost'] != null)
          _buildResultRowPdf('Custo Base (Área Total x Custo/m²):', 'R\$ ${calculation['baseCost']}'),
        if (calculation['safetyMarginPercentage'] != null && calculation['safetyMarginAmount'] != null)
          _buildResultRowPdf('Margem de Segurança (${calculation['safetyMarginPercentage']}%):', 'R\$ ${calculation['safetyMarginAmount']}'),
        pw.SizedBox(height: 5),
        if (calculation['grandTotalCost'] != null)
          _buildResultRowPdf('Custo Total Aproximado:', 'R\$ ${calculation['grandTotalCost']}', isTotal: true),
      ],
    );
  }
}

