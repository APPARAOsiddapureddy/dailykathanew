import 'package:flutter/material.dart';

import '../../app/theme.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.message = 'Loading Daily Katha...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.saffron),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.saffron),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (action != null) ...[const SizedBox(height: 22), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'Could not load content',
      message: message,
      action: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Try Again'),
      ),
    );
  }
}

class KathaNetworkImage extends StatelessWidget {
  const KathaNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackAsset = 'assets/mahabharatam-cover.png',
  });

  final String? url;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    final image = url == null || url!.isEmpty
        ? Image.asset(fallbackAsset, fit: fit)
        : Image.network(
            url!,
            fit: fit,
            loadingBuilder: (context, child, event) {
              if (event == null) return child;
              return const ColoredBox(
                color: Color(0xFFFFEBC7),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.saffron,
                    strokeWidth: 2.5,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(fallbackAsset, fit: fit);
            },
          );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}
