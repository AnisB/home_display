cmake_minimum_required(VERSION 3.5)

function(sub_directory_list out_result target_dir)
  file(GLOB children RELATIVE ${target_dir} ${target_dir}/*)
  set(dirlist "")
  foreach(child ${children})
    if(IS_DIRECTORY ${target_dir}/${child})
      list(APPEND dirlist ${child})
    endif()
  endforeach()
  set("${out_result}" "${dirlist}" PARENT_SCOPE)
endfunction()

function(convert_to_absolute_paths out_list root_dir in_list)
  set(lst)
  foreach(item ${in_list})
    list(APPEND lst "${root_dir}/${item}")
  endforeach()
  set("${out_list}" "${lst}" PARENT_SCOPE)
endfunction()

function(bento_glob_filter out_filter dir)
  # Reset the var
  set(filter)
  # Generate the filter list
  foreach(extension ${bento_source_extensions})
    list(APPEND filter "${dir}/*${extension}")
  endforeach()
  # Override the output var
  set("${out_filter}" "${filter}" PARENT_SCOPE)
endfunction()

function(bento_headers out_absolute_files root_dir specific_filter)
  # Fetch the filters
  bento_glob_filter(filter "${root_dir}")
  # Fetch all the concerned files
  file(GLOB_RECURSE relative_files RELATIVE "${root_dir}" ${filter})
  # Convert them to absolute path
  convert_to_absolute_paths(absolute_files "${root_dir}" "${relative_files}")
  # Set filters
  source_group("${specific_filter}\\Header Files" FILES ${absolute_files})
  # Override the output var
  set("${out_absolute_files}" "${absolute_files}" PARENT_SCOPE)
endfunction()

function(bento_sources out_absolute_files root_dir specific_filter)
  # Fetch the filters
  bento_glob_filter(filter "${root_dir}")
  # Fetch all the concerned files
  file(GLOB_RECURSE relative_files RELATIVE "${root_dir}" ${filter})
  # Convert them to absolute path
  convert_to_absolute_paths(absolute_files "${root_dir}" "${relative_files}")
  # Set filters
  source_group("${specific_filter}\\Source Files" FILES ${absolute_files})
  # Override the output var
  set("${out_absolute_files}" "${absolute_files}" PARENT_SCOPE)
endfunction()

function(bento_static_lib lib folder sources include_dirs)
  # Add the library as static
  add_library("${lib}" STATIC ${sources})
  # Set properties 
  set_target_properties("${lib}" PROPERTIES COMPILE_PDB_NAME "${lib}")
  set_target_properties("${lib}" PROPERTIES FOLDER "${folder}")
  # Log the generation
  message(STATUS "Static project ${lib} has been generated")
  # Set include directories
  target_include_directories("${lib}" PUBLIC ${include_dirs})
endfunction()

function(bento_dynamic_lib lib folder sources include_dirs)
  # Add the library as static
  add_library("${lib}" SHARED ${sources})
  # Set properties 
  set_target_properties("${lib}" PROPERTIES COMPILE_PDB_NAME "${lib}")
  set_target_properties("${lib}" PROPERTIES FOLDER "${folder}")
  # Log the generation
  message(STATUS "Shared project ${lib} has been generated")
  # Set include directories
  target_include_directories("${lib}" PUBLIC ${include_dirs})
endfunction()

function(bento_exe exe sourcegroup sources includes)
  # Generate the exe
  add_executable("${exe}" ${sources})
  # Set properties 
  set_target_properties("${exe}" PROPERTIES COMPILE_PDB_NAME "${exe}")
  set_target_properties("${exe}" PROPERTIES FOLDER "${sourcegroup}")
  # Log the generation
  message(STATUS "Executable ${sourcegroup} has been generated")
  # Set includes
  target_include_directories("${exe}" PRIVATE ${includes})
endfunction()

# Replace compilation flags, configuration type is optional
macro(replace_compile_flags pSearch pReplace)
  set(MacroArgs "${ARGN}")
  if( NOT MacroArgs )
    string(REGEX REPLACE "${pSearch}" "${pReplace}" CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
    string(REGEX REPLACE "${pSearch}" "${pReplace}" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
  else()
    foreach(MacroArg IN LISTS MacroArgs)
      if( MacroArg STREQUAL "debug" )
        string(REGEX REPLACE "${pSearch}" "${pReplace}" CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG}")
        string(REGEX REPLACE "${pSearch}" "${pReplace}" CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG}")
      elseif( MacroArg STREQUAL "dev" )
        string(REGEX REPLACE "${pSearch}" "${pReplace}" CMAKE_C_FLAGS_DEV "${CMAKE_C_FLAGS_DEV}")
        string(REGEX REPLACE "${pSearch}" "${pReplace}" CMAKE_CXX_FLAGS_DEV "${CMAKE_CXX_FLAGS_DEV}")
      elseif( MacroArg STREQUAL "release" )
        string(REGEX REPLACE "${pSearch}" "${pReplace}" CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}")
        string(REGEX REPLACE "${pSearch}" "${pReplace}" CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}")
      else()
        message(FATAL_ERROR "Unknown configuration, cannot replace compile flags!")
      endif()
    endforeach()
  endif()
endmacro()

# Add exe linker flags, configuration type is optional
macro(add_exe_linker_flags pFlags)
  set(MacroArgs "${ARGN}")
  if( NOT MacroArgs )
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${pFlags}")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${pFlags}")
    set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} ${pFlags}")
  else()
    foreach(MacroArg IN LISTS MacroArgs)
      if( MacroArg STREQUAL "debug" )
        set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG} ${pFlags}")
        set(CMAKE_SHARED_LINKER_FLAGS_DEBUG "${CMAKE_SHARED_LINKER_FLAGS_DEBUG} ${pFlags}")
        set(CMAKE_MODULE_LINKER_FLAGS_DEBUG "${CMAKE_MODULE_LINKER_FLAGS_DEBUG} ${pFlags}")
      elseif( MacroArg STREQUAL "dev" )
        set(CMAKE_EXE_LINKER_FLAGS_DEV "${CMAKE_EXE_LINKER_FLAGS_DEV} ${pFlags}")
        set(CMAKE_SHARED_LINKER_FLAGS_DEV "${CMAKE_SHARED_LINKER_FLAGS_DEV} ${pFlags}")
        set(CMAKE_MODULE_LINKER_FLAGS_DEV "${CMAKE_MODULE_LINKER_FLAGS_DEV} ${pFlags}")
      elseif( MacroArg STREQUAL "release" )
        set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} ${pFlags}")
        set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} ${pFlags}")
        set(CMAKE_MODULE_LINKER_FLAGS_RELEASE "${CMAKE_MODULE_LINKER_FLAGS_RELEASE} ${pFlags}")
      else()
        message(FATAL_ERROR "Unknown configuration, cannot add linker flags!")
      endif()
    endforeach()
  endif()
endmacro()

# Replace linker flags, configuration type is optional
macro(replace_linker_flags pSearch pReplace)
  set(MacroArgs "${ARGN}")
  if( NOT MacroArgs )
    string(REGEX REPLACE "${pSearch}" "${pReplace}" CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}")
    string(REGEX REPLACE "${pSearch}" "${pReplace}" CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS}")
    string(REGEX REPLACE "${pSearch}" "${pReplace}" CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS}")
  else()
    foreach(MacroArg IN LISTS MacroArgs)
      if( MacroArg STREQUAL "debug" )
        string(REGEX REPLACE "${pSearch}" "${pReplace}" CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG}")
        string(REGEX REPLACE "${pSearch}" "${pReplace}" CMAKE_SHARED_LINKER_FLAGS_DEBUG "${CMAKE_SHARED_LINKER_FLAGS_DEBUG}")
        string(REGEX REPLACE "${pSearch}" "${pReplace}" CMAKE_MODULE_LINKER_FLAGS_DEBUG "${CMAKE_MODULE_LINKER_FLAGS_DEBUG}")
      elseif( MacroArg STREQUAL "dev" )
        string(REGEX REPLACE "${pSearch}" "${pReplace}" CMAKE_EXE_LINKER_FLAGS_DEV "${CMAKE_EXE_LINKER_FLAGS_DEV}")
        string(REGEX REPLACE "${pSearch}" "${pReplace}" CMAKE_SHARED_LINKER_FLAGS_DEV "${CMAKE_SHARED_LINKER_FLAGS_DEV}")
        string(REGEX REPLACE "${pSearch}" "${pReplace}" CMAKE_MODULE_LINKER_FLAGS_DEV "${CMAKE_MODULE_LINKER_FLAGS_DEV}")
      elseif( MacroArg STREQUAL "release" )
        string(REGEX REPLACE "${pSearch}" "${pReplace}" CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
        string(REGEX REPLACE "${pSearch}" "${pReplace}" CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
        string(REGEX REPLACE "${pSearch}" "${pReplace}" CMAKE_MODULE_LINKER_FLAGS_RELEASE "${CMAKE_MODULE_LINKER_FLAGS_RELEASE}")
      else()
        message(FATAL_ERROR "Unknown configuration, cannot replace linker flags!")
      endif()
    endforeach()
  endif()
endmacro()

function(copy_dependencies output_folder)
  if( PLATFORM_WINDOWS )
    file(GLOB files "${CHECKUP_3RD_BIN}/*.dll")
    foreach(file ${files})
      file(COPY ${file} DESTINATION ${output_folder})
    endforeach()
  endif ()
  file(COPY "${CHECKUP_DATA_ROOT}/config.json" DESTINATION ${output_folder})
  file(COPY "${CHECKUP_DATA_ROOT}/Raleway-Regular.ttf" DESTINATION ${output_folder})
endfunction()
