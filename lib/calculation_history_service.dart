import 'dart:convert'; // Para usar jsonEncode e jsonDecode
import 'package:shared_preferences/shared_preferences.dart';

class CalculationHistoryService {
  static const String _historyKey = 'calculation_history'; // Chave para armazenar no SharedPreferences

  // Salva um novo cálculo no histórico
  // Recebe um mapa com os detalhes do cálculo e o tipo de cálculo (ex: 'Alvenaria')
  Future<void> saveCalculation(Map<String, dynamic> calculationData, String calculationType) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> historyList = prefs.getStringList(_historyKey) ?? [];

    // Adiciona o tipo de cálculo ao mapa de dados
    calculationData['type'] = calculationType;
    // Adiciona um timestamp para ordenação e exibição
    calculationData['timestamp'] = DateTime.now().toIso8601String();

    // Converte o mapa de dados para uma string JSON
    String jsonString = jsonEncode(calculationData);

    historyList.add(jsonString); // Adiciona a string JSON à lista
    await prefs.setStringList(_historyKey, historyList); // Salva a lista atualizada
  }

  // Carrega todos os cálculos do histórico
  Future<List<Map<String, dynamic>>> loadCalculations() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> historyList = prefs.getStringList(_historyKey) ?? [];

    // Converte cada string JSON de volta para um mapa e os ordena por timestamp (mais recente primeiro)
    return historyList.map((jsonString) => jsonDecode(jsonString) as Map<String, dynamic>)
        .toList()
        .reversed // Inverte para mostrar os mais recentes primeiro
        .toList();
  }

  // Limpa todo o histórico de cálculos
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey); // Remove a chave do histórico
  }
}
