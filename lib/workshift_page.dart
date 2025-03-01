import 'package:flutter/material.dart';
import 'config.dart';

class WorkshiftPage extends StatefulWidget {
  const WorkshiftPage({super.key});

  @override
  State<WorkshiftPage> createState() => _WorkshiftPageState();
}

class _WorkshiftPageState extends State<WorkshiftPage> {
  final List<Map<String, String>> shifts = [
    {'date': '02/03/2025', 'start': '08:00', 'end': '17:00'},
    {'date': '03/03/2025', 'start': '09:00', 'end': '18:00'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kerja'),
        backgroundColor: Color(AppColors.primaryColor),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: shifts.length,
        itemBuilder: (context, index) {
          return Card(
            color: Color(AppColors.backgroundColor),
            elevation: 2,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Color(AppColors.secondaryColor),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Icon(
                Icons.access_time,
                color: Color(AppColors.secondaryColor),
              ),
              title: Text(
                shifts[index]['date']!,
                style: TextStyle(
                  color: Color(AppColors.textColor),
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Mulai: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: shifts[index]['start']),
                      ],
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Selesai: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: shifts[index]['end']),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
