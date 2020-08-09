//
//  HyTexView.m
//  OpenGL ES - GLSL案例二：索引绘图
//
//  Created by Henry on 2020/8/9.
//  Copyright © 2020 刘恒. All rights reserved.
//

#import "HyTexView.h"
#import "GLESMath.h"
#import "GLESUtils.h"
#import <OpenGLES/ES2/gl.h>
#import <GLKit/GLKMath.h>

@interface HyTexView()
@property(nonatomic, strong)EAGLContext *myContent;
@property(nonatomic, strong)CAEAGLLayer *myLayer;

@property(nonatomic, assign)GLuint myRenderBuffer;
@property(nonatomic, assign)GLuint myFrameBuffer;
@property(nonatomic, assign)GLuint myProgram;

@end

@implementation HyTexView
{
    CGFloat xDegree;
    CGFloat yDegree;
    CGFloat zDegree;
    
    BOOL bx;
    BOOL by;
    BOOL bz;
    
    dispatch_source_t timer;
}

- (void)layoutSubviews{
    [self setupLayer];
    [self setupContent];
    [self cleanBuffer];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self setupShader];
    [self render];
    
    if(!timer){
        double seconds = 0.1;
        timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC, 0.0);
        dispatch_source_set_event_handler(timer, ^{
            self->xDegree += 0.5f * self->bx;
            self->yDegree += 0.5f * self->by;
            self->zDegree += 0.5f * self->bz;
            [self render];
        });
        dispatch_resume(timer);
    }
}

+ (Class)layerClass{
    return [CAEAGLLayer class];
}

-(void)setupLayer{
    self.myLayer = (CAEAGLLayer *)self.layer;
    [self.myLayer setContentsScale:[[UIScreen mainScreen] scale]];
    self.myLayer.opaque = YES;
    self.myLayer.drawableProperties = @{
        kEAGLDrawablePropertyRetainedBacking:@false,
        kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8,
    };
}

-(void)setupContent{
    self.myContent = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.myContent){
        NSLog(@"content init failed");
        exit(1);
    }
    
    if(![EAGLContext setCurrentContext:self.myContent]){
        NSLog(@"Set Current Context failed");
        exit(1);
    }
}

-(void)cleanBuffer{
    glDeleteRenderbuffers(1, &_myRenderBuffer);
    glDeleteFramebuffers(1, &_myFrameBuffer);
    self.myRenderBuffer = 0;
    self.myFrameBuffer = 0;
}

-(void)setupRenderBuffer{
    GLuint render;
    glGenRenderbuffers(1, &render);
    glBindRenderbuffer(GL_RENDERBUFFER, render);
    self.myRenderBuffer = render;
    if (render == GL_FALSE) {
        NSLog(@"create Render Buffer Failed");
        exit(1);
    }
    
    [self.myContent renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myLayer];
}

-(void)setupFrameBuffer{
    GLuint frame;
    glGenFramebuffers(1, &frame);
    glBindFramebuffer(GL_FRAMEBUFFER, frame);
    self.myFrameBuffer = frame;
    if (frame == GL_FALSE) {
        NSLog(@"create Frame Buffer Failed");
        exit(1);
    }
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myRenderBuffer);
}

-(void)setupShader{
    GLuint vShader,fShader;
    
    NSString *vPath = [[NSBundle mainBundle] pathForResource:@"shaderColorV" ofType:@"glsl"];
    NSString *fPath = [[NSBundle mainBundle] pathForResource:@"shaderColorF" ofType:@"glsl"];
    [self compile:vPath type:GL_VERTEX_SHADER target:&vShader];
    [self compile:fPath type:GL_FRAGMENT_SHADER target:&fShader];
    
    if(self.myProgram) {
        glDeleteProgram(self.myProgram);
        self.myProgram = 0;
    }
    
    self.myProgram = glCreateProgram();
    if(self.myProgram == GL_FALSE){
        NSLog(@"Create program Failed");
        return;
    }
    
    glAttachShader(self.myProgram, vShader);
    glAttachShader(self.myProgram, fShader);
    
    glDeleteShader(vShader);
    glDeleteShader(fShader);
    
    glLinkProgram(self.myProgram);
    
    GLint status;
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &status);
    if (status == GL_FALSE){
        GLchar info[256];
        glGetProgramInfoLog(self.myProgram, sizeof(info), 0, &info[0]);
        NSString *message = [NSString stringWithUTF8String:info];
        NSLog(@"%@",message);
        return;
    }
    NSLog(@"glLinkProgram success");
    
    glUseProgram(self.myProgram);
}

-(void)compile:(NSString *)path type:(GLenum)type target:(GLuint *)target{
    const GLchar *source = (GLchar *)[[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] UTF8String];
    
    *target = glCreateShader(type);
    glShaderSource(*target, 1, &source, NULL);
    if(target == GL_FALSE){
        NSLog(@"%i shader Init Failed", type);
        return;
    }
    
    glCompileShader(*target);
}

-(void)render{
    glClearColor(0.5, 0.1, 0.6, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale,
               self.frame.origin.y * scale,
               self.frame.size.width * scale,
               self.frame.size.height * scale);
    
    //顶点数组, 前3位顶点， 后3位颜色（RGB，A默认为1.0）
    GLfloat vertex[] = {
        -0.5f, 0.0f, -0.5f, 0, 1,  //左上
        -0.5f, 0.0f,  0.5f, 0, 0,  //左下
         0.5f, 0.0f,  0.5f, 1, 0,  //右下
         0.5f, 0.0f, -0.5f, 1, 1,  //右上
         0.0f, 1.0f,  0.0f, 0.5, 1,  //顶点
    };
    
    //索引数组
    //需要根据初始位置的正背面，来确定绘制顺序（逆时针为正面）
    GLuint indices[] = {
        0, 2, 1,    //下左
        3, 2, 0,    //下右
        0, 1, 4,    //上左
        1, 2, 4,    //上前
        2, 3, 4,    //上右
        0, 4, 3,    //上后
    };
    GLuint verBuffer;
    glGenBuffers(1, &verBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, verBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertex), &vertex, GL_DYNAMIC_DRAW);
    
    GLuint positon = glGetAttribLocation(self.myProgram, "position");
    glEnableVertexAttribArray(positon);
    glVertexAttribPointer(positon, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    GLuint textureCoord = glGetAttribLocation(self.myProgram, "textureCoord");
    glEnableVertexAttribArray(textureCoord);
    glVertexAttribPointer(textureCoord, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
    
    glEnable(GL_CULL_FACE);
    GLKMatrix4 projectMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(30.0), self.frame.size.width / self.frame.size.height, 1.0, 100.0);
    GLKMatrix4 viewModelMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, -5.0);
    viewModelMatrix = GLKMatrix4RotateX(viewModelMatrix, GLKMathDegreesToRadians(xDegree));
    viewModelMatrix = GLKMatrix4RotateY(viewModelMatrix, GLKMathDegreesToRadians(yDegree));
    viewModelMatrix = GLKMatrix4RotateZ(viewModelMatrix, GLKMathDegreesToRadians(zDegree));

    GLuint pro = glGetUniformLocation(self.myProgram, "projectionMatrix");
    glUniformMatrix4fv(pro, 1, GL_FALSE, (GLfloat *)&projectMatrix.m00);
    GLuint viewM = glGetUniformLocation(self.myProgram, "modelViewMatrix");
    glUniformMatrix4fv(viewM, 1, GL_FALSE, (GLfloat *)&viewModelMatrix.m00);
    
    GLuint texture = [self loadImage:@"cat"];
    if(texture == GL_FALSE){
        NSLog(@"Load Image Failed");
        return;
    }
    
    //载入纹理
    glUniform1f(self.myProgram, texture);
    
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    
    [self.myContent presentRenderbuffer:GL_RENDERBUFFER];
}

-(GLuint)loadImage:(NSString *)imgName {
    CGImageRef ref = [[UIImage imageNamed:imgName] CGImage];
    if (!ref) {
        NSLog(@"Failed to load image %@", imgName);
        return 0;
    }
    size_t width = CGImageGetWidth(ref);
    size_t height = CGImageGetHeight(ref);
    CGColorSpaceRef space = CGImageGetColorSpace(ref);
    //加压缩结果所占空间大小
    GLubyte * spriteData = calloc(width * height * 4, sizeof(GLubyte));
    
    CGContextRef refContent = CGBitmapContextCreate(spriteData, width, height, 8, width * 4, space, kCGImageAlphaPremultipliedLast);
    
    //图片翻转
    //1 向下平移，防止图片超出绘制范围
    CGContextTranslateCTM(refContent, 0, height);
    //2 将图层按Y轴向上翻转180（CGContent的原点在左上角，Y轴负方向在上）
    CGContextScaleCTM(refContent, 1.0, -1.0);
    
    CGContextDrawImage(refContent, CGRectMake(0, 0, width, height), ref);
    CGContextRelease(refContent);
    
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (float)width, (float)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return  texture;
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
