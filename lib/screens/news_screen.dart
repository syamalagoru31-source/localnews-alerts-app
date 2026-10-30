import 'package:flutter/material.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      // ---------------------------------------------------------
      // APP BAR
      // ---------------------------------------------------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Latest News',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),

      // ---------------------------------------------------------
      // NEWS LIST
      // ---------------------------------------------------------
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =====================================================
          // 1. TRAFFIC NEWS
          // =====================================================
          _newsCard(
            context,
            'City traffic restrictions announced',
            'Traffic',
            '10 minutes ago',
            Icons.traffic_rounded,

            '''
Traffic restrictions have been announced in several areas of the city due to ongoing road maintenance and increased vehicle movement.

Commuters are advised to use alternative routes and allow additional travel time during peak hours. Traffic police have requested residents to follow road signs and instructions given by traffic officials.

The restrictions are expected to remain in effect until the road work is completed. Residents are encouraged to check local traffic updates before starting their journey.
''',
          ),

          // =====================================================
          // 2. LOCAL DEVELOPMENT NEWS
          // =====================================================
          _newsCard(
            context,
            'New development project announced',
            'Local',
            '30 minutes ago',
            Icons.location_city_rounded,

            '''
A new development project has been announced in the local area with the aim of improving public facilities and infrastructure.

The project includes improvements to roads, public spaces, drainage facilities and other basic services. Local authorities are expected to begin the initial work shortly.

Residents will be informed about major changes and temporary restrictions as the project progresses. The development is expected to improve connectivity and facilities for people living in nearby areas.
''',
          ),

          // =====================================================
          // 3. WEATHER NEWS
          // =====================================================
          _newsCard(
            context,
            'Heavy rain expected in the city',
            'Weather',
            '1 hour ago',
            Icons.cloud_rounded,

            '''
Heavy rainfall is expected in several areas of the city. Weather conditions may change throughout the day, with periods of moderate to heavy rain possible.

Residents are advised to stay updated with local weather information and take necessary precautions while travelling. People should be careful around waterlogged roads and areas with poor drainage.

Commuters are advised to allow extra travel time and avoid unnecessary travel during periods of heavy rainfall.
''',
          ),

          // =====================================================
          // 4. COMMUNITY EVENT
          // =====================================================
          _newsCard(
            context,
            'Local community event this weekend',
            'Events',
            '2 hours ago',
            Icons.event_rounded,

            '''
A local community event is scheduled to take place this weekend. The event will include activities for residents and members of the local community.

Several programs and activities are planned throughout the day. Local organizations and community members are expected to participate in the event.

Residents interested in attending can check the official event information for the exact venue, timings and other details.
''',
          ),

          // =====================================================
          // 5. PUBLIC SAFETY ALERT
          // =====================================================
          _newsCard(
            context,
            'Important public safety alert',
            'Emergency',
            '3 hours ago',
            Icons.warning_amber_rounded,

            '''
An important public safety alert has been issued for residents in the local area.

Residents are advised to remain aware of their surroundings and follow instructions provided by local authorities. People should avoid restricted areas and check official announcements for further information.

If travelling through affected areas, residents are advised to follow safety instructions and use alternative routes whenever necessary.
''',
          ),
        ],
      ),
    );
  }

  // =============================================================
  // NEWS CARD
  // =============================================================

  Widget _newsCard(
    BuildContext context,
    String title,
    String category,
    String time,
    IconData icon,
    String description,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),

      child: ListTile(
        contentPadding: const EdgeInsets.all(15),

        // -------------------------------------------------------
        // ICON
        // -------------------------------------------------------
        leading: Container(
          width: 55,
          height: 55,

          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(14),
          ),

          child: Icon(icon, color: Colors.blue.shade700, size: 28),
        ),

        // -------------------------------------------------------
        // TITLE
        // -------------------------------------------------------
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,

          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),

        // -------------------------------------------------------
        // CATEGORY + TIME + MATTER
        // -------------------------------------------------------
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 7),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // Category and time
              Text(
                '$category • $time',

                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),

              const SizedBox(height: 7),

              // Short news matter
              Text(
                description.trim(),

                maxLines: 3,
                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        // -------------------------------------------------------
        // ARROW
        // -------------------------------------------------------
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),

        // -------------------------------------------------------
        // OPEN FULL NEWS
        // -------------------------------------------------------
        onTap: () {
          Navigator.push(
            context,

            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(
                title: title,
                category: category,
                time: time,
                icon: icon,
                description: description,
              ),
            ),
          );
        },
      ),
    );
  }
}

// =================================================================
// NEWS DETAILS SCREEN
// =================================================================

class NewsDetailScreen extends StatelessWidget {
  final String title;
  final String category;
  final String time;
  final IconData icon;
  final String description;

  const NewsDetailScreen({
    super.key,
    required this.title,
    required this.category,
    required this.time,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      // -----------------------------------------------------------
      // APP BAR
      // -----------------------------------------------------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'News Details',

          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),

      // -----------------------------------------------------------
      // DETAILS BODY
      // -----------------------------------------------------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // =====================================================
            // LARGE ICON
            // =====================================================
            Center(
              child: Container(
                width: 90,
                height: 90,

                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(25),
                ),

                child: Icon(icon, color: Colors.blue.shade700, size: 48),
              ),
            ),

            const SizedBox(height: 25),

            // =====================================================
            // CATEGORY
            // =====================================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Text(
                category,

                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 15),

            // =====================================================
            // TITLE
            // =====================================================
            Text(
              title,

              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 10),

            // =====================================================
            // TIME
            // =====================================================
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 17,
                  color: Colors.grey.shade600,
                ),

                const SizedBox(width: 6),

                Text(
                  time,

                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // =====================================================
            // FULL NEWS MATTER
            // =====================================================
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    'About this news',

                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    description.trim(),

                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =====================================================
            // LOCATION
            // =====================================================
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),

              child: Row(
                children: [
                  // Location icon
                  Container(
                    padding: const EdgeInsets.all(10),

                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Icon(
                      Icons.location_on_rounded,
                      color: Colors.blue.shade700,
                    ),
                  ),

                  const SizedBox(width: 15),

                  // Location text
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        'Location',

                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        'Local City Area',

                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =====================================================
            // IMPORTANT INFORMATION
            // =====================================================
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(18),
              ),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.blue.shade700),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Text(
                      'Please follow official announcements and local authority instructions for the latest information and updates.',
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
