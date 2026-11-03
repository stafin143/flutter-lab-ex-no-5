import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Expense {
  final String title;
  final double amount;
  Expense(this.title, this.amount);
}

// State holder - notifies the UI whenever data changes
class BudgetModel extends ChangeNotifier {
  double _income = 0;
  final List<Expense> _expenses = [];

  double get income => _income;
  List<Expense> get expenses => List.unmodifiable(_expenses);
  double get totalExpenses => _expenses.fold<double>(0, (s, e) => s + e.amount);
  double get balance => _income - totalExpenses;

  String get status {
    if (_income == 0) return 'Enter your income to begin';
    if (balance > 0) return 'Surplus - You are saving money';
    if (balance == 0) return 'Break-even - No savings left';
    return 'Deficit - Expenses exceed income';
  }

  void setIncome(double value) {
    _income = value;
    notifyListeners();
  }

  void addExpense(String title, double amount) {
    _expenses.add(Expense(title, amount));
    notifyListeners();
  }

  void removeExpense(int index) {
    _expenses.removeAt(index);
    notifyListeners();
  }

  void reset() {
    _income = 0;
    _expenses.clear();
    notifyListeners();
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => BudgetModel(),
      child: const BudgetApp(),
    ),
  );
}

class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Budget Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const BudgetPage(),
    );
  }
}

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final _incomeController = TextEditingController();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _setIncome() {
    final value = double.tryParse(_incomeController.text.trim());
    if (value == null || value < 0) {
      _msg('Enter a valid income amount');
      return;
    }
    context.read<BudgetModel>().setIncome(value);
  }

  void _addExpense() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (title.isEmpty || amount == null || amount <= 0) {
      _msg('Enter a valid expense name and amount');
      return;
    }
    context.read<BudgetModel>().addExpense(title, amount);
    _titleController.clear();
    _amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final budget = context.watch<BudgetModel>();
    final bool healthy = budget.balance >= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Budget Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              budget.reset();
              _incomeController.clear();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _incomeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Monthly Income (₹)',
                      border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: _setIncome, child: const Text('Set')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                      labelText: 'Expense', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Amount', border: OutlineInputBorder()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: _addExpense,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            color: healthy ? Colors.green.shade50 : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Total Income: ₹${budget.income.toStringAsFixed(2)}'),
                  Text(
                      'Total Expenses: ₹${budget.totalExpenses.toStringAsFixed(2)}'),
                  const Divider(),
                  Text('Remaining Balance: ₹${budget.balance.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: healthy ? Colors.green : Colors.red)),
                  const SizedBox(height: 6),
                  Text(budget.status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Expenses',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ...List.generate(budget.expenses.length, (i) {
            final e = budget.expenses[i];
            return Card(
              child: ListTile(
                title: Text(e.title),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('₹${e.amount.toStringAsFixed(2)}'),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => budget.removeExpense(i),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

