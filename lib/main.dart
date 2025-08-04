import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'concrete_calculation_page.dart';
import 'plaster_calculation_page.dart';
import 'flooring_calculation_page.dart';
import 'painting_calculation_page.dart';
import 'masonry_calculation_page.dart';
import 'general_construction_calculation_page.dart';
import 'labor_calculation_page.dart';
import 'approximate_total_cost_page.dart'; // NOVO: Importa a página de custo total aproximado
import 'package:calc_construtor/calculation_history_service.dart';
import 'package:calc_construtor/history_screen.dart';
import 'calculation_page_base.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Construtor Fácil',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Construtor Fácil'),
        backgroundColor: Colors.blue[600],
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Escolha um Cálculo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              _buildCalculationButton(
                context,
                'Cálculo de Alvenaria',
                Colors.green[500]!,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MasonryCalculationPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildCalculationButton(
                context,
                'Cálculo de Concreto',
                Colors.yellow[500]!,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConcreteCalculationPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildCalculationButton(
                context,
                'Cálculo de Reboco/Chapisco',
                Colors.purple[800]!,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PlasterCalculationPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildCalculationButton(
                context,
                'Cálculo de Piso/Revestimento',
                Colors.red[800]!,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FlooringCalculationPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildCalculationButton(
                context,
                'Cálculo de Pintura',
                Colors.blueGrey[800]!,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaintingCalculationPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildCalculationButton(
                context,
                'Cálculo Geral de Construção',
                Colors.indigo[700]!,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GeneralConstructionCalculationPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildCalculationButton(
                context,
                'Cálculo Detalhado de Mão de Obra',
                Colors.brown[700]!,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LaborCalculationPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              // NOVO: Botão para o Cálculo de Custo Total Aproximado da Obra
              _buildCalculationButton(
                context,
                'Custo Total Aproximado da Obra',
                Colors.teal[700]!, // Uma nova cor
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ApproximateTotalCostPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildCalculationButton(
                context,
                'Ver Histórico de Cálculos',
                Colors.blue[700]!,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistoryScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculationButton(
      BuildContext context, String text, Color color, VoidCallback? onPressed) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
              shadowColor: color.withOpacity(0.5),
            ).copyWith(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.disabled)) {
                    return color.withOpacity(0.5);
                  }
                  return color;
                },
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
