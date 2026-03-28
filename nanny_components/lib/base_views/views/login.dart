import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/view_models/login_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/nanny_core.dart';
import 'package:nanny_components/styles/new_design_auth.dart';

class LoginView extends StatefulWidget {
  final String imgPath;
  final List<LoginPath> paths;

  const LoginView({
    super.key,
    required this.imgPath,
    required this.paths,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final LoginVM vm;

  @override
  void initState() {
    super.initState();
    vm = LoginVM(
      context: context,
      update: setState,
      availableRoleLogin: widget.paths,
      paths: widget.paths,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewDesignAuthTokens.neutral50,
      body: AdaptBuilder(
        builder: (context, size) {
          return SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  decoration: const BoxDecoration(
                    gradient: NewDesignAuthTokens.primaryGradient,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        splashRadius: 22,
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Image.asset(
                          widget.imgPath,
                          height: size.height * 0.2,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Вход в аккаунт",
                        style: NewDesignAuthTokens.titleXL.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Продолжайте управлять поездками, детьми и контрактами в АвтоНяня.",
                        style: NewDesignAuthTokens.bodyM.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    child: Column(
                      children: [
                        _AuthCard(
                          title: "Данные для входа",
                          subtitle:
                              "Введите номер телефона и пароль, которые использовали при регистрации.",
                          child: Column(
                            children: [
                              Form(
                                key: vm.phoneState,
                                child: NannyTextForm(
                                  isExpanded: true,
                                  labelText: "Телефон",
                                  hintText: "+7 (777) 777 77-77",
                                  formatters: [vm.phoneMask],
                                  keyType: TextInputType.number,
                                  validator: (text) {
                                    if (vm.phone.length < 11) {
                                      return "Введите номер телефона!";
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              Form(
                                key: vm.passwordState,
                                child: NannyPasswordForm(
                                  isExpanded: true,
                                  labelText: "Пароль",
                                  hintText: "••••••••",
                                  validator: (text) {
                                    if (vm.password.length < 8) {
                                      return "Пароль не менее 8 символов!";
                                    }
                                    return null;
                                  },
                                  onChanged: (v) => vm.password = v,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: vm.toPasswordReset,
                                  child: Text(
                                    "Забыли пароль?",
                                    style: NewDesignAuthTokens.bodyS.copyWith(
                                      color: NewDesignAuthTokens.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: vm.isLoading ? null : vm.tryLogin,
                                  style: const ButtonStyle(
                                    elevation: WidgetStatePropertyAll(0),
                                    backgroundColor: WidgetStatePropertyAll(
                                      NewDesignAuthTokens.primary,
                                    ),
                                    shadowColor: WidgetStatePropertyAll(
                                      Colors.transparent,
                                    ),
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            NewDesignAuthTokens.radiusLg,
                                      ),
                                    ),
                                  ),
                                  child: vm.isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          "Войти",
                                          style: NewDesignAuthTokens.bodyS
                                              .copyWith(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (vm.canOauth) ...[
                          const SizedBox(height: 16),
                          _AuthCard(
                            title: "Быстрый вход",
                            subtitle:
                                "Если аккаунт уже привязан, используйте привычный сервис.",
                            child: Row(
                              children: [
                                Expanded(
                                  child: _AuthSocialButton(
                                    assetPath:
                                        'packages/nanny_components/assets/images/yandex_auth.png',
                                    label: 'Yandex',
                                    onTap: vm.yandexAuth,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _AuthSocialButton(
                                    assetPath:
                                        'packages/nanny_components/assets/images/vk_auth.png',
                                    label: 'VK',
                                    onTap: vm.vkAuth,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _AuthSocialButton(
                                    assetPath:
                                        'packages/nanny_components/assets/images/telegram_auth.png',
                                    label: 'Telegram',
                                    onTap: vm.telegramAuth,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: NewDesignAuthTokens.primary100,
                            borderRadius: NewDesignAuthTokens.radiusMd,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.shield_outlined,
                                  color: NewDesignAuthTokens.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Ваши данные защищены. Для быстрого повторного входа после авторизации можно использовать PIN-код и биометрию.",
                                  style: NewDesignAuthTokens.bodyS.copyWith(
                                    color: NewDesignAuthTokens.primaryDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: NewDesignAuthTokens.radiusLg,
        border: Border.all(
          color: NewDesignAuthTokens.neutral200,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 15, 30, 0.06),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: NewDesignAuthTokens.titleM),
          const SizedBox(height: 6),
          Text(subtitle, style: NewDesignAuthTokens.bodyM),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _AuthSocialButton extends StatelessWidget {
  const _AuthSocialButton({
    required this.assetPath,
    required this.label,
    required this.onTap,
  });

  final String assetPath;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: NewDesignAuthTokens.radiusMd,
      child: Ink(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: NewDesignAuthTokens.radiusMd,
          border: Border.all(color: NewDesignAuthTokens.neutral200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(assetPath, width: 28, fit: BoxFit.contain),
            const SizedBox(height: 8),
            Text(
              label,
              style: NewDesignAuthTokens.captionS.copyWith(
                color: NewDesignAuthTokens.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
