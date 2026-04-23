add_executable(MacResizeLoopMetal MACOSX_BUNDLE main.mm)

target_compile_options(MacResizeLoopMetal PRIVATE -fobjc-arc -Wall -Wextra)
target_link_libraries(MacResizeLoopMetal PRIVATE "-framework Cocoa" "-framework Metal" "-framework MetalKit")

set_target_properties(MacResizeLoopMetal PROPERTIES
    MACOSX_BUNDLE_BUNDLE_NAME MacResizeLoopMetal
    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.MacResizeLoopMetal
    MACOSX_BUNDLE_BUNDLE_VERSION 1.0
    MACOSX_BUNDLE_SHORT_VERSION_STRING 1.0
)
