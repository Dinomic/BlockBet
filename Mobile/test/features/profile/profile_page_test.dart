import 'package:bbmobile/core/result.dart';
import 'package:bbmobile/core/usecase/usecase.dart';
import 'package:bbmobile/features/profile/domain/entities/profile.dart';
import 'package:bbmobile/features/profile/domain/usecases/get_profile.dart';
import 'package:bbmobile/features/profile/domain/usecases/update_profile.dart';
import 'package:bbmobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:bbmobile/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetProfile extends Mock implements GetProfile {}

class MockUpdateProfile extends Mock implements UpdateProfile {}

void main() {
  late MockGetProfile getProfile;
  late MockUpdateProfile updateProfile;

  const profile = Profile(email: 'a@b.com', displayName: 'Ann', nationality: 'VN');

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const ProfileUpdate());
  });

  setUp(() {
    getProfile = MockGetProfile();
    updateProfile = MockUpdateProfile();
    when(() => getProfile(any())).thenAnswer((_) async => const Success(profile));
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider(
        create: (_) => ProfileBloc(getProfile: getProfile, updateProfile: updateProfile)
          ..add(const ProfileRequested()),
        child: const ProfilePage(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Finder saveButton() => find.widgetWithText(FilledButton, 'Save changes');

  testWidgets('shows loaded profile and keeps Save disabled until something changes', (tester) async {
    await pump(tester);

    expect(find.text('Ann'), findsWidgets);
    expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);

    await tester.enterText(find.widgetWithText(TextFormField, 'Ann'), 'Anna');
    await tester.pump();
    expect(tester.widget<FilledButton>(saveButton()).onPressed, isNotNull);
  });

  testWidgets('saving sends only changed fields and shows confirmation', (tester) async {
    when(() => updateProfile(any())).thenAnswer(
      (_) async => const Success(Profile(email: 'a@b.com', displayName: 'Anna', nationality: 'VN')),
    );
    await pump(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Ann'), 'Anna');
    await tester.pump();
    await tester.ensureVisible(saveButton());
    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    verify(() => updateProfile(const ProfileUpdate(displayName: 'Anna'))).called(1);
    expect(find.text('Profile updated.'), findsOneWidget);
    // Form is clean again after the save.
    expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);
  });

  testWidgets('invalid country code blocks saving', (tester) async {
    await pump(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'VN'), 'VNM');
    await tester.pump();
    await tester.ensureVisible(saveButton());
    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    expect(find.text('Use a 2-letter country code, e.g. VN.'), findsOneWidget);
    verifyNever(() => updateProfile(any()));
  });
}
