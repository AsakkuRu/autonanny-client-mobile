class ChildMedicalInfo {
  ChildMedicalInfo({
    this.id,
    required this.idChild,
    this.allergies,
    this.chronicDiseases,
    this.medications,
    this.bloodType,
    this.medicalPolicyNumber,
    this.specialNeeds,
    this.doctorNotes,
  });

  final int? id;
  final int idChild;
  final String? allergies;
  final String? chronicDiseases;
  final String? medications;
  final String? bloodType;
  final String? medicalPolicyNumber;
  final String? specialNeeds;
  final String? doctorNotes;

  factory ChildMedicalInfo.fromJson(Map<String, dynamic> json) {
    return ChildMedicalInfo(
      id: json['id'],
      idChild: json['id_child'],
      allergies: json['allergies'],
      chronicDiseases: json['chronic_diseases'],
      medications: json['medications'],
      bloodType: json['blood_type'],
      medicalPolicyNumber: json['medical_policy_number'],
      specialNeeds: json['special_needs'],
      doctorNotes: json['doctor_notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'id_child': idChild,
      if (allergies != null) 'allergies': allergies,
      if (chronicDiseases != null) 'chronic_diseases': chronicDiseases,
      if (medications != null) 'medications': medications,
      if (bloodType != null) 'blood_type': bloodType,
      if (medicalPolicyNumber != null) 'medical_policy_number': medicalPolicyNumber,
      if (specialNeeds != null) 'special_needs': specialNeeds,
      if (doctorNotes != null) 'doctor_notes': doctorNotes,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      if (allergies != null) 'allergies': allergies,
      if (chronicDiseases != null) 'chronic_diseases': chronicDiseases,
      if (medications != null) 'medications': medications,
      if (bloodType != null) 'blood_type': bloodType,
      if (medicalPolicyNumber != null) 'medical_policy_number': medicalPolicyNumber,
      if (specialNeeds != null) 'special_needs': specialNeeds,
      if (doctorNotes != null) 'doctor_notes': doctorNotes,
    };
  }
}
