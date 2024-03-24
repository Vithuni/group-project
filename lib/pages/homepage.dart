import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'widgets/btmnavbar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2;
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _chestSizeController = TextEditingController();
  final TextEditingController _waistSizeController = TextEditingController();
  final TextEditingController _backController = TextEditingController();
  final TextEditingController _bicepsController = TextEditingController();
  final TextEditingController _legsController = TextEditingController();
  final TextEditingController _shouldersController = TextEditingController();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop(true);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue, // Example background color
          title: const Text(
            'KINETIC LYNC',
            style: TextStyle(
              fontSize: 24, // Adjust the font size as needed
              fontWeight: FontWeight.bold, // Make the title bold
              color: Colors.white, // Title text color
            ),
          ),
        ),
        bottomNavigationBar: BtmNavBar(
          currentIndex: _currentIndex,
          onItemSelected: _onItemTapped,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Your Progress',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildCharts(),
              const SizedBox(height: 20),
              const Text(
                'Enter Monthly Data',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildDataEntryForm(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _selectDate(context),
                child: const Text('Select Month'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataEntryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _weightController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
          ),
        ),
        TextFormField(
          controller: _heightController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Height (cm)',
          ),
        ),
        TextFormField(
          controller: _chestSizeController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Chest Size (cm)',
          ),
        ),
        TextFormField(
          controller: _waistSizeController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Waist Size (cm)',
          ),
        ),
        TextFormField(
          controller: _backController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Back Size (cm)',
          ),
        ),
        TextFormField(
          controller: _bicepsController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Biceps Size (cm)',
          ),
        ),
        TextFormField(
          controller: _legsController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Legs Size (cm)',
          ),
        ),
        TextFormField(
          controller: _shouldersController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Shoulders Size (cm)',
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _saveUserData,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildCharts() {
    return Column(
      children: [
        _buildChart('Weight', 'weight', ChartType.line),
        _buildChart('Height', 'height', ChartType.bar),
        _buildChart('Chest Size', 'chestSize', ChartType.pie),
        _buildChart('Waist Size', 'waistSize', ChartType.spline),
        _buildChart('Back Size', 'backSize', ChartType.line),
        _buildChart('Biceps Size', 'bicepsSize', ChartType.bar),
        _buildChart('Legs Size', 'legsSize', ChartType.pie),
        _buildChart('Shoulders Size', 'shouldersSize', ChartType.spline),
        _buildChart('BMI', 'bmi', ChartType.bmi),
      ],
    );
  }

  Widget _buildChart(String title, String field, ChartType type) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('data')
          .orderBy('month')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          List<ProgressData> data = snapshot.data!.docs
              .where((doc) =>
                  doc[field] != null) // Filter out documents without the field
              .map((doc) => ProgressData(
                    doc['month'].toString(),
                    double.parse(doc[field].toString()),
                  ))
              .toList();
          if (data.isNotEmpty) {
            return Container(
              height: 300,
              padding: const EdgeInsets.all(20),
              child: _getChart(title, type, data),
            );
          } else {
            return Text('No Data Available for $title');
          }
        } else {
          return const Text('No Data Available');
        }
      },
    );
  }

  Widget _getChart(String title, ChartType type, List<ProgressData> data) {
    switch (type) {
      case ChartType.line:
        return _getLineChart(title, data);
      case ChartType.bar:
        return _getBarChart(title, data);
      case ChartType.pie:
        return _getPieChart(title, data);
      case ChartType.spline:
        return _getSplineChart(title, data);
      case ChartType.bmi:
        return _getLineChart(title, data);
    }
  }

  Widget _getLineChart(String title, List<ProgressData> data) {
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: <CartesianSeries>[
        LineSeries<ProgressData, String>(
          dataSource: data,
          xValueMapper: (ProgressData data, _) => data.month,
          yValueMapper: (ProgressData data, _) => data.value,
          name: title,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _getBarChart(String title, List<ProgressData> data) {
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: <CartesianSeries>[
        BarSeries<ProgressData, String>(
          dataSource: data,
          xValueMapper: (ProgressData data, _) => data.month,
          yValueMapper: (ProgressData data, _) => data.value,
          name: title,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _getPieChart(String title, List<ProgressData> data) {
    return SfCircularChart(
      series: <CircularSeries>[
        PieSeries<ProgressData, String>(
          dataSource: data,
          xValueMapper: (ProgressData data, _) => data.month,
          yValueMapper: (ProgressData data, _) => data.value,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _getSplineChart(String title, List<ProgressData> data) {
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: <CartesianSeries>[
        SplineSeries<ProgressData, String>(
          dataSource: data,
          xValueMapper: (ProgressData data, _) => data.month,
          yValueMapper: (ProgressData data, _) => data.value,
          name: title,
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }

  Future<void> _saveUserData() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    String uid = auth.currentUser!.uid;

    double bmi = calculateBMI(double.parse(_weightController.text),
        double.parse(_heightController.text));

    await firestore.collection('users').doc(uid).collection('data').add({
      'month': _selectedDate.month.toString(),
      'weight': double.parse(_weightController.text),
      'height': double.parse(_heightController.text),
      'chestSize': double.parse(_chestSizeController.text),
      'waistSize': double.parse(_waistSizeController.text),
      'backSize': double.parse(_backController.text),
      'bicepsSize': double.parse(_bicepsController.text),
      'legsSize': double.parse(_legsController.text),
      'shouldersSize': double.parse(_shouldersController.text),
      'bmi': bmi,
    });

    // Clear the text fields after saving data
    _weightController.clear();
    _heightController.clear();
    _chestSizeController.clear();
    _waistSizeController.clear();
    _backController.clear();
    _bicepsController.clear();
    _legsController.clear();
    _shouldersController.clear();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  double calculateBMI(double weight, double height) {
    return weight / pow(height / 100, 2); // Convert height to meters
  }
}

class ProgressData {
  final String month;
  final double value;

  ProgressData(this.month, this.value);
}

enum ChartType {
  line,
  bar,
  pie,
  spline,
  bmi,
}
