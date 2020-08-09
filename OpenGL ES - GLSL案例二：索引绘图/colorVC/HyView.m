//
//  HyView.m
//  OpenGL ES - GLSL案例二：索引绘图
//
//  Created by Henry on 2020/8/8.
//  Copyright © 2020 刘恒. All rights reserved.
//

#import "HyView.h"
#import <OpenGLES/ES2/gl.h>
#import "GLESMath.h"
#import "GLESUtils.h"
@interface HyView()

@property(nonatomic,strong)EAGLContext *myContent;
@property(nonatomic,strong)CAEAGLLayer *myLayer;

@property(nonatomic,assign)GLuint myFrameBuffer;
@property(nonatomic,assign)GLuint myRenderBuffer;
@property(nonatomic,assign)GLuint myProgram;

//@property(nonatomic,assign)KSMatrix4 modelViewMat4;
@property (nonatomic , assign) GLuint  myVertices;

@end

@implementation HyView
{
    BOOL bX;
    BOOL bY;
    BOOL bZ;
    
    GLfloat xDegree;
    GLfloat yDegree;
    GLfloat zDegree;
    
    NSTimer *timer;
}
- (void)layoutSubviews {
    [self setupLayout];
    [self setupContent];
    [self cleanBuffer];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self setupShader];
    [self render];
}

//MARK: 1.setupLayout
+ (Class)layerClass{
    return [CAEAGLLayer class];
}
-(void)setupLayout{
    
    self.myLayer = (CAEAGLLayer *)self.layer;
    //TODO: 忘记
    self.myLayer.contentsScale = [[UIScreen mainScreen] scale];
    self.myLayer.opaque = YES;
    
    self.myLayer.drawableProperties = @{
        kEAGLDrawablePropertyRetainedBacking:@false,
        kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8
    };
}

//MARK: 2.setupContent
-(void)setupContent{
    self.myContent = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.myContent){
        NSLog(@"Content Create failed");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:self.myContent]) {
        NSLog(@"Set Current Context failed");
        exit(1);
    }
}

//MARK: 3.cleanBuffer
-(void)cleanBuffer{
    //TODO: 忘记
    glDeleteRenderbuffers(1, &_myRenderBuffer);
    glDeleteFramebuffers(1, &_myFrameBuffer);
    _myRenderBuffer = 0;
    _myFrameBuffer = 0;
}

//MARK: 4.setupRenderBuffer
-(void)setupRenderBuffer{
    GLuint render;
    glGenRenderbuffers(1, &render);
    glBindRenderbuffer(GL_RENDERBUFFER, render);
    self.myRenderBuffer = render;
    //TODO:忘记
    [self.myContent renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myLayer];
}

//MARK:5.setupFrameBuffer
-(void)setupFrameBuffer{
    GLuint frame;
    glGenFramebuffers(1, &frame);
    glBindFramebuffer(GL_FRAMEBUFFER, frame);
    self.myFrameBuffer = frame;
    //TODO:忘记
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myRenderBuffer);
}

//MARK: 6.setupShader
-(void)setupShader{
    GLuint vShader,fShader;
    
    NSString *cFile = [[NSBundle mainBundle] pathForResource:@"shaderV" ofType:@"any"];
    NSString *fFile = [[NSBundle mainBundle] pathForResource:@"shaderF" ofType:@"glsl"];
    
    [self compileShader:&vShader type:GL_VERTEX_SHADER path:cFile];
    [self compileShader:&fShader type:GL_FRAGMENT_SHADER path:fFile];
    
    //判断self.myProgram是否存在，存在则清空其文件
    if(self.myProgram){
        glDeleteProgram(self.myProgram);
        self.myProgram = 0;
    }
    
    self.myProgram = [self serUpProgram:vShader shaderF:fShader];
    
    glLinkProgram(self.myProgram);
    
    GLint status;
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        GLchar info[256];
        glGetProgramInfoLog(self.myProgram, sizeof(info), 0, &info[0]);
        NSString *message = [NSString stringWithUTF8String:info];
        NSLog(@"Link Program Failed Message:%@",message);
        return;
    }
    NSLog(@"glLinkProgram success");
    glUseProgram(self.myProgram);
}

-(void)compileShader:(GLuint *)shader type:(GLenum)type path:(NSString *)path{
    *shader = glCreateShader(type);
    const GLchar *source = (GLchar *) [[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] UTF8String];
    glShaderSource(*shader, 1, &source, NULL);
    if (*shader == 0) {
        NSLog(@"%i Shader Create Failed",type);
        return;
    }
    glCompileShader(*shader);
}

-(GLuint)serUpProgram:(GLuint)shaderV shaderF:(GLuint)shaderF {
    GLuint program;
    program = glCreateProgram();
    
    glAttachShader(program, shaderV);
    glAttachShader(program, shaderF);
    
    //TODO: 忘记
    glDeleteShader(shaderV);
    glDeleteShader(shaderF);
    
    return program;
}

//MARK: 7.render
-(void)render{
    glClearColor(0.2, 0.3, 0.7, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
//    glEnable(GL_DEPTH_TEST);
    
    
    //TODO:忘记
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale,
               self.frame.origin.y * scale,
               self.frame.size.width * scale,
               self.frame.size.height * scale);
    //顶点数组, 前3位顶点， 后3位颜色（RGB，A默认为1.0）
    GLfloat vertex[] = {
        -0.5f, 0.0f, -0.5f, 1.0f,0.0f,0.0f,  //左上
        -0.5f, 0.0f,  0.5f, 1.0f,0.5f,0.0f,  //左下
         0.5f, 0.0f,  0.5f, 0.5f,0.5f,0.5f,  //右下
         0.5f, 0.0f, -0.5f, 0.0f,0.5f,1.0f,  //右上
         0.0f, 1.0f,  0.0f, 1.0f,1.0f,1.0f,  //顶点
    };
    
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
    
    if (self.myVertices == 0) {
        glGenBuffers(1, &_myVertices);
    }
    glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertex), &vertex, GL_DYNAMIC_DRAW);
    
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    glEnableVertexAttribArray(position);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, (float *)NULL + 0);
    
    GLuint verColor = glGetAttribLocation(self.myProgram, "vertexColor");
    glEnableVertexAttribArray(verColor);
    glVertexAttribPointer(verColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, (float *)NULL + 3);
    
    //设置mvp矩阵
   
    //1.创建观察者矩阵
    KSMatrix4 projectMatrix;
    //1.1 创建单元矩阵
    ksMatrixLoadIdentity(&projectMatrix);
    GLfloat aspect = self.frame.size.width / self.frame.size.height;
    //1.2 设置观察者矩阵
    ksPerspective(&projectMatrix, 30.0, aspect, 5.0, 20.0);
    
    //2. 创建模型视图矩阵
    KSMatrix4 modelViewMatrix;
    //2.1 创建单元矩阵
    ksMatrixLoadIdentity(&modelViewMatrix);
    //2.2 平移变换
    ksTranslate(&modelViewMatrix, 0, 0, -6);
    //2.3 旋转变换
    ksRotate(&modelViewMatrix, xDegree, 1.0, 0, 0);
    ksRotate(&modelViewMatrix, yDegree, 0, 1.0, 0);
    ksRotate(&modelViewMatrix, zDegree, 0, 0, 1.0);
    
    //将mvp传给顶点着色器
    GLuint pShader, mShader;
    pShader = glGetUniformLocation(self.myProgram, "projectMatrix");
    /*
    void glUniformMatrix4fv(GLint location,  GLsizei count,  GLboolean transpose,  const GLfloat *value);
    参数列表：
    location:指要更改的uniform变量的位置
    count:更改矩阵的个数
    transpose:是否要转置矩阵，并将它作为uniform变量的值。必须为GL_FALSE
    value:执行count个元素的指针，用来更新指定uniform变量
    */
    glUniformMatrix4fv(pShader, 1, GL_FALSE, (GLfloat*)&projectMatrix.m[0][0]);
    mShader = glGetUniformLocation(self.myProgram, "viewModelMatrix");
    glUniformMatrix4fv(mShader, 1, GL_FALSE, (GLfloat*)&modelViewMatrix.m[0][0]);
    glEnable(GL_CULL_FACE);
    //使用索引绘图
    /*
     void glDrawElements(GLenum mode,GLsizei count,GLenum type,const GLvoid * indices);
     参数列表：
     mode:要呈现的画图的模型
                GL_POINTS
                GL_LINES
                GL_LINE_LOOP
                GL_LINE_STRIP
                GL_TRIANGLES
                GL_TRIANGLE_STRIP
                GL_TRIANGLE_FAN
     count:绘图个数
     type:类型
             GL_BYTE
             GL_UNSIGNED_BYTE
             GL_SHORT
             GL_UNSIGNED_SHORT
             GL_INT
             GL_UNSIGNED_INT
     indices：绘制索引数组

     */
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    
    //16.要求本地窗口系统显示OpenGL ES渲染<目标>xx
    [self.myContent presentRenderbuffer:GL_RENDERBUFFER];
}

-(void)x{
    if(!timer){
        timer = [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:YES block:^(NSTimer * _Nonnull timer) {
            self->xDegree += 0.5 * self->bX;
            self->yDegree += 0.5 * self->bY;
            self->zDegree += 0.5 * self->bZ;
            [self render];
        }];
    }
    bX = !bX;
}

-(void)y{
    if(!timer){
        timer = [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:YES block:^(NSTimer * _Nonnull timer) {
            self->xDegree += 0.5 * self->bX;
            self->yDegree += 0.5 * self->bY;
            self->zDegree += 0.5 * self->bZ;
            [self render];
        }];
    }
    bY = !bY;
}

-(void)z{
    
    if(!timer){
        timer = [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:YES block:^(NSTimer * _Nonnull timer) {
            self->xDegree += 0.5 * self->bX;
            self->yDegree += 0.5 * self->bY;
            self->zDegree += 0.5 * self->bZ;
            [self render];
        }];
    }
    bZ = !bZ;
}


@end
