// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Macetohuerto';

  @override
  String get homeTitle => 'Macetohuerto';

  @override
  String get addPlant => 'Add plant';

  @override
  String get searchHint => 'Search by name, species or location';

  @override
  String get emptyList => 'Add your first plant 🌱';

  @override
  String get noResults => 'No results';

  @override
  String get orderBy => 'Order by';

  @override
  String get location => 'Location';

  @override
  String get species => 'Species';

  @override
  String get all => 'All';

  @override
  String get nameAZ => 'Name (A→Z)';

  @override
  String get nameZA => 'Name (Z→A)';

  @override
  String get dateNewest => 'Planting date (newest first)';

  @override
  String get dateOldest => 'Planting date (oldest first)';

  @override
  String get plantNew => 'New plant';

  @override
  String get plantEdit => 'Edit plant';

  @override
  String get nameLabel => 'Name *';

  @override
  String get required => 'Required';

  @override
  String get speciesLabel => 'Species/Variety';

  @override
  String get locationLabel => 'Location';

  @override
  String get pickDate => 'Pick date';

  @override
  String get plantedLabel => 'Planted';

  @override
  String get notesLabel => 'Notes';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get createPlant => 'Create plant';

  @override
  String get deletePlantTitle => 'Delete plant';

  @override
  String get deletePlantMessage =>
      'Are you sure you want to delete it? This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get speciesVariety => 'Species/Variety';

  @override
  String get plantedDate => 'Planted';

  @override
  String get notes => 'Notes';

  @override
  String get themeToggleTooltip => 'Toggle theme';
}
