cmake_minimum_required(VERSION 3.20)
project(MacResizeLoop LANGUAGES OBJCXX)

add_executable(MacResizeLoop MACOSX_BUNDLE src/main.mm)

target_compile_options(MacResizeLoop PRIVATE -fobjc-arc -Wall -Wextra)
target_link_libraries(MacResizeLoop PRIVATE "-framework Cocoa")

set_target_properties(MacResizeLoop PROPERTIES
    MACOSX_BUNDLE_BUNDLE_NAME MacResizeLoop
    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.MacResizeLoop
    MACOSX_BUNDLE_BUNDLE_VERSION 1.0
    MACOSX_BUNDLE_SHORT_VERSION_STRING 1.0
)
