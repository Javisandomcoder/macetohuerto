// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MacetoApp';

  @override
  String get homeTitle => 'MacetoApp';

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

  @override
  String get plantCreated => 'Planta añadida';

  @override
  String get plantDeleted => 'Planta eliminada';

  @override
  String get plantUpdated => 'Cambios guardados';

  @override
  String get watering => 'Riego';

  @override
  String get reminder => 'Recordatorio';

  @override
  String get enabled => 'Activado';

  @override
  String get disabled => 'Desactivado';

  @override
  String get intervalDays => 'Intervalo (días)';

  @override
  String get time => 'Hora';

  @override
  String get paused => 'Pausado';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get lastWatered => 'Último riego';

  @override
  String get noWaterData => 'Sin registro';

  @override
  String get nextWatering => 'Próximo riego';

  @override
  String get registerWatering => 'Registrar riego';

  @override
  String get wateringLogged => 'Riego registrado';

  @override
  String get globallyPaused => 'En pausa';

  @override
  String get undo => 'Deshacer';

  @override
  String plantCreatedWithName(Object name) {
    return 'Planta \"$name\" añadida';
  }

  @override
  String plantDeletedWithName(Object name) {
    return 'Planta \"$name\" eliminada';
  }

  @override
  String plantUpdatedWithName(Object name) {
    return 'Cambios guardados en \"$name\"';
  }
}
