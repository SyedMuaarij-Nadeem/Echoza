
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AvatarPicker extends StatefulWidget {
  final Function(String) onAvatarSelected;
  final String? initialAvatar;

  const AvatarPicker({
    Key? key,
    required this.onAvatarSelected,
    this.initialAvatar,
  }) : super(key: key);

  @override
  _AvatarPickerState createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  String? _selectedAvatar;
  final List<String> _avatars = [
    'avatar1', 'avatar2', 'avatar3',
    'avatar4', 'avatar5', 'avatar6',
    'avatar7', 'avatar8', 'avatar9',
    'avatar10', 'avatar11', 'avatar12',
  ];

  @override
  void initState() {
    super.initState();
    _selectedAvatar = widget.initialAvatar;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Text(
      'Choose your avatar',
      style: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF4754C5),
      ),
      ),
      SizedBox(height: 16),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 1,
        ),
        itemCount: _avatars.length,
        itemBuilder: (context, index) {
          final avatar = _avatars[index];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedAvatar = avatar);
              widget.onAvatarSelected(avatar);
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedAvatar == avatar
                      ? const Color(0xFFFE5B54)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/avatars/$avatar.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person, size: 40);
                  },
                ),
              ),
            ),
          );
        },
      ),
      ],
    );
  }
}