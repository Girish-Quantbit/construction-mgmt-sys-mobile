import 'package:equatable/equatable.dart';

class SiteDiaryTask extends Equatable {
  final String task;
  final String? taskSubject;

  const SiteDiaryTask({required this.task, this.taskSubject});

  @override
  List<Object?> get props => [task, taskSubject];
}

class SiteDiaryActivityProgress extends Equatable {
  final String? parentTask;
  final String? parentTaskSubject;
  final String? task;
  final String? taskSubject;
  final double achievedToday;
  final double totalQty;
  final double plannedToday;
  final String? constructionType;
  final double totalAchieved;
  final double percentCompleted;
  final String? uom;

  const SiteDiaryActivityProgress({
    this.parentTask,
    this.parentTaskSubject,
    this.task,
    this.taskSubject,
    this.achievedToday = 0.0,
    this.totalQty = 0.0,
    this.plannedToday = 0.0,
    this.constructionType,
    this.totalAchieved = 0.0,
    this.percentCompleted = 0.0,
    this.uom,
  });

  @override
  List<Object?> get props => [
    parentTask,
    parentTaskSubject,
    task,
    taskSubject,
    achievedToday,
    totalQty,
    plannedToday,
    constructionType,
    totalAchieved,
    percentCompleted,
    uom,
  ];
}

class SiteDiaryManpowerLog extends Equatable {
  final String? parentTask;
  final String? parentTaskSubject;
  final String? task;
  final String? taskSubject;
  final String? tradeCategory;
  final String? itemType;
  final String? subcontractor;
  final String? contractor;
  final String? workArea;
  final String? gangNo;
  final double overtimeHours;
  final double hoursWorked;
  final String? activity;
  final double skilled;
  final double unskilled;
  final double dailyWages;
  final double total;
  final double totalWage;

  const SiteDiaryManpowerLog({
    this.parentTask,
    this.parentTaskSubject,
    this.task,
    this.taskSubject,
    this.tradeCategory,
    this.itemType,
    this.subcontractor,
    this.contractor,
    this.workArea,
    this.gangNo,
    this.overtimeHours = 0.0,
    this.hoursWorked = 0.0,
    this.activity,
    this.skilled = 0.0,
    this.unskilled = 0.0,
    this.dailyWages = 0.0,
    this.total = 0.0,
    this.totalWage = 0.0,
  });

  @override
  List<Object?> get props => [
    parentTask,
    parentTaskSubject,
    task,
    taskSubject,
    tradeCategory,
    itemType,
    subcontractor,
    contractor,
    workArea,
    gangNo,
    overtimeHours,
    hoursWorked,
    activity,
    skilled,
    unskilled,
    dailyWages,
    total,
    totalWage,
  ];
}

class SiteDiaryEquipmentLog extends Equatable {
  final String? parentTask;
  final String? parentTaskSubject;
  final String? task;
  final String? taskSubject;
  final String? item;
  final String? equipmentName;
  final String? itemType;
  final String? ownerType;
  final String? hireSupplier;
  final double quantity;
  final double rate;
  final double workingHours;
  final String? contractor;
  final String? remarks;
  final double totalAmount;

  const SiteDiaryEquipmentLog({
    this.parentTask,
    this.parentTaskSubject,
    this.task,
    this.taskSubject,
    this.item,
    this.equipmentName,
    this.itemType,
    this.ownerType,
    this.hireSupplier,
    this.quantity = 0.0,
    this.rate = 0.0,
    this.workingHours = 0.0,
    this.contractor,
    this.remarks,
    this.totalAmount = 0.0,
  });

  @override
  List<Object?> get props => [
    parentTask,
    parentTaskSubject,
    task,
    taskSubject,
    item,
    equipmentName,
    itemType,
    ownerType,
    hireSupplier,
    quantity,
    rate,
    workingHours,
    contractor,
    remarks,
    totalAmount,
  ];
}

class SiteDiaryMaterialReceived extends Equatable {
  final String? itemCode;
  final double quantity;
  final double rate;
  final double amount;
  final String? warehouse;
  final String? uom;
  final String? transaction;
  final String? transactionType;

  const SiteDiaryMaterialReceived({
    this.itemCode,
    this.quantity = 0.0,
    this.rate = 0.0,
    this.amount = 0.0,
    this.warehouse,
    this.uom,
    this.transaction,
    this.transactionType,
  });

  @override
  List<Object?> get props => [
    itemCode,
    quantity,
    rate,
    amount,
    warehouse,
    uom,
    transaction,
    transactionType,
  ];
}

class SiteDiaryMaterialDelivery extends Equatable {
  final String? parentTask;
  final String? parentTaskSubject;
  final String? task;
  final String? taskSubject;
  final String? item;
  final String? itemType;
  final String? unit;
  final String? description;
  final double quantity;
  final String? supplier;
  final String? deliveryNote;
  final bool inspectionRequired;
  final bool inspectionDone;
  final bool accepted;
  final String? rejectionReason;
  final String? linkedPo;
  final String? warehouse;

  const SiteDiaryMaterialDelivery({
    this.parentTask,
    this.parentTaskSubject,
    this.task,
    this.taskSubject,
    this.item,
    this.itemType,
    this.unit,
    this.description,
    this.quantity = 0.0,
    this.supplier,
    this.deliveryNote,
    this.inspectionRequired = false,
    this.inspectionDone = false,
    this.accepted = false,
    this.rejectionReason,
    this.linkedPo,
    this.warehouse,
  });

  @override
  List<Object?> get props => [
    parentTask,
    parentTaskSubject,
    task,
    taskSubject,
    item,
    itemType,
    unit,
    description,
    quantity,
    supplier,
    deliveryNote,
    inspectionRequired,
    inspectionDone,
    accepted,
    rejectionReason,
    linkedPo,
    warehouse,
  ];
}

class SiteDiaryVisitor extends Equatable {
  final String? visitorName;
  final String? company;
  final String? purpose;
  final String? timeIn;
  final String? timeOut;
  final String? accompaniedBy;
  final bool safetyInducted;
  final String? notes;

  const SiteDiaryVisitor({
    this.visitorName,
    this.company,
    this.purpose,
    this.timeIn,
    this.timeOut,
    this.accompaniedBy,
    this.safetyInducted = false,
    this.notes,
  });

  @override
  List<Object?> get props => [
    visitorName,
    company,
    purpose,
    timeIn,
    timeOut,
    accompaniedBy,
    safetyInducted,
    notes,
  ];
}
