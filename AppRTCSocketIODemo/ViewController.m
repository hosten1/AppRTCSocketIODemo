//
//  ViewController.m
//  AppRTCSocketIODemo
//
//  Created by luoyongmeng on 2022/5/10.
//

#import "ViewController.h"
#import "LYMVideoCallViewController.h"


@interface ViewController ()

@property (nonatomic, strong) UITextField *addressField;
@property (nonatomic, strong) UITextField *portField;
@property (nonatomic, strong) UITextField *roomIdField;
@property (nonatomic, strong) UITextField *userIdField;

@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    [self setupUI];
}

- (void)setupUI {
    // 横向StackView（服务地址 + 端口）
    UIStackView *addressPortStack = [[UIStackView alloc] init];
    addressPortStack.axis = UILayoutConstraintAxisHorizontal;
    addressPortStack.spacing = 10;
    addressPortStack.distribution = UIStackViewDistributionFillEqually;
    addressPortStack.translatesAutoresizingMaskIntoConstraints = NO;

    self.addressField = [self createTextFieldWithPlaceholder:@"服务地址"];
    self.portField = [self createTextFieldWithPlaceholder:@"端口"];
    self.addressField.text = @"8.137.17.218";
    self.portField.text    = @"443";

    [addressPortStack addArrangedSubview:self.addressField];
    [addressPortStack addArrangedSubview:self.portField];

    // 垂直StackView（上面那个横向 + 房间号 + 用户ID + 按钮）
    UIStackView *mainStack = [[UIStackView alloc] init];
    mainStack.axis = UILayoutConstraintAxisVertical;
    mainStack.spacing = 16;
    mainStack.translatesAutoresizingMaskIntoConstraints = NO;

    self.roomIdField = [self createTextFieldWithPlaceholder:@"房间号"];
    self.userIdField = [self createTextFieldWithPlaceholder:@"用户ID"];
    self.roomIdField.text = @"123456";
    // 生成一个 7 位的随机数字字符串
    int randomNumber = arc4random_uniform(9000000) + 1000000;
    self.userIdField.text = [NSString stringWithFormat:@"%d", randomNumber];
    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [confirmButton setTitle:@"确认" forState:UIControlStateNormal];
    [confirmButton addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];

    [mainStack addArrangedSubview:addressPortStack];
    [mainStack addArrangedSubview:self.roomIdField];
    [mainStack addArrangedSubview:self.userIdField];
    [mainStack addArrangedSubview:confirmButton];

    [self.view addSubview:mainStack];

    // 添加 AutoLayout
    [NSLayoutConstraint activateConstraints:@[
        [mainStack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [mainStack.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [mainStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:30],
        [mainStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-30],
    ]];
}

- (UITextField *)createTextFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *tf = [[UITextField alloc] init];
    tf.placeholder = placeholder;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.translatesAutoresizingMaskIntoConstraints = NO;
    return tf;
}

- (void)confirmTapped {
    NSString *address = self.addressField.text;
    NSString *port = self.portField.text;
    NSString *roomId = self.roomIdField.text;
    NSString *userId = self.userIdField.text;

    // 你可以添加验证逻辑
    if (address.length == 0 || port.length == 0 || roomId.length == 0 || userId.length == 0) {
        NSLog(@"请输入所有字段");
        return;
    }
    // 跳转到下一个页面（视频通话）
    LYMVideoCallViewController *vc = [[LYMVideoCallViewController alloc] init];
    vc.serverAddress = address;
    vc.port = port;
    vc.roomId = roomId;
    vc.userId = userId;

    [self.navigationController pushViewController:vc animated:YES];
}
@end
