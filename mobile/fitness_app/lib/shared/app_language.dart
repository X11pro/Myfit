import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage { en, es }

final appLanguageProvider = StateProvider<AppLanguage>((ref) => AppLanguage.en);

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  bool get isEnglish => language == AppLanguage.en;

  String get welcomeTagline => isEnglish
      ? 'Nutrition, training, and energy balance in one app.'
      : 'Nutricion, entrenamiento y balance energetico en una sola app.';

  String get welcomeDescription => isEnglish
      ? 'Use the app directly for now. Authentication is temporarily disabled.'
      : 'Usa la app directamente por ahora. La autenticacion esta deshabilitada temporalmente.';

  String get continueGuest =>
      isEnglish ? 'Continue as guest' : 'Continuar como invitado';

  String get setupProfile => isEnglish ? 'Set up profile' : 'Configurar perfil';

  String get quickActionsTitle =>
      isEnglish ? 'Quick actions' : 'Acciones rapidas';

  String get todaySummaryTitle =>
      isEnglish ? 'Today summary' : 'Resumen de hoy';

  String get dailyHistoryTitle =>
      isEnglish ? 'Daily history' : 'Historial diario';

  String get logWeightTitle =>
      isEnglish ? 'Log today weight' : 'Registrar peso de hoy';

  String get todayWeightTitle => isEnglish ? 'Today weight' : 'Peso de hoy';

  String get noWeightLogged =>
      isEnglish ? 'No weight logged yet' : 'Todavia no hay peso registrado';

  String get saveWeightButton => isEnglish ? 'Save weight' : 'Guardar peso';

  String get weightSavedMessage =>
      isEnglish ? 'Weight saved.' : 'Peso guardado.';

  String get invalidWeightMessage => isEnglish
      ? 'Enter a valid weight in kg.'
      : 'Ingresa un peso valido en kg.';

  String get weightInputLabel => isEnglish ? 'Weight (kg)' : 'Peso (kg)';

  String get noDailySummaryYet => isEnglish
      ? 'No completed daily summary yet. Start logging meals.'
      : 'Todavia no hay resumen diario. Empieza a registrar comidas.';

  String get addMealTitle => isEnglish ? 'Add meal' : 'Agregar comida';

  String get editMealTitle => isEnglish ? 'Edit meal' : 'Editar comida';

  String get addSharedFoodTitle =>
      isEnglish ? 'Add shared food' : 'Agregar alimento compartido';

  String get addSharedFoodSubtitle => isEnglish
      ? 'If a barcode is missing, capture the label with OCR/AI and save the product for everyone.'
      : 'Si falta un codigo de barras, captura la etiqueta con OCR/AI y guarda el producto para todos.';

  String get addMealSubtitle => isEnglish
      ? 'Log a meal manually with basic calories and protein.'
      : 'Registra una comida manualmente con calorias y proteina basicas.';

  String get foodNameLabel => isEnglish ? 'Food name' : 'Nombre de la comida';

  String get mealTypeLabel => isEnglish ? 'Meal type' : 'Tipo de comida';

  String get caloriesLabel => isEnglish ? 'Calories' : 'Calorias';

  String get brandLabel => isEnglish ? 'Brand' : 'Marca';

  String get barcodeLabel => isEnglish ? 'Barcode' : 'Codigo de barras';

  String get proteinLabel => isEnglish ? 'Protein (g)' : 'Proteina (g)';

  String get carbsLabel => isEnglish ? 'Carbs (g)' : 'Carbohidratos (g)';

  String get fatLabel => isEnglish ? 'Fat (g)' : 'Grasas (g)';

  String get sugarLabel => isEnglish ? 'Sugar (g)' : 'Azucares (g)';

  String get fiberLabel => isEnglish ? 'Fiber (g)' : 'Fibra (g)';

  String get labelTextLabel =>
      isEnglish ? 'Label text / OCR' : 'Texto de etiqueta / OCR';

  String get parseWithAiButton =>
      isEnglish ? 'Parse with AI / OCR' : 'Analizar con AI / OCR';

  String get takePhotoButton =>
      isEnglish ? 'Take label photo' : 'Tomar foto de etiqueta';

  String get pickPhotoButton => isEnglish ? 'Choose photo' : 'Elegir foto';

  String get saveSharedFoodButton =>
      isEnglish ? 'Save shared product' : 'Guardar producto compartido';

  String get sharedFoodSavedMessage => isEnglish
      ? 'Shared product saved to Supabase.'
      : 'Producto compartido guardado en Supabase.';

  String get sharedFoodInvalidMessage => isEnglish
      ? 'Enter at least a product name or OCR/label data.'
      : 'Ingresa al menos nombre o datos OCR/etiqueta.';

  String get qualityScoreLabel =>
      isEnglish ? 'Nutrition quality' : 'Calidad nutricional';

  String get qualityReasonLabel =>
      isEnglish ? 'Why this score' : 'Motivo del puntaje';

  String qualityScoreValue(num score) =>
      isEnglish ? '$score / 5' : '$score / 5';

  String get saveMealButton => isEnglish ? 'Save meal' : 'Guardar comida';

  String get addPhotoButton =>
      isEnglish ? 'Attach meal photo' : 'Adjuntar foto de la comida';

  String get choosePhotoButton =>
      isEnglish ? 'Choose from gallery' : 'Elegir desde galeria';

  String get changePhotoButton => isEnglish ? 'Change photo' : 'Cambiar foto';

  String get removePhotoButton => isEnglish ? 'Remove photo' : 'Quitar foto';

  String get mealPhotoLabel => isEnglish ? 'Meal photo' : 'Foto de la comida';

  String get analyzeWithAiButton =>
      isEnglish ? 'Analyze with AI' : 'Analizar con AI';

  String get aiAnalysisNeedsPhoto => isEnglish
      ? 'Attach a meal photo before running AI analysis.'
      : 'Adjunta una foto de la comida antes de ejecutar el analisis AI.';

  String get aiAnalysisSuccess => isEnglish
      ? 'AI analysis completed. Review the estimated values.'
      : 'Analisis AI completado. Revisa los valores estimados.';

  String aiConfidenceLabel(num confidence) => isEnglish
      ? 'Confidence: ${(confidence * 100).round()}%'
      : 'Confianza: ${(confidence * 100).round()}%';

  String get updateMealButton =>
      isEnglish ? 'Update meal' : 'Actualizar comida';

  String get editMealButton => isEnglish ? 'Edit' : 'Editar';

  String get deleteMealButton => isEnglish ? 'Delete' : 'Eliminar';

  String get mealDeletedMessage =>
      isEnglish ? 'Meal deleted.' : 'Comida eliminada.';

  String get invalidMealMessage => isEnglish
      ? 'Enter a name, calories, and protein.'
      : 'Ingresa nombre, calorias y proteina.';

  String get mealsTodayTitle => isEnglish ? 'Meals today' : 'Comidas de hoy';

  String get noMealsYet => isEnglish
      ? 'No meals logged yet. Add your first entry.'
      : 'Todavia no hay comidas registradas. Agrega la primera.';

  String get mealTypeBreakfast => isEnglish ? 'Breakfast' : 'Desayuno';

  String get mealTypeLunch => isEnglish ? 'Lunch' : 'Almuerzo';

  String get mealTypeDinner => isEnglish ? 'Dinner' : 'Cena';

  String get mealTypeSnack => isEnglish ? 'Snack' : 'Snack';

  String get openSetupProfile =>
      isEnglish ? 'Open profile setup' : 'Abrir perfil';

  String get openSharedCatalog =>
      isEnglish ? 'Open shared catalog' : 'Abrir catalogo compartido';

  String dateSummarySubtitle(String dateKey, int count) =>
      isEnglish ? '$dateKey • $count meals' : '$dateKey • $count comidas';

  String entriesCount(int count) =>
      isEnglish ? '$count entries today' : '$count registros hoy';

  String get dashboardTitle => isEnglish ? 'Dashboard' : 'Panel';

  String helloUser(String name) => isEnglish ? 'Hello, $name' : 'Hola, $name';

  String get caloriesConsumed =>
      isEnglish ? 'Calories consumed' : 'Calorias consumidas';

  String get protein => isEnglish ? 'Protein' : 'Proteina';

  String get estimatedBalance =>
      isEnglish ? 'Estimated balance' : 'Balance estimado';

  String get mealsPending => isEnglish
      ? 'Meal tracking not connected yet'
      : 'El registro de comidas aun no esta conectado';

  String get proteinGoalPending => isEnglish
      ? 'Profile goal still pending'
      : 'El objetivo del perfil sigue pendiente';

  String get activityPending => isEnglish
      ? 'No imported activity yet'
      : 'Todavia no hay actividad importada';

  String get nextIntegration => isEnglish
      ? 'Next integration: meals + daily summary + Health Connect/HealthKit.'
      : 'Siguiente integracion: meals + daily summary + Health Connect/HealthKit.';

  String get onboardingTitle =>
      isEnglish ? 'Set your starting point' : 'Configura tu punto de partida';

  String get nameLabel => isEnglish ? 'Name' : 'Nombre';

  String get heightLabel => isEnglish ? 'Height (cm)' : 'Altura (cm)';

  String get weightLabel =>
      isEnglish ? 'Current weight (kg)' : 'Peso actual (kg)';

  String get goalLabel => isEnglish ? 'Goal' : 'Objetivo';

  String get workLabel => isEnglish ? 'Work activity' : 'Trabajo';

  String get saveProfile =>
      isEnglish ? 'Save initial profile' : 'Guardar perfil inicial';

  String get saveOnboardingError => isEnglish
      ? 'Could not save onboarding'
      : 'No se pudo guardar el onboarding';

  String get defaultUserName => isEnglish ? 'User' : 'Usuario';

  String get goalLoseFat => isEnglish ? 'Lose fat' : 'Perder grasa';

  String get goalGainMuscle => isEnglish ? 'Gain muscle' : 'Ganar musculo';

  String get goalMaintain => isEnglish ? 'Maintain weight' : 'Mantener peso';

  String get goalRecomp => isEnglish ? 'Recomposition' : 'Recomposicion';

  String get jobSedentary => isEnglish ? 'Sedentary' : 'Sedentario';

  String get jobStanding => isEnglish ? 'Standing' : 'De pie';

  String get jobLight => isEnglish ? 'Light physical' : 'Fisico ligero';

  String get jobModerate => isEnglish ? 'Moderate physical' : 'Fisico moderado';

  String get jobIntense => isEnglish ? 'Intense physical' : 'Fisico intenso';

  String mealTypeName(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return mealTypeBreakfast;
      case 'lunch':
        return mealTypeLunch;
      case 'dinner':
        return mealTypeDinner;
      case 'snack':
        return mealTypeSnack;
      default:
        return mealType;
    }
  }
}

AppStrings stringsFor(WidgetRef ref) {
  return AppStrings(ref.watch(appLanguageProvider));
}
