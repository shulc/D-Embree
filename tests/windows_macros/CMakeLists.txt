# Compiler-wide flags are directory-scoped, while ISA and strict FP options
# belong to the target. Compile the same source with both production contexts.
get_target_property(embree_source_dir embree SOURCE_DIR)
get_directory_property(embree_variables DIRECTORY "${embree_source_dir}" VARIABLES)
foreach(variable IN LISTS embree_variables)
  if(variable MATCHES "^CMAKE_CXX_FLAGS($|_)")
    get_directory_property(value DIRECTORY "${embree_source_dir}" DEFINITION "${variable}")
    set("${variable}" "${value}")
  endif()
endforeach()

# Compile the real scalar USER traversal with the legacy Windows SDK macros.
# This also detects the collision on hosts without the Windows headers.
set(embree_intersector "${dembree_upstream_SOURCE_DIR}/kernels/bvh/bvh_intersector1_bvh4.cpp")
add_library(dembree_windows_macros OBJECT EXCLUDE_FROM_ALL "${embree_intersector}")
# The pinned upstream assigns per-source stack-protector flags in its own directory.
# Copy that value into this target's directory without changing production.
get_property(embree_source_flags SOURCE "${embree_intersector}"
  TARGET_DIRECTORY embree PROPERTY COMPILE_FLAGS)
set_property(SOURCE "${embree_intersector}" TARGET_DIRECTORY dembree_windows_macros
  PROPERTY COMPILE_FLAGS "${embree_source_flags}")
get_property(embree_compile_flags TARGET embree PROPERTY COMPILE_FLAGS)
set_property(TARGET dembree_windows_macros PROPERTY COMPILE_FLAGS "${embree_compile_flags}")
target_include_directories(dembree_windows_macros PRIVATE
  "$<TARGET_PROPERTY:embree,INCLUDE_DIRECTORIES>")
target_compile_options(dembree_windows_macros PRIVATE
  "$<TARGET_PROPERTY:embree,COMPILE_OPTIONS>")
target_compile_definitions(dembree_windows_macros PRIVATE
  "$<TARGET_PROPERTY:embree,COMPILE_DEFINITIONS>" near= far=)
add_test(NAME dembree_windows_macros COMMAND "${CMAKE_COMMAND}" --build
  "${CMAKE_BINARY_DIR}" --config $<CONFIG> --target dembree_windows_macros)
