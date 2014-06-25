//
//  ESMainViewController.m
//  EasyShare
//
//  Created by likai on 6/25/14.
//  Copyright (c) 2014 edu. All rights reserved.
//

#import "ESMainViewController.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"

#define kServerPort                     1481
#define kTextViewHeight                 314.f
#define kTextViewFontSize               15.f

#define kTextViewBackgroundColor        [UIColor colorWithWhite:.9f alpha:.4f]

#define kShouldClearText                @"ShouldClearTextViewText"

@interface ESMainViewController () <UITextViewDelegate> {
    GCDWebServer *_webServer;
    UITextView *_textView;
    BOOL ShouldClearTextViewText;
}

@property (nonatomic, strong) NSString *contentToClear;

@end

@implementation ESMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _webServer = [[GCDWebServer alloc] init];
        [_webServer startWithPort:kServerPort bonjourName:nil];

        [self setValue:@(YES) forKey:kShouldClearText];
        [self addObserver:self forKeyPath:kShouldClearText options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = [self title];

    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(clearTextViewContent)];
    self.navigationItem.leftBarButtonItem = leftItem;

    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"Share" style:UIBarButtonItemStylePlain target:self action:@selector(shareTextViewContent)];
    self.navigationItem.rightBarButtonItem = rightItem;

    _textView = [[UITextView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.view.bounds.size.width, kTextViewHeight)];
    _textView.font = [UIFont systemFontOfSize:kTextViewFontSize];
    [self.view addSubview:_textView];
    _textView.backgroundColor = kTextViewBackgroundColor;
    _textView.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    NSString *content = [[UIPasteboard generalPasteboard] string];
    if (content) {
        _textView.text = content;
        [self shareTextViewContent];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    if (textView.text.length > 0 && ![[self valueForKey:kShouldClearText] boolValue]) {
        [self setValue:@(YES) forKey:kShouldClearText];
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kShouldClearText]) {
        if ([[change valueForKey:@"new"] boolValue] && ![[change valueForKey:@"old"] boolValue]) {
            [self.navigationItem.leftBarButtonItem setTitle:@"Clear"];
        }
        if ([[change valueForKey:@"old"] boolValue] && ![[change valueForKey:@"new"] boolValue]) {
            [self.navigationItem.leftBarButtonItem setTitle:@"Undo"];
        }
    }
}

#pragma mark - private

- (NSString *)title
{
    if (_webServer.isRunning) {
        return [_webServer.serverURL absoluteString];
    } else {
        return @"Server not running";
    }
}

- (void)shareContent:(NSString *)content
{
    NSDictionary *dict = @{@"content": content};
    NSString *baseURL = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Html"];
    NSString *templatePath = [baseURL stringByAppendingPathComponent:@"template.html"];
    [_webServer addDefaultHandlerForMethod:@"GET"
                              requestClass:[GCDWebServerRequest class]
                              processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
                                  return [GCDWebServerDataResponse responseWithHTMLTemplate:templatePath variables:dict];
                              }];
}

- (void)shareTextViewContent
{
    [self shareContent:_textView.text];
}

- (void)clearTextViewContent
{
    BOOL shouldClearText = [[self valueForKey:kShouldClearText] boolValue];
    if (shouldClearText) {
        self.contentToClear = _textView.text;
        _textView.text = nil;
        [self setValue:@(NO) forKey:kShouldClearText];
    } else {
        _textView.text = self.contentToClear;
        [self setValue:@(YES) forKey:kShouldClearText];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
