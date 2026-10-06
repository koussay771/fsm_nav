// lib/models/department.dart

/// Represents a faculty department or major location on the FSM campus.
class Department {
  final String id;          // Matches SVG element id
  final String name;
  final String shortName;
  final String? description;
  final String? building;

  const Department({
    required this.id,
    required this.name,
    required this.shortName,
    this.description,
    this.building,
  });

  @override
  String toString() => 'Department($id, $name)';
}

/// Seeded list of FSM departments & key locations.
final List<Department> kFsmDepartments = [
  const Department(
    id: 'rentre-de-fsm',
    name: "Entrée Principale FSM",
    shortName: "Entrée FSM",
    description: "Portail d'accès principal de la Faculté des Sciences de Monastir",
    building: "Entrée Sud",
  ),
  const Department(
    id: 'rentre-d-enim',
    name: "Entrée ENIM",
    shortName: "Entrée ENIM",
    description: "Accès ouest partagé avec l'ENIM",
    building: "Entrée Ouest",
  ),
  const Department(
    id: 'departement-de-chimie',
    name: "Département de Chimie",
    shortName: "Chimie",
    description: "Bâtiment du département de chimie et laboratoires",
    building: "Bâtiment Chimie 1",
  ),
  const Department(
    id: 'departement-de-chimie-2',
    name: "Département de Chimie 2",
    shortName: "Chimie 2",
    description: "Deuxième bloc du département de chimie",
    building: "Bâtiment Chimie 2",
  ),
  const Department(
    id: "departement-d'informatique",
    name: "Département d'Informatique",
    shortName: "Informatique",
    description: "Salles machines, laboratoires et bureaux d'informatique",
    building: "Bâtiment Informatique",
  ),
  const Department(
    id: 'departement-de-physique',
    name: "Département de Physique",
    shortName: "Physique",
    description: "Laboratoires et salles de cours de physique",
    building: "Bâtiment Physique 1",
  ),
  const Department(
    id: 'departement-de-physique-2',
    name: "Département de Physique 2",
    shortName: "Physique 2",
    description: "Deuxième bloc du département de physique",
    building: "Bâtiment Physique 2",
  ),
  const Department(
    id: 'departement-math',
    name: "Département de Mathématiques",
    shortName: "Mathématiques",
    description: "Département et bibliothèque de mathématiques",
    building: "Bâtiment Mathématiques",
  ),
  const Department(
    id: 'administration',
    name: "Administration",
    shortName: "Administration",
    description: "Doyen, scolarité et services administratifs",
    building: "Bâtiment Administratif",
  ),
  const Department(
    id: 'les-amphis',
    name: "Les Amphithéâtres",
    shortName: "Amphis",
    description: "Grands amphithéâtres de cours magistraux",
    building: "Complexe des Amphis",
  ),
  const Department(
    id: 'locaux-communs-1',
    name: "Locaux Communs 1",
    shortName: "Locaux 1",
    description: "Salles de cours et travaux dirigés",
    building: "Bâtiment LC1",
  ),
  const Department(
    id: 'locaux-communs-4',
    name: "Locaux Communs 4",
    shortName: "Locaux 4",
    description: "Salles d'enseignement commun",
    building: "Bâtiment LC4",
  ),
  const Department(
    id: 'infirmerie',
    name: "Infirmerie",
    shortName: "Infirmerie",
    description: "Service médical et soins d'urgence du campus",
    building: "Pavillon Médical",
  ),
  const Department(
    id: 'magasin',
    name: "Magasin",
    shortName: "Magasin",
    description: "Magasin général et stockage",
    building: "Magasin",
  ),
  const Department(
    id: 'parking',
    name: "Parking Ouest",
    shortName: "Parking Ouest",
    description: "Zone de stationnement ouest",
    building: "Extérieur",
  ),
  const Department(
    id: 'parking-1',
    name: "Parking Sud",
    shortName: "Parking Sud",
    description: "Zone de stationnement sud près de l'entrée FSM",
    building: "Extérieur",
  ),
  const Department(
    id: 'cour-rouge',
    name: "Cour Rouge",
    shortName: "Cour Rouge",
    description: "Esplanade centrale du campus",
    building: "Extérieur",
  ),
];
