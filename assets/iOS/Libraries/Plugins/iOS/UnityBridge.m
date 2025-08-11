#import <Foundation/Foundation.h>

// Фиктивная, "слабая" (weak) реализация функции _sendMessageToFlutter.
// Это нужно, чтобы проект Unity-iPhone мог собраться без ошибок компоновки.
// При сборке финального Flutter-приложения, настоящая реализация из пакета
// flutter_embed_unity переопределит эту.
__attribute__((weak)) void _sendMessageToFlutter(const char* message) {
    NSLog(@"[Unity-Dummy] _sendMessageToFlutter called with message: %s. This is a weak implementation and should be overridden by the Flutter host app.", message);
}
