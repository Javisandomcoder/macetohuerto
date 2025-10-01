import '../models/plant.dart';

/// Calcula la próxima fecha de riego para una planta
///
/// La lógica es simple:
/// - Toma como base lastWateredAt (o plantedAt si no hay último riego)
/// - Suma el intervalo de días configurado (ajustado por estación si se proporciona)
/// - Aplica la hora configurada
///
/// [seasonMultiplier] ajusta el intervalo según la estación:
/// - Verano (1.0): sin cambios
/// - Invierno (1.5): las plantas necesitan un 50% menos de riego
///
/// Esto garantiza que cuando se registra un riego, el contador se reinicia
/// desde ese momento, sumando el intervalo completo ajustado.
DateTime? calculateNextWatering(Plant plant, {double seasonMultiplier = 1.0}) {
  if (!plant.reminderEnabled ||
      plant.wateringIntervalDays == null ||
      plant.wateringTime == null) {
    return null;
  }

  final parts = plant.wateringTime!.split(':');
  final hh = int.tryParse(parts[0]) ?? 9;
  final mm = int.tryParse(parts[1]) ?? 0;
  final now = DateTime.now();

  // Base: último riego o fecha de plantación
  final baseline = plant.lastWateredAt ?? plant.plantedAt ?? now;

  // Aplicar multiplicador estacional
  final baseInterval = plant.wateringIntervalDays!;
  final interval = (baseInterval * seasonMultiplier).round().clamp(1, 365);

  // Calcular fecha objetivo: base + intervalo completo
  final targetDate = baseline.add(Duration(days: interval));
  var next = DateTime(targetDate.year, targetDate.month, targetDate.day, hh, mm);

  // Si ya pasó (casos edge: cambio de intervalo, planta muy descuidada),
  // calcular cuántos intervalos han pasado
  if (!next.isAfter(now)) {
    final daysSinceBaseline = now.difference(baseline).inDays;
    final intervalsPassed = (daysSinceBaseline / interval).ceil();
    final correctedDate = baseline.add(Duration(days: interval * intervalsPassed));
    next = DateTime(correctedDate.year, correctedDate.month, correctedDate.day, hh, mm);

    // Asegurar que está en el futuro
    while (!next.isAfter(now)) {
      next = next.add(Duration(days: interval));
    }
  }

  return next;
}

/// Verifica si una planta necesita riego pronto (en las próximas 24 horas)
bool needsWaterSoon(Plant plant, {bool globallyPaused = false, double seasonMultiplier = 1.0}) {
  if (!plant.reminderEnabled ||
      plant.reminderPaused ||
      globallyPaused) {
    return false;
  }

  final nextWatering = calculateNextWatering(plant, seasonMultiplier: seasonMultiplier);
  if (nextWatering == null) return false;

  final now = DateTime.now();
  final hoursUntilWatering = nextWatering.difference(now).inHours;
  return hoursUntilWatering >= 0 && hoursUntilWatering <= 24;
}

/// Calcula el intervalo efectivo considerando la estación
int calculateEffectiveInterval(int baseInterval, double seasonMultiplier) {
  return (baseInterval * seasonMultiplier).round().clamp(1, 365);
}
