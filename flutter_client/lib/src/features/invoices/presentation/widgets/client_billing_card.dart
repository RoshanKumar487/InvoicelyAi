import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../../clients/data/client.dart';
import 'invoice_editor_components.dart';

class ClientBillingCard extends StatelessWidget {
  const ClientBillingCard({
    super.key,
    required this.clientNameController,
    required this.companyController,
    required this.emailController,
    required this.phoneController,
    required this.addressController,
    required this.taxIdController,
    required this.selectedClientId,
    required this.loadingClients,
    required this.showSuggestions,
    required this.clientLoadError,
    required this.matchingClients,
    required this.hasExactClientMatch,
    required this.canSaveClient,
    required this.onClearClient,
    required this.onApplyClient,
    required this.onSaveClient,
    required this.onNameChanged,
    required this.onNameTap,
  });

  final TextEditingController clientNameController;
  final TextEditingController companyController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController taxIdController;

  final int? selectedClientId;
  final bool loadingClients;
  final bool showSuggestions;
  final String? clientLoadError;
  final List<Client> matchingClients;
  final bool hasExactClientMatch;
  final bool canSaveClient;

  final VoidCallback onClearClient;
  final ValueChanged<Client> onApplyClient;
  final VoidCallback onSaveClient;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onNameTap;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Bill to',
      subtitle: 'Client contact details',
      children: [
        ResponsiveFields(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: clientNameController,
                  decoration: InputDecoration(
                    labelText: 'Client name',
                    prefixIcon: const Icon(Icons.person_outline),
                    suffixIcon: loadingClients
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : selectedClientId == null
                            ? null
                            : IconButton(
                                tooltip: 'Clear selected client',
                                onPressed: onClearClient,
                                icon: const Icon(Icons.close),
                              ),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'This field is required' : null,
                  onChanged: onNameChanged,
                  onTap: onNameTap,
                ),
                if (showSuggestions &&
                    selectedClientId == null &&
                    clientNameController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final client in matchingClients)
                          ListTile(
                            dense: true,
                            leading: const CircleAvatar(
                              radius: 17,
                              child: Icon(Icons.person_outline, size: 18),
                            ),
                            title: Text(
                              client.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              [
                                client.companyName,
                                client.email,
                                client.phone,
                              ].where((v) => v.isNotEmpty).join(' • '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => onApplyClient(client),
                          ),
                        if (matchingClients.isEmpty)
                          const ListTile(
                            dense: true,
                            leading: Icon(Icons.search_off_outlined),
                            title: Text('No saved client matches yet'),
                          ),
                        if (canSaveClient && !hasExactClientMatch)
                          ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.person_add_alt_1,
                              color: AppColors.blue,
                            ),
                            title: Text(
                              'Save "${clientNameController.text.trim()}" as a new client',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.blue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onTap: onSaveClient,
                          ),
                      ],
                    ),
                  ),
                ],
                if (clientLoadError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      clientLoadError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            appTextField(
              controller: companyController,
              label: 'Company',
              isRequired: false,
            ),
            appTextField(
              controller: emailController,
              label: 'Email address',
              isRequired: false,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isNotEmpty &&
                    !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            appTextField(
              controller: phoneController,
              label: 'Phone',
              isRequired: false,
              keyboardType: TextInputType.phone,
            ),
            appTextField(
              controller: taxIdController,
              label: 'Client tax ID',
              isRequired: false,
            ),
            appTextField(
              controller: addressController,
              label: 'Billing address',
              isRequired: false,
              maxLines: 2,
            ),
          ],
        ),
      ],
    );
  }
}
