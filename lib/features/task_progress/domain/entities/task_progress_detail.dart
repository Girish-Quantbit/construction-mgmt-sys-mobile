import 'package:equatable/equatable.dart';

class TaskProgressDetail extends Equatable {
  final String? parentTask;
  final String? task;
  final double totalQty;
  final double achievedToday;
  final double plannedToday;
  final double totalAchieved;
  final double percentCompleted;
  final String? taskSubject;
  final String? image1;
  final String? image2;
  final String? image3;
  final String? image4;
  final String? image5;
  final String? image6;
  final String? image7;
  final String? image8;
  final String? image9;
  final String? image10;

  const TaskProgressDetail({
    this.parentTask,
    this.task,
    this.totalQty = 0.0,
    this.achievedToday = 0.0,
    this.plannedToday = 0.0,
    this.totalAchieved = 0.0,
    this.percentCompleted = 0.0,
    this.taskSubject,
    this.image1,
    this.image2,
    this.image3,
    this.image4,
    this.image5,
    this.image6,
    this.image7,
    this.image8,
    this.image9,
    this.image10,
  });

  @override
  List<Object?> get props => [
    parentTask,
    task,
    totalQty,
    achievedToday,
    plannedToday,
    totalAchieved,
    percentCompleted,
    taskSubject,
    image1,
    image2,
    image3,
    image4,
    image5,
    image6,
    image7,
    image8,
    image9,
    image10,
  ];

  factory TaskProgressDetail.fromJson(Map<String, dynamic> json) {
    return TaskProgressDetail(
      parentTask: json['parent_task'],
      task: json['task'],
      totalQty: (json['total_qty'] ?? 0.0).toDouble(),
      achievedToday: (json['achieved_today'] ?? 0.0).toDouble(),
      plannedToday: (json['planned_today'] ?? 0.0).toDouble(),
      totalAchieved: (json['total_achieved'] ?? 0.0).toDouble(),
      percentCompleted: (json['percent_completed'] ?? 0.0).toDouble(),
      taskSubject: json['task_subject'],
      image1: json['image_1'],
      image2: json['image_2'],
      image3: json['image_3'],
      image4: json['image_4'],
      image5: json['image_5'],
      image6: json['image_6'],
      image7: json['image_7'],
      image8: json['image_8'],
      image9: json['image_9'],
      image10: json['image_10'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parent_task': parentTask,
      'task': task,
      'total_qty': totalQty,
      'achieved_today': achievedToday,
      'planned_today': plannedToday,
      'total_achieved': totalAchieved,
      'percent_completed': percentCompleted,
      'task_subject': taskSubject,
      'image_1': image1,
      'image_2': image2,
      'image_3': image3,
      'image_4': image4,
      'image_5': image5,
      'image_6': image6,
      'image_7': image7,
      'image_8': image8,
      'image_9': image9,
      'image_10': image10,
    };
  }
}
