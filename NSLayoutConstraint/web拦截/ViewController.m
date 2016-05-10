//
//  ViewController.m
//  web拦截
//
//  Created by 申帅 on 16/5/9.
//  Copyright © 2016年 申帅. All rights reserved.
//
/*
 原理：IOS6.0 之后，苹果优化了UI界面的布局方式，提出了自动布局的概念，和之前的autoresizing相比功能更强大。子视图基于父视图的自动布局显示。都是父视图去添加对子视图的约束。
 在这里主要说的是通过代码对自动布局视图的实现。
 代码中一般用到的有两个添加约束的方式：
 1.- (void)addConstraint:(NSLayoutConstraint *)constraint NS_AVAILABLE_IOS(6_0);
 2.- (void)addConstraints:(NSArray *)constraints NS_AVAILABLE_IOS(6_0);
 <</span>
 在使用自动布局之前要对子视图的布局方式进行调整，用到这个UIView的属性。
 - (BOOL)translatesAutoresizingMaskIntoConstraints NS_AVAILABLE_IOS(6_0); // Default YES
 需要将其设置为NO；
 >
 下面用简单例子说明一下：
 UIView *v1 = [[UIView alloc] initWithFrame:CGRectZero];
 v1.translatesAutoresizingMaskIntoConstraints = NO;
 v1.backgroundColor = [UIColor redColor];
 [self.view addSubview:v1];
 
 UIView *v2 = [[UIView alloc] initWithFrame:CGRectZero];
 v2.backgroundColor = [UIColor grayColor];
 v2.translatesAutoresizingMaskIntoConstraints = NO;
 [self.view addSubview:v2];//添加两个允许自动布局的子视图
 
 [self.view addConstraint:[NSLayoutConstraint constraintWithItem:v1
 attribute:NSLayoutAttributeWidth
 relatedBy:NSLayoutRelationEqual
 toItem:self.view
 attribute:NSLayoutAttributeWidth
 multiplier:1.0
 constant:0]];//设置子视图的宽度和父视图的宽度相同
 
 [self.view addConstraint:[NSLayoutConstraint constraintWithItem:v1
 attribute:NSLayoutAttributeHeight
 relatedBy:NSLayoutRelationEqual
 toItem:self.view
 attribute:NSLayoutAttributeHeight
 multiplier:0.5
 constant:0]];//设置子视图的高度是父视图高度的一半
 
 [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[v1][v2(==v1)]-0-|" options:0 metrics:nil views:views]];//通过addConstraints 添加对水平方向上v1的控制--距离父视图左侧距离为0（距离为0的话也可省略）同时将v2的水平方向的宽度和v1设置成相同
 
 [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[v1][v2(==v1)]|" options:0 metrics:nil views:views]];/通过addConstraints 添加对垂直方向上v1的控制--距离父视图上侧距离为0（距离为0的话也可省略）同时将v2的垂直方向的高度和v1设置成相同
 
 [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[v1]-0-[v2]-0-|" options:0 metrics:nil views:views]];//最后是垂直布局两个子view
 这样就可以实现上下两个view，各占一半。旋转屏幕的情况下也会自动处理布局。这样看起来代码多，但是可以适应多种分辨率的屏幕。不排除以后苹果出更大更多分辨率的手机。
 
 关于constraintsWithVisualFormat：函数介绍：
 
 constraintsWithVisualFormat:参数为NSString型，指定Contsraint的属性，是垂直方向的限定还是水平方向的限定，参数定义一般如下：
 V:|-(>=XXX) :表示垂直方向上相对于SuperView大于、等于、小于某个距离
 若是要定义水平方向，则将V：改成H：即可
 在接着后面-[]中括号里面对当前的View/控件 的高度/宽度进行设定；
 options：字典类型的值；这里的值一般在系统定义的一个enum里面选取
 metrics：nil；一般为nil ，参数类型为NSDictionary，从外部传入 //衡量标准
 views：就是上面所加入到NSDictionary中的绑定的View
 在这里要注意的是 AddConstraints  和 AddConstraint 之间的区别，一个添加的参数是NSArray，一个是NSLayoutConstraint
 使用规则
 
 |: 表示父视图
 -:表示距离
 V:  :表示垂直
 H:  :表示水平
 >= :表示视图间距、宽度和高度必须大于或等于某个值
 <= :表示视图间距、宽度和高度必须小宇或等于某个值
 == :表示视图间距、宽度或者高度必须等于某个值
 @  :>=、<=、==  限制   最大为  1000
 
 1.|-[view]-|:  视图处在父视图的左右边缘内
 2.|-[view]  :   视图处在父视图的左边缘
 3.|[view]   :   视图和父视图左边对齐
 4.-[view]-  :  设置视图的宽度高度
 5.|-30.0-[view]-30.0-|:  表示离父视图 左右间距  30
 6.[view(200.0)] : 表示视图宽度为 200.0
 7.|-[view(view1)]-[view1]-| :表示视图宽度一样，并且在父视图左右边缘内
 8. V:|-[view(50.0)] : 视图高度为  50
 9: V:|-(==padding)-[imageView]->=0-[button]-(==padding)-| : 表示离父视图的距离
 为Padding,这两个视图间距必须大于或等于0并且距离底部父视图为 padding。
 10:  [wideView(>=60@700)]  :视图的宽度为至少为60 不能超过  700
 11: 如果没有声明方向默认为  水平  V:
 */

#import "ViewController.h"
#import <WebKit/WebKit.h>
@interface ViewController ()<UIScrollViewDelegate>

@property(strong, nonatomic) WKWebView *webView;
@property(strong, nonatomic) UIView *naviBarView;

@end

@implementation ViewController{
    UIImageView *reloadIcon;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)initView{
    /*
     |指父视图, H之X轴,V之Y轴,-?-指控件到父视图的距离,(?)指控件的大小
     */
    _naviBarView = [[UIView alloc] initWithFrame:CGRectZero];
    _naviBarView.translatesAutoresizingMaskIntoConstraints = NO;
    _naviBarView.backgroundColor = [UIColor colorWithRed:211 green:211 blue:211 alpha:1];
    [self.view addSubview:_naviBarView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_naviBarView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_naviBarView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_naviBarView(64)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_naviBarView)]];
    UILabel *titleBle = [[UILabel alloc] initWithFrame:CGRectZero];
    titleBle.translatesAutoresizingMaskIntoConstraints = NO;
    titleBle.text = @"WKWebView";
    [_naviBarView addSubview:titleBle];
    //水平居中 constant设置偏移量 负 向左 multiplier设置倍数
    [_naviBarView addConstraint:[NSLayoutConstraint constraintWithItem:titleBle attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_naviBarView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    //垂直居中 向下偏移10
    [_naviBarView addConstraint:[NSLayoutConstraint constraintWithItem:titleBle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_naviBarView attribute:NSLayoutAttributeCenterY multiplier:1 constant:10]];
    

    [_naviBarView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[titleBle(30)]" options:NSLayoutFormatAlignAllCenterY metrics:nil views:NSDictionaryOfVariableBindings(titleBle)]];
    _webView = [[WKWebView alloc] initWithFrame:CGRectZero];
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    _webView.scrollView.delegate = self;
    [self.view addSubview:_webView];
    //
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView)]];
//    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-64-[_webView]-64-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView)]];
    // bottomLayoutGuide 距离系统控件的间距
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_naviBarView][_webView][bottomLayoutGuide]" options:0 metrics:nil views:@{@"_naviBarView":_naviBarView,@"_webView":_webView,@"bottomLayoutGuide":self.bottomLayoutGuide}]];
//    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView)]];
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://wap.baidu.com"]]];
    reloadIcon = [[UIImageView alloc] initWithFrame:CGRectZero];
    reloadIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:reloadIcon];
    reloadIcon.layer.cornerRadius = 32;
    reloadIcon.layer.masksToBounds = YES;
    reloadIcon.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlereload)];
    [reloadIcon addGestureRecognizer:tap];
    reloadIcon.image = [UIImage imageNamed:@"reload"];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[reloadIcon(64)]-70-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(reloadIcon)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[reloadIcon(64)]-70-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(reloadIcon)]];

}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    reloadIcon.hidden = YES;
    [UIView animateWithDuration:0.2 animations:^{
        reloadIcon.alpha = 0;
    }];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    reloadIcon.hidden = NO;
    [UIView animateWithDuration:1 animations:^{
        reloadIcon.alpha = 1;
    }];
}

- (void)handlereload{
    [_webView reload];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
