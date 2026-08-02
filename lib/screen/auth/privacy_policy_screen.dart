import 'package:flutter/material.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';
import 'package:walkamon_mobile/widgets/common/game_back_button.dart';
import 'package:walkamon_mobile/widgets/common/game_button_label.dart';

import '../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primary = AppColors.buttonGreen;
    const cardColor = AppColors.authCard;
    const accent = AppColors.woodDeep;
    const mutedForeground = AppColors.oliveDeep;
    const foreground = AppColors.inkDark;
    const borderColor = AppColors.wood;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: Stack(
            children: [
              Center(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 72, 20, 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 420,
                        maxHeight: 720,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: borderColor, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3D2B472E),
                              blurRadius: 32,
                              offset: Offset(0, 14),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Column(
                            children: [
                              // ── HEADER ──
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.creamLight.withValues(
                                    alpha: 0.48,
                                  ),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: borderColor,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.leafLight.withValues(
                                          alpha: 0.72,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.wood,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: AppIcon(
                                        Icons.gavel_rounded,
                                        color: primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Điều Khoản Dịch Vụ',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                  color: foreground,
                                                  letterSpacing: -0.5,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Khế ước đồng hành cùng Walkamon',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: mutedForeground,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ── SCROLLABLE CONTENT ──
                              Expanded(
                                child: RawScrollbar(
                                  thumbColor: Colors.transparent,
                                  radius: const Radius.circular(8),
                                  thickness: 0,
                                  interactive: false,
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Giới thiệu
                                        _buildSectionTitle(
                                          title: 'GIỚI THIỆU',
                                          theme: theme,
                                          primary: primary,
                                          foreground: foreground,
                                        ),
                                        const SizedBox(height: 8),
                                        _buildParagraph(
                                          text:
                                              'Cảm ơn bạn đã sử dụng dịch vụ của chúng tôi. Để truy cập và trải nghiệm ứng dụng Walkamon, bạn có thể phải đăng ký tài khoản. Bằng việc truy cập hay sử dụng dịch vụ, bạn xác nhận rằng bạn đã đọc, hiểu và đồng ý bị ràng buộc bởi Điều khoản Dịch vụ này.',
                                          theme: theme,
                                          mutedForeground: mutedForeground,
                                        ),
                                        const SizedBox(height: 24),

                                        // PHẦN 1
                                        _buildPartHeader(
                                          title:
                                              'PHẦN 1: QUY ĐỊNH ĐIỀU KHOẢN THÀNH VIÊN',
                                          accent: accent,
                                        ),
                                        const SizedBox(height: 16),

                                        _buildSubSection(
                                          title:
                                              '1. Đăng ký và bảo mật tài khoản',
                                          content:
                                              '• Xác thực thông tin: Để tham gia chơi trò chơi, người dùng bắt buộc phải cung cấp đầy đủ, chính xác các thông tin tại Việt Nam. Theo nghị định 147/2024/NĐ-CP của Chính phủ Việt Nam, việc xác thực tài khoản bắt buộc thực hiện qua số điện thoại di động tại Việt Nam, và chỉ những tài khoản đã xác thực mới được tham gia chơi.\n'
                                              '• Người chơi dưới 16 tuổi: Trường hợp bạn chưa đủ 16 tuổi, cha, mẹ hoặc người giám hộ theo pháp luật dân sự phải sử dụng thông tin của mình để đăng ký tài khoản và chịu trách nhiệm giám sát, quản lý thời gian chơi cũng như nội dung trò chơi.\n'
                                              '• Bảo mật tài khoản: Bạn có trách nhiệm duy trì tính bảo mật của mật khẩu và tài khoản của mình, hoàn toàn chịu trách nhiệm cho tất cả các hoạt động diễn ra trên tài khoản đó. Mỗi tài khoản phải được sử dụng riêng cho cá nhân và không được chuyển nhượng hay chia sẻ cho người khác.',
                                          theme: theme,
                                          foreground: foreground,
                                          mutedForeground: mutedForeground,
                                        ),
                                        const SizedBox(height: 20),

                                        _buildSubSection(
                                          title:
                                              '2. Quy định về đặt tên tài khoản và nhân vật',
                                          content:
                                              '• Tên tài khoản và nhân vật bao gồm các ký tự chữ và số, không bao gồm ký tự đặc biệt, có độ dài tối thiểu 6 ký tự và tối đa 16 ký tự.\n'
                                              '• Không được đặt tên trùng hoặc có liên quan đến các nhân vật lịch sử, nhà lãnh đạo, không vi phạm thuần phong mỹ tục.\n'
                                              '• Tuyệt đối không được đặt tên tài khoản, kênh, nhóm trùng hoặc dễ gây nhầm lẫn với tên các cơ quan báo chí (như: Báo, đài, tạp chí, tin tức, truyền hình, thông tấn...).',
                                          theme: theme,
                                          foreground: foreground,
                                          mutedForeground: mutedForeground,
                                        ),
                                        const SizedBox(height: 20),

                                        _buildSubSection(
                                          title:
                                              '3. Quy định về lưu trữ, bảo mật và xóa dữ liệu người dùng',
                                          content:
                                              '• Lưu trữ dữ liệu: Walkamon thiết lập ít nhất 01 hệ thống máy chủ đặt tại Việt Nam để lưu trữ thông tin, giải quyết khiếu nại và cung cấp thông tin khi có yêu cầu từ cơ quan có thẩm quyền. Chúng tôi sẽ lưu giữ các thông tin cá nhân và thông tin về quá trình sử dụng dịch vụ của bạn (như tên tài khoản, thời gian sử dụng, vật phẩm/tính năng ảo đang sở hữu) trong suốt quá trình bạn sử dụng dịch vụ.\n'
                                              '• Quyền riêng tư: Bạn có toàn quyền quyết định việc cho phép hoặc không cho phép chúng tôi sử dụng thông tin của bạn cho mục đích quảng bá, truyền thông hoặc cung cấp cho bên thứ ba.\n'
                                              '• Chấm dứt và xóa dữ liệu: Khi bạn ngừng sử dụng dịch vụ (chấm dứt tài khoản), chúng tôi có nghĩa vụ tiếp tục lưu giữ các thông tin của bạn trong thời gian 06 tháng. Sau khi hết hạn thời gian lưu trữ theo quy định này, hệ thống sẽ xóa hoàn toàn thông tin của người chơi.',
                                          theme: theme,
                                          foreground: foreground,
                                          mutedForeground: mutedForeground,
                                        ),
                                        const SizedBox(height: 20),

                                        _buildSubSection(
                                          title:
                                              '4. Các hành vi người dùng bị nghiêm cấm',
                                          content:
                                              'Người dùng tuyệt đối không được lợi dụng trò chơi điện tử để thực hiện các hành vi vi phạm pháp luật. Cụ thể nghiêm cấm:\n'
                                              '• Tải lên, phát tán phần mềm độc hại, virus nhằm phá hỏng hoặc hạn chế chức năng của phần mềm, phần cứng máy tính.\n'
                                              '• Cung cấp, chia sẻ thông tin giả mạo, sai sự thật, vu khống, xúc phạm uy tín của cơ quan, tổ chức, danh dự, nhân phẩm của cá nhân. (Hành vi này có thể bị cơ quan chức năng xử phạt từ 20.000.000 đồng đến 30.000.000 đồng theo quy định pháp luật).\n'
                                              '• Truyền bá hình ảnh khiêu dâm, đồi trụy, bạo lực, cờ bạc, hoặc sử dụng ma túy, rượu bia.\n'
                                              '• Cung cấp, chia sẻ hình ảnh bản đồ Việt Nam không thể hiện hoặc thể hiện không đúng chủ quyền quốc gia.',
                                          theme: theme,
                                          foreground: foreground,
                                          mutedForeground: mutedForeground,
                                        ),
                                        const SizedBox(height: 20),

                                        _buildSubSection(
                                          title: '5. Chấm dứt tài khoản',
                                          content:
                                              'Walkamon có thể chấm dứt tài khoản của bạn khi chúng tôi có lý do để tin rằng tài khoản đó vi phạm hoặc đã không tuân thủ Điều khoản Dịch vụ.',
                                          theme: theme,
                                          foreground: foreground,
                                          mutedForeground: mutedForeground,
                                        ),
                                        const SizedBox(height: 24),

                                        // PHẦN 2
                                        _buildPartHeader(
                                          title:
                                              'PHẦN 2: QUY ĐỊNH VỀ QUẢN LÝ NỘI DUNG, THÔNG TIN VÀ HOẠT ĐỘNG TRÒ CHƠI',
                                          accent: accent,
                                        ),
                                        const SizedBox(height: 16),

                                        _buildSubSection(
                                          title:
                                              '1. Quản lý nội dung và cơ chế xử lý vi phạm',
                                          content:
                                              '• Quyền cấp phép nội dung: Bằng việc gửi nội dung (bình luận, hình ảnh...) lên hệ thống, bạn cấp cho chúng tôi quyền sử dụng, tái tạo và xuất bản các nội dung đó. Chúng tôi không tuyên bố quyền sở hữu nhưng có quyền từ chối hoặc xóa bất kỳ nội dung nào vi phạm.\n'
                                              '• Xử lý vi phạm: Ban quản trị sẽ kiểm tra, giám sát và gỡ bỏ các thông tin, dịch vụ vi phạm pháp luật chậm nhất là 24 giờ kể từ thời điểm phát hiện hoặc có yêu cầu từ cơ quan chức năng.\n'
                                              '• Khóa tài khoản: Đối với các tài khoản thường xuyên đăng tải nội dung vi phạm, chúng tôi sẽ thực hiện khóa tạm thời từ 07 ngày đến 30 ngày. Chúng tôi sẽ khóa vĩnh viễn các tài khoản đăng tải nội dung xâm phạm an ninh quốc gia hoặc đã bị khóa tạm thời từ 03 lần trở lên.',
                                          theme: theme,
                                          foreground: foreground,
                                          mutedForeground: mutedForeground,
                                        ),
                                        const SizedBox(height: 20),

                                        _buildSubSection(
                                          title:
                                              '2. Phân loại độ tuổi và quản lý thời gian chơi',
                                          content:
                                              '• Phân loại độ tuổi: Các trò chơi trên nền tảng được phân loại theo độ tuổi (00+, 12+, 16+, 18+) được hiển thị liên tục trong quá trình chơi và trên các nội dung quảng cáo. Người chơi có nghĩa vụ lựa chọn trò chơi phù hợp với độ tuổi của mình.\n'
                                              '• Giới hạn giờ chơi cho người dưới 18 tuổi: Hệ thống tự động quản lý thời gian chơi trong ngày (từ 00h00 đến 24h00) của người chơi dưới 18 tuổi, bảo đảm không quá 60 phút đối với từng trò chơi và không quá 180 phút một ngày đối với tất cả trò chơi trên nền tảng.\n'
                                              '• Cảnh báo sức khỏe: Hệ thống sẽ hiển thị thông tin khuyến cáo "Chơi quá 180 phút một ngày sẽ ảnh hưởng xấu đến sức khỏe" dưới mỗi khung hình chơi game, xuyên suốt trong mọi game.',
                                          theme: theme,
                                          foreground: foreground,
                                          mutedForeground: mutedForeground,
                                        ),
                                        const SizedBox(height: 20),

                                        _buildSubSection(
                                          title:
                                              '3. Quản lý vật phẩm ảo, tính năng nâng cấp và điểm thưởng',
                                          content:
                                              '• Mục đích sử dụng: Trò chơi chỉ cung cấp các vật phẩm ảo, điểm thưởng, và tính năng nâng cấp đã được thiết lập sẵn trong từng game. Người chơi nhận được các tính năng này thông qua việc tham gia trò chơi hoặc xem quảng cáo. Mọi vật phẩm và tính năng chỉ được sử dụng trong phạm vi trò chơi đang chơi.\n'
                                              '• Nghiêm cấm quy đổi: Tuyệt đối không được quy đổi vật phẩm ảo, tính năng nâng cấp, điểm thưởng ngược lại thành tiền mặt, thẻ trả trước dịch vụ viễn thông di động, thẻ ngân hàng, thẻ quà tặng hoặc các hiện vật có giá trị giao dịch bên ngoài trò chơi.\n'
                                              '• Nghiêm cấm mua bán: Nghiêm cấm mọi hành vi mua, bán vật phẩm ảo, đơn vị ảo, điểm thưởng giữa những người chơi với nhau.',
                                          theme: theme,
                                          foreground: foreground,
                                          mutedForeground: mutedForeground,
                                        ),
                                        const SizedBox(height: 20),

                                        _buildSubSection(
                                          title:
                                              '4. Bản quyền và Sở hữu trí tuệ',
                                          content:
                                              '• Tất cả Quyền sở hữu trí tuệ liên quan tới Dịch vụ, phần mềm, văn bản, video, âm thanh, hình ảnh chứa trên Dịch vụ (ngoại trừ Nội dung do Người dùng tự tạo) đều thuộc về Walkamon và bên cấp phép của chúng tôi.\n'
                                              '• Người chơi không được phép sửa đổi, thuê, bán, phân phối hoặc tạo ra các tác phẩm phái sinh dựa trên Dịch vụ của chúng tôi nếu chưa được sự cho phép bằng văn bản.',
                                          theme: theme,
                                          foreground: foreground,
                                          mutedForeground: mutedForeground,
                                        ),
                                        const SizedBox(height: 20),

                                        _buildSubSection(
                                          title:
                                              '5. Quy định về nội dung và đường liên kết tới website của bên thứ ba',
                                          content:
                                              '• Sự hiện diện của bên thứ ba: Trong quá trình cung cấp dịch vụ (bao gồm cả hệ thống xem quảng cáo nhận thưởng), Walkamon có thể chứa các quảng cáo, nội dung hoặc đường liên kết (link) dẫn đến các trang web, ứng dụng của bên thứ ba ("Trang web liên kết"). Các Trang web liên kết này không thuộc quyền sở hữu và không chịu sự kiểm soát trực tiếp của chúng tôi.\n'
                                              '• Giới hạn trách nhiệm về giao dịch và quyền riêng tư: Chúng tôi không xác nhận, tài trợ, giới thiệu hoặc cam kết bảo đảm đối với các nội dung, hàng hóa, dịch vụ hay thực hành về quyền riêng tư của các Trang web liên kết. Người chơi tự chịu trách nhiệm và rủi ro khi quyết định nhấp vào đường liên kết, truy cập, giao dịch hoặc cung cấp thông tin cá nhân cho các nền tảng bên thứ ba này.\n'
                                              '• Nghiêm cấm chia sẻ đường liên kết vi phạm pháp luật: Tuân thủ pháp luật Việt Nam, người sử dụng dịch vụ tuyệt đối không được lợi dụng nền tảng của chúng tôi (thông qua tính năng bình luận, diễn đàn trò chuyện nếu có) để cung cấp, chia sẻ đường dẫn (link) đến các thông tin trên mạng có nội dung bị cấm, thông tin sai sự thật, hoặc quảng cáo hàng hóa/dịch vụ bị cấm. Người dùng phải hoàn toàn chịu trách nhiệm trước pháp luật về các đường liên kết do chính mình thiết lập, chia sẻ.\n'
                                              '• Cơ chế rà soát và xử lý: Mặc dù không có nghĩa vụ giám sát toàn bộ Trang web liên kết, nhưng để bảo đảm an toàn không gian mạng, Ban quản trị Walkamon có quyền và nghĩa vụ rà soát, ngăn chặn và gỡ bỏ ngay lập tức các đường liên kết dẫn đến nội dung, dịch vụ, ứng dụng vi phạm pháp luật chậm nhất là 24 giờ kể từ khi tự phát hiện hoặc có yêu cầu từ cơ quan chức năng có thẩm quyền. Các tài khoản cố tình chia sẻ đường liên kết độc hại, vi phạm pháp luật sẽ bị khóa tạm thời hoặc vĩnh viễn tùy theo mức độ vi phạm.',
                                          theme: theme,
                                          foreground: foreground,
                                          mutedForeground: mutedForeground,
                                        ),
                                        const SizedBox(height: 24),

                                        // LIÊN HỆ
                                        _buildSectionTitle(
                                          title: 'LIÊN HỆ',
                                          theme: theme,
                                          primary: primary,
                                          foreground: foreground,
                                        ),
                                        const SizedBox(height: 8),
                                        _buildParagraph(
                                          text:
                                              'Hãy liên lạc với chúng tôi khi có bất kỳ thắc mắc hoặc để báo cáo bất kỳ hành vi vi phạm các Điều khoản Dịch vụ theo địa chỉ email: walkamonn@gmail.com\n\n'
                                              'Walkamon có thể liên lạc với bạn và gửi cho bạn các thông báo, bao gồm cả thông báo liên quan đến những thay đổi trong Điều khoản Dịch vụ này, qua email, điện thoại bằng cách đăng ký nhận thông báo.',
                                          theme: theme,
                                          mutedForeground: mutedForeground,
                                        ),
                                        const SizedBox(height: 16),

                                        // Ngày cập nhật
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            'Ngày cập nhật: 25/06/2026',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: accent,
                                                  fontWeight: FontWeight.w700,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // ── FOOTER BUTTON ──
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: borderColor,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: FilledButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(56),
                                    backgroundColor: AppColors.buttonGreen,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shadowColor: AppColors.leafShadow
                                        .withValues(alpha: 0.35),
                                    shape: const StadiumBorder(
                                      side: const BorderSide(
                                        color: AppColors.buttonBorder,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: const GameButtonLabel(
                                    'Tôi Đã Hiểu & Đồng Ý',
                                    color: Colors.white,
                                    outlineColor: AppColors.buttonBorder,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              PositionedGameBackButton(
                semanticLabel: MaterialLocalizations.of(
                  context,
                ).backButtonTooltip,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── HELPER WIDGETS FOR CONTENT ──

  Widget _buildSectionTitle({
    required String title,
    required ThemeData theme,
    required Color primary,
    required Color foreground,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: foreground,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildParagraph({
    required String text,
    required ThemeData theme,
    required Color mutedForeground,
  }) {
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: mutedForeground,
        fontWeight: FontWeight.w500,
        height: 1.6,
      ),
    );
  }

  Widget _buildPartHeader({required String title, required Color accent}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.2), width: 1),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: accent,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildSubSection({
    required String title,
    required String content,
    required ThemeData theme,
    required Color foreground,
    required Color mutedForeground,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: foreground,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: mutedForeground,
            fontWeight: FontWeight.w500,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
