set(rtn_smartassets_generated_dir "${CMAKE_CURRENT_SOURCE_DIR}/generated")

file(GLOB_RECURSE rtn_smartassets_generated_SRC "${rtn_smartassets_generated_dir}/**/*.cpp")

file(GLOB rtn_smartassets_SRC CONFIGURE_DEPENDS *.cpp)

add_library(smartassets SHARED ${rtn_smartassets_SRC} ${rtn_smartassets_generated_SRC})

target_include_directories(smartassets PUBLIC ${CMAKE_CURRENT_SOURCE_DIR} ${rtn_smartassets_generated_dir})

target_link_libraries(smartassets PUBLIC rnoh)