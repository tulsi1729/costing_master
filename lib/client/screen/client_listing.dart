import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/auth/screens/login.dart';
import 'package:costing_master/client/notifier/client_notifier.dart';
import 'package:costing_master/common/extension/async_value.dart';
import 'package:costing_master/costings/notifier/selected_client_notifier.dart';
import 'package:costing_master/costings/screens/costing_listing.dart';
import 'package:costing_master/model/client.dart';
import 'package:costing_master/model/user_model.dart';
import 'package:costing_master/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClientListing extends ConsumerStatefulWidget {
  const ClientListing({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreateNewClientState();
}

class _CreateNewClientState extends ConsumerState<ClientListing> {
  final clientNameController = TextEditingController();

  @override
  void dispose() {
    clientNameController.dispose();
    super.dispose();
  }

  void logOut() {
    ref.read(authProvider.notifier).logOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ref.watch(clientsProvider).whenWidget(
          (clients) => Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              elevation: 1.5,
              title: const Text(
                "Clients",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              centerTitle: true,
            ),
            drawer: Drawer(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.primaryContainer,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor:
                              colorScheme.onPrimary.withOpacity(0.1),
                          child: Icon(
                            Icons.account_circle,
                            size: 72,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Costing Master',
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => logOut(),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text(
                          "Log Out",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: colorScheme.primary.withOpacity(0.5),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            body: clients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 90,
                          color: colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Clients Yet',
                          style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.75),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add your first client',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: clients.length,
                    itemBuilder: ((context, index) {
                      final client = clients[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          child: Card(
                            elevation: 3,
                            shadowColor:
                                colorScheme.shadow.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              leading: CircleAvatar(
                                radius: 26,
                                backgroundColor:
                                    colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.person,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              title: Text(
                                client.name,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: colorScheme.onSurface.withOpacity(0.4),
                                size: 28,
                              ),
                            ),
                          ),
                          onTap: () {
                            ref
                                .read(selectedClientProvider.notifier)
                                .set(client);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CostingListing(
                                  clientName: client.name,
                                  clientGuid: client.guid,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                clientNameController.clear();
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (BuildContext context) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 50,
                                height: 5,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color:
                                      colorScheme.onSurface.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Add New Client',
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => Navigator.pop(context),
                                  style: IconButton.styleFrom(
                                    backgroundColor: colorScheme
                                        .secondaryContainer
                                        .withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: clientNameController,
                              decoration: InputDecoration(
                                labelText: "Client Name",
                                hintText: "Enter client name",
                                prefixIcon:
                                    const Icon(Icons.person_outline_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: colorScheme
                                    .secondaryContainer
                                    .withOpacity(0.25),
                              ),
                              autofocus: true,
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (clientNameController.text
                                      .trim()
                                      .isEmpty) {
                                    return;
                                  }
                                  UserModel userModel =
                                      (await ref.read(authProvider.future))!;
                                  Client newClient = Client(
                                    name:
                                        clientNameController.text.trim(),
                                    createdBy: userModel.uid,
                                  );
                                  await ref
                                      .read(clientsProvider.notifier)
                                      .createClient(newClient);
                                  await ref
                                      .read(clientsProvider.notifier)
                                      .refresh();
                                  clientNameController.clear();
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.save_rounded),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                                label: const Text(
                                  "Save Client",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Client',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        );
  }
}
