import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';

/// شیت قوانین استفاده و حریم خصوصی — قابل فراخوانی در صفحهٔ ورود و پروفایل
/// برای رعایت الزامات کافه‌بازار، مایکت و گوگل‌پلی.
class PrivacyPolicySheet extends StatelessWidget {
  const PrivacyPolicySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTok.background(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const PrivacyPolicySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFa = AppLang.I.isFa;
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);
    final card = AppTok.card(context);
    final border = AppTok.border(context);

    final sections = isFa ? _faSections : _enSections;

    return Directionality(
      textDirection: AppLang.I.direction,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: textSoft.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.privacy_tip_rounded,
                        color: accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFa
                                ? 'حریم خصوصی و قوانین استفاده'
                                : 'Privacy Policy & Terms of Use',
                            style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isFa
                                ? 'برنامهٔ برنامه‌ریزی عروسی Wedding Time'
                                : 'Wedding Time Planner Application',
                            style: TextStyle(
                              color: textSoft,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: textSoft),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: border),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  itemCount: sections.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = sections[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(item.icon, color: accent, size: 19),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    color: text,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.body,
                            style: TextStyle(
                              color: textSoft,
                              fontSize: 12.8,
                              height: 1.65,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PolicySection {
  const _PolicySection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

const List<_PolicySection> _faSections = [
  _PolicySection(
    icon: Icons.verified_user_rounded,
    title: '۱. اطلاعاتی که دریافت می‌کنیم',
    body:
        'برای ایجاد حساب کاربری و همگام‌سازی اطلاعات مراسم بین عروس و داماد، تنها آدرس ایمیل، نام نمایشی و اطلاعات مراسمی که خودتان وارد می‌کنید (تاریخ عروسی، چک‌لیست‌ها، بودجه، لیست مهمانان و رویدادهای تقویم) ذخیره می‌شود.',
  ),
  _PolicySection(
    icon: Icons.photo_camera_back_rounded,
    title: '۲. دسترسی به دوربین و گالری تصاویر',
    body:
        'دسترسی به دوربین و گالری صرفاً زمانی استفاده می‌شود که خودتان بخواهید تصویر پروفایل، عکس کارت دعوت یا عکس‌های یادگاری گالری مراسم را انتخاب یا ثبت کنید. هیچ عکسی بدون انتخاب مستقیم شما خوانده یا ارسال نمی‌شود.',
  ),
  _PolicySection(
    icon: Icons.lock_rounded,
    title: '۳. امنیت و نگهداری داده‌ها',
    body:
        'تمامی ارتباطات برنامه از طریق پروتکل امن HTTPS رمزنگاری می‌شود. اطلاعات مراسم شما خصوصی است و فقط برای شما و همسرتان (در صورت اشتراک کد دعوت پارتنر) قابل مشاهده و ویرایش است.',
  ),
  _PolicySection(
    icon: Icons.share_rounded,
    title: '۴. عدم اشتراک‌گذاری با اشخاص ثالث',
    body:
        'ما اطلاعات شخصی، ایمیل، لیست مهمانان یا تصاویر شما را به هیچ شرکت تبلیغاتی یا شخص ثالثی نمی‌فروشیم و واگذار نمی‌کنیم.',
  ),
  _PolicySection(
    icon: Icons.delete_forever_rounded,
    title: '۵. حق حذف کامل حساب کاربری و اطلاعات',
    body:
        'شما در هر زمان می‌توانید از بخش «پروفایل ← حذف حساب کاربری» حساب خود و اطلاعات مرتبط با آن را به‌طور دائمی حذف کنید.',
  ),
  _PolicySection(
    icon: Icons.support_agent_rounded,
    title: '۶. پشتیبانی و ارتباط با ما',
    body:
        'در صورت داشتن هرگونه سؤال یا درخواست دربارهٔ حریم خصوصی و حساب کاربری، می‌توانید از بخش «پشتیبانی» داخل برنامه یا ایمیل پشتیبانی با ما در ارتباط باشید.',
  ),
];

const List<_PolicySection> _enSections = [
  _PolicySection(
    icon: Icons.verified_user_rounded,
    title: '1. Information We Collect',
    body:
        'To create your account and sync wedding data between partners, we only store your email address, display name, and the wedding planning details you enter (wedding date, checklists, budget, guest list, and calendar events).',
  ),
  _PolicySection(
    icon: Icons.photo_camera_back_rounded,
    title: '2. Camera & Photo Gallery Permissions',
    body:
        'Camera and photo library permissions are used strictly when you choose to upload a profile picture, invitation photo, or wedding gallery memory. No media is accessed without your explicit action.',
  ),
  _PolicySection(
    icon: Icons.lock_rounded,
    title: '3. Data Security',
    body:
        'All network communication is encrypted via HTTPS. Your wedding workspace is private and accessible only to you and your partner (when linked via partner invite code).',
  ),
  _PolicySection(
    icon: Icons.share_rounded,
    title: '4. No Third-Party Selling',
    body:
        'We never sell, rent, or trade your personal information, guest list, or photos to advertisers or third parties.',
  ),
  _PolicySection(
    icon: Icons.delete_forever_rounded,
    title: '5. Account & Data Deletion',
    body:
        'You can permanently delete your account and associated profile data at any time directly inside the app via "Profile → Delete Account".',
  ),
  _PolicySection(
    icon: Icons.support_agent_rounded,
    title: '6. Contact & Support',
    body:
        'For any questions regarding privacy or your account, please contact us through the in-app Support Ticket section.',
  ),
];
