//
//  IOBluetoothDevice+Remove.h
//  MultiversalControl
//
//  Created by Igor Bielopolskyi on 9/6/22.
//

#import <IOBluetooth/IOBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface IOBluetoothDevice (Remove)
- (int) unpair;
@end

NS_ASSUME_NONNULL_END
