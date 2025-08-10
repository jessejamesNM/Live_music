import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AgeTermsScreen extends HookWidget {
  final GoRouter goRouter;

  AgeTermsScreen({required this.goRouter});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);
    final selectedDate = useState<DateTime?>(null);
    final acceptTerms = useState(false);
    final acceptPrivacy = useState(false);
    final isValid = useState(false);

    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    int calculateAge(DateTime birthDate) {
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    }

    useEffect(() {
      void validate() {
        final age =
            selectedDate.value != null ? calculateAge(selectedDate.value!) : 0;
        isValid.value = age >= 13 && acceptTerms.value && acceptPrivacy.value;
      }

      validate();
      return null;
    }, [selectedDate.value, acceptTerms.value, acceptPrivacy.value]);

    void _showDialog(String title, String content) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              backgroundColor: colorScheme[AppStrings.primaryColor],
              title: Text(
                title,
                style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
              ),
              content: SingleChildScrollView(
                child: Text(
                  content,
                  style: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cerrar',
                    style: TextStyle(
                      color: colorScheme[AppStrings.essentialColor],
                    ),
                  ),
                ),
              ],
            ),
      );
    }

    Future<void> _onContinue() async {
      final user = auth.currentUser;
      if (user == null || selectedDate.value == null) return;

      final age = calculateAge(selectedDate.value!);

      await firestore.collection('users').doc(user.uid).set({
        'birthDate': selectedDate.value!.toIso8601String(),
        'age': age,
        'acceptedTerms': acceptTerms.value,
        'acceptedPrivacy': acceptPrivacy.value,
      }, SetOptions(merge: true));

      final doc = await firestore.collection('users').doc(user.uid).get();
      final userType = doc.data()?['userType'];

      if ([
        'artist',
        'furniture',
        'entertainment',
        'bakery',
        'place',
        'decoration',
        'decorator',
      ].contains(userType)) {
        goRouter.go(AppStrings.groupNameScreenRoute);
      } else {
        goRouter.go(AppStrings.usernameScreen);
      }
    }

    void _showDateWheelPicker(BuildContext context) {
      final now = DateTime.now();
      final years = List.generate(100, (i) => now.year - i);
      final months = List.generate(12, (i) => i + 1);
      final days = List.generate(31, (i) => i + 1);

      int selDay = selectedDate.value?.day ?? 1;
      int selMonth = selectedDate.value?.month ?? 1;
      int selYear = selectedDate.value?.year ?? now.year - 13;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: colorScheme[AppStrings.primaryColor],
        builder: (_) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 300,
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          backgroundColor: colorScheme[AppStrings.primaryColor],
                          scrollController: FixedExtentScrollController(
                            initialItem: selDay - 1,
                          ),
                          itemExtent: 32,
                          onSelectedItemChanged: (i) => selDay = days[i],
                          children:
                              days
                                  .map(
                                    (d) => Center(
                                      child: Text(
                                        '$d',
                                        style: TextStyle(
                                          color:
                                              colorScheme[AppStrings
                                                  .secondaryColor],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          backgroundColor: colorScheme[AppStrings.primaryColor],
                          scrollController: FixedExtentScrollController(
                            initialItem: selMonth - 1,
                          ),
                          itemExtent: 32,
                          onSelectedItemChanged: (i) => selMonth = months[i],
                          children:
                              months
                                  .map(
                                    (m) => Center(
                                      child: Text(
                                        '$m',
                                        style: TextStyle(
                                          color:
                                              colorScheme[AppStrings
                                                  .secondaryColor],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          backgroundColor: colorScheme[AppStrings.primaryColor],
                          scrollController: FixedExtentScrollController(
                            initialItem: years.indexOf(selYear),
                          ),
                          itemExtent: 32,
                          onSelectedItemChanged: (i) => selYear = years[i],
                          children:
                              years
                                  .map(
                                    (y) => Center(
                                      child: Text(
                                        '$y',
                                        style: TextStyle(
                                          color:
                                              colorScheme[AppStrings
                                                  .secondaryColor],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  color: colorScheme[AppStrings.primaryColor],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        try {
                          selectedDate.value = DateTime(
                            selYear,
                            selMonth,
                            selDay,
                          );
                        } catch (_) {
                          selectedDate.value = DateTime(selYear, selMonth, 1);
                        }
                      },
                      child: Text(
                        'Aceptar',
                        style: TextStyle(
                          color: colorScheme[AppStrings.essentialColor],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor],
      appBar: AppBar(
        title: Text(
          'Fecha de nacimiento y Términos',
          style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
        ),
        backgroundColor: colorScheme[AppStrings.primaryColor],
        iconTheme: IconThemeData(color: colorScheme[AppStrings.essentialColor]),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: colorScheme[AppStrings.primarySecondColor],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(
                  selectedDate.value == null
                      ? 'Selecciona tu fecha de nacimiento'
                      : 'Fecha de nacimiento: ${DateFormat('dd/MM/yyyy').format(selectedDate.value!)}',
                  style: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
                trailing: Icon(
                  Icons.calendar_today,
                  color: colorScheme[AppStrings.essentialColor],
                ),
                onTap: () => _showDateWheelPicker(context),
              ),
            ),
            CheckboxListTile(
              activeColor: colorScheme[AppStrings.essentialColor],
              value: acceptTerms.value,
              onChanged: (v) => acceptTerms.value = v ?? false,
              title: Row(
                children: [
                  Text(
                    'Acepto los ',
                    style: TextStyle(
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                  ),
                  GestureDetector(
                    onTap:
                        () => _showDialog(
                          'Términos y Condiciones',
                          AppStrings.termsText,
                        ),
                    child: Text(
                      'términos',
                      style: TextStyle(
                        color: colorScheme[AppStrings.essentialColor],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CheckboxListTile(
              activeColor: colorScheme[AppStrings.essentialColor],
              value: acceptPrivacy.value,
              onChanged: (v) => acceptPrivacy.value = v ?? false,
              title: Row(
                children: [
                  Text(
                    'Acepto la ',
                    style: TextStyle(
                      color: colorScheme[AppStrings.secondaryColor],
                    ),
                  ),
                  GestureDetector(
                    onTap:
                        () => _showDialog(
                          'Política de Privacidad',
                          AppStrings.privacyText,
                        ),
                    child: Text(
                      'política',
                      style: TextStyle(
                        color: colorScheme[AppStrings.essentialColor],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme[AppStrings.essentialColor],
                minimumSize: Size(double.infinity, 48),
              ),
              onPressed: isValid.value ? _onContinue : null,
              child: Text(
                'Continuar',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
