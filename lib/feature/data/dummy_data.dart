import 'package:camp_nest/core/model/questionnaire.dart';
import 'package:camp_nest/core/model/room_listing.dart';
import 'package:camp_nest/core/model/roomate_matching.dart';

class DummyData {
  static List<RoomListingModel> get roomListings => [
    RoomListingModel(
      id: '1',
      title: 'Cozy Studio Near Campus',
      description:
          'Beautiful studio apartment just 5 minutes walk from university. Fully furnished with modern amenities.',
      price: 800.0,
      location: 'Downtown Campus Area',
      images: ['/placeholder.svg?height=200&width=300'],
      ownerId: 'owner1',
      ownerName: 'Sarah Johnson',
      amenities: ['WiFi', 'Laundry', 'Kitchen', 'Parking'],
      rules: ['No smoking', 'No pets', 'Quiet hours after 10 PM'],
      gender: 'female',
      availableFrom: DateTime.now().add(const Duration(days: 30)),
    ),
    RoomListingModel(
      id: '2',
      title: 'Shared Apartment - 2BR/2BA',
      description:
          'Looking for a roommate to share this spacious 2-bedroom apartment. Great location with easy access to public transport.',
      price: 600.0,
      location: 'University District',
      images: ['/placeholder.svg?height=200&width=300'],
      ownerId: 'owner2',
      ownerName: 'Mike Chen',
      amenities: ['WiFi', 'Gym', 'Pool', 'Study Room'],
      rules: ['No smoking', 'Clean common areas', 'Guests welcome'],
      gender: 'any',
      availableFrom: DateTime.now().add(const Duration(days: 15)),
    ),
    RoomListingModel(
      id: '3',
      title: 'Private Room in House',
      description:
          'Private bedroom in a 4-bedroom house with 3 other students. Friendly environment and great for studying.',
      price: 450.0,
      location: 'Residential Area',
      images: ['/placeholder.svg?height=200&width=300'],
      ownerId: 'owner3',
      ownerName: 'Emma Davis',
      amenities: ['WiFi', 'Kitchen', 'Backyard', 'Parking'],
      rules: [
        'No smoking',
        'Keep common areas clean',
        'No loud music after 11 PM',
      ],
      gender: 'female',
      availableFrom: DateTime.now().add(const Duration(days: 7)),
    ),
  ];

  static List<RoommateMatchModel> get roommateMatches => [
    RoommateMatchModel(
      id: '1',
      name: 'Alex Thompson',
      profileImage: '/placeholder.svg?height=100&width=100',
      age: 20,
      school: 'State University',
      gender: 'male',
      budget: 700.0,
      compatibilityScore: 95,
      commonInterests: ['Gaming', 'Movies', 'Cooking'],
      preferences: {
        'cleanliness': 'Very Clean',
        'socialLevel': 'Moderately Social',
        'sleepSchedule': 'Night Owl',
        'smoking': 'Non-smoker',
      },
    ),
    RoommateMatchModel(
      id: '2',
      name: 'Jessica Park',
      profileImage: '/placeholder.svg?height=100&width=100',
      age: 19,
      school: 'State University',
      gender: 'female',
      budget: 650.0,
      compatibilityScore: 88,
      commonInterests: ['Reading', 'Yoga', 'Coffee'],
      preferences: {
        'cleanliness': 'Clean',
        'socialLevel': 'Social',
        'sleepSchedule': 'Early Bird',
        'smoking': 'Non-smoker',
      },
    ),
    RoommateMatchModel(
      id: '3',
      name: 'David Kim',
      profileImage: '/placeholder.svg?height=100&width=100',
      age: 21,
      school: 'State University',
      gender: 'male',
      budget: 800.0,
      compatibilityScore: 82,
      commonInterests: ['Sports', 'Music', 'Travel'],
      preferences: {
        'cleanliness': 'Moderately Clean',
        'socialLevel': 'Very Social',
        'sleepSchedule': 'Flexible',
        'smoking': 'Occasional',
      },
    ),
  ];

  static List<QuestionnaireQuestion> get questionnaireQuestions => [
    QuestionnaireQuestion(
      id: '1',
      question: 'What is your monthly budget for housing?',
      options: [
        'Under \$400',
        '\$400-600',
        '\$600-800',
        '\$800-1000',
        'Over \$1000',
      ],
      type: 'single',
    ),
    QuestionnaireQuestion(
      id: '2',
      question: 'How would you describe your cleanliness level?',
      options: [
        'Very messy',
        'Somewhat messy',
        'Average',
        'Clean',
        'Very clean',
      ],
      type: 'single',
    ),
    QuestionnaireQuestion(
      id: '3',
      question: 'What is your typical sleep schedule?',
      options: [
        'Early bird (sleep before 10 PM)',
        'Normal (10 PM - 12 AM)',
        'Night owl (after 12 AM)',
        'Irregular/Flexible',
      ],
      type: 'single',
    ),
    QuestionnaireQuestion(
      id: '4',
      question: 'How social are you?',
      options: [
        'Very introverted',
        'Somewhat introverted',
        'Balanced',
        'Somewhat social',
        'Very social',
      ],
      type: 'single',
    ),
    QuestionnaireQuestion(
      id: '5',
      question: 'Do you smoke or drink?',
      options: [
        'Neither',
        'Drink occasionally',
        'Smoke occasionally',
        'Both occasionally',
        'Regularly',
      ],
      type: 'single',
    ),
    QuestionnaireQuestion(
      id: '6',
      question: 'How often do you have guests over?',
      options: ['Never', 'Rarely', 'Sometimes', 'Often', 'Very often'],
      type: 'single',
    ),
    QuestionnaireQuestion(
      id: '7',
      question: 'What are your study habits?',
      options: [
        'Study at home quietly',
        'Study at home with music',
        'Study at library',
        'Study in groups',
        'Flexible',
      ],
      type: 'multiple',
    ),
    QuestionnaireQuestion(
      id: '8',
      question: 'How do you prefer to split household chores?',
      options: [
        'Strict schedule',
        'Flexible rotation',
        'Based on availability',
        'Each person their own mess',
        'Hire cleaning service',
      ],
      type: 'single',
    ),
    QuestionnaireQuestion(
      id: '9',
      question: 'What are your hobbies/interests?',
      options: [
        'Gaming',
        'Sports',
        'Reading',
        'Movies/TV',
        'Cooking',
        'Music',
        'Art',
        'Travel',
      ],
      type: 'multiple',
    ),
    QuestionnaireQuestion(
      id: '10',
      question: 'How important is it to be friends with your roommate?',
      options: [
        'Not important - just respectful',
        'Somewhat important',
        'Important',
        'Very important - want to be close friends',
      ],
      type: 'single',
    ),
  ];
}
