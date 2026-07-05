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
      ? 'Use the app in guest mode now, or sign in when Supabase is configured.'
      : 'Usa la app en modo invitado por ahora, o inicia sesion cuando Supabase este configurado.';

  String get signInWithEmailButton =>
      isEnglish ? 'Sign in with email' : 'Entrar con email';

  String get loginDescription => isEnglish
      ? 'Enter your email to receive an access code and continue with your profile.'
      : 'Ingresa tu email para recibir un codigo de acceso y continuar con tu perfil.';

  String get loginMissingConfig => isEnglish
      ? 'Missing `SUPABASE_URL` and `SUPABASE_ANON_KEY`. Real authentication is not available until those variables are configured.'
      : 'Faltan `SUPABASE_URL` y `SUPABASE_ANON_KEY`. La autenticacion real no esta disponible hasta configurar esas variables.';

  String get emailLabel => isEnglish ? 'Email' : 'Email';

  String get emailHint => isEnglish ? 'you@email.com' : 'tu@email.com';

  String get accessCodeLabel => isEnglish ? 'Access code' : 'Codigo de acceso';

  String get accessCodeHint => isEnglish ? '6 digits' : '6 digitos';

  String get verifyCodeButton => isEnglish ? 'Verify code' : 'Verificar codigo';

  String get receiveAccessCodeButton =>
      isEnglish ? 'Receive access code' : 'Recibir codigo de acceso';

  String get changeEmailButton => isEnglish ? 'Change email' : 'Cambiar email';

  String get invalidEmailMessage =>
      isEnglish ? 'Enter a valid email.' : 'Ingresa un email valido.';

  String get codeSentMessage => isEnglish
      ? 'We sent you a code by email.'
      : 'Te enviamos un codigo por email.';

  String sendCodeErrorMessage(Object error) => isEnglish
      ? 'Could not send the code: $error'
      : 'No se pudo enviar el codigo: $error';

  String get staleEmailMessage => isEnglish
      ? 'The email is no longer valid. Try again.'
      : 'El email ya no es valido. Vuelve a intentarlo.';

  String get invalidAccessCodeMessage =>
      isEnglish ? 'Enter the 6-digit code.' : 'Ingresa el codigo de 6 digitos.';

  String verifyCodeErrorMessage(Object error) => isEnglish
      ? 'Could not verify the code: $error'
      : 'No se pudo verificar el codigo: $error';

  String get missingSupabaseConfigMessage => isEnglish
      ? 'Missing SUPABASE_URL and SUPABASE_ANON_KEY.'
      : 'Faltan SUPABASE_URL y SUPABASE_ANON_KEY.';

  String get continueGuest =>
      isEnglish ? 'Continue as guest' : 'Continuar como invitado';

  String signedInDescription(String? email) => isEnglish
      ? 'You are signed in${email == null || email.isEmpty ? '' : ' as $email'}.'
      : 'Tu sesion esta iniciada${email == null || email.isEmpty ? '' : ' como $email'}.';

  String get openProfileOrDashboardButton =>
      isEnglish ? 'Open app' : 'Abrir app';

  String get signOutButton => isEnglish ? 'Sign out' : 'Cerrar sesion';

  String get welcomeScreenTitle => isEnglish ? 'Welcome' : 'Bienvenida';

  String get backButtonTooltip => isEnglish ? 'Back' : 'Atras';

  String get homeButtonTooltip => isEnglish ? 'Home' : 'Inicio';

  String get menuButtonTooltip => isEnglish ? 'Menu' : 'Menu';

  String get setupProfile => isEnglish ? 'Set up profile' : 'Configurar perfil';

  String get quickActionsTitle =>
      isEnglish ? 'Quick actions' : 'Acciones rapidas';

  String get quickActionWorkout => isEnglish ? 'Log workout' : 'Registrar gym';

  String get todaySummaryTitle =>
      isEnglish ? 'Today summary' : 'Resumen de hoy';

  String get dailyHistoryTitle =>
      isEnglish ? 'Daily history' : 'Historial diario';

  String get gymTitle => isEnglish ? 'Gym tracker' : 'Seguimiento gym';

  String get gymSubtitle => isEnglish
      ? 'Save your sets, weight, and session date to track progress over time.'
      : 'Guarda tus sets, pesos y fecha de sesion para seguir el progreso en el tiempo.';

  String get logWorkoutTitle =>
      isEnglish ? 'Manual workout' : 'Entrenamiento manual';

  String get workoutNameLabel =>
      isEnglish ? 'Session name' : 'Nombre de la sesion';

  String get workoutDateLabel => isEnglish ? 'Date' : 'Fecha';

  String get durationMinutesLabel =>
      isEnglish ? 'Duration (min)' : 'Duracion (min)';

  String get workoutCaloriesLabel =>
      isEnglish ? 'Calories burned' : 'Calorias quemadas';

  String get notesLabel => isEnglish ? 'Notes' : 'Notas';

  String get workoutSessionTimerTitle =>
      isEnglish ? 'Workout timer' : 'Cronometro de entrenamiento';

  String get restTimerTitle =>
      isEnglish ? 'Rest timer' : 'Cronometro de descanso';

  String get startTimerButton => isEnglish ? 'Start timer' : 'Iniciar timer';

  String get startRestButton => isEnglish ? 'Start rest' : 'Iniciar descanso';

  String get pauseTimerButton => isEnglish ? 'Pause' : 'Pausar';

  String get resumeTimerButton => isEnglish ? 'Resume' : 'Reanudar';

  String get resetTimerButton => isEnglish ? 'Reset' : 'Reiniciar';

  String get loggedSetsTitle => isEnglish ? 'Logged sets' : 'Sets cargados';

  String get addSetButton => isEnglish ? 'Add set' : 'Agregar set';

  String get repeatLastSetButton =>
      isEnglish ? 'Repeat last' : 'Repetir ultimo';

  String get noSetsAddedYet =>
      isEnglish ? 'No sets added yet.' : 'Todavia no agregaste sets.';

  String get recentExercisesTitle =>
      isEnglish ? 'Recent exercises' : 'Ejercicios recientes';

  String get defaultWorkoutTitle => isEnglish ? 'Gym session' : 'Sesion de gym';

  String get saveWorkoutButton =>
      isEnglish ? 'Save workout' : 'Guardar entrenamiento';

  String get workoutSavedMessage =>
      isEnglish ? 'Workout saved.' : 'Entrenamiento guardado.';

  String repeatLastSetMessage(String exerciseName) => isEnglish
      ? 'Last set duplicated for $exerciseName.'
      : 'Se duplico el ultimo set de $exerciseName.';

  String get invalidWorkoutMessage => isEnglish
      ? 'Enter a session name and at least one set.'
      : 'Ingresa un nombre de sesion y al menos un set.';

  String get exerciseNameLabel => isEnglish ? 'Exercise' : 'Ejercicio';

  String get muscleGroupLabel => isEnglish ? 'Muscle group' : 'Grupo muscular';

  String get selectMuscleGroupLabel =>
      isEnglish ? 'Select muscle group' : 'Elegir grupo muscular';

  String get selectExerciseLabel =>
      isEnglish ? 'Select exercise' : 'Elegir ejercicio';

  String get repsLabel => isEnglish ? 'Reps' : 'Repeticiones';

  String get setsLabel => isEnglish ? 'Sets' : 'Sets';

  String get setWeightLabel => isEnglish ? 'Weight (kg)' : 'Peso (kg)';

  String get rpeLabel => isEnglish ? 'RPE (optional)' : 'RPE (opcional)';

  String get rpeHelpLabel =>
      isEnglish ? 'Effort felt in the set' : 'Esfuerzo sentido en el set';

  String get noRpeLabel => isEnglish ? 'No RPE' : 'Sin RPE';

  String get addCustomExerciseOption =>
      isEnglish ? 'Add custom exercise' : 'Agregar ejercicio personalizado';

  String get customExerciseLabel =>
      isEnglish ? 'Custom exercise' : 'Ejercicio personalizado';

  String rpeValueLabel(double value) {
    final isWhole = value == value.roundToDouble();
    return isWhole ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  String rpeEffortTitle(double value) {
    if (value >= 9.5) {
      return isEnglish ? 'Max Effort' : 'Esfuerzo maximo';
    }
    if (value >= 8.5) {
      return isEnglish ? 'Very Hard Effort' : 'Esfuerzo muy duro';
    }
    if (value >= 7.5) {
      return isEnglish ? 'Hard Effort' : 'Esfuerzo duro';
    }
    if (value >= 6.5) {
      return isEnglish ? 'Moderate Effort' : 'Esfuerzo moderado';
    }
    return isEnglish ? 'Controlled Effort' : 'Esfuerzo controlado';
  }

  String rpeReserveHint(double value) {
    final repsLeft = 10 - value;
    if (repsLeft <= 0) {
      return isEnglish
          ? 'Could not do another rep'
          : 'No podias hacer otra repeticion';
    }

    final repsText = repsLeft == repsLeft.roundToDouble()
        ? repsLeft.toStringAsFixed(0)
        : repsLeft.toStringAsFixed(1);

    return isEnglish
        ? 'Could probably do $repsText more reps'
        : 'Probablemente podias hacer $repsText reps mas';
  }

  String get cancelButton => isEnglish ? 'Cancel' : 'Cancelar';

  String get addButton => isEnglish ? 'Add' : 'Agregar';

  String setsCountLabel(int count) => isEnglish ? '$count sets' : '$count sets';

  String repsCountLabel(int count) =>
      isEnglish ? '$count reps' : '$count repeticiones';

  String get generalMuscleGroup => isEnglish ? 'General' : 'General';

  String maxWeightLabel(double kg) => isEnglish
      ? '${kg.toStringAsFixed(1)} kg max'
      : '${kg.toStringAsFixed(1)} kg max';

  String setNumberLabel(int setNumber) =>
      isEnglish ? 'Set $setNumber' : 'Set $setNumber';

  String workoutDateSetsSummary(String dateKey, int setCount, int repsCount) =>
      '$dateKey • ${setsCountLabel(setCount)} • ${repsCountLabel(repsCount)}';

  String draftSetSubtitle({
    required int reps,
    required int setNumber,
    required String muscleGroup,
  }) {
    final group = muscleGroup.isEmpty ? generalMuscleGroup : muscleGroup;
    return '${repsCountLabel(reps)} • ${setNumberLabel(setNumber)} • $group';
  }

  String exerciseWeightRepsLabel({
    required String exerciseName,
    required double weightKg,
    required int reps,
  }) {
    return '$exerciseName: $weightKg kg x ${repsCountLabel(reps)}';
  }

  String get workoutHistoryTitle =>
      isEnglish ? 'Workout history' : 'Historial de entrenamientos';

  String get noWorkoutsYet => isEnglish
      ? 'No workouts logged yet. Add your first gym session.'
      : 'Todavia no hay entrenamientos cargados. Agrega tu primera sesion.';

  String get deleteWorkoutButton =>
      isEnglish ? 'Delete workout' : 'Eliminar entrenamiento';

  String get workoutDeletedMessage =>
      isEnglish ? 'Workout deleted.' : 'Entrenamiento eliminado.';

  String get workoutTodayTitle =>
      isEnglish ? 'Workout today' : 'Entrenamiento de hoy';

  String get workoutCaloriesToday =>
      isEnglish ? 'Workout calories' : 'Calorias de entrenamiento';

  String get workoutSetsToday => isEnglish ? 'Sets today' : 'Sets de hoy';

  String get workoutRepsToday =>
      isEnglish ? 'Reps today' : 'Repeticiones de hoy';

  String get dailyTargetsTitle =>
      isEnglish ? 'Daily targets' : 'Objetivos del dia';

  String get estimatedBurnTitle =>
      isEnglish ? 'Estimated burn' : 'Gasto estimado';

  String get targetCaloriesTitle =>
      isEnglish ? 'Target calories' : 'Calorias objetivo';

  String get targetProteinTitle =>
      isEnglish ? 'Target protein' : 'Proteina objetivo';

  String get workoutRecommendationsTitle =>
      isEnglish ? 'Routine recommendation' : 'Recomendacion de rutina';

  String get nutritionFocusTitle =>
      isEnglish ? 'Nutrition focus' : 'Foco nutricional';

  String get progressDiagramTitle =>
      isEnglish ? 'Progress diagram' : 'Diagrama de progreso';

  String get progressStrength => isEnglish ? 'Weight lifted' : 'Peso levantado';

  String get strengthMetricLabel =>
      isEnglish ? 'Strength metric' : 'Metrica de fuerza';

  String get progressHeaviestWeight =>
      isEnglish ? 'Heaviest weight' : 'Peso maximo';

  String get progressTrainingVolume =>
      isEnglish ? 'Training volume' : 'Volumen';

  String get progressEstimatedOneRepMax =>
      isEnglish ? 'Estimated 1RM' : '1RM estimado';

  String get progressBodyWeight => isEnglish ? 'Body weight' : 'Peso corporal';

  String get progressCaloriesBurned =>
      isEnglish ? 'Calories burned' : 'Calorias quemadas';

  String get progressCombined => isEnglish ? 'Combined' : 'Combinado';

  String get progressScreenTitle => isEnglish ? 'Progress' : 'Progreso';

  String get progressScreenSubtitle => isEnglish
      ? 'Review the trend of your gym performance, body weight, and calorie burn.'
      : 'Revisa la tendencia de tu rendimiento en gym, peso corporal y calorias quemadas.';

  String get exerciseFilterLabel =>
      isEnglish ? 'Exercise filter' : 'Filtro por ejercicio';

  String get allExercisesOption =>
      isEnglish ? 'All exercises' : 'Todos los ejercicios';

  String get openProgressButton =>
      isEnglish ? 'Open progress' : 'Abrir progreso';

  String get progressDeltaTitle => isEnglish ? 'Delta' : 'Cambio';

  String get latestValueLabel => isEnglish ? 'Latest' : 'Ultimo';

  String get bestValueLabel => isEnglish ? 'Best' : 'Mejor';

  String get filterActiveTitle => isEnglish ? 'Active filter' : 'Filtro activo';

  String filteredExerciseLabel(String exercise) => isEnglish
      ? 'Strength filtered by $exercise'
      : 'Fuerza filtrada por $exercise';

  String get dashboardFocusTitle => isEnglish ? 'Today focus' : 'Foco de hoy';

  String get nextBestActionTitle =>
      isEnglish ? 'Next best action' : 'Siguiente mejor accion';

  String get ctaLogWorkoutHeadline => isEnglish
      ? 'You have not logged a workout today.'
      : 'Todavia no registraste entrenamiento hoy.';

  String get ctaLogWorkoutSubtitle => isEnglish
      ? 'Save your session, sets, and lifted weight to keep your progress trend accurate.'
      : 'Guarda tu sesion, sets y peso levantado para que la tendencia de progreso sea precisa.';

  String get ctaAddMealHeadline => isEnglish
      ? 'Your food log is still empty today.'
      : 'Tu registro de comidas de hoy sigue vacio.';

  String get ctaAddMealSubtitle => isEnglish
      ? 'Add a meal so the dashboard can compare intake against your target.'
      : 'Agrega una comida para que el panel compare tu ingesta contra el objetivo.';

  String get ctaProteinHeadline => isEnglish
      ? 'Protein is the main gap for today.'
      : 'La proteina es la principal brecha de hoy.';

  String ctaProteinSubtitle(int grams) => isEnglish
      ? 'You still need about $grams g. A high-protein meal would improve the day fast.'
      : 'Todavia te faltan unos $grams g. Una comida alta en proteina mejoraria rapido el dia.';

  String get ctaReviewProgressHeadline => isEnglish
      ? 'Today is on track. Review your trend.'
      : 'Hoy va encaminado. Revisa tu tendencia.';

  String get ctaReviewProgressSubtitle => isEnglish
      ? 'Use the progress view to verify strength, body weight, and calorie burn changes.'
      : 'Usa la vista de progreso para verificar cambios en fuerza, peso corporal y calorias quemadas.';

  String get reviewProgressButton =>
      isEnglish ? 'Review progress' : 'Revisar progreso';

  String get collapseSectionHint => isEnglish
      ? 'Tap to expand or collapse.'
      : 'Toca para expandir o contraer.';

  String get recentMealsSection =>
      isEnglish ? 'Recent meals' : 'Comidas recientes';

  String get recentWorkoutsSection =>
      isEnglish ? 'Recent workouts' : 'Entrenamientos recientes';

  String get dailyHistorySection =>
      isEnglish ? 'Daily nutrition history' : 'Historial diario de nutricion';

  String bodyWeightDeltaMessage(double delta) {
    final absolute = delta.abs().toStringAsFixed(1);
    if (isEnglish) {
      if (delta == 0) {
        return 'Body weight is stable.';
      }
      return delta < 0
          ? 'Body weight is down $absolute kg.'
          : 'Body weight is up $absolute kg.';
    }

    if (delta == 0) {
      return 'El peso corporal esta estable.';
    }

    return delta < 0
        ? 'El peso corporal bajo $absolute kg.'
        : 'El peso corporal subio $absolute kg.';
  }

  String trendDirectionMessage(double delta) {
    if (isEnglish) {
      if (delta == 0) {
        return 'Stable trend.';
      }
      return delta > 0 ? 'Trend is moving up.' : 'Trend is moving down.';
    }

    if (delta == 0) {
      return 'Tendencia estable.';
    }

    return delta > 0 ? 'La tendencia va subiendo.' : 'La tendencia va bajando.';
  }

  String get noProgressDataYet => isEnglish
      ? 'Not enough data yet. Log workouts or body weight to see progress.'
      : 'Todavia no hay datos suficientes. Registra entrenamientos o peso corporal para ver progreso.';

  String get bodyWeightTrendDown => isEnglish
      ? 'Lower bars mean body weight is going down.'
      : 'Barras mas bajas significan que el peso corporal esta bajando.';

  String goalSummary(String goal) =>
      isEnglish ? 'Goal: ${goalName(goal)}' : 'Objetivo: ${goalName(goal)}';

  String remainingProteinMessage(int grams) => isEnglish
      ? 'You still need $grams g of protein today.'
      : 'Todavia te faltan $grams g de proteina hoy.';

  String calorieDeltaMessage(int calories) {
    if (isEnglish) {
      if (calories == 0) {
        return 'You are exactly on your calorie target.';
      }
      return calories > 0
          ? 'You are $calories kcal above target.'
          : 'You are ${calories.abs()} kcal below target.';
    }

    if (calories == 0) {
      return 'Estas exactamente en tu objetivo calorico.';
    }

    return calories > 0
        ? 'Vas $calories kcal por encima del objetivo.'
        : 'Vas ${calories.abs()} kcal por debajo del objetivo.';
  }

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

  String get foodGalleryTitle =>
      isEnglish ? 'Food gallery' : 'Galeria de comidas';

  String get foodGallerySubtitle => isEnglish
      ? 'Review your saved meal photos together with their nutrition details.'
      : 'Revisa tus fotos de comidas guardadas junto con sus detalles nutricionales.';

  String savedMealPhotosCount(int count) => isEnglish
      ? '$count saved meal photos'
      : '$count fotos de comidas guardadas';

  String get noMealPhotosYet => isEnglish
      ? 'No saved meal photos yet.'
      : 'Todavia no hay fotos de comidas guardadas.';

  String get foodGalleryEmptyHint => isEnglish
      ? 'Add a meal with photo and it will appear here for later review.'
      : 'Agrega una comida con foto y aparecera aqui para revisarla despues.';

  String get addSharedFoodSubtitle => isEnglish
      ? 'If a barcode is missing, capture the label with OCR/AI and save the product for everyone.'
      : 'Si falta un codigo de barras, captura la etiqueta con OCR/AI y guarda el producto para todos.';

  String get addMealSubtitle => isEnglish
      ? 'Log a meal manually with basic calories and protein.'
      : 'Registra una comida manualmente con calorias y proteina basicas.';

  String get scanBarcodeButton =>
      isEnglish ? 'Scan barcode' : 'Escanear codigo';

  String get lookupBarcodeButton =>
      isEnglish ? 'Lookup barcode' : 'Buscar codigo';

  String get barcodeLookupInProgress =>
      isEnglish ? 'Looking up barcode...' : 'Buscando codigo...';

  String get barcodeLookupNeedsCode => isEnglish
      ? 'Enter or scan a barcode first.'
      : 'Ingresa o escanea un codigo primero.';

  String get barcodeLookupNoMatch => isEnglish
      ? 'No product found for that barcode yet.'
      : 'Todavia no se encontro un producto para ese codigo.';

  String get barcodeLookupSuccess => isEnglish
      ? 'Barcode product loaded. Review the values before saving.'
      : 'Producto por codigo cargado. Revisa los valores antes de guardar.';

  String get barcodeResultTitle =>
      isEnglish ? 'Barcode result' : 'Resultado del codigo';

  String get barcodeResultSubtitle => isEnglish
      ? 'Review the detected product before saving it.'
      : 'Revisa el producto detectado antes de guardarlo.';

  String get barcodeSourceLabel => isEnglish ? 'Source' : 'Fuente';

  String get barcodeCachedLabel =>
      isEnglish ? 'Cached in Myfit' : 'Cacheado en Myfit';

  String get barcodeFreshLookupLabel =>
      isEnglish ? 'Fresh lookup' : 'Busqueda nueva';

  String barcodeSourceValue(String? source) {
    switch (source) {
      case 'open_food_facts':
        return isEnglish ? 'Open Food Facts' : 'Open Food Facts';
      case 'usda':
        return isEnglish ? 'USDA FoodData Central' : 'USDA FoodData Central';
      case 'shared_barcode':
        return isEnglish ? 'Shared barcode' : 'Codigo compartido';
      default:
        return isEnglish ? 'Unknown source' : 'Fuente desconocida';
    }
  }

  String get barcodeScannerTitle =>
      isEnglish ? 'Scan barcode' : 'Escanear codigo';

  String get barcodeScannerHint => isEnglish
      ? 'Point the camera at the product barcode.'
      : 'Apunta la camara al codigo del producto.';

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

  String get sharedFoodInvalidResponse => isEnglish
      ? 'The shared catalog parser returned incomplete data.'
      : 'El analisis del catalogo compartido devolvio datos incompletos.';

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

  String get aiAnalysisInvalidResponse => isEnglish
      ? 'The AI response was incomplete. Try another photo or fill the fields manually.'
      : 'La respuesta AI vino incompleta. Prueba otra foto o completa los campos manualmente.';

  String aiConfidenceLabel(num confidence) => isEnglish
      ? 'Confidence: ${(confidence * 100).round()}%'
      : 'Confianza: ${(confidence * 100).round()}%';

  String get updateMealButton =>
      isEnglish ? 'Update meal' : 'Actualizar comida';

  String get editMealButton => isEnglish ? 'Edit' : 'Editar';

  String get editWorkoutTitle =>
      isEnglish ? 'Edit workout' : 'Editar entrenamiento';

  String get updateWorkoutButton =>
      isEnglish ? 'Update workout' : 'Actualizar entrenamiento';

  String get updateSetButton => isEnglish ? 'Update set' : 'Actualizar set';

  String get workoutUpdatedMessage =>
      isEnglish ? 'Workout updated.' : 'Entrenamiento actualizado.';

  String get editSetButton => isEnglish ? 'Edit set' : 'Editar set';

  String get editWorkoutButton =>
      isEnglish ? 'Edit workout' : 'Editar entrenamiento';

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

  String get carbs => isEnglish ? 'Carbs' : 'Carbohidratos';

  String get fat => isEnglish ? 'Fat' : 'Grasas';

  String get sugar => isEnglish ? 'Sugar' : 'Azucar';

  String get fiber => isEnglish ? 'Fiber' : 'Fibra';

  String get confidence => isEnglish ? 'Confidence' : 'Confianza';

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

  String get workoutProgressHint => isEnglish
      ? 'Track strength, body weight, calories, or all three together.'
      : 'Sigue fuerza, peso corporal, calorias o las tres cosas juntas.';

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

  String goalName(String goal) {
    switch (goal) {
      case 'lose_fat':
        return goalLoseFat;
      case 'gain_muscle':
        return goalGainMuscle;
      case 'maintain':
        return goalMaintain;
      case 'recomp':
        return goalRecomp;
      default:
        return goal;
    }
  }

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
