import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../services/ai_schedule_service.dart';
import '../models/task_model.dart';
import 'task_input_screen.dart';
import 'recommendation_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    final aiService = Provider.of<AiScheduleService>(context);

    final sortedTasks = List<TaskModel>.from(scheduleProvider.tasks);
    sortedTasks.sort((a, b) {
      if (a.startTime.hour != b.startTime.hour) {
        return a.startTime.hour.compareTo(b.startTime.hour);
      }
      return a.startTime.minute.compareTo(b.startTime.minute);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Resolver'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: sortedTasks.isEmpty
                ? null
                : () => aiService.analyzeSchedule(sortedTasks),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (aiService.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: LinearProgressIndicator(),
              ),
            if (aiService.currentAnalysis != null)
              Card(
                color: Colors.green.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Recommendation Ready!!',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RecommendationScreen()),
                        ),
                        child: const Text('View Recommendation'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16.0),
            Expanded(
              child: sortedTasks.isEmpty
                  ? const Center(child: Text('No tasks added yet.'))
                  : ListView.builder(
                      itemCount: sortedTasks.length,
                      itemBuilder: (context, index) {
                        final task = sortedTasks[index];
                        return Card(
                          child: ListTile(
                            title: Text(task.title),
                            subtitle: Text(
                                '${task.category} | ${task.startTime.hour}:${task.startTime.minute}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  scheduleProvider.removeTask(task.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (sortedTasks.isNotEmpty)
              ElevatedButton(onPressed: aiService.isLoading ? null : () => aiService.analyzeSchedule(scheduleProvider.tasks),
              child: aiService.isLoading ? const CircularProgressIndicator() : const Text('Resolve Conflicts with AI'),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TaskInputScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
