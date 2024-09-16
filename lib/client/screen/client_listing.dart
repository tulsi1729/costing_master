import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/auth/screens/login.dart';
import 'package:costing_master/client/notifier/client_notifier.dart';
import 'package:costing_master/common/extension/async_value.dart';
import 'package:costing_master/costing_listing/screens/costing_listing.dart';
import 'package:costing_master/model/client.dart';
import 'package:costing_master/model/user_model.dart';
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
    // Clean up the controller when the widget is disposed.
    clientNameController.dispose();
    super.dispose();
  }

  void logOut() {
    ref.read(authProvider.notifier).logOut();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // List<Client> clients = [
  //   Client(name: "Kashturi"),
  //   Client(name: 'Ram'),
  // ];
  @override
  Widget build(BuildContext context) {
    return ref.watch(clientsProvider).whenWidget(
          (clients) => Scaffold(
            appBar: AppBar(
              elevation: 4,
              title: const Text("Clients List"),
            ),
            drawer: Drawer(
              child: Column(
                children: [
                  TextButton(
                      onPressed: () => logOut(), child: const Text("Log Out")),
                ],
              ),
            ),
            body: ListView.builder(
              itemCount: clients.length,
              itemBuilder: ((context, index) {
                final client = clients[index];
                return GestureDetector(
                    child: Card(
                      child: ListTile(
                        title: Text(client.name),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CostingListing(
                            clientName: client.name,
                          ),
                        ),
                      );
                    });
              }),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        height: 200,
                        child: Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                              TextField(
                                controller: clientNameController,
                                decoration: const InputDecoration(
                                  labelText: "Name",
                                ),
                                autofocus: true,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    UserModel userModel =
                                        (await ref.read(authProvider.future))!;

                                    Client newClient = Client(
                                      name: clientNameController.text,
                                      createdBy: userModel.uid,
                                    );
                                    await ref
                                        .read(clientsProvider.notifier)
                                        .createClient(newClient);
                                    await ref
                                        .read(clientsProvider.notifier)
                                        .refresh()
                                        .then(
                                            (value) => Navigator.pop(context));

                                    debugPrint(
                                        " New Party  ${clientNameController.text}");
                                  },
                                  child: const Text("Save Party"),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              child: const Icon(Icons.add),
            ),
          ),
        );
  }
}
