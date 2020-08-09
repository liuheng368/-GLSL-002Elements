//
//  HyGlkView.m
//  OpenGL ES - GLSL案例二：索引绘图
//
//  Created by Henry on 2020/8/9.
//  Copyright © 2020 刘恒. All rights reserved.
//

#import "HyGlkView.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import <GLKit/GLKMath.h>

@interface HyGlkView() <GLKViewDelegate>

@property(nonatomic,strong)GLKBaseEffect *myEffect;

@end

@implementation HyGlkView
{
    CGFloat xDegree;
    CGFloat yDegree;
    CGFloat zDegree;
    
    BOOL bx;
    BOOL by;
    BOOL bz;
    
    CADisplayLink *link;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
        [EAGLContext setCurrentContext:context];
        self = [super initWithFrame:frame context:context];
    }
    return self;
}

- (void)layoutSubviews{
    [self setupContext];
    
    [self render];
}

-(void)setupContext{
    self.delegate = self;
    self.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    self.drawableDepthFormat = GLKViewDrawableDepthFormat24;
//    glDepthRangef(1, 0);
    glEnable(GL_DEPTH_TEST);
}

-(void)render{
    
    //顶点数组, 前3位顶点， 后3位颜色（RGB，A默认为1.0）
    GLfloat vertex[] = {
        -0.5f, 0.5f, 0.0f, 0, 1,  //左上
       -0.5f, -0.5f, 0.0f, 0, 0,  //左下
          0.5f, -0.5f, 0.0f, 1, 0,  //右下
         0.5f, 0.5f, 0.0f, 1, 1,  //右上
         0.0f, 0.0f, 1.0f,  0.5, 1,  //顶点
    };
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertex), vertex, GL_DYNAMIC_DRAW);
    
    //将索引数组存储到索引缓冲区 GL_ELEMENT_ARRAY_BUFFER
//    GLuint elementBuffer;
//    glGenBuffers(1, &elementBuffer);
//    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBuffer);
//    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_DYNAMIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5,(GLfloat *)NULL + 0);
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5,(GLfloat *)NULL + 3);
    
    NSError *error;
    GLKTextureInfo *texInfo = [GLKTextureLoader textureWithCGImage:[[UIImage imageNamed:@"cat"] CGImage]  options:@{GLKTextureLoaderOriginBottomLeft: @(YES)} error:&error];
    
    self.myEffect = [[GLKBaseEffect alloc] init];
    self.myEffect.texture2d0.enabled = YES;
    self.myEffect.texture2d0.name = texInfo.name;
    self.myEffect.texture2d0.target = texInfo.target;
    
    //mvp视图
    CGSize size = self.bounds.size;
    float aspect = fabs(size.width / size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0), aspect, 0.1f, 100.0);
    self.myEffect.transform.projectionMatrix = projectionMatrix;
    
    //定时器
    link = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
    [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

-(void)update{
    xDegree += 0.5f * bx;
    yDegree += 0.5f * by;
    zDegree += 0.5f * bz;
    GLKMatrix4 modelMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.5);
    modelMatrix = GLKMatrix4Rotate(modelMatrix, GLKMathDegreesToRadians(xDegree), 1, 0, 0);
    modelMatrix = GLKMatrix4Rotate(modelMatrix, GLKMathDegreesToRadians(yDegree), 0, 1, 0);
    modelMatrix = GLKMatrix4Rotate(modelMatrix, GLKMathDegreesToRadians(zDegree), 0, 0, 1);
    //赋值后替换之前设置，并不会做矩阵计算
    self.myEffect.transform.modelviewMatrix = modelMatrix;
    [self display];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    glClearColor(0.5, 0.3, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.myEffect prepareToDraw];
    
    //索引数组
    //需要根据初始位置的正背面，来确定绘制顺序（逆时针为正面）
    GLuint indices[] = {
        0, 2, 1,    //下左
        3, 2, 0,    //下右
        0, 1, 4,    //上左
        1, 2, 4,    //上下
        2, 3, 4,    //上左
        0, 4, 3,    //上后
    };
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);
}

-(void)x{
    bx = !bx;
}
-(void)y{
    by = !by;
}
-(void)z{
    bz = !bz;
}

@end
