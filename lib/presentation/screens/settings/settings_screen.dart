import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../logic/auth_bloc/auth_bloc.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/custom_toast.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _defaultProfileImageUrl =
      'https://res.cloudinary.com/dwsgqffmj/image/upload/v1779099891/expense-tracker/profiles/xmv6cembzeqxgu3cicwg.jpg';
  bool _isUploadingImage = false;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCachedProfileImage();
  }

  Future<void> _loadCachedProfileImage() async {
    final repo = context.read<AuthRepository>();
    final url = await repo.getCachedProfileImageUrl();
    if (mounted) {
      setState(() => _profileImageUrl = _normalizeImageUrl(url));
    }
  }

  String _getInitials(String email) {
    if (email.isEmpty) return '?';
    final name = email.split('@').first;
    if (name.length >= 2) return name.substring(0, 2).toUpperCase();
    return name.toUpperCase();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked == null) return;

      setState(() => _isUploadingImage = true);

      final repo = context.read<AuthRepository>();
      final imageUrl = await repo.uploadProfileImage(File(picked.path));

      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          if (imageUrl.isNotEmpty) {
            _profileImageUrl = _normalizeImageUrl(imageUrl);
          }
        });
        CustomToast.show(context, message: 'Profile photo updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        CustomToast.show(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  String? _normalizeImageUrl(String? url) {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return _defaultProfileImageUrl;
    }
    return trimmed;
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to log out of your account?',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            child: Text(
              'Log Out',
              style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            CustomToast.show(context, message: 'Logged out successfully.');
            context.go('/login');
          }
        },
        builder: (context, state) {
          String userEmail = '';
          String userId = '';

          if (state is AuthAuthenticated) {
            userEmail = state.user.email;
            userId = state.user.id;
          }

          final initials = _getInitials(userEmail);
          final username = userEmail.isNotEmpty ? userEmail.split('@').first : 'User';

          return CustomScrollView(
            slivers: [
              // ── Gradient SliverAppBar with tappable avatar ──
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppTheme.primary,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Tappable Avatar ──
                            GestureDetector(
                              onTap: _isUploadingImage ? null : _pickAndUploadImage,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 76,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                                    ),
                                    child: _isUploadingImage
                                        ? const Center(
                                            child: SizedBox(
                                              width: 28,
                                              height: 28,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            ),
                                          )
                                        : _buildProfileAvatar(initials),
                                  ),
                                  // Camera badge
                                  if (!_isUploadingImage)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.15),
                                              blurRadius: 4,
                                            )
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 14,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              username,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userEmail.isEmpty ? 'Not logged in' : userEmail,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap photo to change',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.6),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  'Account',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),

              // ── Content ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Account Details Card ──
                      _sectionLabel('Account Details'),
                      const SizedBox(height: 12),
                      _infoCard(children: [
                        _infoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: userEmail.isEmpty ? '—' : userEmail,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _infoRow(
                          icon: Icons.account_circle_outlined,
                          label: 'Username',
                          value: username,
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _infoRow(
                          icon: Icons.badge_outlined,
                          label: 'User ID',
                          value: userId.isEmpty
                              ? '—'
                              : userId.length > 22
                                  ? '${userId.substring(0, 22)}…'
                                  : userId,
                        ),
                      ]),
                      const SizedBox(height: 32),

                      // ── App Info Card ──
                      _sectionLabel('App Info'),
                      const SizedBox(height: 12),
                      _infoCard(children: [
                        _infoRow(
                          icon: Icons.receipt_long_rounded,
                          label: 'App Name',
                          value: 'Expense Tracker',
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _infoRow(
                          icon: Icons.info_outline_rounded,
                          label: 'Version',
                          value: '1.0.0',
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _infoRow(
                          icon: Icons.currency_rupee_rounded,
                          label: 'Currency',
                          value: 'Indian Rupees (₹)',
                        ),
                      ]),
                      const SizedBox(height: 48),

                      // ── Logout Button ──
                      GestureDetector(
                        onTap: () => _confirmLogout(context),
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Log Out',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildProfileAvatar(String initials) {
    final imageUrl = _normalizeImageUrl(_profileImageUrl);
    if (imageUrl == null) {
      return _buildInitialsAvatar(initials);
    }

    return ClipOval(
      child: SizedBox.expand(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          fadeInDuration: Duration.zero,
          placeholder: (_, __) => _buildInitialsAvatar(initials),
          errorWidget: (_, __, ___) => _buildInitialsAvatar(initials),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.outfit(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
