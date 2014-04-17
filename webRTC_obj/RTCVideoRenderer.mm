/*
 * libjingle
 * Copyright 2013, Google Inc.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *  1. Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *  3. The name of the author may not be used to endorse or promote products
 *     derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "RTCVideoRenderer+Internal.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "RTCI420Frame.h"
#import "RTCVideoRendererDelegate.h"
#import "webrtc/modules/video_render/ios/video_render_ios_view.h"
#import "webrtc/modules/video_render/ios/video_render_ios_impl.h"
#include "common_video/interface/i420_video_frame.h"
#include "talk/media/base/videoframe.h"


#include "talk/app/webrtc/mediastreaminterface.h"
#include "webrtc/modules/video_render/include/video_render_defines.h"

class CallbackConverter : public webrtc::VideoRendererInterface {
    
public:
    CallbackConverter(webrtc::VideoRenderCallback *callback, const uint32_t streamId) : callback_(callback), streamId_(streamId) {}
    
    virtual void SetSize(int width, int height) {};
    virtual void RenderFrame(const cricket::VideoFrame* frame) {
      NSLog(@"*** HERE in RTCVideoRenderer.mm 0");

      //Make this into an I420VideoFrame
    
      size_t width = frame->GetWidth();
      size_t height = frame->GetHeight();
    
      size_t y_plane_size = width * height;
      size_t uv_plane_size = frame->GetChromaSize();
        
      webrtc::I420VideoFrame *i420Frame = new webrtc::I420VideoFrame();
      i420Frame->CreateFrame(
        y_plane_size, frame->GetYPlane(),
        uv_plane_size, frame->GetUPlane(),
        uv_plane_size, frame->GetVPlane(),
        width, height,
        frame->GetYPitch(), frame->GetUPitch(), frame->GetVPitch());
        
      i420Frame->set_render_time_ms(frame->GetTimeStamp() / 1000000);
        
      callback_->RenderFrame(streamId_, *i420Frame);
    
      delete i420Frame;
    }
    
private:
    webrtc::VideoRenderCallback *callback_;
    const uint32_t streamId_;
};


@implementation RTCVideoRenderer {
  CallbackConverter *_renderer;
  talk_base::scoped_ptr<webrtc::VideoRenderIosImpl> _iosRenderer;
}

+ (RTCVideoRenderer *)videoRenderGUIWithFrame:(CGRect)frame {
  // TODO (hughv): Implement.
  NSLog(@"*** HERE in RTCVideoRenderer.mm 1");
  return nil;
}

- (id)initWithDelegate:(id<RTCVideoRendererDelegate>)delegate {
  if ((self = [super init])) {
    _delegate = delegate;
    // TODO (hughv): Create video renderer.
  }
  NSLog(@"*** HERE in RTCVideoRenderer.mm 2");
  return self;
}

+ (UIView<RTCVideoRenderView> *)newRenderViewWithFrame:(CGRect)frame {
  VideoRenderIosView *newView = [[VideoRenderIosView alloc] initWithFrame:frame];
  NSLog(@"*** HERE in RTCVideoRenderer.mm 3");

  return (UIView<RTCVideoRenderView> *)newView;
}

- (id)initWithRenderView:(UIView<RTCVideoRenderView> *)view {
  NSAssert([view isKindOfClass:[VideoRenderIosView class]], @"The view must be a render view");
  NSLog(@"*** HERE in RTCVideoRenderer.mm 4");

  if ((self = [super init])) {
    VideoRenderIosView *renderView = (VideoRenderIosView *)view;
  
    webrtc::VideoRenderIosImpl* ptrRenderer = new webrtc::VideoRenderIosImpl(0, (__bridge void *)renderView, NO);
    if (ptrRenderer->Init() != -1) {
    
      _iosRenderer.reset(ptrRenderer);
      
      webrtc::VideoRenderCallback *callback = _iosRenderer->AddIncomingRenderStream(0, 1, 0, 0, 1, 1);
      _renderer = new CallbackConverter(callback, 0);
      
      _iosRenderer->StartRender();
      
    } else {
      return nil;
    }
    
  }
  return self;

}

- (BOOL)start {
  NSLog(@"*** HERE in RTCVideoRenderer.mm START Render");

  return _iosRenderer->StartRender();
}

- (BOOL)stop {
  NSLog(@"*** HERE in RTCVideoRenderer.mm STOP Render");

  return _iosRenderer->StopRender();
}

@end

@implementation RTCVideoRenderer (Internal)

- (id)initWithVideoRenderer:(webrtc::VideoRendererInterface *)videoRenderer {
  NSLog(@"*** HERE in RTCVideoRenderer.mm 5");

  if ((self = [super init])) {
    //_renderer.reset(videoRenderer);
  }
  return self;
}

- (webrtc::VideoRendererInterface *)videoRenderer {
  NSLog(@"*** HERE in RTCVideoRenderer.mm 6");

  return _renderer;
}

@end
