import 'package:flutter/material.dart';
import 'package:network_monitor/pages/home_page.dart';

class BottomBar extends StatelessWidget {
  BottomBar({
    super.key,
    required this.selected_index,
    required this.onTabChanged,
  });

  final int selected_index;
  final ValueChanged<int> onTabChanged; // ✅ Callback для навігації

  // ✅ Іконки та назви для кожної вкладки
  final List<BottomNavItem> _navItems = [
    BottomNavItem(icon: Icons.home, label: 'Home'),
    BottomNavItem(icon: Icons.devices, label: 'Devices'),
    BottomNavItem(icon: Icons.assistant, label: 'Chat'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = selected_index == index;

              return GestureDetector(
                onTap: () => onTabChanged(index), // ✅ Навігація
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ Анімована іконка
                      AnimatedScale(
                        scale: isSelected ? 1.2 : 1.0,
                        duration: Duration(milliseconds: 200),
                        child: Icon(
                          item.icon,
                          color: isSelected ? Colors.blue : Colors.white70,
                          size: isSelected ? 28 : 24,
                        ),
                      ),
                      SizedBox(height: 4),
                      // ✅ Назва з анімацією
                      AnimatedDefaultTextStyle(
                        duration: Duration(milliseconds: 200),
                        style: TextStyle(
                          color: isSelected ? Colors.blue : Colors.white54,
                          fontSize: isSelected ? 11 : 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          letterSpacing: isSelected ? 0.5 : 0,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;

  BottomNavItem({required this.icon, required this.label});
}