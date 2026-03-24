class ServiceCategory {
  final String id;
  final String name;
  final String tamilName;
  final String emoji;
  final double basePrice;
  final List<String> checklist;
  final List<String> checklistTamil;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.tamilName,
    required this.emoji,
    required this.basePrice,
    this.checklist = const [],
    this.checklistTamil = const [],
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      tamilName: json['tamil_name'] as String? ?? json['name'] as String,
      emoji: json['emoji'] as String? ?? '🔧',
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0,
      checklist: (json['checklist'] as List<dynamic>?)?.cast<String>() ?? [],
      checklistTamil:
          (json['checklist_tamil'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tamil_name': tamilName,
    'emoji': emoji,
    'base_price': basePrice,
    'checklist': checklist,
    'checklist_tamil': checklistTamil,
  };

  static const List<ServiceCategory> defaultCategories = [
    ServiceCategory(
      id: 'plumbing',
      name: 'Plumbing',
      tamilName: 'குழாய் பணி',
      emoji: '🔧',
      basePrice: 299,
      checklist: [
        'Inspect issue',
        'Turn off water supply',
        'Fix/Replace parts',
        'Test for leaks',
        'Clean work area',
      ],
      checklistTamil: [
        'சிக்கலை ஆய்வு செய்',
        'தண்ணீர் விநியோகத்தை நிறுத்து',
        'பாகங்களை சரி செய்/மாற்று',
        'கசிவு சோதனை',
        'பணியிடத்தை சுத்தம் செய்',
      ],
    ),
    ServiceCategory(
      id: 'electrical',
      name: 'Electrical',
      tamilName: 'மின் பணி',
      emoji: '⚡',
      basePrice: 349,
      checklist: [
        'Safety check - power off',
        'Diagnose issue',
        'Repair/Install',
        'Test connections',
        'Verify safety',
      ],
      checklistTamil: [
        'பாதுகாப்பு சோதனை - மின்சாரம் நிறுத்து',
        'சிக்கலை கண்டறி',
        'பழுது/நிறுவு',
        'இணைப்புகளை சோதி',
        'பாதுகாப்பை உறுதிசெய்',
      ],
    ),
    ServiceCategory(
      id: 'cleaning',
      name: 'Cleaning',
      tamilName: 'சுத்தம்',
      emoji: '🧹',
      basePrice: 499,
      checklist: [
        'Survey rooms',
        'Dust surfaces',
        'Mop floors',
        'Clean bathrooms',
        'Final walkthrough',
      ],
      checklistTamil: [
        'அறைகளை ஆய்வு செய்',
        'மேற்பரப்புகளை துடை',
        'தரையை துடை',
        'குளியலறைகளை சுத்தம் செய்',
        'இறுதி சோதனை',
      ],
    ),
    ServiceCategory(
      id: 'ac_service',
      name: 'AC Service',
      tamilName: 'ஏசி சேவை',
      emoji: '❄️',
      basePrice: 599,
      checklist: [
        'Check cooling',
        'Clean filters',
        'Check gas level',
        'Clean condenser',
        'Test operation',
      ],
      checklistTamil: [
        'குளிர்ச்சியை சோதி',
        'வடிகட்டிகளை சுத்தம் செய்',
        'கேஸ் அளவை சோதி',
        'கண்டென்சரை சுத்தம் செய்',
        'இயக்கத்தை சோதி',
      ],
    ),
    ServiceCategory(
      id: 'carpentry',
      name: 'Carpentry',
      tamilName: 'தச்சு பணி',
      emoji: '🪚',
      basePrice: 399,
      checklist: [
        'Measure area',
        'Prepare materials',
        'Build/Repair',
        'Sand & Finish',
        'Clean up',
      ],
      checklistTamil: [
        'பகுதியை அளவிடு',
        'பொருட்களை தயார் செய்',
        'கட்டு/பழுது',
        'மணல் & முடிப்பு',
        'சுத்தம் செய்',
      ],
    ),
    ServiceCategory(
      id: 'maid',
      name: 'Maid Service',
      tamilName: 'வீட்டு உதவி',
      emoji: '🏠',
      basePrice: 399,
      checklist: ['Dishes', 'Laundry', 'Dusting', 'Mopping', 'Organizing'],
      checklistTamil: [
        'பாத்திரங்கள்',
        'துணி துவைப்பு',
        'தூசி துடைப்பு',
        'தரை துடைப்பு',
        'ஒழுங்குபடுத்துதல்',
      ],
    ),
  ];
}
