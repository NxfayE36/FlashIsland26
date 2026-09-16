#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

@interface FIWindow : UIWindow @end
@implementation FIWindow
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e {
    UIView *v=[super hitTest:p withEvent:e];
    if (!v || v==self) return nil;
    return v;
}
@end

@interface FIPanel : UIControl
@property(nonatomic,strong) UIImageView *torch;
@property(nonatomic,strong) CAShapeLayer *arc;
@property(nonatomic,strong) CAGradientLayer *beam;
@property(nonatomic) CGFloat level;
@property(nonatomic) CGFloat widthValue;
@end

static FIWindow *fiWindow;
static FIPanel *fiPanel;
static id fiFlashlight;
static CGFloat fiLevel=1.0;
static CGFloat fiWidth=.5;
static IMP fiOrigSetLevel;
static IMP fiOrigOff;

typedef BOOL (*FISetLevelIMP)(id,SEL,CGFloat,id);
typedef void (*FIOffIMP)(id,SEL);

static void FIUpdateVisuals(void);
static void FIHide(void);

@implementation FIPanel
- (instancetype)initWithFrame:(CGRect)r {
    if((self=[super initWithFrame:r])) {
        self.backgroundColor=[UIColor colorWithWhite:.035 alpha:.965];
        self.layer.cornerRadius=56;
        self.layer.masksToBounds=YES;
        _level=1; _widthValue=.5;
        _torch=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"flashlight.on.fill"]];
        _torch.tintColor=UIColor.whiteColor; _torch.contentMode=UIViewContentModeScaleAspectFit;
        [self addSubview:_torch];
        _arc=[CAShapeLayer layer]; _arc.fillColor=nil; _arc.strokeColor=[UIColor colorWithWhite:.55 alpha:.95].CGColor; _arc.lineWidth=3; _arc.lineCap=kCALineCapRound; [self.layer addSublayer:_arc];
        _beam=[CAGradientLayer layer]; _beam.colors=@[(id)[UIColor colorWithWhite:1 alpha:.38].CGColor,(id)[UIColor colorWithWhite:1 alpha:.0].CGColor]; _beam.startPoint=CGPointMake(.5,.05); _beam.endPoint=CGPointMake(.5,1); _beam.cornerRadius=80; [self.layer addSublayer:_beam];
        UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(fiPan:)]; [self addGestureRecognizer:pan];
        UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fiTap:)]; [self addGestureRecognizer:tap];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews]; CGFloat w=self.bounds.size.width,h=self.bounds.size.height;
    self.torch.frame=CGRectMake(w/2-48,h-290,96,150);
    self.beam.frame=CGRectMake(w/2-160,h-590,320,380);
    CGFloat radius=185 + self.widthValue*45;
    UIBezierPath *p=[UIBezierPath bezierPath]; [p addArcWithCenter:CGPointMake(w/2,300) radius:radius startAngle:M_PI*1.22 endAngle:M_PI*1.78 clockwise:YES]; self.arc.path=p.CGPath;
}
- (void)fiPan:(UIPanGestureRecognizer*)g {
    CGPoint d=[g translationInView:self];
    if(g.state==UIGestureRecognizerStateChanged){
        self.level=MAX(.08,MIN(1.0,self.level-d.y/350.0));
        self.widthValue=MAX(0,MIN(1.0,self.widthValue+d.x/420.0));
        [g setTranslation:CGPointZero inView:self]; FIUpdateVisuals();
        if([fiFlashlight respondsToSelector:NSSelectorFromString(@"setFlashlightLevel:withError:")]) {
            ((FISetLevelIMP)fiOrigSetLevel)(fiFlashlight,NSSelectorFromString(@"setFlashlightLevel:withError:"),self.level,nil);
        }
        SEL s=NSSelectorFromString(@"setBeamWidth:"); if([fiFlashlight respondsToSelector:s]) ((void(*)(id,SEL,CGFloat))objc_msgSend)(fiFlashlight,s,self.widthValue);
    }
}
- (void)fiTap:(UITapGestureRecognizer*)g { if(g.state==UIGestureRecognizerStateEnded){ if(self.torch.alpha>.5){ if(fiOrigOff) ((FIOffIMP)fiOrigOff)(fiFlashlight,NSSelectorFromString(@"turnPowerOff:")); else if([fiFlashlight respondsToSelector:NSSelectorFromString(@"turnPowerOff")]) ((FIOffIMP)fiOrigOff)(fiFlashlight,NSSelectorFromString(@"turnPowerOff")); } } }
@end

static void FIUpdateVisuals(void){
    dispatch_async(dispatch_get_main_queue(), ^{
        if(!fiPanel) return;
        fiPanel.torch.alpha=.55+.45*fiPanel.level;
        fiPanel.beam.opacity=.2+.8*fiPanel.level;
        [fiPanel setNeedsLayout];
    });
}

static UIWindow *FIHostWindow(void){
    for(UIScene *s in UIApplication.sharedApplication.connectedScenes){
        if(s.activationState==UISceneActivationStateForegroundActive && [s isKindOfClass:UIWindowScene.class]){
            UIWindow *key=((UIWindowScene*)s).keyWindow; if(key) return key;
        }
    }
    return UIApplication.sharedApplication.windows.firstObject;
}

static void FIShow(id flashlight, CGFloat level){
    dispatch_async(dispatch_get_main_queue(), ^{
        fiFlashlight=flashlight; fiLevel=level;
        if(!fiWindow){
            UIWindow *host=FIHostWindow(); if(!host) return;
            fiWindow=[[FIWindow alloc] initWithFrame:host.bounds];
            fiWindow.windowLevel=UIWindowLevelStatusBar+2; fiWindow.backgroundColor=UIColor.clearColor; fiWindow.rootViewController=[UIViewController new]; fiWindow.rootViewController.view.backgroundColor=UIColor.clearColor;
        }
        CGFloat w=host.bounds.size.width*.61; if(w<330) w=330; CGFloat h=host.bounds.size.height*.78;
        fiPanel=[[FIPanel alloc] initWithFrame:CGRectMake((host.bounds.size.width-w)/2,12,w,h)];
        fiPanel.level=level>0?level:1; fiPanel.widthValue=.5;
        [fiWindow.rootViewController.view addSubview:fiPanel];
        fiWindow.hidden=NO;
        fiPanel.alpha=0; fiPanel.transform=CGAffineTransformMakeScale(.88,.88);
        [UIView animateWithDuration:.34 delay:0 usingSpringWithDamping:.78 initialSpringVelocity:.2 options:UIViewAnimationOptionCurveEaseOut animations:^{fiPanel.alpha=1;fiPanel.transform=CGAffineTransformIdentity;} completion:nil];
        FIUpdateVisuals();
    });
}
static void FIHide(void){
    dispatch_async(dispatch_get_main_queue(), ^{ if(!fiPanel) return; [UIView animateWithDuration:.22 animations:^{fiPanel.alpha=0;fiPanel.transform=CGAffineTransformMakeScale(.88,.88);} completion:^(BOOL ok){[fiPanel removeFromSuperview];fiPanel=nil;fiWindow.hidden=YES;}]; });
}

static BOOL FIHookSetLevel(id self, SEL cmd, CGFloat level, id error){
    BOOL r=((FISetLevelIMP)fiOrigSetLevel)(self,cmd,level,error);
    if(level>0.001) FIShow(self,level); else FIHide();
    return r;
}
static void FIHookOff(id self, SEL cmd){ ((FIOffIMP)fiOrigOff)(self,cmd); FIHide(); }

__attribute__((constructor)) static void FIInit(void){
    dispatch_async(dispatch_get_main_queue(), ^{
        Class c=objc_getClass("AVFlashlight"); if(!c) return;
        SEL set=NSSelectorFromString(@"setFlashlightLevel:withError:"); Method m=class_getInstanceMethod(c,set); if(m){fiOrigSetLevel=method_getImplementation(m); method_setImplementation(m,(IMP)FIHookSetLevel);}
        SEL off=NSSelectorFromString(@"turnPowerOff"); Method mo=class_getInstanceMethod(c,off); if(mo){fiOrigOff=method_getImplementation(mo); method_setImplementation(mo,(IMP)FIHookOff);}
    });
}
