// ignore_for_file: use_build_context_synchronously

import 'package:app_links/app_links.dart';
// ignore: depend_on_referenced_packages
import 'package:nanny_client/routing/client_entity_router.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/nanny_core.dart';

class AppLinksHandler {
  static late AppLinks links;
  static void initAppLinkHandler() {
    links = AppLinks();
    links.uriLinkStream.listen((uri) async {
      final params = uri.queryParameters;
      final currentContext = NannyGlobals.navKey.currentContext;

      Logger().i("Got app link:\n${uri.toString()}");
      // NannyDialogs.showMessageBox(NannyGlobals.currentContext, "CurrentUrl", uri.toString());
      if (params.containsKey("ref")) {
        if (currentContext == null) {
          return;
        }
        final success =
            await NannyUser.oauthLogin(params["ref"]!, currentContext);
        if (!success && currentContext.mounted) {
          NannyDialogs.showMessageBox(
            currentContext,
            "Ошибка!",
            "У вас нет аккаунта, привязанного к этому приложению!",
          );
        }
        return;
      }

      if (currentContext == null || !currentContext.mounted) {
        return;
      }
      final handled = await ClientEntityRouter.handleUri(
        currentContext,
        uri,
      );
      if (!handled) {
        Logger().w("Unhandled client app link: ${uri.toString()}");
      }
    });
  }
}
