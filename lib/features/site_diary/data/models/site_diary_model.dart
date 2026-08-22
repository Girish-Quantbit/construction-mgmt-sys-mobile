import '../../domain/entities/site_diary.dart';
import '../../domain/entities/site_diary_child_entities.dart';

class SiteDiaryModel extends SiteDiary {
  const SiteDiaryModel({
    required super.name,
    super.siteDate,
    super.project,
    super.generalRemarks,
    super.weatherAm,
    super.weatherPm,
    required super.status,
    super.tasks = const [],
    super.activityProgress = const [],
    super.manpowerLogs = const [],
    super.equipmentLogs = const [],
    super.materialsReceived = const [],
    super.materialsDelivered = const [],
    super.visitors = const [],
    super.rawData = const {},
  });

  factory SiteDiaryModel.fromJson(Map<String, dynamic> json) {
    return SiteDiaryModel(
      name: json['name'] ?? '',
      siteDate: json['site_date'] != null ? DateTime.tryParse(json['site_date']) : null,
      project: json['project'],
      generalRemarks: json['general_remarks'],
      weatherAm: json['weather_am'],
      weatherPm: json['weather_pm'],
      status: json['status'] ?? '',
      tasks: (json['task'] as List? ?? [])
          .map((e) => SiteDiaryTaskModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      activityProgress: (json['activity_progress'] as List? ?? [])
          .map((e) => SiteDiaryActivityProgressModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      manpowerLogs: (json['manpower_log'] as List? ?? [])
          .map((e) => SiteDiaryManpowerLogModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      equipmentLogs: (json['equipment_log'] as List? ?? [])
          .map((e) => SiteDiaryEquipmentLogModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      materialsReceived: (json['material_received'] as List? ?? [])
          .map((e) => SiteDiaryMaterialReceivedModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      materialsDelivered: (json['material_deliveries'] as List? ?? [])
          .map((e) => SiteDiaryMaterialDeliveryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      visitors: (json['visitors'] as List? ?? [])
          .map((e) => SiteDiaryVisitorModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'site_date': siteDate?.toIso8601String(),
      'project': project,
      'general_remarks': generalRemarks,
      'weather_am': weatherAm,
      'weather_pm': weatherPm,
      'status': status,
      'task': tasks.map((e) => (e as SiteDiaryTaskModel).toJson()).toList(),
      'activity_progress': activityProgress.map((e) => (e as SiteDiaryActivityProgressModel).toJson()).toList(),
      'manpower_log': manpowerLogs.map((e) => (e as SiteDiaryManpowerLogModel).toJson()).toList(),
      'equipment_log': equipmentLogs.map((e) => (e as SiteDiaryEquipmentLogModel).toJson()).toList(),
      'material_received': materialsReceived.map((e) => (e as SiteDiaryMaterialReceivedModel).toJson()).toList(),
      'material_deliveries': materialsDelivered.map((e) => (e as SiteDiaryMaterialDeliveryModel).toJson()).toList(),
      'visitors': visitors.map((e) => (e as SiteDiaryVisitorModel).toJson()).toList(),
    };
  }
}

class SiteDiaryTaskModel extends SiteDiaryTask {
  const SiteDiaryTaskModel({required super.task, super.taskSubject});

  factory SiteDiaryTaskModel.fromJson(Map<String, dynamic> json) {
    return SiteDiaryTaskModel(
      task: json['task'] ?? '',
      taskSubject: json['task_subject'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task': task,
      'task_subject': taskSubject,
    };
  }
}

class SiteDiaryActivityProgressModel extends SiteDiaryActivityProgress {
  const SiteDiaryActivityProgressModel({
    super.parentTask,
    super.parentTaskSubject,
    super.task,
    super.taskSubject,
    super.achievedToday = 0.0,
    super.totalQty = 0.0,
    super.plannedToday = 0.0,
    super.constructionType,
    super.totalAchieved = 0.0,
    super.percentCompleted = 0.0,
    super.uom,
  });

  factory SiteDiaryActivityProgressModel.fromJson(Map<String, dynamic> json) {
    return SiteDiaryActivityProgressModel(
      parentTask: json['parent_task'],
      parentTaskSubject: json['parent_task_subject'],
      task: json['task'],
      taskSubject: json['task_subject'],
      achievedToday: (json['achieved_today'] ?? 0).toDouble(),
      totalQty: (json['total_qty'] ?? 0).toDouble(),
      plannedToday: (json['planned_today'] ?? 0).toDouble(),
      constructionType: json['construction_type'],
      totalAchieved: (json['total_achieved'] ?? 0).toDouble(),
      percentCompleted: (json['percent_completed'] ?? 0).toDouble(),
      uom: json['uom'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parent_task': parentTask,
      'parent_task_subject': parentTaskSubject,
      'task': task,
      'task_subject': taskSubject,
      'achieved_today': achievedToday,
      'total_qty': totalQty,
      'planned_today': plannedToday,
      'construction_type': constructionType,
      'total_achieved': totalAchieved,
      'percent_completed': percentCompleted,
      'uom': uom,
    };
  }
}

class SiteDiaryManpowerLogModel extends SiteDiaryManpowerLog {
  const SiteDiaryManpowerLogModel({
    super.parentTask,
    super.parentTaskSubject,
    super.task,
    super.taskSubject,
    super.tradeCategory,
    super.itemType,
    super.subcontractor,
    super.contractor,
    super.workArea,
    super.gangNo,
    super.overtimeHours = 0.0,
    super.hoursWorked = 0.0,
    super.activity,
    super.skilled = 0.0,
    super.unskilled = 0.0,
    super.dailyWages = 0.0,
    super.total = 0.0,
    super.totalWage = 0.0,
  });

  factory SiteDiaryManpowerLogModel.fromJson(Map<String, dynamic> json) {
    return SiteDiaryManpowerLogModel(
      parentTask: json['parent_task'],
      parentTaskSubject: json['parent_task_subject'],
      task: json['task'],
      taskSubject: json['task_subject'],
      tradeCategory: json['trade_category'] ?? json['tradecategory'],
      itemType: json['item_type'],
      subcontractor: json['subcontractor'],
      contractor: json['contractor'] ?? json['contratcor'],
      workArea: json['work_area'],
      gangNo: json['gang_no'],
      overtimeHours: (json['overtime_hours'] ?? 0).toDouble(),
      hoursWorked: (json['hours_worked'] ?? 0).toDouble(),
      activity: json['activity'],
      skilled: (json['skilled'] ?? 0).toDouble(),
      unskilled: (json['unskilled'] ?? 0).toDouble(),
      dailyWages: (json['daily_wages'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      totalWage: (json['total_wage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parent_task': parentTask,
      'parent_task_subject': parentTaskSubject,
      'task': task,
      'task_subject': taskSubject,
      'trade_category': tradeCategory,
      'item_type': itemType,
      'subcontractor': subcontractor,
      'contractor': contractor,
      'work_area': workArea,
      'gang_no': gangNo,
      'overtime_hours': overtimeHours,
      'hours_worked': hoursWorked,
      'activity': activity,
      'skilled': skilled,
      'unskilled': unskilled,
      'daily_wages': dailyWages,
      'total': total,
      'total_wage': totalWage,
    };
  }
}

class SiteDiaryEquipmentLogModel extends SiteDiaryEquipmentLog {
  const SiteDiaryEquipmentLogModel({
    super.parentTask,
    super.parentTaskSubject,
    super.task,
    super.taskSubject,
    super.item,
    super.equipmentName,
    super.itemType,
    super.ownerType,
    super.hireSupplier,
    super.quantity = 0.0,
    super.rate = 0.0,
    super.workingHours = 0.0,
    super.contractor,
    super.remarks,
    super.totalAmount = 0.0,
  });

  factory SiteDiaryEquipmentLogModel.fromJson(Map<String, dynamic> json) {
    return SiteDiaryEquipmentLogModel(
      parentTask: json['parent_task'],
      parentTaskSubject: json['parent_task_subject'],
      task: json['task'],
      taskSubject: json['task_subject'],
      item: json['item'],
      equipmentName: json['equipment_name'],
      itemType: json['item_type'],
      ownerType: json['owner_type'],
      hireSupplier: json['hire_supplier'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      rate: (json['rate'] ?? 0).toDouble(),
      workingHours: (json['working_hours'] ?? 0).toDouble(),
      contractor: json['contractor'],
      remarks: json['remarks'],
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parent_task': parentTask,
      'parent_task_subject': parentTaskSubject,
      'task': task,
      'task_subject': taskSubject,
      'item': item,
      'equipment_name': equipmentName,
      'item_type': itemType,
      'owner_type': ownerType,
      'hire_supplier': hireSupplier,
      'quantity': quantity,
      'rate': rate,
      'working_hours': workingHours,
      'contractor': contractor,
      'remarks': remarks,
      'total_amount': totalAmount,
    };
  }
}

class SiteDiaryMaterialReceivedModel extends SiteDiaryMaterialReceived {
  const SiteDiaryMaterialReceivedModel({
    super.itemCode,
    super.quantity = 0.0,
    super.rate = 0.0,
    super.amount = 0.0,
    super.warehouse,
    super.uom,
    super.transaction,
    super.transactionType,
  });

  factory SiteDiaryMaterialReceivedModel.fromJson(Map<String, dynamic> json) {
    return SiteDiaryMaterialReceivedModel(
      itemCode: json['item_code'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      rate: (json['rate'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
      warehouse: json['warehouse'],
      uom: json['uom'],
      transaction: json['transaction'],
      transactionType: json['transaction_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_code': itemCode,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
      'warehouse': warehouse,
      'uom': uom,
      'transaction': transaction,
      'transaction_type': transactionType,
    };
  }
}

class SiteDiaryMaterialDeliveryModel extends SiteDiaryMaterialDelivery {
  const SiteDiaryMaterialDeliveryModel({
    super.parentTask,
    super.parentTaskSubject,
    super.task,
    super.taskSubject,
    super.item,
    super.itemType,
    super.unit,
    super.description,
    super.quantity = 0.0,
    super.supplier,
    super.deliveryNote,
    super.inspectionRequired = false,
    super.inspectionDone = false,
    super.accepted = false,
    super.rejectionReason,
    super.linkedPo,
    super.warehouse,
  });

  factory SiteDiaryMaterialDeliveryModel.fromJson(Map<String, dynamic> json) {
    return SiteDiaryMaterialDeliveryModel(
      parentTask: json['parent_task'],
      parentTaskSubject: json['parent_task_subject'],
      task: json['task'],
      taskSubject: json['task_subject'],
      item: json['item'],
      itemType: json['item_type'],
      unit: json['unit'],
      description: json['description'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      supplier: json['supplier'],
      deliveryNote: json['delivery_note'],
      inspectionRequired: json['inspection_required'] == 1 || json['inspection_required'] == true,
      inspectionDone: json['inspection_done'] == 1 || json['inspection_done'] == true,
      accepted: json['accepted'] == 1 || json['accepted'] == true,
      rejectionReason: json['rejection_reason'],
      linkedPo: json['linked_po'],
      warehouse: json['warehouse'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parent_task': parentTask,
      'parent_task_subject': parentTaskSubject,
      'task': task,
      'task_subject': taskSubject,
      'item': item,
      'item_type': itemType,
      'unit': unit,
      'description': description,
      'quantity': quantity,
      'supplier': supplier,
      'delivery_note': deliveryNote,
      'inspection_required': inspectionRequired ? 1 : 0,
      'inspection_done': inspectionDone ? 1 : 0,
      'accepted': accepted ? 1 : 0,
      'rejection_reason': rejectionReason,
      'linked_po': linkedPo,
      'warehouse': warehouse,
    };
  }
}

class SiteDiaryVisitorModel extends SiteDiaryVisitor {
  const SiteDiaryVisitorModel({
    super.visitorName,
    super.company,
    super.purpose,
    super.timeIn,
    super.timeOut,
    super.accompaniedBy,
    super.safetyInducted = false,
    super.notes,
  });

  factory SiteDiaryVisitorModel.fromJson(Map<String, dynamic> json) {
    return SiteDiaryVisitorModel(
      visitorName: json['visitor_name'],
      company: json['company'],
      purpose: json['purpose'],
      timeIn: json['in_time'] ?? json['time_in'],
      timeOut: json['out_time'] ?? json['time_out'],
      accompaniedBy: json['accompanied_by'],
      safetyInducted: json['safety_inducted'] == 1 || json['safety_inducted'] == true,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visitor_name': visitorName,
      'company': company,
      'purpose': purpose,
      'in_time': timeIn,
      'out_time': timeOut,
      'accompanied_by': accompaniedBy,
      'safety_inducted': safetyInducted ? 1 : 0,
      'notes': notes,
    };
  }
}
