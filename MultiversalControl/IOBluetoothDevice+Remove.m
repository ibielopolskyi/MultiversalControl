//
//  IOBluetoothDevice+Remove.m
//  MultiversalControl
//
//  Created by Igor Bielopolskyi on 9/6/22.
//

#import "IOBluetoothDevice+Remove.h"
#include <sysexits.h>
#include <regex.h>

#define STRINGIFY_(x) #x
#define STRINGIFY(x) STRINGIFY_(x)

//void *assert_alloc(void *pointer) {
//  if (pointer == NULL) {
//    printf("%s\n", strerror(errno));
//    exit(EX_OSERR);
//  }
//  return pointer;
//}
//
//int assert_reg(int errcode, const regex_t *restrict preg, char *reason) {
//  if (errcode == 0 || errcode == REG_NOMATCH) return errcode;
//
//  size_t errbuf_size = regerror(errcode, preg, NULL, 0);
//  char *restrict errbuf = assert_alloc(malloc(errbuf_size));
//  regerror(errcode, preg, errbuf, errbuf_size);
//
//  printf("%s: %s\n", reason, errbuf);
//  exit(EX_SOFTWARE);
//}
//
//bool check_device_address_arg(char *arg) {
//  regex_t regex;
//  int result;
//
//  result = regcomp(&regex,
//    "^[0-9a-f]{2}([0-9a-f]{10}|(-[0-9a-f]{2}){5}|(:[0-9a-f]{2}){5})$",
//    REG_EXTENDED | REG_ICASE | REG_NOSUB);
//  assert_reg(result, &regex, "Compiling device address regex");
//
//  result = regexec(&regex, arg, 0, NULL, 0);
//  assert_reg(result, &regex, "Matching device address regex");
//
//  regfree(&regex);
//
//  return result == 0;
//}
//
//IOBluetoothDevice *get_device(char *id) {
//  NSString *nsId = [NSString stringWithCString:id encoding:[NSString defaultCStringEncoding]];
//
//  IOBluetoothDevice *device = nil;
//
//  if (check_device_address_arg(id)) {
//    device = [IOBluetoothDevice deviceWithAddressString:nsId];
//
//    if (!device) {
//      printf("Device not found by address: %s\n", id);
//      exit(EXIT_FAILURE);
//    }
//  } else {
//    NSArray *recentDevices = [IOBluetoothDevice recentDevices:0];
//
//    if (!recentDevices) {
//      printf("No recent devices to search for: %s\n", id);
//      exit(EXIT_FAILURE);
//    }
//
//    NSArray *byName = [recentDevices filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@", nsId]];
//    if (byName.count > 0) {
//      device = byName.firstObject;
//    }
//
//    if (!device) {
//      printf("Device not found by name: %s\n", id);
//      exit(EXIT_FAILURE);
//    }
//  }
//    return device;
//}
//size_t cmd_n = 0, cmd_reserved = 0;
//struct cmd_with_args *cmds = NULL;
//#define CMD_CHUNK 8
//
//void add_cmd(void *args, cmd cmd) {
//  if (cmd_n >= cmd_reserved) {
//    cmd_reserved += CMD_CHUNK;
//    cmds = assert_alloc(reallocf(cmds, sizeof(struct cmd_with_args) * cmd_reserved));
//  }
//  cmds[cmd_n++] = (struct cmd_with_args){.cmd = cmd, .args = args};
//}
//struct args_device_id {
//  char *device_id;
//};
//
//-(int) remove(device_id) {
//    ALLOC_ARGS(device_id);
//
//    args->device_id = optarg;
//
//    add_cmd(args, ^int(void *_args) {
//      struct args_device_id *args = (struct args_device_id *)_args;
//
//      IOBluetoothDevice *device = get_device(args->device_id);
//
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wundeclared-selector"
//      if ([device respondsToSelector:@selector(remove)]) {
//        [device performSelector:@selector(remove)];
//#pragma clang diagnostic pop
//        return EXIT_SUCCESS;
//      } else {
//        return EX_UNAVAILABLE;
//      }
//    });
//}

@implementation IOBluetoothDevice (Remove)
-(int) unpair {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
          if ([self respondsToSelector:@selector(remove)]) {
            [self performSelector:@selector(remove)];
#pragma clang diagnostic pop
            return EXIT_SUCCESS;
          } else {
            return EX_UNAVAILABLE;
          }
}
@end
