import 'package:flutter/material.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  static AppStrings of(BuildContext context) {
    final strings = Localizations.of<AppStrings>(context, AppStrings);
    if (strings == null) {
      return AppStrings(const Locale('en'));
    }
    return strings;
  }

  static const Map<String, Map<String, String>> _values = {
      'en': {
        'nav_home': 'Home',
        'nav_about': 'About Us',
        'login_welcome': 'Welcome',
        'login_room_number': 'Room Number',
        'login_room_hint': 'e.g. 412',
        'login_last_name': 'Last Name',
        'login_last_name_hint': 'Name on reservation',
        'login_access_app': 'Access Guest App',
        'login_email': 'Email',
        'login_password': 'Password',
        'login_email_hint': 'guest@example.com',
        'login_forgot_password': 'Forgot Password?',
        'login_sign_in': 'Sign In',
        'login_no_account': "Don't have an account?",
        'login_or': 'or',
        'drawer_section_dining': 'DINING',
        'drawer_section_services': 'SERVICES & WELLNESS',
        'drawer_section_my_stay': 'MY STAY',
        'drawer_section_support': 'SUPPORT',
        'drawer_section_account': 'ACCOUNT',
        'drawer_item_restaurant_menu': 'Restaurant Menu',
        'drawer_item_table_reservation': 'Table Reservation',
        'drawer_item_hotel_services': 'Hotel Services',
        'drawer_item_spa_wellness': 'Spa & Wellness',
        'drawer_item_attractions_map': 'Attractions & Map',
        'drawer_item_tours_excursions': 'Tours & Excursions',
        'drawer_item_stay_summary': 'Stay Summary',
        'drawer_item_express_checkout': 'Express Checkout',
        'drawer_item_report_issue': 'Report Issue',
        'drawer_item_feedback_rating': 'Feedback & Rating',
        'drawer_item_emergency': 'Emergency',
        'drawer_item_profile_settings': 'Profile & Settings',
        'drawer_item_change_password': 'Change Password',
        'drawer_sign_out': 'Log Out',
        'dashboard_guest': 'Guest',
        'dashboard_good_morning': 'Good morning, {name}!',
        'dashboard_good_afternoon': 'Good afternoon, {name}!',
        'dashboard_good_evening': 'Good evening, {name}!',
        'dashboard_loading_weather': 'Loading weather...',
        'dashboard_no_weather': 'No weather data',
        'dashboard_about_us': 'About Us',
        'dashboard_about_us_subtitle': 'Welcome to La Pirogue Hotel',
        'dashboard_housekeeping': 'Housekeeping',
        'dashboard_order_dining': 'Order Dining',
        'dashboard_chat': 'Chat',
        'dashboard_eco_points': 'Eco Points',
        'dashboard_today_itinerary': "Today's Schedule",
        'dashboard_view_all': 'View All',
        'dashboard_no_events': 'No events scheduled for today.',
        'dashboard_featured_for_you': 'Featured for You',
        'dashboard_no_featured': 'No featured activities at the moment.',
        'forgot_password_title': 'Forgot Password',
        'forgot_password_header': 'Reset your password',
        'forgot_password_instruction': 'Enter your email address and we will send you a link to reset your password.',
        'forgot_password_placeholder': 'guest@example.com',
        'forgot_password_send': 'Send Reset Link',
        'forgot_password_sending': 'Sending...',
        'forgot_password_success': 'Reset link sent! Please check your email.',
        'forgot_password_back_to_login': 'Back to Login',
        'change_password_title': 'Change Password',
        'change_password_current': 'Current Password',
        'change_password_new': 'New Password',
        'change_password_confirm': 'Confirm New Password',
        'change_password_current_hint': 'Enter your current password',
        'change_password_new_hint': 'Enter your new password',
        'change_password_confirm_hint': 'Re-enter your new password',
        'change_password_saving': 'Updating...',
        'change_password_success': 'Password updated successfully.',
        'change_password_save': 'Update Password',
        'password_min_length': 'Password must be at least 8 characters',
        'password_mismatch': 'Passwords do not match',
        'itinerary_today_only': 'Only today\'s activities can be opened.',
        'itinerary_no_activities': 'No activities scheduled for today',
        'feedback_title': 'Feedback',
        'feedback_category': 'Category',
        'feedback_hotel': 'Hotel',
        'feedback_tour': 'Tour',
        'feedback_restaurant': 'Restaurant',
        'feedback_overall_rating': 'Overall Rating',
        'feedback_service_rating': 'Service Rating',
        'feedback_food_rating': 'Food Rating',
        'feedback_comments': 'Comments',
        'feedback_hint': 'Share your experience...',
        'feedback_submit': 'Submit Feedback',
        'feedback_history': 'Feedback History',
        'payment_title': 'Payment Summary',
        'payment_total_amount_due': 'Total Amount Due',
        'payment_instructions': 'Payment is made at the hotel reception. This screen shows a summary of all charges incurred during your stay.',
        'payment_recent_charges': 'Recent Charges',
        'language_english': 'English',
        'language_french': 'French',
      },
      'fr': {
        'nav_home': 'Accueil',
        'nav_about': 'A propos',
        'login_welcome': 'Bienvenue',
        'login_room_number': 'Numero de chambre',
        'login_room_hint': 'ex. 412',
        'login_last_name': 'Nom de famille',
        'login_last_name_hint': 'Nom de la reservation',
        'login_access_app': 'Acceder a l\'application',
        'login_email': 'Email',
        'login_password': 'Mot de passe',
        'login_email_hint': 'invite@exemple.com',
        'login_forgot_password': 'Mot de passe oublie ?',
        'login_sign_in': 'Se connecter',
        'login_no_account': 'Vous n\'avez pas de compte ?',
        'login_or': 'ou',
        'drawer_section_dining': 'RESTAURATION',
        'drawer_section_services': 'SERVICES ET BIEN-ETRE',
        'drawer_section_my_stay': 'MON SEJOUR',
        'drawer_section_support': 'ASSISTANCE',
        'drawer_section_account': 'COMPTE',
        'drawer_item_restaurant_menu': 'Menu du restaurant',
        'drawer_item_table_reservation': 'Reservation de table',
        'drawer_item_hotel_services': 'Services de l\'hotel',
        'drawer_item_spa_wellness': 'Spa et bien-etre',
        'drawer_item_attractions_map': 'Attractions et carte',
        'drawer_item_tours_excursions': 'Tours et excursions',
        'drawer_item_stay_summary': 'Resume du sejour',
        'drawer_item_express_checkout': 'Depart express',
        'drawer_item_report_issue': 'Signaler un probleme',
        'drawer_item_feedback_rating': 'Commentaires et notation',
        'drawer_item_emergency': 'Urgence',
        'drawer_item_profile_settings': 'Profil et parametres',
        'drawer_item_change_password': 'Modifier le mot de passe',
        'drawer_sign_out': 'Se deconnecter',
        'dashboard_guest': 'Client',
        'dashboard_good_morning': 'Bonjour, {name} !',
        'dashboard_good_afternoon': 'Bon apres-midi, {name} !',
        'dashboard_good_evening': 'Bonsoir, {name} !',
        'dashboard_loading_weather': 'Chargement de la meteo...',
        'dashboard_no_weather': 'Aucune donnee meteo',
        'dashboard_about_us': 'A propos de nous',
        'dashboard_about_us_subtitle': 'Bienvenue a l\'hotel La Pirogue',
        'dashboard_housekeeping': 'Menage',
        'dashboard_order_dining': 'Commander un repas',
        'dashboard_chat': 'Chat',
        'dashboard_eco_points': 'Eco-Points',
        'dashboard_today_itinerary': 'Programme du jour',
        'dashboard_view_all': 'Voir tout',
        'dashboard_no_events': 'Aucun evenement prevu aujourd\'hui',
        'dashboard_featured_for_you': 'Selection pour vous',
        'dashboard_no_featured': 'Aucun service en vedette',
        'forgot_password_title': 'Mot de passe oublie',
        'forgot_password_header': 'Reinitialiser votre mot de passe',
        'forgot_password_instruction': 'Entrez votre adresse email et nous vous enverrons un lien pour reinitialiser votre mot de passe.',
        'forgot_password_placeholder': 'invite@exemple.com',
        'forgot_password_send': 'Envoyer le lien',
        'forgot_password_sending': 'Envoi...',
        'forgot_password_success': 'Lien envoye ! Veuillez verifier votre email.',
        'forgot_password_back_to_login': 'Retour a la connexion',
        'change_password_title': 'Modifier le mot de passe',
        'change_password_current': 'Mot de passe actuel',
        'change_password_new': 'Nouveau mot de passe',
        'change_password_confirm': 'Confirmer le mot de passe',
        'change_password_current_hint': 'Entrez votre mot de passe actuel',
        'change_password_new_hint': 'Entrez votre nouveau mot de passe',
        'change_password_confirm_hint': 'Retapez votre nouveau mot de passe',
        'change_password_saving': 'Mise a jour...',
        'change_password_success': 'Mot de passe modifie avec succes.',
        'change_password_save': 'Mettre a jour',
        'password_min_length': 'Le mot de passe doit contenir au moins 8 caracteres',
        'password_mismatch': 'Les mots de passe ne correspondent pas',
        'itinerary_today_only':
            'Seules les activites du jour peuvent etre ouvertes.',
        'itinerary_no_activities': 'Aucune activite prevue pour aujourd\'hui',
        'feedback_title': 'Commentaires',
        'feedback_category': 'Categorie',
        'feedback_hotel': 'Hotel',
        'feedback_tour': 'Tour',
        'feedback_restaurant': 'Restaurant',
        'feedback_overall_rating': 'Note globale',
        'feedback_service_rating': 'Note service',
        'feedback_food_rating': 'Note nourriture',
        'feedback_comments': 'Commentaires',
        'feedback_hint': 'Partagez votre experience...',
        'feedback_submit': 'Envoyer les commentaires',
        'feedback_history': 'Historique des commentaires',
        'payment_title': 'Resume des paiements',
        'payment_total_amount_due': 'Montant total du',
        'payment_instructions': 'Le paiement est effectue a la reception de l\'hotel. Cet ecran montre un resume de tous les frais engages pendant votre sejour.',
        'payment_recent_charges': 'Frais recents',
      },
  };

  String t(String key, {Map<String, String> params = const {}}) {
    final lang = _values[locale.languageCode] ?? _values['en']!;
    var value = lang[key] ?? _values['en']![key] ?? key;

    for (final entry in params.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }

    return value;
  }
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en' || locale.languageCode == 'fr';

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}

extension AppStringsContext on BuildContext {
  AppStrings get l10n => AppStrings.of(this);
}
