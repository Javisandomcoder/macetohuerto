// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Macetohuerto';

  @override
  String get homeTitle => 'Macetohuerto';

  @override
  String get addPlant => 'Añadir planta';

  @override
  String get searchHint => 'Buscar por nombre, especie o ubicación';

  @override
  String get emptyList => 'Añade tu primera planta 🌱';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get orderBy => 'Ordenar por';

  @override
  String get location => 'Ubicación';

  @override
  String get species => 'Especie';

  @override
  String get all => 'Todas';

  @override
  String get nameAZ => 'Nombre (A→Z)';

  @override
  String get nameZA => 'Nombre (Z→A)';

  @override
  String get dateNewest => 'Fecha plantación (reciente primero)';

  @override
  String get dateOldest => 'Fecha plantación (antiguo primero)';

  @override
  String get plantNew => 'Nueva planta';

  @override
  String get plantEdit => 'Editar planta';

  @override
  String get nameLabel => 'Nombre *';

  @override
  String get required => 'Obligatorio';

  @override
  String get speciesLabel => 'Especie/Variedad';

  @override
  String get locationLabel => 'Ubicación';

  @override
  String get pickDate => 'Elegir fecha';

  @override
  String get plantedLabel => 'Plantada';

  @override
  String get notesLabel => 'Notas';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get createPlant => 'Crear planta';

  @override
  String get deletePlantTitle => 'Eliminar planta';

  @override
  String get deletePlantMessage =>
      '¿Seguro que quieres eliminarla? Esta acción no se puede deshacer.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get speciesVariety => 'Especie/Variedad';

  @override
  String get plantedDate => 'Plantada';

  @override
  String get notes => 'Notas';

  @override
  String get themeToggleTooltip => 'Cambiar tema';
}
