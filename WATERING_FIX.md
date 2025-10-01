# Corrección: Reinicio correcto del contador de riego

## Problema
Cuando el usuario registraba un riego manualmente, la notificación no se reprogramaba correctamente desde ese momento.

**Ejemplo del bug**:
- Planta configurada para riego cada 7 días
- Último riego: hace 6 días (próximo riego: mañana)
- Usuario riega HOY manualmente
- ❌ **Antes**: Notificación llegaba mañana (incorrecto)
- ✅ **Ahora**: Notificación llega dentro de 7 días desde HOY

## Solución implementada

### 1. Función centralizada: `watering_calculator.dart`

Creé un helper centralizado para calcular el próximo riego:

```dart
DateTime? calculateNextWatering(Plant plant) {
  // Base: último riego o fecha de plantación
  final baseline = plant.lastWateredAt ?? plant.plantedAt ?? now;
  final interval = plant.wateringIntervalDays!;

  // Calcular fecha objetivo: base + intervalo completo
  final targetDate = baseline.add(Duration(days: interval));
  var next = DateTime(targetDate.year, targetDate.month, targetDate.day, hh, mm);

  // Si ya pasó (casos edge), calcular próximo intervalo
  if (!next.isAfter(now)) {
    final daysSinceBaseline = now.difference(baseline).inDays;
    final intervalsPassed = (daysSinceBaseline / interval).ceil();
    final correctedDate = baseline.add(Duration(days: interval * intervalsPassed));
    next = DateTime(correctedDate.year, correctedDate.month, correctedDate.day, hh, mm);

    while (!next.isAfter(now)) {
      next = next.add(Duration(days: interval));
    }
  }

  return next;
}
```

**Lógica clave**:
- Toma `lastWateredAt` como base
- Suma el intervalo COMPLETO (no busca la próxima hora del día)
- Garantiza que cuando se riega hoy, el próximo riego es en `intervalo` días desde hoy

### 2. Archivos actualizados

- ✅ `services/notification_service.dart` - Lógica de programación de notificaciones
- ✅ `pages/plant_detail_page.dart` - Cálculo de próximo riego en UI
- ✅ `widgets/plant_card.dart` - Indicador "regar pronto" en lista
- ✅ `widgets/plant_grid_item.dart` - Indicador "regar pronto" en grid
- ✅ `pages/stats_page.dart` - Estadísticas de plantas que necesitan riego

Todos ahora usan la función centralizada `calculateNextWatering()`.

### 3. Verificación automática

El sistema ya tenía listeners en `home_page.dart` que reprograman notificaciones cuando `lastWateredAt` cambia:

```dart
ref.listen(plantsProvider, (prev, next) {
  // Detecta cambios en lastWateredAt y reprograma
});
```

## Resultado

✅ Registrar un riego reinicia el contador desde cero
✅ Próxima notificación = HOY + intervalo configurado
✅ Funciona correctamente incluso con plantas muy descuidadas
✅ Sin duplicación de código - todo centralizado en `watering_calculator.dart`
