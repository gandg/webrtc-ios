#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "RTCDataChannel+Internal.h"

namespace webrtc {

class RTCDataChannelObserver
    : public DataChannelObserver {
 public:
  RTCDataChannelObserver(id<RTCDataChannelDelegate> delegate, RTCDataChannel *dataChannel) {
    _delegate = delegate;
    _dataChannel = dataChannel;
  }
  
  virtual void OnStateChange() {
    BOOL isOpen = [_dataChannel dataChannel]->state() == webrtc::DataChannelInterface::DataState::kOpen;
    
    [_delegate dataChannel:_dataChannel stateChange:isOpen];
  }
  
  virtual void OnMessage(const webrtc::DataBuffer& buffer) {
    NSData *message = [NSData dataWithBytes:buffer.data.data() length:buffer.data.length()];
    [_delegate dataChannel:_dataChannel gotMessage:message];
  }

 private:
  __weak id<RTCDataChannelDelegate> _delegate;
  __weak RTCDataChannel *_dataChannel;
};

};

@implementation RTCDataChannel {
  talk_base::scoped_refptr<webrtc::DataChannelInterface> _dataChannel;
  webrtc::RTCDataChannelObserver *_channelObserver;
}

- (void)send:(NSData *)message {
  talk_base::Buffer buffer([message bytes], [message length]);
  webrtc::DataBuffer dataBuffer(buffer, true); // We set false for the binary flag because channels don't support binary data yet. This means we must always assume it was binary data
  _dataChannel->Send(dataBuffer);
}

- (void)setDelegate:(id<RTCDataChannelDelegate>)delegate {
  if (_channelObserver) {
    _dataChannel->UnregisterObserver();
    delete _channelObserver;
    _channelObserver = NULL;
  }
  
  _delegate = delegate;
  if (_delegate) {
    _channelObserver = new webrtc::RTCDataChannelObserver(delegate, self);
    _dataChannel->RegisterObserver(_channelObserver);
  }
}

- (void)dealloc {
  if (_channelObserver) {
    _dataChannel->UnregisterObserver();
    delete _channelObserver;
    _channelObserver = NULL;
  }
}

@end

@implementation RTCDataChannel (Internal)

- (id)initWithDataChannel:
        (talk_base::scoped_refptr<webrtc::DataChannelInterface>)dataChannel {
  if (!dataChannel) {
    NSAssert(NO, @"nil arguments not allowed");
    self = nil;
    return nil;
  }
  if ((self = [super init])) {
    _dataChannel = dataChannel;
  }
  return self;
}

- (talk_base::scoped_refptr<webrtc::DataChannelInterface>)dataChannel {
  return _dataChannel;
}

@end
